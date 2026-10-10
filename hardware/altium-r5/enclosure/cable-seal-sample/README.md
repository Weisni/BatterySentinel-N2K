# Profiled cable seal sample

Corrected after the user's feedback: the requested dimensions must retain the original profiled seal form. Export: [Kabeltuelle_ID6p8_AD11p5_L9mm_Profiliert.stl](../../../../output/Kabeltuelle_ID6p8_AD11p5_L9mm_Profiliert.stl).

- Minimum inner diameter: 6.8 mm at two rounded inward sealing beads, preserving the original 0.6 mm bead section radius.
- Relief bore between the beads: 7.5 mm, matching the original design principle.
- Maximum outer diameter: 11.5 mm.
- Overall length: 9.0 mm, including the 0.8 mm raised rounded end bead; straight body length: 8.2 mm.
- Outer edge rounds: 0.35 mm at the flat end and 0.2 mm at the shoulder end.
- The raised end bead faces the pocket shoulder. The opposite end has a flat annular print/contact land.
- STL units: millimetres. The bore runs along Z; the bottom is at Z=0.

This standalone sample does not revise the V2.3 enclosure or its existing 6 mm deep seal pocket. Its compression and fit in that assembly are not qualified. The former straight tube and its generator remain as superseded files, not the corrected design.

## Progress and acceptance

- [x] Restored two internal toroidal beads, the rounded axial end bead and rounded outer edges.
- [x] Measured actual CAD cross-sections at both bead crests, the relief bore and outer rounds.
- [x] Read back the STL and checked envelope, minimum vertex bore, edge incidence, connectedness, triangle area and volume.
- [x] Reviewed the real STL exterior and CAD cutaway in [the corrected parts preview](../../../../output/Kabeltuelle_und_Klemmoberteil_Korrigiert.png).
- [ ] Verify printed bore, outer diameter, compression and sealing with the actual material and cable.

Rebuild with FreeCAD 1.1 Python and `tools/build_profiled_cable_seal.py`. Digital results are in `validation.json`. The earlier `tools/build_cable_seal_sample.py` generates the rejected plain tube only.
