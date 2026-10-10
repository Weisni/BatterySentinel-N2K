"""Compare the production C++ PBKDF2/HMAC core against Python hashlib.

Build tools/check_password_hash.cpp as described in its file header, then run:
python tools/verify_password_hash.py --checker PATH_TO_EXECUTABLE
Only public synthetic passwords are used. No device or credential store is read.
"""

import argparse
import hashlib
from pathlib import Path
import subprocess


def cases():
    lengths = (0, 1, 12, 55, 56, 63, 64, 65, 119, 120, 127, 128)
    salts = (bytes(16), bytes(range(16)), bytes([255]) * 16)
    for length in lengths:
        password = bytes((index * 37 + 11) % 256 for index in range(length))
        for salt in salts:
            for rounds in (1, 2, 17):
                yield password, salt, rounds
        yield password, salts[1], 120000
    for password in (b"correct horse battery staple", b"A" * 64, b"A" * 65,
                     bytes(range(128)), bytes(128), "Grüße 🔐 über WLAN".encode("utf-8")):
        for salt in salts:
            yield password, salt, 120000


def verify(checker: Path) -> None:
    count = 0
    for password, salt, rounds in cases():
        expected = hashlib.pbkdf2_hmac("sha256", password, salt, rounds, 32).hex()
        result = subprocess.run([str(checker), password.hex(), salt.hex(), str(rounds)],
                                capture_output=True, text=True, timeout=60, check=False)
        if result.returncode != 0 or result.stdout.strip() != expected:
            raise AssertionError(
                f"PBKDF2 mismatch for password length {len(password)}, salt {salt.hex()}, "
                f"iterations {rounds}: exit {result.returncode}, stdout {result.stdout!r}, "
                f"stderr {result.stderr!r}, expected {expected}"
            )
        count += 1

    invalid = [
        ("00" * 129, "00" * 16, "1"),
        ("00", "00" * 16, "0"),
        ("00", "00" * 15, "1"),
        ("00", "00" * 17, "1"),
        ("0", "00" * 16, "1"),
        ("zz", "00" * 16, "1"),
        ("00", "00" * 16, "-1"),
        ("00", "00" * 16, "4294967296"),
    ]
    for arguments in invalid:
        result = subprocess.run([str(checker), *arguments], capture_output=True,
                                text=True, timeout=10, check=False)
        if result.returncode == 0 or result.stdout.strip():
            raise AssertionError(f"Invalid input returned a digest: {arguments!r}")
    print(f"Verified {count} PBKDF2 vectors against Python hashlib and {len(invalid)} rejected inputs.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--checker", required=True, type=Path)
    args = parser.parse_args()
    verify(args.checker.resolve(strict=True))


if __name__ == "__main__":
    main()
