# V2.3 enclosure - editable STEP solids for Onshape

This package exports the native V2.3 CAD boundary representation. No STL or 3MF mesh is converted. The original planar faces, analytic cylinders and rounded surfaces remain CAD surfaces; lofts may use spline surfaces. Flat geometric facets intentionally present in the design, including the fine polygonal artwork contours, remain unchanged.

## Files

- `Orion-Enclosure-V2.3-Assembled-All-Variants.step`: one STEP containing the complete closed V2.3 enclosure assembly at its native coordinates, plus clearly named element variants in separate groups beside it. The lid/inlay registration and all released housing-component installation positions are preserved. Electronics, screws and inserts are not modelled by this housing export.
- `parts/*.step`: all 27 original V2.3 print items as individual named CAD files, including gasket alternatives, shim pairs and optional calibration coupons. The original `strain_relief_upper` is 6 mm high.
- `latest-variants/strain_relief_upper_5mm.step`: the subsequently requested 5 mm upper clamp. The lower half remains part of the original base.
- `latest-variants/cable_seal_ID6p8_OD11p5_L9mm_profiled.step`: the subsequently requested profiled sleeve with two internal sealing beads, 6.8 mm minimum bore, 11.5 mm maximum outside diameter and 9 mm overall length. Its fit in the unchanged 6 mm enclosure pocket is not qualified.
- `validation.json`: per-file solid counts, surface types, hashes and export/readback comparisons.

The combined file contains these groups:

| Group | Contents |
| --- | --- |
| `01_Assembled_V2_3` | Closed housing, lid with registered artwork, covers, cap, original 6 mm clamp and seated 0.2 mm shim pair; seals in the original nominal installed state |
| `02_Cable_seal_variants_FREE` | All nine original sleeves, named by bore/free length and OD 11 mm, plus the latest ID 6.8 / OD 11.5 / L 9 mm profiled sleeve |
| `03_Upper_clamp_variants` | Original 6 mm and latest 5 mm upper clamps |
| `04_Clamp_shim_variants` | Clearly named 0.2 mm and 0.4 mm paired shims |
| `05_Face_gaskets_FREE` | Actual free 1.8 mm profiled lid, USB and switch gaskets |
| `06_Optional_calibration_parts` | Original optional fit and material coupons |

The primary assembly retains original V2.3 geometry, including simplified seated TPU envelopes, explicitly labelled `SEATED` / `ENVELOPE`. The `FREE` variants contain the actual manufactured profiles. Alternative parts are parked outside the main assembly so mutually exclusive sleeves and clamps do not overlap. Hide groups 02-06 for an unobstructed view of the assembled enclosure; edit or insert the desired variant when making a change. STEP does not transfer a native Onshape configuration table, active/suppressed variant choices or mate constraints.

`lid_body` and `lid_markings` share their coordinate frame in the individual files and their assembled placement in the combined file. Marking islands and shim pairs are multiple intentional solids.

## Import and edit in Onshape

1. Unzip this package locally. Import the `.step` file itself, not the distribution ZIP.
2. In an open Onshape document, choose the bottom-left **+** menu, then **Import**. Select `Orion-Enclosure-V2.3-Assembled-All-Variants.step`, or choose a file from `parts` if only one component is needed.
3. Choose **Import to a single document** to preserve the assembly/group structure and obtain the associated editable Part Studios. Alternatively, choose **Combine to a single Part Studio** for all individually selectable solids in one editing space. Keep **Y Axis Up** disabled: these files use millimetres with Z up. Keep automatic composite creation disabled if offered, so parts remain separately selectable.
4. Open the desired part's imported Part Studio. Select a planar face for a new sketch and add or remove material with an extrude. Use direct editing such as **Move face**, **Delete face**, fillets and chamfers where the chosen geometry permits.
5. For the lid, retain the inlay's placement if retaining two-colour artwork. For easier envelope edits, hide the separate lettering parts while selecting the lid body.

STEP transfers solids and surfaces, not the original sketch dimensions, feature tree or constraints. You can immediately add Onshape features and directly edit compatible faces, but there is no reconstructed native Onshape modelling history. No mesh-to-solid conversion is needed. Individual editing operations can still fail for geometrically incompatible modifications.

## Progress and verification

- [x] Exported native CAD rather than triangulated print meshes.
- [x] Kept V2.3 parts separate from the latest standalone variants.
- [x] Exported one complete assembled enclosure with named variant subgroups, preserving the original lid/inlay alignment. A reproduced STEP exporter bug that dropped translated compound placements is handled by rebuilding identity-positioned compound roots from their located native solids.
- [x] Replaced the older assembly's unrefined cap/clamp topology with the matching valid manufactured CAD solids in the same installation frames, and checked their surface equivalence. No mesh conversion or dimensional redesign was used.
- [x] Checked every exported STEP by local reimport: valid closed solids, preserved solid count and no tessellated STEP entities.
- [x] Compared source and reimported surfaces in both directions using all tessellation vertices, with a 0.05 mm acceptance threshold and 0.2% mesh-volume threshold.
- [x] Compared regenerated base, branded lid and inlay against the released V2.3 CAD; verified original source file hashes remained unchanged.
- [x] Checked ZIP CRC and each packaged STEP hash.
- [ ] Import in the user's Onshape account and confirm the chosen downstream edits. No account upload was performed during generation.

These checks establish digital export fidelity, not physical fit, retention or sealing. Rebuild with FreeCAD 1.1 Python and `tools/export_enclosure_onshape.py` from the project root.

Official Onshape guidance, consulted 29 September 2026:

- [Importing files and processing options](https://cad.onshape.com/help/Content/Document/importing_files.htm)
- [Importing and directly editing STEP/Parasolid solids](https://www.onshape.com/en/resource-center/tech-tips/import-edit-step-iges-parasolid-stl)
