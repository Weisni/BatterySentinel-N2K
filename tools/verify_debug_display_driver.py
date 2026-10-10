"""Fault-inject the real OLED driver with host-side Arduino/Wire/U8g2 boundaries.

This verifies callback suppression, locks, configuration and driver lifecycle.
It does not emulate OLED pixels, prove real I2C timeout timing, or identify the
physical panel. The firmware build and real-device acceptance remain separate.
"""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tools/debug_display_driver_fixtures"


def main():
    output = ROOT / "tmp"
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="debug-display-driver-", dir=output) as folder:
        executable = Path(folder) / ("driver.exe" if os.name == "nt" else "driver")
        subprocess.run([os.environ.get("CXX", "g++"), "-std=c++17", "-Wall", "-Wextra", "-Werror",
                        "-DBATTERYSENTINEL_DEBUG_OLED=1", "-I" + str(FIXTURES),
                        "-I" + str(ROOT / "src"), "-I" + str(ROOT / "include"),
                        "-I" + str(ROOT / "lib/DebugDisplay/src"),
                        str(ROOT / "src/BridgeDebugDisplay.cpp"), str(FIXTURES / "driver_test.cpp"),
                        "-o", str(executable)], check=True, timeout=30)
        for scenario in ("healthy", "buffer", "begin", "probe", "init", "contrast", "boot", "runtime", "short-write"):
            subprocess.run([str(executable), scenario], check=True, timeout=5)
    print("OLED driver: 9 lifecycle/fault scenarios passed (host boundaries; no physical device).")


if __name__ == "__main__":
    main()
