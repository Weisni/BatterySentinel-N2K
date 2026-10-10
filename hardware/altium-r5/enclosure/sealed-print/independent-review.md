# Independent enclosure interface review

**Project-internal engineering and production record.** This file records development evidence; the assembly PDF and current print-package README provide the user instructions.

Reviewed on 2026-09-24. This records independent read-only inspection of the saved native PCB, the design JSON, the enclosure generator, and the selected cable's product photographs. No PCB or schematic was rebuilt or edited. Physical fit, sealing, durability, and printer performance remain untested.

## Native PCB against enclosure source

Native source: `hardware/altium-r5/BatterySentinel-N2K-Orion-R5.PcbDoc`.

- SHA-256: `3dd1aa823ffbf749577ac1a446e843ffbb9ee1a0ca3e7c57f527c5d1c9fb9e92`.
- Enclosure geometry source: `hardware/altium-r5/orion-r5-design.json`.
- JSON SHA-256: `c2bf4b8ffe4e4592865f9705d4225aa2acfeaae2b860f8d6b53a96eb7e0427ea`.

The existing `altium_libraries.read_cfb_streams` and `verify_altium_binary_r3.decode_board` readers were used to inspect the actual native binary, including native component-body coordinates and heights. Native positions were compared with the JSON; native 3D contours were compared with the JSON bodies transformed through each component's position and rotation.

| Check | Independent result |
|---|---|
| Component placement | All 37 match the JSON within 0.01 mm and 0.001 degrees |
| Component 3D geometry | All 224 bodies match outline and height within 0.00001 mm |
| Board exterior | 52 x 36 mm; Hausdorff difference 0.00000156 mm; symmetric area difference 0.00006198 mm2 |
| Antenna window | One window; bounds approximately (28,14.5) to (33,25.5); Hausdorff difference 0.00000161 mm |
| Mounting holes | Four holes at (3,3), (3,33), (49,3), (49,33); native diameter 2.20000068 mm |
| USB interface | MCU1 at (40,20), rotated 270 degrees; mouth (52.65,20), 2.75 mm above carrier top, facing +X |
| RUN/SERVICE interface | SW3 mouth (39,36.85), 0.7 mm above carrier top, facing +Y |
| Vertical component envelope | Highest body 10.33 mm above carrier top; lowest modeled tail -2.5 mm |

The strict `decode_r5` wrapper rejected the saved antenna-window region because it is marked `ISBOARDCUTOUT=TRUE`, `KIND=0`, on `KEEPOUT`, whereas that wrapper expects `MULTILAYER`. Direct readback confirms that its geometry matches the intended JSON window. This review verifies the geometry used for enclosure fit; it does not certify Altium fabrication-layer interpretation or replace a native DRC/CAM check.

## Enclosure design review

The revised generator separates the four PCB screws from the six lid screws. The lid screws lie outside the continuous sealing loop. USB and RUN/SERVICE have separate screw-fastened covers and continuous TPU face seals. Side cover insert pilots terminate in the 8 mm wall, with nominal 1.3 mm material remaining between the pilot bottom and the inner cavity. The mounting-ear holes remain outside the cavity.

Face gaskets are 1.2 mm thick before assembly and are designed to close into 1.0 mm grooves, giving 16.7% imposed axial squeeze. Both heights align with the selected 0.2 mm print layers. The wider grooves allow nominal lateral displacement. The cable cartridge is unsplit and closes from 7 mm to 6 mm length; its nominal volume is sized against the selected cable diameter and the 12.2 mm pocket. These are imposed geometric conditions, not a simulation or measurement of TPU contact pressure or water sealing.

The final candidate moves both middle lid towers and both mounting ears to X=10 mm, clearing the RUN/SERVICE cover. The USB cover width is reduced to 43 mm to provide approximately 0.524 mm analytical clearance to the adjacent corner tower. Its opening remains 18 x 10 mm. Overall assembled dimensions are approximately 82.4 x 88 x 33.2 mm, including service covers and mounting ears; the final exported-model checks are the authority for these dimensions.

With the modeled 1.6 mm PCB at Z=8 mm, nominal geometric clearances include 3.35 mm from the USB mouth to the inner +X wall, 3.15 mm from the switch actuator to the inner +Y wall, 10.07 mm above the tallest component, and 4.1 mm from the lowest modeled tail to the floor. The USB mouth is recessed 11.35 mm from the exterior wall, so the actual cable plug must enter the 18 x 10 mm opening far enough to mate. The modeled opening does not prove compatibility with every USB overmould.

M2 x 5 PCB screws are recommended: 3.4 mm nominal engagement through a 1.6 mm PCB, leaving 1.2 mm to the blind pilot bottom. M2 x 6 would leave only 0.2 mm. Use screw heads that fit the modeled 4 mm head envelope and the reserved PCB courtyard. M3 x 8 closure screws through 3.2 mm covers give 4.8 mm nominal engagement and 1.9 mm pilot-bottom clearance.

The fit coupon's upright socket/pilots assess nominal dimensions and insertion behavior. The enclosure's side insert pilots and cable socket print horizontally; their roofs, roundness, and diameter still need inspection on the printed base. The cartridge must be threaded over the bare pigtail end before soldering it to J1. Leave room to route the individual conductors inside the case; do not force the intact jacket against the solder pads. Operate SERVICE before plugging in USB and disconnect USB before returning to RUN.

## Independent readback of exported CAD

The generated `Orion-R5-sealed-enclosure.FCStd` was reopened independently in FreeCAD after its successful geometry check. Reviewed FCStd SHA-256: `6f18bbd682f3e62d6688e2df827d9393a85365e173060cd4f98223b7e4d69dd2`.

Sixteen short cylindrical material probes were placed immediately behind the blind pilot bottoms: six side-cover/cable-cap inserts, six lid inserts, and four PCB inserts. Every probe was 100% covered by the base solid. The side probes use a 1.9 mm radius, slightly inside each 2 mm pilot radius; the PCB probes use 1.5 mm inside each 1.6 mm pilot radius. This confirms nominal closed pilot bottoms in the exported CAD, independently of the generator's depth metadata.

The assembled printable parts were compounded directly from the reopened document. Actual envelope: X=-15.2 to 67.2, Y=-25 to 63, Z=0 to 33.2 mm; overall **82.4 x 88 x 33.2 mm**. Service covers and the solid cable cartridge were included; the PCB and component bodies were excluded from this enclosure envelope.

The generator's additional OCCT intersection, full seal-land, mesh, and STEP checks are recorded separately in `validation.json`. CAD contact and closed blind pilots do not prove physical liquid tightness after printing and inserting hardware.

## Selected HangTon cable: photograph review

Selected product: [HangTon male Micro DeviceNet 5-pin to bare wire, 1 m, ASIN B0DTHSNSHS](https://www.amazon.de/dp/B0DTHSNSHS). The exact page was read directly and the high-resolution images from its initial product gallery were inspected, including:

- [Main product photograph](https://m.media-amazon.com/images/I/61G35QEMHUL._SL1500_.jpg).
- [Additional jacket/connector photograph](https://m.media-amazon.com/images/I/61A5a+OZjbL._SL1500_.jpg).
- [Connector dimension drawing and pinout](https://m.media-amazon.com/images/I/61ZVgY5XG-L._SL1500_.jpg).

The visible jacket markings include `ZELONGKANG`, `VW-1`, `105 C`, `300 V`, `AWM I A/B`; another photograph shows `E330488`. These do not state the cable outside diameter. The drawing labels the connector as diameter 15 mm with M12 x 1 thread and approximate connector lengths 46.5/44.9 mm. It provides no cable-diameter callout or tolerance. Its drawn cable width scales to approximately 5 mm against the connector dimension, but that is only a schematic estimate and must not be treated as a manufacturer diameter specification or used to freeze a sealing fit.

[UL's explanation](https://www.ul.com/resources/iec-62368-1-ask-engineers-question-and-answer-page) identifies VW-1 as a vertical flame-test designation. [UL's historical AWM 2464 manufacturer listing](https://iq.ul.com/awm/company.aspx?Style=2464) associates E330488 with Dongguan Zelongkang Wire Co., Ltd.; that listing does not establish which cable construction or diameter appears in this assembled HangTon product.

No defensible exact cable OD was found in the selected page or inspected images. Retain the interchangeable 5.0, 5.5, 6.0, 6.5, and 7.0 mm cartridge options, and choose the final cartridge only after measuring the delivered jacket. Use the solid cartridge to close the entry when no cable is installed. Leak, pull, thermal, and RF acceptance tests remain separate physical checks; no IP or waterproof rating is claimed.
