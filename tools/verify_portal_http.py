"""Compile and exercise the actual firmware HTTP handlers using host adapters.

Run with Python and g++ available. No device, credentials, network, PlatformIO
cache, or preview server is used. Complete function definitions are extracted
unchanged from BridgePortal.cpp; routing is never reimplemented in this test.
"""

import argparse
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FUNCTIONS = (
    "responseHeaders", "otaResponse", "numberOrNull",
    "BridgePortal::dispatch", "BridgePortal::send", "BridgePortal::sendPage",
    "BridgePortal::denied", "BridgePortal::body", "BridgePortal::field",
    "BridgePortal::escape", "BridgePortal::jsonEscape", "BridgePortal::authenticated",
    "BridgePortal::csrfValid", "BridgePortal::newSession", "BridgePortal::endSession",
    "BridgePortal::scheduleRestart", "BridgePortal::eventsJson", "BridgePortal::notificationSettings", "BridgePortal::notificationAcknowledge",
    "BridgePortal::handle",
)


def definition(source, name):
    pattern = rf"^(?:[\w:]+\s+)+{re.escape(name)}\s*\([^;{{]*\)\s*(?:const\s*)?\{{"
    matches = list(re.finditer(pattern, source, re.MULTILINE))
    if len(matches) != 1:
        raise AssertionError(f"Expected exactly one firmware definition of {name}")
    match = matches[0]
    depth = 1
    position = match.end()
    while position < len(source):
        if source.startswith("//", position):
            end = source.find("\n", position)
            position = len(source) if end < 0 else end + 1
            continue
        if source.startswith("/*", position):
            end = source.find("*/", position + 2)
            if end < 0:
                raise AssertionError("Unclosed C++ comment")
            position = end + 2
            continue
        raw = re.match(r'R"([^\s()\\]{0,16})\(', source[position:])
        if raw:
            end = source.find(")" + raw.group(1) + '"', position + raw.end())
            if end < 0:
                raise AssertionError("Unclosed C++ raw string")
            position = end + len(raw.group(1)) + 2
            continue
        if source[position] in ('"', "'"):
            quote = source[position]
            position += 1
            while position < len(source):
                if source[position] == "\\":
                    position += 2
                elif source[position] == quote:
                    position += 1
                    break
                else:
                    position += 1
            continue
        if source[position] == "{":
            depth += 1
        elif source[position] == "}":
            depth -= 1
            if depth == 0:
                return source[match.start():position + 1]
        position += 1
    raise AssertionError(f"Unclosed firmware definition of {name}")


def run(source, compiler, expected_failure=None):
    extracted = "namespace bs {\n" + "\n\n".join(definition(source, name) for name in FUNCTIONS) + "\n}\n"
    with tempfile.TemporaryDirectory(prefix="orion-http-test-") as temporary:
        directory = Path(temporary)
        (directory / "portal_http_methods.inc").write_text(extracted, encoding="utf-8")
        executable = directory / "check_portal_http.exe"
        subprocess.run([
            compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror",
            "-Wno-sign-compare", "-I" + str(directory), "-I" + str(ROOT / "src"),
            "-I" + str(ROOT / "lib/BridgeAuth/src"),
            "-I" + str(ROOT / "lib/OrionBridge/src"),
            "-I" + str(ROOT / "lib/BridgeInsights/src"),
            str(ROOT / "tools/check_portal_http.cpp"), "-o", str(executable),
        ], check=True)
        if expected_failure is None:
            subprocess.run([str(executable)], check=True)
        else:
            result = subprocess.run([str(executable)], capture_output=True, text=True, check=False)
            if result.returncode == 0 or expected_failure not in result.stderr:
                raise AssertionError("Restoring the original bug did not trigger the expected regression check")
            print(f"PASS: original bug rejected: {expected_failure}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", default="g++")
    parser.add_argument("--check-regressions", action="store_true",
                        help="Also restore each original bug in temporary sources and require test failure")
    args = parser.parse_args()
    source = (ROOT / "src/BridgePortal.cpp").read_text(encoding="utf-8")
    run(source, args.compiler)
    if args.check_regressions:
        previous_dispatch = """esp_err_t BridgePortal::dispatch(httpd_req_t* request) {
    return static_cast<BridgePortal*>(request->user_ctx)->handle(request);
}"""
        run(source.replace(definition(source, "BridgePortal::dispatch"), previous_dispatch), args.compiler,
            "Firmware dispatch must release the HTTPS connection")
        previous_routes, count = re.subn(r'    if \(path == "/login" && !post\) \{.*?^    \}\n',
                                         "", source, count=1, flags=re.MULTILINE | re.DOTALL)
        if count != 1:
            raise AssertionError("Could not isolate GET /login for the original-bug check")
        run(previous_routes, args.compiler, "GET /login must redirect before the auth guard")


if __name__ == "__main__":
    main()
