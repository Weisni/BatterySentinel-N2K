"""Check saved-key retention on an authorized, already-configured Orion device.

Read administrator credentials as JSON from stdin. Use its trusted certificate.
Invalid requests must leave settings unchanged; the successful request resaves
the existing MAC/instances with an empty key and restarts the bridge once.
No credentials, session tokens, configuration values or HTML are logged.
"""

import argparse
from html.parser import HTMLParser
from http.client import HTTPException
import json
from pathlib import Path
import socket
import ssl
import sys
import time
from urllib.parse import urlencode

from test_ota_device import CheckFailed, Dashboard, Device, emit


class KeyField(HTMLParser):
    def __init__(self):
        super().__init__()
        self.attributes = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "input" and attrs.get("id") == "orion-key":
            self.attributes = attrs


def read_dashboard(device):
    status, _, body = device.request("GET", "/")
    if status != 200:
        raise CheckFailed("dashboard_failed", status)
    html = body.decode("utf-8")
    page, key = Dashboard(), KeyField()
    page.feed(html)
    key.feed(html)
    device.csrf, fingerprint = page.result()
    if page.fields["configured"] != "1":
        raise CheckFailed("device_must_already_be_configured")
    if not key.attributes or key.attributes.get("data-key-present") != "1":
        raise CheckFailed("key_presence_missing")
    if key.attributes.get("value", ""):
        raise CheckFailed("key_value_must_not_be_rendered")
    return page.fields, fingerprint


def run(device):
    device.login()
    fields, before = read_dashboard(device)
    expected = device.metadata()
    base = {"mac": fields["mac"], "key": "", "out": fields["outInstance"],
            "in": fields["inInstance"]}
    mac_octets = fields["mac"].split(":")
    mac_octets[-1] = f"{int(mac_octets[-1], 16) ^ 1:02x}"
    cases = (
        ("changed_mac_without_key", {"mac": ":".join(mac_octets)}),
        ("literal_mask_rejected", {"key": "*" * 32}),
        ("invalid_key_rejected", {"key": "g" * 32}),
        ("duplicate_instance_rejected", {"in": fields["outInstance"]}),
    )
    for name, changes in cases:
        body = urlencode({**base, **changes, "csrf": device.csrf}).encode("ascii")
        status, _, _ = device.request("POST", "/config", body,
                                     content_type="application/x-www-form-urlencoded")
        if status != 400:
            raise CheckFailed(name, status)
        _, after = read_dashboard(device)
        if after != before:
            raise CheckFailed("rejected_configuration_changed_settings")
        emit(check=name, status=status, settingsUnchanged=True)

    # Alternate letter case/separators must normalize to the same stored MAC.
    body = urlencode({**base, "mac": fields["mac"].replace(":", "-").upper(),
                      "csrf": device.csrf}).encode("ascii")
    status, _, _ = device.request("POST", "/config", body,
                                 content_type="application/x-www-form-urlencoded")
    if status != 200:
        raise CheckFailed("retain_key_save_failed", status)
    emit(check="retain_key_save", status=status, restarting=True)
    deadline = time.monotonic() + 120
    time.sleep(3)
    while time.monotonic() < deadline:
        try:
            device.deadline = deadline
            device.login()
            _, after = read_dashboard(device)
            actual = device.metadata()
            if after != before:
                raise CheckFailed("retained_key_settings_changed")
            if (actual["runningElfSha256"] != expected["runningElfSha256"] or
                    actual["runningPartition"] != expected["runningPartition"]):
                raise CheckFailed("unexpected_firmware_change")
            emit(check="retain_key_after_restart", configured=True,
                 settingsUnchanged=True, firmwareUnchanged=True)
            return
        except ssl.SSLCertVerificationError:
            raise CheckFailed("certificate_verification_failed") from None
        except (OSError, HTTPException):
            time.sleep(2)
    raise CheckFailed("restart_verification_timeout")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ca", required=True, type=Path)
    args = parser.parse_args()
    try:
        run(Device("192.168.4.1", args.ca, json.load(sys.stdin)))
    except CheckFailed as error:
        emit(result="FAIL", code=error.code, status=error.status)
        sys.exit(1)
    except (OSError, HTTPException, ValueError) as error:
        emit(result="FAIL", code="transport_or_input_error", errorType=type(error).__name__)
        sys.exit(1)
