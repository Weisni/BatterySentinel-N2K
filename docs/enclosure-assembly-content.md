# Orion R5 enclosure — assembly manual content

**Project-internal engineering and production record.** This file records development evidence; the assembly PDF and current print-package README provide the user instructions.

Content-planning reference for the English illustrated assembly manual. Reviewed against the final `hardware/altium-r5/enclosure/sealed-print` README, contract, independent review and enclosure generator on 2026-09-24. This document concerns the gasketed printable prototype in that directory.

The following ten-page outline records the initial copy and figure plan. The final **11-page** manual uses the revised copy and layout in `tools/build_enclosure_assembly_manual.py`; use that builder and the PDF as the edition authority. Figure directions and production notes here are editorial proposals, not statements of physical validation.

## Page 1 — Build a closed enclosure

**Orion R5**  
**Enclosure assembly and service guide**  
Bambu P2S · PETG case · TPU seals · R5 sealed printable prototype v1

This guide takes you from printed parts to an assembled enclosure and explains what each closure does. Start with the small fit coupon. Check the cable fit and test the empty case before fitting the electronics.

The base holds the PCB on four independent supports. The lid closes the main cavity. Two smaller covers close the USB and RUN/SERVICE access openings. A screw-fastened cable cap compresses a single TPU sleeve around the cable; a solid cartridge closes the same entry when no cable is fitted.

The six lid screws and two mounting slots sit outside the continuous lid seal. The insert holes are blind: they end in plastic rather than passing into the cavity. Keep these closed bottoms intact.

**Prototype status.** CAD and slicer checks passed. Actual print fit, cable retention and water sealing have not been qualified. This manual does not give the enclosure an IP or waterproof rating. Complete the physical checks before boat installation.

**Your route through the build**  
Identify → print a trial → install inserts → fit the cable → test empty → fit electronics → close → mount and service.

*Figure 1: Closed enclosure with cable, covers, mounting ears and lid identified. Show the actual final geometry. A small companion cutaway may show the PCB remaining in the base when the lid is lifted. Caption: “The lid and covers close separate openings; the PCB does not hang from the lid.”*

## Page 2 — Lay out the parts

Use these letters throughout this guide. The letters are illustration labels; they are not embossed identifiers on the supplied parts.

| Label | Part | Material | Install |
|---|---|---|---:|
| A | Base | PETG | 1 |
| B | Lid | PETG | 1 |
| C | USB cover | PETG | 1 |
| D | RUN/SERVICE switch cover | PETG | 1 |
| E | Cable pressure cap | PETG | 1 |
| F | Insert/cable fit coupon | PETG | Test piece only |
| G | Lid gasket | TPU | 1 |
| H | USB cover gasket | TPU | 1 |
| I | Switch cover gasket | TPU | 1 |
| J | Cable sleeve or solid blank | TPU | **One alternative only** |

The complete 3MF contains 15 printable objects: six PETG objects and nine TPU objects. A finished enclosure uses nine printed pieces. The fit coupon stays on the bench, and only one of the six cable cartridges is installed. The five sleeves are labelled by nominal cable diameter: 5.0, 5.5, 6.0, 6.5 and 7.0 mm. The sixth cartridge has no hole.

**Gather the hardware**

| Hardware | Quantity | Use |
|---|---:|---|
| M3 × 8 mm screws | 12 | Lid: 6; USB cover: 2; switch cover: 2; cable cap: 2 |
| ruthex RX-M3x5.7 inserts | 12 | Corresponding blind holes in A |
| M2 × 5 mm screws | 4 | PCB; head diameter at most 4.0 mm |
| ruthex RX-M2x4 inserts | 4 | Four PCB supports in A |
| Mounting screws and washers | 2 sets | Choose for the mounting surface |

Keep extra inserts for the coupon. Use non-countersunk screws; the stated screw length is measured under the head. Use the screw sizes and locations listed above.

**Tools:** suitable drivers, callipers, temperature-controlled insert tool, stable heat-resistant work support, deburring tools, good lighting, absorbent paper and the actual cable. Use the insert and filament manufacturers' process guidance.

*Figure 2: Actual CAD-derived parts inventory, with A–J callouts. Show J as a single selected sleeve with a small alternatives strip; avoid depicting six cartridges stacked or fitted at once. Distinguish F from a final enclosure component.*

## Page 3 — Prove the fit and install inserts

**1. Print a small trial first.** In Bambu Studio, copy F and E to a PETG trial plate. Print a candidate J on a separate TPU plate. Printing the complete rigid plate would also print the full enclosure.

F reproduces the cable wall in its real print orientation, plus insert pilots and a short gasket groove. Use it to check insert seating, screw engagement, horizontal opening quality and cable-cap fit with your actual hardware.

**2. Check the prepared project.** Select Bambu P2S with a 0.4 mm nozzle and the actual filament and build-plate profiles. The saved setup uses 0.20 mm layers, PETG rigid parts and a separate TPU plate. Feed TPU from the external spool. Preserve the saved part orientations and scale.

**3. Inspect every final print.** Reject missing extrusion, warped contact faces, cracked parts and torn or incomplete seals. Clear loose strings and raised debris from the flat sealing surfaces and grooves. Inspect the roofs of the horizontal cable socket, openings and side insert holes. Do not carve a gasket channel deeper or drill a blind hole through to make a poor print fit.

**4. Set the insert process on F.** Support the coupon steadily. Use a correctly sized insert tip and the insert manufacturer's procedure to find a suitable temperature and feed rate for the actual PETG. Guide the insert straight into its pilot with controlled pressure; finish flush with the surrounding surface. Let it cool before trying a screw. Do not guess a temperature or force a cold insert into the print.

**5. Install all 16 inserts in A while the enclosure is empty and unpowered.** Fit twelve M3 inserts at the lid, cover and cable-cap locations and four M2 inserts in the PCB supports. Reorient and support the base so each insert enters straight. Keep heat and tools off the seal grooves. Let every insert cool, then remove loose debris.

An insert that sits proud prevents the intended rigid contact surfaces from meeting. A recessed or tilted insert changes screw engagement and can crack its support. Rework or replace a defective part before assembly. No installation temperature, tightening torque or pull-out strength has been physically qualified for this print.

*Figure 3: Insert-location map: six M3 on the rim, six M3 across the three side closures, four M2 on PCB supports. Detail views show flush/straight seating and a blind bottom. A second small image should show the actual coupon with E attached to its upright cable wall.*

## Page 4 — Fit the cable before soldering

**6. Measure the delivered cable.** Measure the intact outer jacket at several positions and in more than one direction without crushing it. Record the measurements. The purchased HangTon B0DTHSNSHS cable has no verified jacket diameter in the project. Its VW-1 marking is not a diameter. Select and test the corresponding sleeve; do not assume it is 6 mm.

The sleeve label refers to nominal cable outside diameter. Its free bore is modelled 0.2 mm smaller. Treat this as a fit starting point: actual printed bore, TPU hardness and jacket shape matter. If none of the five sleeves fits properly, revise and rebuild the cartridge. Do not scale the whole enclosure or cut a slit in the sleeve.

**7. Thread the bare end in this order:**  
**E cable cap → J unsplit sleeve → A base entry.**

Do this before soldering or terminating the cable. The external connector cannot pass through the small entry. Keep a round, unbroken section of outer jacket inside J; stripped conductors and the end of the jacket must remain clear of the sealing zone. Leave enough internal slack for the board and for conductors to reach their connection points without tension.

**8. Seat the sleeve and cap.** Push J fully into the cable socket until it reaches the internal shoulder. Align E and start both M3 × 8 screws by hand. Tighten them a little at a time, alternating sides, until the cap's rigid face seats against A. Keep the cable centred and check that the cap does not bow.

**How it works.** E pushes directly on J. The shoulder supports its inner end. Closing E shortens the sleeve from a nominal 7 mm to 6 mm so the soft material is confined around the jacket and socket. E has no separate face gasket. The sleeve provides the intended cable seal; its pressure and retention must be checked on the real print.

With no cable, install the solid J blank in the same pocket and close E. Never leave the cap's centre hole backed by an empty socket. Use exactly one cartridge, without stacking sleeves or adding a second blank.

*Figure 4: Cable threading sequence with bare wires advancing through E, J and A while the moulded connector stays outside. Adjacent accurate cutaway: E → J → shoulder with intact jacket through the centre. Label 7 mm free / 6 mm seated as nominal geometry, not measured performance.*

## Page 5 — Test the empty enclosure

Complete every wet test with **no PCB or electronic modules inside** and with the cable disconnected from all power and network equipment. Keep test paper clear of the seal grooves.

**9. Make a preliminary closure.** Fit H into the groove in C and I into the groove in D. Fit each cover with two M3 × 8 screws. Place G in the groove in A and close B with six M3 × 8 screws. Start every screw before progressively tightening opposing locations until the rigid surfaces meet. Page 7 explains these contact surfaces.

Place dry absorbent paper inside before closing. Use separate small pieces near the cable wall, service openings and lid perimeter so a wet area is easier to locate. Record the cable or blank installed.

**10. Check the intended splash exposure.** Test the empty closed case in the proposed orientation and record how it was exposed and for how long. Inspect all walls and closures. Dry the outside before opening so surface droplets do not fall inside and confuse the result. Any damp paper or moisture inside is a failed test. Find the source, correct it and repeat with fresh dry paper.

**11. Finish the mechanical checks while the cable is still unterminated.** With the intended cable and chosen sleeve installed, check retention and repeated gentle flexing in the directions expected at the installation. Watch for cable slip, jacket damage, cap movement and cracks. Increase loads only within a deliberate test plan; no qualified pull-force limit is supplied for this prototype. A good fit must not transfer normal cable loads to the future solder joints.

**12. Repeat the empty-case leak check after flexing and after opening and reclosing the service covers.** If the preliminary check used a blank, repeat with the actual cable and selected sleeve. This is the final wet mechanical check before wiring. Dry all parts completely before bringing electronics into the case.

A successful local test applies to the tested print, material, cable and exposure. If water gets through an FDM wall or a seal cannot pass the required exposure, change the design or use an enclosure and sealing hardware qualified for that environment.

*Figure 5: Empty case with absorbent paper placements, actual cable and fitted cartridge. No board in the wet-test image. A second small panel shows a hand checking cable movement while the case is supported, without applying load to a PCB.*

## Page 6 — Fit and connect the electronics

**13. Trial-fit the actual board in the dry case.** Check the PCB, modules, solder tails and internal cable route. Match the board's USB connector to the USB opening and the physical switch to its service opening. Confirm that the board rests on all four supports without rocking and that components and solder tails clear the floor and walls.

The PCB uses four M2 × 5 screws. The lid uses six M3 × 8 screws. These are separate fastening systems: removing the lid must leave the board secured in A.

**14. Check service access before final fastening.** Try the actual USB plug while unpowered. Its overmould must fit through the opening and reach the recessed connector fully. Check access through D's opening to the full switch travel. Do not force a plug or infer RUN/SERVICE from the direction shown in an illustration. Confirm switch positions using the current R5 power-review procedure.

**15. Terminate the cable using the current R5 PCB and electrical documentation.** Identify conductors by connector-to-wire continuity before soldering; do not rely only on jacket colours or this mechanical illustration. Use the actual R5 J1 pin/net assignment and inspect the completed connections. The current source documents are listed on page 10.

E and J must already be on the cable. Arrange sufficient slack for the connection work without stretching the conductors or displacing the tested sealing zone. Protect printed parts and seals from soldering heat and debris. Finish this work with every power source disconnected.

**16. Secure the PCB.** Start all four M2 × 5 screws before tightening progressively. Use heads no larger than 4.0 mm. Stop when the board is held securely; do not bow it. Route wires clear of mounting supports, lid lip, seal groove, USB access and switch motion. Nothing should pull at the solder joints when the external cable is handled normally.

If fitting the board requires changing a port, cable cartridge or sealing surface, return to the empty-case checks. Remove the electronics before any further wet test.

*Figure 6: Actual PCB body in A, with four M2 fasteners and a loose illustrative internal cable route. Mark “Routing example; use current R5 electrical documentation for termination.” Do not draw an invented coloured wire-to-pad connection. Separate detail highlights the recessed USB plug approach and switch opening.*

## Page 7 — Close the three face seals

**17. Clean and seat the gaskets.** G belongs in the perimeter groove in A. H belongs in the inside groove of C, and I in the inside groove of D. Check the full loop for twists, tears and trapped strands. Each gasket must lie continuously in its groove.

**18. Close the small covers.** Hold each gasket in its groove while bringing its cover squarely to the wall. Start both M3 × 8 screws, then alternate small tightening steps until the rigid lands meet. Check around the perimeter for a pinched or displaced gasket.

**19. Close the lid.** Lower B so its short locating lip enters A without trapping wires. Start all six M3 × 8 screws loosely. Tighten a little at a time across opposing positions, working around all six. Stop when the lid sits evenly on its rigid contact surfaces. Do not use the screws to pull down a visibly misaligned lid.

**How the face seals work.** The uncompressed gaskets are nominally 1.2 mm thick. Their grooves leave 1.0 mm between the opposing faces when the surrounding rigid plastic surfaces meet. This gives about 16.7% nominal compression. The wider groove leaves room for the TPU to spread sideways.

Those surrounding surfaces are the **hard stops**. They set the designed closure height. Extra tightening after they meet does not improve the intended seal geometry; it can bend a cover, distort the print or damage an insert. If a cover will not seat or leaks, diagnose the fit and gasket rather than applying more force.

The external mounting holes and lid screw bores are outside G's loop. Side fasteners terminate in blind holes. The continuous sealing paths are the lid loop, the USB loop, the switch loop and the cable cartridge. All four must be present for a fully closed enclosure.

*Figure 7: Actual lid and service-cover cross-sections, showing different groove locations and labelled hard-stop contact. Show 1.2 mm free gasket and 1.0 mm closed cavity. A six-point top view may show progressive opposing tightening, but no torque values. Avoid drawing extra washers or O-rings into the sealing design.*

## Page 8 — Mount it and use the service openings

**20. Mount through the external ears.** The two 3.6 mm-wide mounting slots are 76 mm apart at their centres. Use washers and fasteners appropriate to the mounting surface. Support both ears on a flat surface and tighten without twisting the case. The nominal assembled envelope is 82.4 × 88 × 33.2 mm, excluding screw heads and cable.

Choose an installation that sheds water away from the cable entry. Support the cable close to the case so movement is taken by that support rather than the printed sleeve. Leave access to the lid and service-cover screws. Confirm that the installation has not distorted the lid seam or covers.

**Normal use:** lid, USB cover and switch cover closed; cable sleeve or blank installed; USB unplugged; RUN selected after the actual switch positions have been verified.

**Dry USB service**

1. Move to or establish a dry working location. Open the switch and USB covers and keep screws and gaskets clean.
2. Select **SERVICE before connecting USB**. Use the verified switch position; the enclosure does not define a left/right direction.
3. Connect the tested USB plug without forcing it. Perform the required service work.
4. Disconnect USB **before returning to RUN**.
5. Inspect and reseat H and I. Refit C and D, tightening their two screws progressively until the rigid surfaces meet.

The switch separates the external positive supply from the module's 5 V input during USB service. It is not a general power-off control for all circuitry: parts of the carrier may remain powered if the NMEA supply remains connected. Disconnect all supplies before opening the main lid for assembly or wiring work.

After service or a period of vibration, inspect the cable, seals, covers and fasteners. Replace damaged seals. Keep a record of reopening cycles and physical checks. Check closed-case temperature and wireless operation in the actual location before accepting the installation.

*Figure 8: Mounting view with external ears, washers and independently supported cable. Add a dry-service flow graphic: SERVICE → connect USB → service → disconnect USB → RUN → close covers. Do not draw switch-travel arrows or a spray jet on a populated enclosure.*

## Page 9 — Find and correct problems

| What you notice | Check first | Corrective action |
|---|---|---|
| Insert will not seat straight or flush | Pilot print quality, support, tool alignment and coupon process | Re-establish the process on F; repair or replace the affected part. Keep the blind bottom closed. |
| Screw stops while the cover is still loose | Correct screw type and length, debris, tilted or proud insert | Remove and inspect. Use the specified screw; do not force a bottomed screw. |
| Lid or cover sits unevenly | Trapped wire, twisted gasket, raised seam, warped print or proud insert | Open it, clear the obstruction and reseat. Replace a warped or damaged part. |
| Cable sleeve is loose or will not accept the jacket | Actual jacket measurements and chosen J | Trial another appropriate sleeve or rebuild for the measured cable. Do not cut the sleeve or stack cartridges. |
| Cable slides or jacket becomes marked/damaged | Sleeve fit, cartridge seating, cap flatness and cable support | Correct the fit and support. Repeat retention and empty-case leak checks; do not compensate with more screw force. |
| Paper is wet near a lid or service seam | Continuous gasket, clean sealing faces, flat rigid contact | Repair the cause, replace damaged gaskets and repeat with fresh dry paper. |
| Paper is wet near a side insert or through a wall | Cracks, insert damage, incomplete extrusion or porous print | Replace/revise the print and retest. Closed CAD geometry cannot repair print porosity. |
| USB plug does not fully mate | Actual overmould size and reach into the recessed opening | Use a confirmed compatible plug or revise the opening; do not force the PCB connector. |
| Switch position is uncertain | Current R5 power-review and unpowered continuity check | Verify and identify the positions before USB use. |
| Heat or wireless behaviour is unacceptable when closed | Actual installation, internal temperatures and reception | Resolve and retest before installation acceptance. Do not create an unsealed ventilation hole. |

Keep the failed part, measurements, print settings and photographs until the cause is understood. Retest the changed sealing interface with the electronics removed. A printed seal that repeatedly fails the required exposure needs a different sealing solution, such as a selected commercial gland/conventional seal or a qualified enclosure.

*Figure 9 optional: Small clear close-ups of a seated gasket, a pinched gasket and an even rigid seam. Label them “Illustrative inspection examples”; do not present generated defects as photographs of tested parts.*

## Page 10 — Build record and final checklist

**Build date:** __________________  **Builder:** __________________  
**PETG / batch:** ________________  **TPU / hardness:** ________________  
**Printer / nozzle:** _____________  **Slicer profile revision:** _____________  
**Cable jacket measurements:** ___________________________________  
**Selected J:** __________________  **Changes from supplied files:** ___________

### Before fitting electronics

- [ ] F, E and the chosen J trial-fit with the actual inserts, screws and cable.
- [ ] All 12 M3 and 4 M2 inserts are straight, flush and cool; blind bottoms remain intact.
- [ ] Sealing surfaces and horizontal openings are complete and clean.
- [ ] Cap and unsplit sleeve were threaded onto the cable before termination.
- [ ] The actual cartridge is seated; the cable seal grips intact jacket.
- [ ] Preliminary empty-case leak check passed.
- [ ] Cable retention/flex check passed without movement or jacket damage.
- [ ] Final empty-case leak check after cable handling and cover cycling passed.
- [ ] All parts are completely dry.

### Final dry assembly and installation

- [ ] Actual PCB, solder tails, USB plug and switch access fit.
- [ ] Cable continuity and termination were checked against current R5 documentation.
- [ ] Four correct M2 × 5 PCB screws fitted; wires have slack and clear the seals.
- [ ] G, H and I are continuous and seated; exactly one J is installed.
- [ ] All 12 M3 × 8 closure screws are fitted; rigid faces meet evenly.
- [ ] USB is disconnected and the verified RUN position selected for normal use.
- [ ] Mounting does not distort the case; the cable has external support.
- [ ] Closed-case temperature and wireless operation checked at the intended location.

**Test exposure / orientation / duration:** ______________________________  
**Cable load / flex method and result:** _______________________________  
**Cover reopening cycles:** ________________________________________  
**Leak result / corrective work / retest:** ______________________________  
**Thermal and wireless results:** ____________________________________  
**Outstanding work:** ____________________________________________

Passing this checklist records the builder's checks on this unit. It does not assign an IP rating or establish durability beyond the recorded conditions.

**Project sources**

- Prepared files, print settings, hardware and physical acceptance: `hardware/altium-r5/enclosure/sealed-print/README.md`.
- Exact mechanical dimensions: `hardware/altium-r5/enclosure/sealed-print/sealed-contract.json`.
- CAD, native PCB and purchased-cable review: `hardware/altium-r5/enclosure/sealed-print/independent-review.md`.
- PCB: `hardware/altium-r5/BatterySentinel-N2K-Orion-R5.PcbDoc`; schematics: `BatterySentinel-N2K-Orion-R5-Power.SchDoc` and `BatterySentinel-N2K-Orion-R5-Logic.SchDoc` in the same directory.
- Selected module and USB power handling: `hardware/altium-r5/module-selection.md` and `hardware/altium-r5/power-review.md`.
- Purchased cable record: `hardware/altium-r5/lcsc-order-2026-09-24.md`.

## Production and review notes

1. **Critical figure: cable routing order.** A plausible generic gland picture is not sufficient. This model uses an unsplit cylindrical sleeve and a flat cap. The drawing must show a bare end passing through cap, sleeve and wall; the connector remains outside. There is no slit, locknut, threaded gland body, extra O-ring or invented washer seal.
2. **Critical figure: groove placement.** G is in the base. H and I are in the covers. The cable cap compresses J directly and has no separate face gasket. Use section views that agree with the generator.
3. **Critical figure: actual board fasteners.** Four independent M2 screws go down into PCB supports. Six M3 lid screws are outside the lid loop. A generic exploded enclosure with shared PCB/lid posts would be misleading.
4. **Assembly order.** Finish wet tests before soldering/installing the board so the actual cable cartridge can be changed while the end is bare. If a part change later needs wet testing, remove electronics first. Do not illustrate a spray test with an installed PCB.
5. **Generated image honesty.** Use accurate CAD geometry as the visual authority. AI images may illustrate actions, hands or installation context, but label conceptual sections and routing examples. Do not imply that an image is evidence of a completed physical build, passing spray test or known TPU compression behaviour.
6. **Hardware count.** The full case takes 12 M3 × 8 screws/12 M3 inserts and four M2 × 5 screws/four M2 inserts. Mounting hardware and consumed coupon inserts are additional. Full 3MF object count is 15; installed printed part count is nine.
7. **Scope and language.** The user's current request is in English and project policy defaults documentation to English. The separate existing German device manual is not this enclosure assembly manual.
8. **Readability.** Use brief coloured callouts only where the relevant action appears. Keep the complete prototype-status statement on page 1 and test record on page 10 rather than repeating alarm panels on every page.
9. **USB SERVICE semantics.** SERVICE disconnects the external positive supply to the module; it does not make the whole case unpowered if the NMEA supply remains connected. Do not call SERVICE “power off.”
10. **Not new electrical instructions.** No new conductor-to-pad wiring figure belongs in this manual without a separate check of current R5 net data. The existing source and continuity instruction are the authority.
