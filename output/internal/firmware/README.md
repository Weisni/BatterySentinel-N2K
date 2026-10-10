# Project-internal firmware archive

This directory preserves engineering evidence, not user downloads. The R4
WROOM design was not built and is not an existing or previously released product.
Its compiled test artifacts are retained here only to reproduce internal build
checks. Do not install them on the actual SuperMini Orion Bridge.

## Original records

The text snapshots below preserve the exact bytes of the former notes and
checksum lists. Their old paths and installation wording describe the original
internal working state; they are not current instructions.

| Firmware state | Original README snapshot | Original checksum snapshot |
| --- | --- | --- |
| 1.1.0 | [Original notes](1.1.0/original-README.md.txt) | [Original checksum list](1.1.0/original-SHA256SUMS.txt.txt) |
| 1.1.1 | [Original notes](1.1.1/original-README.md.txt) | [Original checksum list](1.1.1/original-SHA256SUMS.txt.txt) |
| 1.1.2 | [Original notes](1.1.2/original-README.md.txt) | [Original checksum list](1.1.2/original-SHA256SUMS.txt.txt) |
| 1.1.3 | [Original notes](1.1.3/original-README.md.txt) | [Original checksum list](1.1.3/original-SHA256SUMS.txt.txt) |
| 1.1.4 | [Original notes](1.1.4/original-README.md.txt) | [Original checksum list](1.1.4/original-SHA256SUMS.txt.txt) |

The corresponding SuperMini test artifacts remain in the labelled historical
folders under `output/firmware/`. The current user download is the SuperMini
application in `output/firmware/1.1.4/`.

## Relocated unbuilt-design test artifacts

The following files were moved on 2026-09-26. Source and destination paths were
resolved inside the workspace before moving; SHA-256 was checked before and
after each move. No binary content changed.

| Original workspace path | Internal artifact | SHA-256 |
| --- | --- | --- |
| `output/firmware/1.1.3/orion-r4-1.1.3.bin` | [orion-r4-1.1.3.bin](1.1.3/orion-r4-1.1.3.bin) | `dc9b3ad4d47ddc326b8cb10d9ea24a973d08a977e3b2e0c011d73124b6cf6ea2` |
| `output/firmware/1.1.4/orion-r4-1.1.4.bin` | [orion-r4-1.1.4.bin](1.1.4/orion-r4-1.1.4.bin) | `9b9c69f69670b37ea27f7d617388b9ac04b33593c4603af03207c5220eb6931b` |

## Status

- Complete: separate user downloads from internal unbuilt-design artifacts.
- Complete: retain original notes, checksum lists and binary contents.
- Open: physical verification of the current actual hardware follows its own
  acceptance plan; internal builds do not demonstrate that a design was built.
