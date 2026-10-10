# Independent flush-colour lid review

**Project-internal engineering and production record.** This file records development evidence; the assembly PDF and current print-package README provide the user instructions.

Reviewed on 2026-09-25. This review inspected the generator and independently read the STL and 3MF outputs without rebuilding the enclosure or repeating the expensive CAD union.

## Geometry and coordinates

`build_orion_r5_flush_lid.py` uses the same logo polygons and font contours as the original engraving. The current sealed contract specifies 0.4 mm depth, matching the delivered lid. The original lid body is copied without changing its screw holes, seal lip, or other geometry. The added colour islands terminate at the same outside plane as the surrounding lid.

Both STL parts receive one shared rotation and translation, preserving their registration. The lid prints exterior-face down; the contrasting PETG occupies Z=0 to 0.4 mm, corresponding to two nominal 0.2 mm layers. The islands must remain parts of one multicolour object and must be co-printed. They are not separately assembled inserts.

The generator checks zero body/marking overlap, valid solids, one solid after combining the materials, matching top heights, and no missing material in a thin slab across the artwork surface. The completed `flush-lid-validation.json` reports a pass: body/marking overlap is 0 mm3, the exterior test slab has 0 mm3 void, the combined geometry is one valid solid, and STEP readback contains the expected 32 valid solids (one lid body plus 31 colour islands). The reported exterior is neither raised nor recessed. These results were read from the completed CAD check; the expensive Boolean operation was not rerun by this reviewer.

## Independent STL checks

The independently inspected staging STLs passed all edge-incidence, orientation, and non-degenerate-triangle checks. Every connected shell has positive signed volume.

After completion, the final `lid_body.stl` and `lid_markings.stl` hashes were independently checked and are byte-identical to those inspected staging files. The measurements below therefore apply to the delivered final meshes.

| Property | Lid body | Markings |
|---|---:|---:|
| Connected closed shells | 1 | 31 |
| Vertices | 26,252 | 23,438 |
| Triangles | 52,524 | 46,792 |
| Boundary/nonmanifold edges | 0 | 0 |
| Inconsistently directed edges | 0 | 0 |
| Degenerate triangles | 0 | 0 |
| Signed mesh volume | 15,233.318318 mm3 | 62.174447 mm3 |

Marking bounds in the common print coordinates: X=14.275801 to 66.524200, Y=19.498816 to 48.344044, Z=0 to 0.4 mm. The preview was inspected visually and shows the intended logo, `BatterySentinel-N2K`, and `Orion-R5` in contrasting material on a flush surface.

The standalone exported body STL is a fresh tessellation of the same CAD body, so it is not byte- or triangle-identical to the earlier `lid.stl`: it has eight more triangles. Its bounds are identical, and its volume differs by only 0.000199 mm3, approximately 0.0000013%. Independent point-to-surface checks at every vertex and triangle centroid in both directions sampled 157,540 locations; the largest sampled deviation was 0.000890 mm. This is a sampled surface comparison, not a proof of a continuous Hausdorff bound.

Reviewed STL SHA-256 values:

- Original `lid.stl`: `75ef58f2b181e72c3117a2735b383caecc660f74f0b4fc498c72a62c1620c976`.
- Final `lid_body.stl`: `c65c93608722013e062ca517f75321fd10ad264781d4ca3e235780632aa3803d`.
- Final `lid_markings.stl`: `1e6caab1e16361b359390693c9243e1f15d436ae8e7c4f5d0ec7a7fcffbe7dec`.

## Native 3MF preservation

The complete 3MF revision retains the original native lid mesh and adds the marking mesh as a second part of that same lid object. It does **not** substitute the separately retessellated body STL. Independent ZIP/XML readback confirmed that the original lid mesh and every original `3D/Objects/*.model` entry remain byte-identical. The original and new lid components both use identity component transforms, with the marking vertices translated into the existing native local coordinates. The project contains the additional third filament for contrasting PETG.

The native frame translation from the original print STL is approximately (-40.4005949, -33.4000015, -2.5) mm. An independent nearest-vertex comparison checked all 26,248 original lid vertices against the native mesh after that translation; the maximum mismatch was 0.00000272 mm. This supports using that same translation for the added colour part.

The packaging agent's separate `project-preservation-validation.json` records preservation of the user's four plates, object settings, and build transforms. Native slicer checks and colour mapping are recorded separately; mesh closure alone does not establish successful multicolour slicing.

## Physical limits

No physical print was performed. Colour opacity through 0.4 mm of PETG, adhesion between colours, small lettering details, plate texture, hardware fit, and enclosure sealing remain physical checks. The flush colour revision adds no environmental protection qualification.
