# Orion enclosure V2 - 7 mm cable

1. Read [Manufacturing and TPU Air calibration](manuals/Orion-Enclosure-V2-Manufacturing-EN.pdf).
2. Print and check the fit and material coupons before a complete enclosure.
3. Follow [Assembly](manuals/Orion-Enclosure-V2-Assembly-EN.pdf).

The [detailed README](enclosure/README.md) lists parts, hardware, profiles and open physical tests.
All CAD, STL, 3MF and calibration profiles are in `enclosure/`.
The three TPU temperature projects are alternative calibration trials. Print only the selected samples first.
Flow 1.00 is an uncalibrated seed. Temperature does not guarantee a Shore hardness.
The digital validation passed; physical fit, retention, hardness, creep and sealing remain unqualified.

The original repository retains the previous user project and rebuild scripts.
This package includes editable FreeCAD geometry and design parameters; it is not a standalone build-tool distribution.
The assembly's seated TPU bodies are simplified envelopes. Use the free-shape STLs for printing.
`SHA256SUMS.json` records every payload file. No cached G-code is included.
