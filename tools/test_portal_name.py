"""Bounded mDNS and optional verified-HTTPS checks for the service access point.

Specify the PC's Wi-Fi IPv4 address with --interface-ip so Ethernet stays out of
the test. The default legacy query uses an ephemeral source port and requests a
unicast reply (RFC 6762 sections 5.1 and 6.7). --mode qu instead uses port 5353
and the QU question bit; a system mDNS service may already own/share that port.

--ca additionally checks HTTPS using the expected IP as the TCP destination and
the .local name as TLS SNI, certificate SAN and HTTP Host. It never disables
certificate verification or relies on the operating system's name resolver.
--self-test validates packet handling offline and opens no sockets.
"""

import argparse
import hashlib
import http.client
import ipaddress
import json
from pathlib import Path
import re
import secrets
import socket
import ssl
import struct
import sys
import threading
import time


GROUP = "224.0.0.251"
PORT = 5353
MAX_RECORDS = 128
MAX_HTTP_BODY = 256 * 1024


def dns_name(name):
    labels = name.rstrip(".").encode("ascii").split(b".")
    if any(not label or len(label) > 63 for label in labels):
        raise ValueError("invalid DNS label")
    encoded = b"".join(bytes([len(label)]) + label for label in labels) + b"\0"
    if len(encoded) > 255:
        raise ValueError("DNS name too long")
    return encoded


def make_query(name, query_id, qu=False):
    return struct.pack("!6H", query_id, 0, 1, 0, 0, 0) + dns_name(name) + struct.pack("!HH", 1, 0x8001 if qu else 1)


def read_name(packet, offset):
    """Read a compressed name with bounded expansion and cycle detection."""
    labels, seen = [], set()
    end, expanded = None, 1
    while True:
        if offset >= len(packet) or offset in seen:
            raise ValueError("truncated or cyclic DNS name")
        seen.add(offset)
        length = packet[offset]
        if length & 0xC0 == 0xC0:
            if offset + 1 >= len(packet):
                raise ValueError("truncated DNS pointer")
            pointer = ((length & 0x3F) << 8) | packet[offset + 1]
            if pointer >= offset:
                raise ValueError("DNS pointer must refer to an earlier name")
            if end is None:
                end = offset + 2
            offset = pointer
            continue
        if length & 0xC0:
            raise ValueError("unsupported DNS label")
        offset += 1
        if length == 0:
            return ".".join(labels).lower(), end if end is not None else offset
        expanded += length + 1
        if offset + length > len(packet) or expanded > 255:
            raise ValueError("truncated or oversized DNS name")
        labels.append(packet[offset:offset + length].decode("utf-8"))
        offset += length


def parse_response(packet):
    if len(packet) < 12:
        raise ValueError("truncated DNS header")
    query_id, flags, questions, answers, authority, additional = struct.unpack_from("!6H", packet)
    if not flags & 0x8000 or flags & 0x7A0F:
        raise ValueError("not a complete successful DNS response")
    if questions + answers + authority + additional > MAX_RECORDS:
        raise ValueError("too many DNS records")
    offset = 12
    for _ in range(questions):
        _, offset = read_name(packet, offset)
        if offset + 4 > len(packet):
            raise ValueError("truncated DNS question")
        offset += 4
    records = []
    for _ in range(answers + authority + additional):
        name, offset = read_name(packet, offset)
        if offset + 10 > len(packet):
            raise ValueError("truncated DNS record")
        record_type, record_class, ttl, length = struct.unpack_from("!HHIH", packet, offset)
        offset += 10
        if offset + length > len(packet):
            raise ValueError("truncated DNS data")
        if record_type == 1 and record_class & 0x7FFF == 1 and length == 4 and ttl:
            records.append({"name": name, "address": socket.inet_ntoa(packet[offset:offset + length]), "ttl": ttl})
        offset += length
    return query_id, records


def resolve_mdns(interface_ip, name, expected_ip, mode="legacy", timeout=2.0, attempts=3):
    query_id = secrets.randbelow(65535) + 1 if mode == "legacy" else 0
    query = make_query(name, query_id, qu=mode == "qu")
    started, ignored, wrong_addresses = time.monotonic(), 0, set()
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP) as udp:
        if mode == "qu":
            udp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            udp.bind(("", PORT))
            udp.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, socket.inet_aton(GROUP) + socket.inet_aton(interface_ip))
        else:
            udp.bind((interface_ip, 0))
        udp.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_IF, socket.inet_aton(interface_ip))
        udp.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 255)
        for attempt in range(1, attempts + 1):
            udp.sendto(query, (GROUP, PORT))
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                udp.settimeout(max(0.001, deadline - time.monotonic()))
                try:
                    packet, sender = udp.recvfrom(9000)
                except socket.timeout:
                    break
                if sender != (expected_ip, PORT):
                    ignored += 1
                    continue
                try:
                    response_id, records = parse_response(packet)
                except (ValueError, UnicodeError):
                    ignored += 1
                    continue
                if response_id != query_id:
                    ignored += 1
                    continue
                for record in records:
                    if record["name"] != name:
                        continue
                    if record["address"] == expected_ip:
                        return {"phase": "mdns", "ok": True, "name": name, "address": expected_ip,
                                "source": sender[0], "mode": mode, "attempt": attempt,
                                "ttl": record["ttl"], "ignoredPackets": ignored,
                                "elapsedMs": round((time.monotonic() - started) * 1000)}
                    wrong_addresses.add(record["address"])
    if wrong_addresses:
        raise RuntimeError("mDNS returned unexpected addresses: " + ",".join(sorted(wrong_addresses)))
    raise TimeoutError("No matching mDNS answer from the expected device on the selected Wi-Fi interface")


def check_https(interface_ip, name, expected_ip, ca, timeout=10.0):
    context = ssl.create_default_context(cafile=str(ca))
    context.hostname_checks_common_name = False  # Require the SAN used by modern browsers.
    started = time.monotonic()
    deadline = started + timeout
    with socket.create_connection((expected_ip, 443), timeout=timeout, source_address=(interface_ip, 0)) as tcp:
        tcp.settimeout(max(0.001, deadline - time.monotonic()))
        with context.wrap_socket(tcp, server_hostname=name) as tls:
            handshake_ms = round((time.monotonic() - started) * 1000)
            certificate = tls.getpeercert(binary_form=True)
            expired = threading.Event()

            def interrupt():
                expired.set()
                try:
                    tls.shutdown(socket.SHUT_RDWR)
                except OSError:
                    pass

            # Socket inactivity timeouts alone do not bound a slowly dripped
            # HTTP response. This deadline also interrupts its buffered reads.
            timer = threading.Timer(max(0.001, deadline - time.monotonic()), interrupt)
            timer.daemon = True
            timer.start()
            try:
                tls.sendall(("GET / HTTP/1.1\r\nHost: " + name + "\r\nConnection: close\r\n\r\n").encode("ascii"))
                response = http.client.HTTPResponse(tls)
                response.begin()
                size = 0
                while True:
                    chunk = response.read(min(16384, MAX_HTTP_BODY - size + 1))
                    if not chunk:
                        break
                    size += len(chunk)
                    if size > MAX_HTTP_BODY:
                        raise RuntimeError("HTTPS response exceeded the bounded body limit")
                if expired.is_set():
                    raise TimeoutError("HTTPS total deadline exceeded")
                if response.status != 200 or "text/html" not in response.getheader("Content-Type", ""):
                    raise RuntimeError("Unexpected HTTPS portal status or content type")
                return {"phase": "https", "ok": True, "name": name, "address": expected_ip,
                        "certificateAndSanVerified": True, "status": response.status, "bytes": size,
                        "certificateSha256": hashlib.sha256(certificate).hexdigest(),
                        "handshakeMs": handshake_ms, "elapsedMs": round((time.monotonic() - started) * 1000)}
            finally:
                timer.cancel()


def self_test():
    name, query_id = "batterysentinel.local", 42
    query = make_query(name, query_id)
    response = struct.pack("!6H", query_id, 0x8400, 1, 1, 0, 0) + query[12:]
    response += b"\xc0\x0c" + struct.pack("!HHIH", 1, 0x8001, 10, 4) + socket.inet_aton("192.168.4.1")
    assert parse_response(response) == (query_id, [{"name": name, "address": "192.168.4.1", "ttl": 10}])
    assert struct.unpack("!H", make_query(name, 0, qu=True)[-2:])[0] == 0x8001
    # Every truncated version must fail, including a missing IPv4 byte.
    for length in range(len(response)):
        try:
            parse_response(response[:length])
        except (ValueError, UnicodeError):
            continue
        raise AssertionError("Accepted truncated response at " + str(length))
    for malformed in (b"\xc0\x00", b"\xc0", b"\x40", b"\x03ab", b"\xc0\xff"):
        try:
            read_name(malformed, 0)
        except (ValueError, UnicodeError):
            continue
        raise AssertionError("Accepted malformed name")
    # Explicit no-question response also covers the usual QU response layout.
    no_question = struct.pack("!6H", 0, 0x8400, 0, 1, 0, 0) + dns_name(name)
    no_question += struct.pack("!HHIH", 1, 1, 0, 4) + socket.inet_aton("192.168.4.1")
    assert parse_response(no_question) == (0, []), "Do not accept goodbye records as successful resolution"
    return {"phase": "self-test", "ok": True, "checks": "compressed A, QU encoding, truncation, malformed names, goodbye TTL"}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--interface-ip", help="PC IPv4 address on the ESP service Wi-Fi (required except for --self-test)")
    parser.add_argument("--name", default="batterysentinel.local")
    parser.add_argument("--expected-ip", default="192.168.4.1")
    parser.add_argument("--mode", choices=("legacy", "qu"), default="legacy")
    parser.add_argument("--timeout", type=float, default=2.0, help="Seconds per mDNS attempt, 0.1 to 10")
    parser.add_argument("--attempts", type=int, default=3, help="mDNS attempts, 1 to 5")
    parser.add_argument("--ca", type=Path, help="Trusted device certificate; enables HTTPS SAN/Host verification")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        print(json.dumps(self_test(), separators=(",", ":")))
        return 0
    if not args.interface_ip:
        parser.error("--interface-ip is required for device checks")
    if not 0.1 <= args.timeout <= 10 or not 1 <= args.attempts <= 5:
        parser.error("mDNS timeout/attempts outside the bounded range")
    name = args.name.rstrip(".").lower()
    if not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.local", name):
        parser.error("--name must be a single ASCII hostname followed by .local")
    try:
        interface_ip = str(ipaddress.IPv4Address(args.interface_ip))
        expected_ip = str(ipaddress.IPv4Address(args.expected_ip))
        print(json.dumps(resolve_mdns(interface_ip, name, expected_ip, args.mode, args.timeout, args.attempts)), flush=True)
        if args.ca:
            print(json.dumps(check_https(interface_ip, name, expected_ip, args.ca)), flush=True)
        return 0
    except (OSError, ValueError, RuntimeError, http.client.HTTPException) as error:
        print(json.dumps({"ok": False, "error": type(error).__name__, "detail": str(error)}), file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
