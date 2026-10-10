# Flush-colour lid and four-plate print setup

The lid artwork uses a second PETG colour. Lettering and the logo finish level with the surrounding lid: no raised text and no open engraving. The coloured regions are co-printed as parts of the same lid, not fitted afterwards.

Use the complete [Orion-R5-P2S-flush-colour.3mf](../Orion-R5-P2S-flush-colour.3mf), which includes the prepared PETG and TPU trial plates.

## Plates and colours

| Plate | Contents | Material |
| --- | --- | --- |
| 1 | Base, two-colour lid, USB cover, switch cover, cable cap | PETG |
| 2 | Three face gaskets and six alternative cable cartridges | TPU |
| 3 — Test Piece PETG | F test piece and a duplicate cable cap | PETG |
| 4 — Test Piece TPU | A duplicate nominal 6.0 mm cable sleeve | TPU |

Filament 1 is the existing dark PETG, filament 2 is the existing TPU, and filament 3 is contrasting white PETG. Remap the two PETG slots to the actual spools in the slicer. Both lid colours must use compatible PETG. Keep TPU on its separate plates and external-spool workflow.

The lid prints exterior-face down. The colour regions occupy the first 0.4 mm (two nominal 0.20 mm layers) and share the lid body's exact coordinates. Keep both parts together as one object. Do not arrange, scale or centre the lettering independently. Print the lid body and colour regions together.

Multicolour printing needs a way to change the two PETG colours within the same layer, such as an AMS; a simple one-time layer colour change cannot make this artwork. Check the actual filament mapping and slice the project before printing. Colour opacity and adhesion remain physical print checks.

## Test pieces and hardware

Use the two prepared test plates before printing the full enclosure. Plate 4's 6.0 mm sleeve is a test option, not a measured cable size. The delivered cable still needs measuring before a sleeve is chosen for assembly.

F is a small practice piece, not an enclosure component. Use it to check insert installation, screw fit, cable-sleeve/cap fit and a short section of the gasket groove before printing the full case. It does not establish complete-case leak resistance.

The purchased Habwea insert assortment and WZHUIDA M2 screw assortment are recorded in the [cost list](../../../../../README.md#recorded-procurement-costs). Their exact dimensions and compatibility with the specified ruthex inserts/M2 x 5 screws remain unverified. The M2 assortment does not supply the required M3 x 8 screws by virtue of being an M2 kit. Use extra inserts for coupon trials; do not force a mismatching insert into the full case.

## Source and validation

`tools/build_orion_r5_flush_lid.py` creates complementary artwork from the same logo and font contours as the delivered lid. Both STLs share one print transform. `flush-lid-validation.json` records solid validity, absence of material overlap, surface fill, common height and mesh closure/orientation. The body, screw holes, lid lip and enclosure geometry share the validated assembly dimensions.

The source generator and colour script reproduce the current four-plate colour project. Its validation reports are stored beside these instructions.

Progress (2026-09-25): CAD validation passed with zero overlap between body and markings, zero unfilled volume in the artwork's surface plane, and one valid solid when both materials are united. All marking and body meshes are closed and consistently oriented. Digital review confirms the registration and integrity of the native body mesh.

Native slicing passed for all four plates. Actual toolpaths use the two PETG colours on the first two layers (Z 0.2 and 0.4 mm), with only body PETG afterwards. The prime tower occupies a clear area of plate 1; the two TPU plates remain separate. Dark-to-white and white-to-dark purge allowances are conservative starting values, not physically calibrated colour-change settings.

The installed OrcaSlicer 2.4.1 is older than the 2.5.16 file metadata saved in the user's source. Native validation uses a disposable copy and changes two disabled-support sentinel values from -1 to 0 only for that compatibility check. The delivered project retains the user's newer settings. It remains editable and should be sliced in the user's current slicer before printing.

Stale plate-1 preview caches are removed; the older command-line slicer cannot regenerate those images on this host. Open and slice the project in the GUI for current plate previews. The accurate [CAD lid preview](lid-flush-preview.png) shows the outward face and its flush colour treatment.

Orca reports inherited bed-temperature/profile warnings: saved PETG bed 70 C equals the profile's 70 C glass-transition value, and TPU bed 35 C exceeds its profile's 30 C value. These saved temperatures were preserved. Confirm bed/nozzle settings against the actual filament rather than treating these generic profiles as material qualification. No mesh, build-volume or support warnings were reported in the completed native slice.

Use the [assembly manual](../../../../../output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf) for part identification, assembly and empty-case tests. Keep both registered PETG parts together when printing the lid; the illustrations identify mechanical parts and sealing details.

Open: verify purchased hardware dimensions, measure cable OD, test physical print fit/colour adhesion and empty-case sealing, then check temperature/radio operation in the completed installation. No new waterproof or IP qualification is implied.
