# Upper cable clamp - 5 mm height

Requested on 29 September 2026. This standalone variant interprets the unchanged "underside" as the lower clamp half integrated into the enclosure. The lower part remains unchanged.

Current export: [strain_relief_upper_5mm.stl](../../../../output/strain_relief_upper_5mm.stl). The preceding 5.6 mm trial remains separately available; its report is `validation-5p6mm.json`.

The upper contact profile and its three rounded ribs move down by 1.0 mm. The upper part's mounting feet retain their original seating plane. Its total height decreases from the original 6.0 to exactly 5.0 mm, retaining the original roof thickness above the cable. This reduces available cable clearance; simply removing material from the outer roof would not increase compression.

| Feature | Dimension |
| --- | --- |
| Overall size | 12 x 28 x 5.0 mm |
| Screw spacing / holes | 20 mm / 3.4 mm, unchanged |
| Rib-crest clearance with unchanged lower half, no shim | 5.7 mm (originally 6.7 mm) |
| Rib-crest clearance, equal 0.2 / 0.4 mm shims | 5.9 / 6.1 mm |
| Clearance between ribs, no shim | 6.4 mm |

Print with the supplied orientation: flat outer face on the bed, cable saddle upward. Retain the established PETG clamp process with 100% infill. The original enclosure CAD, lower half, print package and original upper STL are preserved.

## Assembly and physical trial

The original M3x10 screws and nominal 0.5 mm washers retain approximately 4.1-4.5 mm engagement over the available shim range. Verify actual hardware. This version reduces the local gap substantially for a 7 mm cable. Start with equal 0.4 mm shims, tighten evenly and inspect the cable jacket. Do not force the part to its stops if the jacket is excessively flattened or damaged; use greater equal stand-off if necessary. The quoted clearance is the local height between rib crests, not a circular bore diameter or a measured force. Jacket compression, retention and creep must be checked physically.

## Progress

- [x] Generated the separate variant from the existing FreeCAD upper part.
- [x] Checked reduced clearances, retained roof thickness, mounting holes and flat washer seats.
- [x] Checked assembly intersections at all three shim heights and exported mesh topology/dimensions.
- [x] Verified source CAD and original upper/base STL hashes are unchanged.
- [x] Reviewed the exported STL in [the corrected parts preview](../../../../output/Kabeltuelle_und_Klemmoberteil_Korrigiert.png).
- [ ] Validate actual cable grip, jacket condition and creep after printing.

Rebuild with FreeCAD 1.1 Python and `tools/build_strain_relief_upper_flat.py`. See `validation.json` for measured CAD/STL results.
