"""Bounded, certificate-verified OTA acceptance checks on an authorized device.

Read one JSON object from stdin: {"username": "...", "password": "..."}.
Supply --ca with the device certificate obtained through a trusted physical
connection. There is deliberately no insecure TLS option. Credentials, cookies,
CSRF tokens, HTML and configuration values never appear in output or files.

The negative phase writes only invalid/incomplete images to the inactive slot.
The upload phase activates the supplied firmware and restarts the device once.
An interrupted upload is never automatically retried. Reboot verification is
limited to 120 seconds; reconnect the host to the service Wi-Fi if needed.
"""

import argparse
import hashlib
from html.parser import HTMLParser
from http.client import HTTPSConnection, HTTPException
from http.cookies import SimpleCookie, CookieError
import json
from pathlib import Path
import re
import socket
import ssl
import sys
import time
from urllib.parse import urlencode

from verify_ota_image import inspect_image, TARGETS


CHUNK_SIZE = 2048
INTERRUPT_SIZE = 64 * 1024
RESPONSE_LIMIT = 256 * 1024
NEGATIVE_CASES = ("unauthenticated", "csrf", "content_type", "oversized", "wrong_target",
                  "corrupted_checksum", "corrupted_digest", "one_byte_truncation", "interrupted_64k")
HEX32 = re.compile(r"[0-9a-f]{32}\Z")
HEX64 = re.compile(r"[0-9a-f]{64}\Z")


class CheckFailed(Exception):
    """A fixed, non-sensitive diagnostic code, never a raw server response."""

    def __init__(self, code, status=None):
        self.code = code
        self.status = status
        super().__init__(code)


def emit(**summary):
    print(json.dumps(summary, ensure_ascii=True, separators=(",", ":")), flush=True)


class Dashboard(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.csrf = set()
        self.fields = {}
        self.orion_form = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "app-shell" in attrs.get("class", "").split():
            self.fields["configured"] = attrs.get("data-configured")
        if tag == "form":
            self.orion_form = attrs.get("id") == "orion-form"
        if tag != "input":
            return
        if attrs.get("name") == "csrf":
            self.csrf.add(attrs.get("value", ""))
        by_id = {"orion-mac": "mac", "input-alias": "inputAlias", "output-alias": "outputAlias"}
        key = by_id.get(attrs.get("id"))
        if key:
            self.fields[key] = attrs.get("value", "")
        if self.orion_form and attrs.get("name") in ("in", "out"):
            self.fields[attrs["name"] + "Instance"] = attrs.get("value")

    def handle_endtag(self, tag):
        if tag == "form":
            self.orion_form = False

    def result(self):
        expected = {"configured", "mac", "inputAlias", "outputAlias", "inInstance", "outInstance"}
        if len(self.csrf) != 1 or not HEX32.fullmatch(next(iter(self.csrf), "")):
            raise CheckFailed("dashboard_csrf_missing")
        if set(self.fields) != expected or self.fields["configured"] not in ("0", "1"):
            raise CheckFailed("dashboard_settings_missing")
        if any(value is None for value in self.fields.values()):
            raise CheckFailed("dashboard_settings_missing")
        # This digest stays in memory. Even a hash of low-entropy settings is
        # unnecessary to publish; results report equality only.
        fingerprint = hashlib.sha256(json.dumps(self.fields, sort_keys=True,
                                                ensure_ascii=False).encode("utf-8")).digest()
        return next(iter(self.csrf)), fingerprint


class Device:
    def __init__(self, host, ca, credentials):
        self.context = ssl.create_default_context(cafile=str(ca))
        self.host = host
        self.credentials = credentials
        self.cookie = None
        self.csrf = None
        self.deadline = None

    def timeout(self, requested):
        if self.deadline is None:
            return requested
        remaining = self.deadline - time.monotonic()
        if remaining <= 0:
            raise CheckFailed("reboot_verification_timeout")
        return min(requested, remaining)

    def request(self, method, path, body=b"", *, authenticated=True,
                declared_size=None, content_type=None, csrf=None, timeout=30):
        """Fresh TLS connection for every sequential request; no redirects/retries.

        declared_size may exceed body length for a deliberate rejection/timeout
        test. It must never be used by the valid installation request.
        """
        connection = HTTPSConnection(self.host, context=self.context,
                                     timeout=self.timeout(timeout))
        try:
            connection.putrequest(method, path)
            connection.putheader("Connection", "close")
            if authenticated and self.cookie:
                connection.putheader("Cookie", self.cookie)
            if content_type:
                connection.putheader("Content-Type", content_type)
            if csrf is not None:
                connection.putheader("X-CSRF-Token", csrf)
            if method == "POST":
                connection.putheader("Content-Length", str(len(body) if declared_size is None else declared_size))
            connection.endheaders()
            for offset in range(0, len(body), CHUNK_SIZE):
                connection.send(body[offset:offset + CHUNK_SIZE])
            response = connection.getresponse()
            content = response.read(RESPONSE_LIMIT + 1)
            if len(content) > RESPONSE_LIMIT:
                raise CheckFailed("response_too_large", response.status)
            return response.status, response.getheaders(), content
        finally:
            connection.close()

    @staticmethod
    def decode_json(response):
        status, headers, body = response
        content_type = next((value for key, value in headers if key.lower() == "content-type"), "")
        if content_type.split(";", 1)[0].strip().lower() != "application/json":
            raise CheckFailed("unexpected_content_type", status)
        try:
            value = json.loads(body)
        except (ValueError, UnicodeError):
            raise CheckFailed("invalid_json", status) from None
        if not isinstance(value, dict):
            raise CheckFailed("invalid_json_shape", status)
        return value

    def login(self):
        body = urlencode({"user": self.credentials["username"],
                          "password": self.credentials["password"]}).encode("ascii")
        status, headers, _ = self.request("POST", "/login", body, authenticated=False,
                                        content_type="application/x-www-form-urlencoded")
        if status != 303:
            raise CheckFailed("login_failed", status)
        locations = [value for key, value in headers if key.lower() == "location"]
        if locations != ["/"]:
            raise CheckFailed("unexpected_login_redirect", status)
        cookie = SimpleCookie()
        try:
            for key, value in headers:
                if key.lower() == "set-cookie":
                    cookie.load(value)
        except CookieError:
            raise CheckFailed("invalid_session_cookie") from None
        session = cookie.get("session")
        if (session is None or not HEX32.fullmatch(session.value)
                or not session["secure"] or not session["httponly"]
                or session["path"] != "/" or session["samesite"].lower() != "strict"):
            raise CheckFailed("invalid_session_cookie")
        self.cookie = "session=" + session.value

    def dashboard(self):
        status, _, body = self.request("GET", "/")
        if status != 200:
            raise CheckFailed("dashboard_failed", status)
        page = Dashboard()
        try:
            page.feed(body.decode("utf-8"))
        except UnicodeError:
            raise CheckFailed("invalid_dashboard_encoding") from None
        self.csrf, fingerprint = page.result()
        return fingerprint

    def metadata(self, timeout=30):
        response = self.request("GET", "/api/firmware", timeout=timeout)
        if response[0] == 401:
            raise CheckFailed("authentication_required", 401)
        if response[0] != 200:
            raise CheckFailed("metadata_failed", response[0])
        value = self.decode_json(response)
        if (value.get("target") not in TARGETS
                or not isinstance(value.get("version"), str)
                or not re.fullmatch(r"[ -~]{1,32}", value["version"])
                or type(value.get("maxSize")) is not int or value["maxSize"] <= 0
                or value.get("available") is not True
                or not isinstance(value.get("runningElfSha256"), str)
                or not HEX64.fullmatch(value["runningElfSha256"])):
            raise CheckFailed("invalid_or_unavailable_metadata")
        for name in ("running", "boot", "next"):
            if (not isinstance(value.get(name + "Partition"), str)
                    or not re.fullmatch(r"[a-zA-Z0-9_]{1,16}", value[name + "Partition"])
                    or type(value.get(name + "Address")) is not int
                    or value[name + "Address"] < 0):
                raise CheckFailed("partition_metadata_missing")
        if value["runningAddress"] == value["nextAddress"]:
            raise CheckFailed("inactive_partition_missing")
        return value

    def post_firmware(self, image=b"", **kwargs):
        kwargs.setdefault("csrf", self.csrf)
        kwargs.setdefault("content_type", "application/octet-stream")
        return self.request("POST", "/api/firmware", image, **kwargs)


def boot_identity(metadata):
    return tuple(metadata[key] for key in ("runningPartition", "runningAddress",
                                           "bootPartition", "bootAddress", "runningElfSha256"))


def negative_checks(device, image, wrong_target, baseline, fingerprint, case=None):
    def unchanged():
        if boot_identity(device.metadata()) != boot_identity(baseline):
            raise CheckFailed("negative_test_changed_firmware")
        if device.dashboard() != fingerprint:
            raise CheckFailed("negative_test_changed_settings")

    def reject(name, status, code, body=b"", **kwargs):
        if case is not None and case != name:
            return
        emit(phase="negative", test=name, stage="start")
        response = device.post_firmware(body, **kwargs)
        payload = device.decode_json(response)
        if response[0] != status or payload.get("ok") is not False or payload.get("error") != code:
            raise CheckFailed("unexpected_negative_test_result", response[0])
        unchanged()
        emit(phase="negative", test=name, ok=True, status=status, error=code,
             runningFirmwareUnchanged=True, bootSelectionUnchanged=True, settingsUnchanged=True)

    # The ESP-IDF parser needs the start of the declared body before dispatch.
    # This descriptor prefix triggers dispatch; these checks still reject before
    # inspecting the prefix or erasing/writing the inactive application slot.
    prefix = image[:288]
    reject("unauthenticated", 401, "auth", prefix, authenticated=False, declared_size=len(image))
    reject("csrf", 403, "csrf", prefix, csrf="0" * 32 if device.csrf != "0" * 32 else "1" * 32,
           declared_size=len(image))
    reject("content_type", 415, "content_type", prefix, content_type="text/plain", declared_size=len(image))
    reject("oversized", 413, "size", prefix, declared_size=baseline["maxSize"] + 1)
    if wrong_target is not None:
        # A genuine image's descriptor alone is sufficient to reject its target.
        # Sending just this prefix avoids writing into a server-closed TLS socket.
        reject("wrong_target", 400, "target", wrong_target[:288], declared_size=len(wrong_target))
    elif case is None or case == "wrong_target":
        emit(phase="negative", test="wrong_target", skipped=True, reason="wrong_target_file_not_supplied")
    # Alter payload after the identity fields without updating the XOR checksum
    # or SHA-256. The stream validator must reject its checksum before the hash.
    checksum_corrupt = bytearray(image)
    checksum_offset = 32 + int.from_bytes(image[28:32], "little") - 1
    checksum_corrupt[checksum_offset] ^= 1
    reject("corrupted_checksum", 400, "checksum", checksum_corrupt, timeout=180)
    corrupt = image[:-1] + bytes([image[-1] ^ 1])
    reject("corrupted_digest", 400, "hash", corrupt, timeout=180)
    reject("one_byte_truncation", 400, "image", image[:-1], timeout=180)
    # The image is correct but transfer stops after 64 KiB. Keep the socket open
    # to observe the server's three ~5-second receive timeouts and explicit 408.
    reject("interrupted_64k", 408, "receive", image[:INTERRUPT_SIZE],
           declared_size=len(image), timeout=30)


def upload_and_verify(device, image, baseline, fingerprint):
    response = device.post_firmware(image, timeout=180)
    result = device.decode_json(response)
    if response[0] != 200 or result.get("ok") is not True or result.get("rebooting") is not True:
        raise CheckFailed("upload_not_confirmed", response[0])
    emit(phase="upload", test="transfer", ok=True, rebooting=True)
    expected_hash = image[176:208].hex()
    # Windows reconnection and the device's password derivation can exceed
    # 45 seconds together. Keep verification bounded without resending firmware.
    device.deadline = time.monotonic() + 120
    # No second firmware POST occurs, even if the reply or reboot is uncertain.
    while time.monotonic() < device.deadline:
        time.sleep(min(1, max(0, device.deadline - time.monotonic())))
        try:
            # A disconnected Windows Wi-Fi adapter can leave a connect call
            # pending. Reserve time for a later attempt and the slow login.
            current = device.metadata(timeout=5)
        except CheckFailed as error:
            if error.code == "authentication_required":
                try:
                    device.login()
                    current = device.metadata(timeout=5)
                except ssl.SSLCertVerificationError:
                    raise
                except (OSError, HTTPException):
                    continue
            elif error.code == "metadata_failed" and error.status == 409:
                continue
            else:
                raise
        except ssl.SSLCertVerificationError:
            raise
        except (OSError, HTTPException):
            # A reboot can terminate TLS without close_notify. Retry the read
            # within the deadline, but never retry an invalid certificate.
            continue
        if current["runningAddress"] == baseline["runningAddress"]:
            continue
        if (current["runningAddress"] != baseline["nextAddress"]
                or current["runningPartition"] != baseline["nextPartition"]
                or current["bootAddress"] != current["runningAddress"]
                or current["bootPartition"] != current["runningPartition"]):
            raise CheckFailed("unexpected_boot_partition")
        if current["runningElfSha256"] != expected_hash:
            raise CheckFailed("installed_elf_hash_mismatch")
        if device.dashboard() != fingerprint:
            raise CheckFailed("settings_changed_after_update")
        emit(phase="upload", test="reboot", ok=True, partitionSwitched=True,
             runningPartition=current["runningPartition"], elfHashMatches=True,
             settingsUnchanged=True)
        return
    raise CheckFailed("reboot_verification_timeout")


def read_credentials(stream):
    try:
        raw = stream.readline(8193)
        if len(raw) > 8192:
            raise ValueError()
        value = json.loads(raw)
        if not isinstance(value, dict) or set(value) != {"username", "password"}:
            raise ValueError()
        if any(not isinstance(value[key], str) or not value[key] for key in value):
            raise ValueError()
        # BridgePortal::body() uses its default 512-byte bound for /login.
        if len(urlencode({"user": value["username"], "password": value["password"]})) > 512:
            raise ValueError()
        return value
    except (ValueError, UnicodeError):
        raise CheckFailed("invalid_credentials_input") from None


class JsonArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        # argparse's normal error includes user-supplied values. Do not echo
        # accidental credentials or paths; --help remains available explicitly.
        emit(ok=False, stage="arguments", error="invalid_arguments")
        raise SystemExit(2)


def main():
    parser = JsonArgumentParser(description=__doc__)
    parser.add_argument("--ca", type=Path, required=True,
                        help="Trusted PEM device certificate extracted over a physical connection")
    parser.add_argument("--host", default="192.168.4.1")
    parser.add_argument("--firmware", type=Path, required=True)
    parser.add_argument("--wrong-target", type=Path, help="Optional genuine firmware.bin for the other Orion target")
    parser.add_argument("--phase", choices=("preflight", "negative", "upload"), required=True)
    parser.add_argument("--negative-case", choices=NEGATIVE_CASES,
                        help="Run only this negative test; default runs all available cases")
    args = parser.parse_args()
    if args.negative_case is not None and args.phase != "negative":
        parser.error("--negative-case requires --phase negative")
    stage = "local_preflight"
    try:
        credentials = read_credentials(sys.stdin)
        image = args.firmware.read_bytes()
        # Check artifacts before connecting, without weakening device validation.
        target_bytes = image[80:112].split(b"\0", 1)[0]
        try:
            target = target_bytes.decode("ascii")
            inspect_image(image, target)
        except (ValueError, UnicodeError):
            raise CheckFailed("invalid_local_firmware") from None
        if (len(image) <= INTERRUPT_SIZE and args.phase == "negative"
                and args.negative_case in (None, "interrupted_64k")):
            raise CheckFailed("firmware_too_small_for_interruption_test")
        if args.negative_case == "wrong_target" and args.wrong_target is None:
            raise CheckFailed("wrong_target_file_required")
        wrong = args.wrong_target.read_bytes() if args.wrong_target else None
        if wrong is not None:
            other = next(value for value in TARGETS if value != target)
            try:
                inspect_image(wrong, other)
            except ValueError:
                raise CheckFailed("invalid_wrong_target_firmware") from None
        device = Device(args.host, args.ca, credentials)
        stage = "login"
        device.login()
        stage = "preflight"
        fingerprint = device.dashboard()
        baseline = device.metadata()
        if baseline["target"] != target or len(image) > baseline["maxSize"]:
            raise CheckFailed("firmware_incompatible_with_device")
        if baseline["bootAddress"] != baseline["runningAddress"]:
            raise CheckFailed("boot_change_already_pending")
        emit(phase=args.phase, test="preflight", ok=True, tlsVerified=True, authenticated=True,
             target=baseline["target"], version=baseline["version"], maxSize=baseline["maxSize"],
             runningPartition=baseline["runningPartition"], runningAddress=baseline["runningAddress"],
             nextPartition=baseline["nextPartition"], nextAddress=baseline["nextAddress"],
             runningElfSha256=baseline["runningElfSha256"], settingsFingerprintCaptured=True)
        stage = args.phase
        if args.phase == "negative":
            negative_checks(device, image, wrong, baseline, fingerprint, args.negative_case)
        elif args.phase == "upload":
            upload_and_verify(device, image, baseline, fingerprint)
        emit(phase=args.phase, complete=True, ok=True)
        return 0
    except CheckFailed as error:
        summary = {"phase": args.phase, "stage": stage, "ok": False, "error": error.code}
        if error.status is not None:
            summary["status"] = error.status
        emit(**summary)
    except ssl.SSLCertVerificationError:
        emit(phase=args.phase, stage=stage, ok=False, error="tls_certificate_verification_failed")
    except (socket.timeout, TimeoutError):
        emit(phase=args.phase, stage=stage, ok=False, error="network_timeout")
    except ssl.SSLError:
        emit(phase=args.phase, stage=stage, ok=False, error="tls_failed")
    except (OSError, HTTPException) as error:
        number = getattr(error, "errno", None)
        emit(phase=args.phase, stage=stage, ok=False, error="local_file_or_connection_failed",
             exceptionType=type(error).__name__, errno=number if type(number) is int else None)
    except KeyboardInterrupt:
        emit(phase=args.phase, stage=stage, ok=False, error="interrupted_result_unknown")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
