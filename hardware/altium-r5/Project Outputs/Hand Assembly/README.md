# Orion-R5 hand assembly package

Generated 2026-10-07 from the user's final Altium release archive. Documentation is in English. Start with [the illustrated PDF](Orion-R5-Hand-Assembly-EN.pdf).

## Files

- `Orion-R5-Hand-Assembly-EN.pdf`: 11 A4 landscape pages, overview, purchased BOM, per-reference checklist, passive placement, orientation details, module/cable assembly and first-power checks. Print at 100% for the stated enlargement; the diagrams are magnified bench aids, not 1:1 templates.
- `Placement-TOP.svg`: scalable top-side placement map. Cable pads left, USB notch right, service switch at top. Gold pads, blue body envelopes, red dots at PCB pad 1 for directional parts. The original footprint envelope is retained for replacements; it is not a drawing of the substitute body.
- `BOM-Hand-Assembly.csv`: grouped release values and purchased MPN/LCSC overlay, exact quantities for 1 and 4 boards. 34 carrier components + one separately purchased module + one cable per board; no purchased part at TP1. No assembly-loss/spare allowance.
- `Placements-and-Checklist.csv`: all 37 references, release values, purchased parts, side, geometric centres, component origins, Altium angles, orientation and blank solder/inspection fields.
- `Release-Pad-Netlist.csv`: all 120 release pads, including 114 numbered electrical pads and six non-plated mechanical holes. Module GPIO pad names are GPIO numbers, not sequential lead indices. `NC` means unconnected.
- `source-references/`: original release assembly/schematic PDFs, BOM, CPL and ASCII PCB, plus the reviewed supplier datasheets; copied unchanged for cross-checking.
- `validation.json`: release/source SHA-256 and digital consistency results. Visual PDF QA is recorded separately in `visual-qa.json` after rendering.

CSV files use comma separators and UTF-8 with BOM. If your spreadsheet opens a single column, import as comma-separated UTF-8. The position CSV is labelled for manual assembly and is not a machine-specific PCBA file.

## Release authority and substitutions

Source: `../BatterySentinel-N2K-Orion-R5.zip` (ASCII/CPL export 2026-09-23 20:53).
SHA-256: `e24c59211106f45f4e4c015c83d5ed1609e4d62eef0830f722931325e9dc08d9`.

Placement, pad geometry/numbering and connectivity come directly from that release. The archive, Gerber files, native sources and original BOM are preserved. Do not regenerate the fabrication release from this package.

The local procurement records `../../lcsc-order-2026-09-24.md` and `../../lcsc-preisvergleich-2026-09-23.md` supply the purchased overlay:

- L1: **PSCIAQ4532-510Z / C2932173**, replacing release ACT45B-510-2P-TL003; keep winding paths 1-4 and 2-3. Verify the two windings and actual terminal wetting before acceptance. No external pin-1 marking is established by the replacement sheet. The digital land overlap review is not a physical soldering/EMC qualification.
- L2/L3: **FNR4030S4R7MT / C167874**, replacing the planned Sunlord part on the existing SUNLORD_SWPA4030 footprint. Non-polar two-terminal 4.7 uH inductors.
- C4/C5 generic descriptions still mention 16 V, while release values and purchased MPN specify **100 nF, 50 V, X7R**. Use the release value and purchased MPN.
- MCU1: selected C3 SuperMini **ASIN B0FN4F6244**, direct 16-land perimeter soldering; USB points right and antenna left. Confirm actual delivered module identity and fit.

## Assembly order

1. Inspect PCB and parts; dry-fit the module, U2 and switch. Sort capacitors by label/value/package.
2. Solder resistors and MLCCs, then small ICs/diodes with pin-1 and cathode checks.
3. Fit F1 and inductors. Verify L1 winding orientation before soldering.
4. Fit tall U2 and SW3. Confirm switch continuity: RUN = 1-2; SERVICE = 2-3, with 1-2 open.
5. Inspect shorts and check carrier supplies before adding the module where practical. Mount all 16 castellations without headers or under-module paste.
6. Thread the unsplit cable-entry parts before terminating J1. Verify actual wire/contact continuity rather than relying only on colours. Provide independent strain relief.
7. Complete the power-off inspection and staged bench measurements in the PDF, then firmware, radio, NMEA/Garmin and enclosure acceptance.

SERVICE before USB; disconnect USB before RUN. Keep SHIELD, GND_BUS and GND_LOGIC separate. Use each rail's own ground for measurements. Do not bridge isolation with oscilloscope ground clips.

## Progress, findings and open work

- [x] Release ASCII PCB/BOM/CPL parsed and all 37 references reconciled.
- [x] All components confirmed top-side; 34 carrier components in 17 supplier groups, plus module, cable and bare TP1.
- [x] All 114 numbered pad nets compared to the design connectivity; placement/origin/rotation compared to release CPL.
- [x] Purchased L1/L2/L3 substitutions separated from immutable fabrication data.
- [x] Illustrated PDF, vector map, CSV checklists and source copies generated; PDF text/reference/MPN coverage checked.
- [x] All 11 rendered PDF pages visually inspected; source copies and ZIP contents hash-checked. See `visual-qa.json` for the exact PDF hash.
- [ ] Receive/identify parts; inspect actual fit and solder joints.
- [ ] Verify switch continuity, rail values/startup peaks, bus current and thermal behaviour.
- [ ] Verify installed module RF, CAN/NMEA/Garmin delivery, cable retention and enclosure sealing.

No physical board test or new Altium DRC was performed. See the existing power/module reviews for design assumptions and electrical limits. A multimeter short check is not a certified insulation test.

## Rebuild

From the repository root, run `python tools/build_r5_hand_assembly.py` using a Python environment containing reportlab, openpyxl and pypdf. The script stops on inconsistent release references, origins, rotations or pad nets. Render the resulting PDF with Poppler and inspect every page before delivery. Rerunning clears the previous visual sign-off because the PDF has been regenerated.
