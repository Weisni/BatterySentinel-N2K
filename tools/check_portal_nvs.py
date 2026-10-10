"""Compare private unencrypted NVS readbacks without printing stored values.

The only optional export is the public HTTPS certificate for physically obtained
TLS trust. Never place readbacks or private keys in the repository. Format:
https://docs.espressif.com/projects/esp-idf/en/v4.4.7/esp32c3/api-reference/storage/nvs_flash.html#internals
"""

import argparse
import json
from pathlib import Path
import ssl
import struct
import zlib


def decode_application(blob):
    if not blob or len(blob) % 4096:
        raise ValueError("Invalid partition size")
    entries = []
    pages = [blob[offset:offset + 4096] for offset in range(0, len(blob), 4096)]
    pages = [page for page in pages if struct.unpack_from("<I", page)[0]
             in (0xfffffffe, 0xfffffffc)]
    for page in sorted(pages, key=lambda value: struct.unpack_from("<I", value, 4)[0]):
        if zlib.crc32(page[4:28], 0xffffffff) != struct.unpack_from("<I", page, 28)[0]:
            raise ValueError("Invalid page CRC")
        bitmap = int.from_bytes(page[32:64], "little")
        index = 0
        while index < 126:
            if (bitmap >> (2 * index)) & 3 != 2:
                index += 1
                continue
            entry = page[64 + index * 32:96 + index * 32]
            namespace, kind, span, chunk = entry[:4]
            if not 1 <= span <= 126 - index or not all(
                    (bitmap >> (2 * position)) & 3 == 2
                    for position in range(index, index + span)):
                raise ValueError("Invalid entry span/state")
            if zlib.crc32(entry[:4] + entry[8:], 0xffffffff) != struct.unpack_from("<I", entry, 4)[0]:
                raise ValueError("Invalid entry CRC")
            name = entry[8:24].split(b"\0", 1)[0].decode("ascii")
            if kind in (0x21, 0x41, 0x42):
                size = struct.unpack_from("<H", entry, 24)[0]
                if size > 32 * (span - 1):
                    raise ValueError("Invalid value size")
                value = page[96 + index * 32:96 + index * 32 + size]
                if zlib.crc32(value, 0xffffffff) != struct.unpack_from("<I", entry, 28)[0]:
                    raise ValueError("Invalid value CRC")
            else:
                value = entry[24:32]
            entries.append((namespace, kind, chunk, name, value))
            index += span
    namespaces = {name: value[0] for ns, kind, _, name, value in entries if ns == 0 and kind == 1}
    namespace = namespaces["orion-bridge"]
    values, chunks, indices = {}, {}, {}
    for ns, kind, chunk, name, value in entries:
        if ns != namespace:
            continue
        if kind == 0x42:
            chunks[(name, chunk)] = value
        elif kind == 0x48:
            indices[name] = value
        elif kind in (0x21, 0x41):
            values[name] = (kind, value)
        elif kind in (1, 2, 4, 8, 0x11, 0x12, 0x14, 0x18):
            values[name] = (kind, value[:kind & 15])
        else:
            raise ValueError("Unsupported application type")
    for name, index in indices.items():
        size = struct.unpack_from("<I", index)[0]
        count, start = index[4:6]
        value = b"".join(chunks[(name, start + offset)] for offset in range(count))
        if len(value) != size:
            raise ValueError("Invalid blob size")
        values[name] = (0x48, value)
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", required=True, type=Path)
    parser.add_argument("--after", required=True, type=Path)
    parser.add_argument("--certificate-migration", action="store_true")
    parser.add_argument("--export-ca", type=Path)
    args = parser.parse_args()
    before = decode_application(args.before.read_bytes())
    after = decode_application(args.after.read_bytes())
    if not before or not after:
        raise ValueError("Missing application data")
    if args.certificate_migration:
        expected = {**before, "tls_ver": (1, b"\x03"),
                    "tls3_cert": after["tls3_cert"], "tls3_key": after["tls3_key"]}
        ok = (after == expected and after["tls3_key"] == before["tls_key"]
              and after["tls3_cert"] != before["tls_cert"])
    else:
        ok = before == after
    print(json.dumps({"ok": ok, "applicationValues": len(after),
                      "onlyCertificateMigration": args.certificate_migration,
                      "readoutKeyUnchanged": before["orion_key"] == after["orion_key"]}))
    if not ok:
        raise ValueError("Application comparison failed")
    if args.export_ca:
        name = "tls3_cert" if after["tls_ver"] == (1, b"\x03") else "tls_cert"
        certificate = after[name][1].rstrip(b"\0")
        ssl.PEM_cert_to_DER_cert(certificate.decode("ascii"))
        args.export_ca.write_bytes(certificate)
        print(json.dumps({"publicCertificateExported": True}))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, struct.error):
        print(json.dumps({"ok": False, "error": "readback_validation_failed"}))
        raise SystemExit(1)
