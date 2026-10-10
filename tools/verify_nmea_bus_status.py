"""Exercise the real TWAI backend through host-side Arduino/NMEA2000/IDF stubs.

Run with Python 3 and a C++17 compiler (g++ by default, or set CXX to its path).
The harness checks read-only status, driver failures, receive history and counter
semantics. It does not emulate arbitration, physical CAN, or real driver timing.
"""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tools/nmea_bus_status_fixtures"
SCENARIOS = (
    "uninstalled", "install-failure", "start-failure", "states", "counters",
    "receive", "malformed", "rollover", "status-failure",
)


def main():
    output = ROOT / "tmp"
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="nmea-bus-status-", dir=output) as folder:
        executable = Path(folder) / ("bus-status.exe" if os.name == "nt" else "bus-status")
        subprocess.run([
            os.environ.get("CXX", "g++"), "-std=c++17", "-Wall", "-Wextra", "-Werror",
            "-I" + str(FIXTURES), "-I" + str(ROOT / "src"),
            str(ROOT / "src/Nmea2000Twai.cpp"), str(FIXTURES / "bus_status_test.cpp"),
            "-o", str(executable),
        ], check=True, timeout=30)
        for scenario in SCENARIOS:
            subprocess.run([str(executable), scenario], check=True, timeout=5)
    print(f"TWAI bus status: {len(SCENARIOS)} scenarios passed (host boundaries; no physical device).")


if __name__ == "__main__":
    main()
