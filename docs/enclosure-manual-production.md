# Orion-R5 enclosure assembly manual: production and verification

**Project-internal engineering and production record.** This file records development evidence; the assembly PDF and current print-package README provide the user instructions.

Output: [Orion-R5-Enclosure-Assembly-Manual-EN.pdf](../output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf).

Edition EN 1.1, 2026-09-26: 11 A4 pages for assembly of the final gasketed Bambu P2S enclosure in `hardware/altium-r5/enclosure/sealed-print`. The guide explains the closures, insert installation, cable threading, seal compression, independent PCB mounting, service access and physical acceptance. It uses a printable checklist and writing lines, not interactive PDF form fields.

## Sources and images

- The final enclosure contract, README, validation records, FCStd model and prepared 3MF define the dimensions, part selection and fasteners. The prepared file for this edition is `Orion-R5-P2S-flush-colour.3mf`; retained development records are project-internal.
- `hardware/altium-r5/power-review.md` and `module-selection.md` establish the SERVICE/USB sequence. SERVICE disconnects the module-positive supply; it is not a whole-device power-off state with NMEA power connected.
- `tools/build_enclosure_assembly_manual.py` holds the final copy and layout. `docs/enclosure-assembly-content.md` preserves the initial ten-page editorial outline; it is not the final pagination or edition authority.
- Nine technical PNGs under `docs/enclosure-manual-assets/cad/` were rendered at 2000 x 1400 pixels from the delivered CAD using `tools/render_enclosure_manual.py`. They show the rigid kit, flexible kit, insert map, cable entry, two cover seals, PCB retention, exploded lid and closed assembly. Panel images are individually scaled for identification.
- The built-in image generation tool created `docs/enclosure-manual-assets/cover-generated.png` from the existing assembled preview. [Full prompt and provenance](enclosure-manual-assets/image-generation.md). It is a product illustration, not a photograph or dimensional reference.
- Seal cross-sections and the tightening plan are PDF vectors. Section shapes are enlarged schematics; their dimensions come from the enclosure contract. Illustrative metal fasteners and cable geometry are identified in captions. The HangTon cable diameter remains unverified.
- `docs/enclosure-manual-assets/source-manifest.json` records SHA-256 hashes for 20 build sources and assets. `cad/image-notes.json` records model provenance for the CAD renders. The PDF contains three clickable references to ruthex insert guidance and Prusa's enclosure experiments, checked on 2026-09-24.

## Rebuild

Run from the repository root. The first command is only needed when regenerating CAD illustrations; it does not edit the enclosure model.

```powershell
& 'C:/Program Files/FreeCAD 1.1/bin/python.exe' tools/render_enclosure_manual.py
$enclosureManualPython = 'C:/Users/marce/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $enclosureManualPython tools/build_enclosure_assembly_manual.py
pdftoppm -r 120 -png output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf tmp/pdfs/enclosure-manual/page
& $enclosureManualPython tools/check_enclosure_assembly_manual.py
```

The PDF builder uses ReportLab, Pillow and installed Segoe UI fonts. The checker uses pypdf, pdfplumber and Pillow. Poppler produces the page previews. The builder rejects overflowing paragraph and table blocks; it also limits long title widths and preserves image aspect ratios. Review every rendered page after a content or layout change.

## Current edition changes

- Removed obsolete enclosure screw comparisons from the user instructions.
- Matched the print plan and file reference to the existing four-plate flush-colour project, including its PETG/TPU trial plates and registered two-part lid.
- Kept geometry, prepared manufacturing files, service sequence, seal instructions and physical acceptance requirements unchanged.
- The public enclosure index now links only the current package. Its previous provisional-design text is preserved in `hardware/altium-r5/enclosure/PROVISIONAL-ENCLOSURE-INTERNAL.md`; review and production notes are explicitly project-internal.

## Verification completed

- All 11 final page PNGs were individually inspected at 120 DPI. Part labels, technical callouts, tables, seal sections and the tightening diagram are readable, with no observed clipping or overlapping text. The initial part-label collisions were corrected before the final render.
- An independent content review checked all page text and visually inspected technical pages 4–9 against the final enclosure. Corrections keep the jacket intact through the entire cable seal, require drying the exterior before opening after a splash test, and place USB/switch fit checks before cable termination.
- [Automated QA report](enclosure-manual-assets/qa-report.json): 11 A4 pages, 11 valid outline entries, 3 HTTPS link annotations, 2,352 words, no suspicious glyphs or characters outside page bounds, all 20 source hashes matching, and all 10 raster assets decoding correctly. The script intentionally reports visual review as a separate requirement; the completed visual review is recorded here and in `visual-review.json`.
- CAD and the prepared 3MF were unchanged by this documentation task. SHA-256 values: FCStd `6f18bbd682f3e62d6688e2df827d9393a85365e173060cd4f98223b7e4d69dd2`; current flush-colour 3MF `42b3f908d36bcf05f9e6db00a5fa211718de9470043e692a058046715ff46b13`.
- Final PDF SHA-256: `d214d0ed871c7a71f399c2c97027264ed02640fc80c653a288e9d526ed8951a1`.

## Physical work still open

- Measure the delivered cable, then select or rebuild the sleeve and prove fit on the coupon with the actual materials, inserts and screws.
- Check the real PCB, solder tails, USB plug and switch access. Keep the intact cable jacket through the sleeve; terminate the cable only after the cap and unsplit sleeve have been threaded on.
- Test the empty enclosure with the actual cartridge for the intended splash exposure and cable retention; repeat after flexing and opening/closing. Remove electronics before any later wet test.
- Check closed-case temperature, radio reception, fastener retention and repeated service cycles in the intended installation. No physical assembly, leak test, saltwater test, IP qualification or waterproof rating was established during manual production.

The guide provides a way to record these checks without marking any physical test as completed.
