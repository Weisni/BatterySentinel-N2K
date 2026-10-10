# Orion R5 gasketed enclosure — Bambu P2S prototype

**Previous prototype - superseded by [V2](../sealed-v2/README.md):** on 27 September 2026 the user reported that 95A TPU is too stiff, the cable is not retained and the pressure cap bends. The confirmed jacket diameter is 7 mm. V2 implements separate internal strain relief, a stiff three-screw cap and new seals, with its own CAD/3MF and manuals. The files/settings below are preserved for history and user test-plate retention; their digital checks do not establish successful physical sealing or retention. Do not mix these seals with V2 parts.

This enclosure closes the lid, USB service opening, RUN/SERVICE switch opening and cable entry with removable, screw-fastened parts. The PCB mounts independently of the lid. External mounting ears and the lid screw bores stay outside the lid seal loop.

Current revision (2026-09-25): [four-plate P2S project with flush-colour lid](Orion-R5-P2S-flush-colour.3mf). The lettering and logo are contrasting PETG level with the lid surface. The user's PETG and TPU test plates and existing settings are preserved. [Colour setup, test-piece explanation and revision details](flush-colour/README.md).

Optional process presets (2026-09-25): [Awesome AI at 0.20 and 0.12 mm](awesome-ai-profiles/README.md) combine the user's Smooth Surface settings with the successful enclosure process. Both pass native QuackSlicer coupon slicing and key-setting readback; their combined surface finish still needs a physical comparison. The existing 3MF is unchanged.

The nominal assembled envelope is **82.4 × 88 × 33.2 mm**, including covers and mounting ears but excluding screw heads and cable. The two mounting-slot centres are 76 mm apart at PCB coordinates `(10, -20)` and `(10, 56)`. The USB cover is 43 × 24 mm.

**Physical qualification is pending.** These files define a printable prototype, not a verified waterproof or IP-rated enclosure. Printed TPU gaskets and the cable sleeve are experimental seals. A closed CAD surface does not establish that the printed case will keep water out on a boat.

## Files and progress

- [Illustrated assembly manual (English PDF)](../../../../output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf) walks through the full assembly with part labels, CAD views, seal sections and a printable acceptance record.
- [Orion-R5-P2S-flush-colour.3mf](Orion-R5-P2S-flush-colour.3mf) is the current project: plate 1 contains rigid enclosure parts, plate 2 the TPU alternatives, plate 3 the PETG test piece/cap and plate 4 a 6.0 mm test sleeve. The lid is one object with two colour parts. Select the Bambu P2S with a 0.4 mm nozzle and check actual filament mapping before slicing.
- [Orion-R5-all-parts-portable.3mf](Orion-R5-all-parts-portable.3mf) is the portable geometry fallback. Import it as separate objects, assign materials and keep PETG and TPU on separate plates; portable geometry does not carry the complete Bambu process setup.
- [print-manifest.json](print-manifest.json) identifies every printable part, its material and which cable cartridges are alternatives. Hardware, PCB and component reference models are not printable parts.
- [Orion-R5-sealed-enclosure.FCStd](Orion-R5-sealed-enclosure.FCStd) is the editable CAD assembly; [Orion-R5-sealed-assembly.step](Orion-R5-sealed-assembly.step) is the assembly exchange file. Individual STL files provide a fallback import route.
- [CAD validation](validation.json) passed: valid solids, collision and sealing-land checks, 15 closed and consistently oriented printable meshes, and STEP readback with nine valid assembly solids. The minimum modelled component-to-case clearance is 1.678 mm. Independent CAD readback also confirmed all 16 blind pilot bottoms remain closed.
- Native slicing passed for all four plates in the current [flush-colour project](flush-colour/README.md). These are digital checks; physical acceptance remains open below.
- `preview-assembled.png` and `preview-exploded.png` show the assembly. Fasteners are omitted from these views.

The generator is [`tools/build_orion_r5_sealed_enclosure.py`](../../../../tools/build_orion_r5_sealed_enclosure.py). It takes the current R5 PCB outline and component bodies from the project rather than changing the Altium board. Use this directory's parts and hardware list together.

## Parts to print

| Material | Parts for one assembled enclosure | Quantity |
| --- | --- | ---: |
| PETG | Base, lid, USB cover, service-switch cover, cable pressure cap | 1 each |
| TPU | Lid gasket, USB gasket, service-switch gasket | 1 each |
| TPU | One cable sleeve **or** the solid cable blank | 1 total |
| PETG | Insert/cable fit coupon, used before the enclosure print | 1 test piece |

Five sleeve alternatives are supplied for nominal **5.0, 5.5, 6.0, 6.5 and 7.0 mm cable outside diameter**, plus a solid blank for use without a cable. They are alternative cartridges; do not stack them. Print extra sleeves as needed to select a fit after the cable arrives.

The purchased cable is the [HangTon B0DTHSNSHS male-to-bare-wire pigtail](https://www.amazon.de/dp/B0DTHSNSHS), recorded in the [purchased-item list](../../lcsc-order-2026-09-24.md). The [listing's dimension image](https://m.media-amazon.com/images/I/61ZVgY5XG-L._SL1500_.jpg) dimensions the connector at 15 mm diameter but does not specify the cable jacket diameter. `VW-1` is a flame-test designation, not a diameter; see [UL's wire-flammability explanation](https://www.ul.com/resources/iec-62368-1-ask-engineers-question-and-answer-page).

The user confirmed a **7 mm jacket diameter on 27 September 2026**. Check ovality and tolerance at several positions before fixing the new seal bore. The old sleeve sizes remain prototype alternatives; the 6 mm test sleeve already saved in the project is historical and is not the correct nominal choice for this cable. The reported 95A failure still requires the linked redesign/calibration work; selecting the old 7 mm sleeve alone does not establish success.

## Printing and first fit

Use the saved orientations: base with its outside bottom on the bed; lid and service covers with their exterior faces down; flat gaskets on the bed; cable cartridges upright. Preserve the orientation and scale when importing individual STLs. Print PETG and TPU on separate plates with the corresponding material profile.

Print `fit_coupon` first. It combines a cropped cable-entry wall in its actual print orientation with a calibration block. The wall reproduces the horizontal cable socket and cap insert bores; fit the actual cable pressure cap to it. The block contains vertical M3/M2 insert pilots, a 12.2 mm diameter, 6 mm deep cable socket with a 7.6 mm through-hole, and a lid-gasket groove segment. Test the actual inserts, screws and selected sleeve before consuming a full base. The coupon checks local fit and horizontal bridging; it does not prove complete-case sealing or pull resistance.

The user's current project already provides the trial plates: plate 3 has `fit_coupon` and a duplicate `cable_pressure_cap`; plate 4 has a duplicate `cable_seal_6p0mm`. Print those plates first. The 6.0 mm sleeve is a provisional test choice; use a different cartridge once the delivered cable is measured if needed.

The prepared settings use a 0.20 mm layer height and Textured PEI plate:

| Setting | PETG parts | TPU parts |
| --- | --- | --- |
| Wall loops | 5 | 3 |
| Top / bottom layers | 6 / 6 | 6 / 6 |
| Infill | 35% gyroid | 100% |
| Outer / inner wall speed | 40 / 80 mm/s | 25 / 30 mm/s |
| Maximum volumetric speed in the user's saved project | 12 mm³/s | 3.2 mm³/s |
| Generic profile nozzle / bed | 255 / 70 °C | 240 / 35 °C |

Use the external spool for the prepared TPU workflow. These generic filament temperatures must be checked against the actual filament; re-slice after changing a material or plate profile.

Re-slice the four-plate colour project with the actual filament mapping to obtain print times and material use. It uses the saved 12/3.2 mm³/s volumetric limits and includes PETG colour changes. Only one cable cartridge is installed.

Keep sealing lands and grooves free of support scars, strings and raised seams. Inspect bridge quality above the side openings before inserting hardware. Reject warped covers, incomplete extrusion and visible gaps in seal parts. Dry and calibrate the chosen filaments according to their manufacturer. Use the prepared settings as a starting point, with a physical trial for the actual TPU hardness and PETG batch.

## Required hardware for one enclosure

| Hardware | Quantity | Location |
| --- | ---: | --- |
| M3 × 8 mm screws | 12 | Lid 6, USB cover 2, switch cover 2, cable cap 2 |
| ruthex RX-M3x5.7 heat-set inserts | 12 | Matching blind pilots in the base |
| M2 × 5 mm screws, head diameter no more than 4.0 mm | 4 | PCB mounting holes |
| ruthex RX-M2x4 heat-set inserts | 4 | PCB standoffs |
| Mounting screws and washers appropriate to the boat's mounting surface | 2 sets | External ears; 3.6 mm wide slots |

The table excludes additional trial inserts consumed by the coupon. Use corrosion-resistant fasteners suitable for the installation. Screw lengths above are measured under a non-countersunk head; countersunk screws are not intended.

The 25 September purchase records include Habwea heat-set inserts and a WZHUIDA M2 fastener assortment. Exact insert dimensions and the available M2 screw lengths/head diameters are not yet verified against this table. Check the delivered parts on the test piece before using them; do not assume a matching thread size establishes insert-body compatibility. The M3 × 8 screws remain a separate hardware requirement.

The M3 pilots are nominally **4.0 mm diameter × 6.7 mm deep**; the M2 pilots are **3.2 mm diameter × 4.6 mm deep**. These are provisional print/process dimensions, not a guaranteed press fit. The selected inserts have nominal lengths of [5.7 mm for RX-M3x5.7](https://www.ruthex.de/products/ruthex-gewindeeinsatz-m3-100-stuck-rx-m3x5-7-messing-gewindebuchsen) and [4.0 mm for RX-M2x4](https://www.ruthex.de/en/products/ruthex-gewindeeinsatz-m2-70-stuck-rx-m2x4-messing-gewindebuchsen). Install them straight and flush, using the manufacturer's process and the coupon to set temperature and depth. Let them cool before tightening.

With flush inserts and the nominal parts, the M3 screws enter 4.8 mm and leave 1.9 mm to the blind pilot bottom. The M2 × 5 screws pass through the 1.6 mm PCB, enter 3.4 mm and leave 1.2 mm to the pilot bottom. Confirm actual screw length and insert seating; do not drill these holes through. No tightening torque or insert pull-out strength has been physically qualified.

## Assembly

1. Disconnect NMEA power and USB. Selecting SERVICE alone does not remove all power. Inspect the printed parts and complete the coupon checks. Install all heat-set inserts before fitting electronics. Remove debris without cutting into sealing lands or opening blind pilots.
2. For an installed cable, feed its **bare-wire end through the cable pressure cap, then through the unsplit TPU sleeve and the base entry before soldering**. The connector cannot pass through the small entry. Keep the jacket intact through the entire sleeve and into the cavity; strip only inside the cavity, clear of the sealing zone. Leave enough internal slack that the conductors and solder joints do not carry cable loads. Use the blank cartridge instead when there is no cable.
3. Seat the cartridge against the internal shoulder and tighten the cable cap's two M3 screws evenly until the rigid cap seats. The sleeve compresses axially from 7 to 6 mm. Its bore is nominally 0.2 mm smaller than its labelled cable diameter. This describes the geometry only: actual contact pressure, jacket damage, sealing and strain relief remain to be tested. Do not tighten further to compensate for a poor fit.
4. Temporarily close the **empty** case. Place the USB and switch gaskets in their cover grooves and fit each cover with two M3 × 8 screws. Place absorbent paper inside, clear of the seals, then place the lid gasket in the base groove and fit the lid with six M3 × 8 screws. Tighten progressively and evenly until the rigid lands meet, without bowing the covers or damaging an insert.
5. Check the intended splash exposure and cable retention with all wiring disconnected. Dry the exterior before opening and inspecting for moisture. Repeat the empty-case leak check after cable flexing and after opening and reclosing covers. Correct failures and dry everything completely before installing electronics. If seals change later, remove electronics before another wet test.
6. Dry-fit the actual PCB, modules, solder tails, USB plug and switch access before cable termination. Terminate the cable using the current R5 wiring documentation and continuity checks. Fit the PCB with four M2 × 5 screws, leaving wire slack. Do not substitute the lid screws. Confirm that no wire is trapped under the board or crosses the lid seal.
7. Refit the lid and both service covers. The lid and service gaskets are 1.2 mm free thickness and 1.0 mm when the lands meet: **16.7% nominal compression**. Both heights align with 0.20 mm layers. The 3.4 mm wide grooves leave room for sideways displacement. Check that each gasket remains continuous and seated all around.
8. Mount through the external ears with washers and fixings suited to the substrate. Support the cable near the case and arrange it to shed water away from the entry. Check the final installation for cable movement, fastener loosening and enclosure distortion.

Open service covers only in a dry location. Select **SERVICE before connecting USB**; disconnect USB before returning to **RUN**. Do not infer switch travel direction from the housing. The CAD clearance uses the project module model, but the actual USB plug overmould and reach through the wall must still be checked. A plug that cannot seat fully requires a revised opening or compatible plug; do not force it. Refit both covers before boat operation.

## Acceptance work still open

- [x] User confirmed 7 mm cable jacket diameter on 27 September 2026.
- [ ] Check jacket ovality/tolerance and develop the revised sleeve/independent clamp using the linked concept.
- [ ] Print the coupon; confirm insert installation, screw engagement and cable fit.
- [ ] Trial-fit the real PCB, modules, USB plug and switch access, including solder tails and internal wiring.
- [ ] Assemble an **empty** case with the intended cable or blank and absorbent paper inside. Check for leaks at the walls, lid, service covers, inserts and cable entry under the intended splash exposure; repeat after opening and closing the covers. Dry the exterior before opening, then dry all parts completely before fitting electronics.
- [ ] Test cable retention and flexing with the actual sleeve and cap; confirm that loads do not reach solder joints. Repeat the leak check afterward.
- [ ] Verify temperature and Wi-Fi/Bluetooth operation in the closed case at the intended ambient temperature and installation location.
- [ ] Inspect sealing and fastener retention after vibration and repeated service cycles. Record the material, slicer settings, results and any changes here.

Printed TPU seals and FDM walls can leak even when they look solid. Prusa's enclosure experiments reported failures of printed flexible gaskets and better results with suitable conventional elastomer seals; see [Watertight 3D printing, part 2](https://blog.prusa3d.com/watertight-3d-printing-part-2_53638/). If this prototype does not pass the required exposure tests, revise it for a selected commercial cable gland and conventional seals, or use a qualified enclosure. No spray, immersion, saltwater, pressure, UV, temperature, vibration or IP qualification has been performed for this design.
