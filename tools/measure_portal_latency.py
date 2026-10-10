"""Sequential device measurements; credentials only from stdin, no secret output."""
import argparse
from http.client import HTTPSConnection
import json
from pathlib import Path
import re
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from test_ota_device import Device, emit, RESPONSE_LIMIT

class MeasuredDevice(Device):
    def request(self, method, path, body=b"", *, authenticated=True,
                declared_size=None, content_type=None, csrf=None, timeout=40):
        connection = HTTPSConnection(self.host, context=self.context, timeout=timeout)
        started = time.monotonic()
        try:
            connection.connect()
            connected = time.monotonic()
            headers = {"Connection": "close"}
            if authenticated and self.cookie:
                headers["Cookie"] = self.cookie
            if content_type:
                headers["Content-Type"] = content_type
            if csrf:
                headers["X-CSRF-Token"] = csrf
            connection.request(method, path, body=body, headers=headers)
            response = connection.getresponse()
            first = time.monotonic()
            data = response.read(RESPONSE_LIMIT + 1)
            end = time.monotonic()
            emit(method=method, path=path, status=response.status, bytes=len(data),
                 connectMs=round((connected-started)*1000),
                 responseMs=round((first-connected)*1000),
                 bodyMs=round((end-first)*1000), totalMs=round((end-started)*1000))
            return response.status, response.getheaders(), data
        finally:
            connection.close()

parser = argparse.ArgumentParser()
parser.add_argument("--ca", type=Path, required=True)
parser.add_argument("--repeat", type=int, default=2)
args = parser.parse_args()
device = MeasuredDevice("192.168.4.1", args.ca, json.load(sys.stdin))
device.request("GET", "/", authenticated=False)
for _ in range(args.repeat):
    device.login()
    device.dashboard()
    info = device.metadata()
    emit(version=info["version"], partition=info["runningPartition"],
         elfSha256=info["runningElfSha256"])
    result = device.request("GET", "/api/live?after=0")
    # Only fixed numeric auth timing leaves memory; no dashboard/events payload.
    matches = re.findall(rb'Password verification (\d+) ms', result[2])
    emit(passwordVerificationMs=[int(value) for value in matches])
