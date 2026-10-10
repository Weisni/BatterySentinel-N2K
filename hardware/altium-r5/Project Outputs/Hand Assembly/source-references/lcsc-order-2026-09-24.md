# LCSC procurement check - 2026-09-24

## Current order status - 2026-09-25

The user confirms that all parts have been ordered and PCB manufacture has been commissioned. Delivery is pending; assembly and first commissioning of the complete R5 hardware are the next stages. This supersedes earlier unsubmitted-cart statements below. Delivered contents, dimensions and physical acceptance remain to be checked. The update does not establish new final checkout amounts or additional confirmed payments.

## Actual payment update

User-confirmed payments: **JLC EUR 40.20**, **LCSC EUR 58.22**. **Total paid: EUR 98.42.** The electronics/cable Amazon items are now reported as ordered; their recorded cart value is EUR 53.39, with final checkout amount and payment not separately confirmed. A separate Amazon hardware order dated 2026-09-25 adds EUR 20.98, with payment not separately confirmed. On 2026-09-30, the user confirmed payment of **EUR 23.85 for PCB customs and DHL processing** and supplied the [original DHL invoice](procurement/2026-09-30-DHL-PCB-customs-invoice.pdf). This comprises EUR 6.00 customs duty and EUR 17.85 processing including VAT; see the [evidence record](procurement/README.md). **Total confirmed paid: EUR 122.27. Total recorded costs remain EUR 196.64**, comprising EUR 122.27 paid plus EUR 74.37 of payment-unconfirmed Amazon amounts. The customs amount was already included and is not added again. These amounts and payment statuses supersede the historical cart estimates below.

## Amazon enclosure hardware order - 2026-09-25

Source: the user's order screenshot, dated 25 September 2026. It shows one combined **EUR 20.98** order containing:

| Item | Quantity | Price information |
|---|---:|---|
| Habwea 308-piece brass heat-set insert assortment, M2/M2.5/M3/M4/M5/M6; soldering-iron insertion aid included in the product title | 1 assortment | Individual price not shown |
| WZHUIDA 660-piece M2 stainless button-head hex-socket screw, nut and washer assortment | 1 assortment | Individual price not shown |

The combined EUR 20.98 is counted once. The screenshot establishes that the order was placed; payment is not separately confirmed. No personal name, delivery address or order identifier is retained here.

The Amazon electronics/cable items, now reported as ordered, have a previously recorded cart value of EUR 53.39: one NMEA 2000 T-piece (EUR 18.14), one four-pack ESP32-C3 SuperMini without OLED (EUR 18.99), and one 1 m male-to-bare-wire NMEA cable (EUR 16.26). The displayed ESP32 coupon has not been deducted. Amazon recorded subtotal is now **EUR 74.37**; overall recorded costs, including the import duty reported on 2026-09-30, are **EUR 40.20 + EUR 58.22 + EUR 53.39 + EUR 20.98 + EUR 23.85 = EUR 196.64**. The historical four-cable estimate below is not included in this current total.

Compatibility remains open: the screenshot does not establish the Habwea insert lengths/outer diameters, individual screw lengths or screw-head dimensions. The [current sealed enclosure](enclosure/sealed-print/README.md) specifies 12 ruthex RX-M3x5.7 inserts with 12 M3 x 8 screws and four RX-M2x4 inserts with four M2 x 5 screws per enclosure. Do not treat the generic assortments as verified substitutes based on thread size alone. Check the delivered dimensions and perform the insert-fit coupon trial; the pictured M2 fastener set does not establish availability of the required M3 x 8 screws. The old M2 x 18 shared lid/PCB fastener proposal below is historical.

Open: confirm payment status, verify delivered contents and compatible quantities, and update the remaining hardware list after the dimensional/coupon checks. No CAD or assembly-manual change follows from this purchase record alone.

## Historical four-board cart check (before ordering)

The user requested four boards. Updated and verified the live cart: C2671714 quantity 4, C7500927 quantity 4, C2071056 quantity 8, C138687 quantity 8. All other quantities in the historical table below remain unchanged. Every one of the 17 lines is in stock and supports at least four boards; the minimum capacity is exactly four, without assembly losses. No order was submitted.

Current merchandise total EUR 30.38 less EUR 0.48 discount = **EUR 29.90**. Estimated shipping EUR 10.40; **cart total EUR 40.30**, EUR 9.95 above the two-board cart. With the user's EUR 45.75 PCB/stencil quote: **EUR 86.05**, allocated EUR 21.51 per board, before ESP32, NMEA pigtails, consumables and any additional LCSC checkout/import charges. This supersedes the two-board cost calculation below.

Separate Amazon items checked live:

- One [Meshnology four-pack ESP32-C3 SuperMini, B0FN4F6244](https://www.amazon.de/dp/B0FN4F6244), selected variant `4 x C3`, EUR 18.99, in stock. This is the user's specified module, not a substitute.
- Four [HangTon NMEA 2000 male Micro DeviceNet 5-pin to bare-wire pigtails, 1 m, B0DTHSNSHS](https://www.amazon.de/dp/B0DTHSNSHS), EUR 16.26 each, EUR 65.04 for four. The page showed 17 in stock. Selected variant: male to bare wire, 1 m. Listing states shield plus red/black/white/blue conductors on pins 1/2/3/4/5 respectively. Verify physical continuity before soldering. Cable outside diameter and enclosure-clamp fit have not been verified.
- Amazon electronics/cable subtotal EUR 84.03 before any shipping; combined with the displayed LCSC and PCB/stencil figures EUR 170.08 (EUR 42.52 per board). Prices are observations, not reservations.
- Solder paste, flux and cleaning materials are additional if not already owned. The provisional enclosure design calls for 16 RX-M2x4 inserts and 16 M2x18 screws for four enclosures, but its mechanical contract remains unfrozen; these are not a released enclosure purchase list.

The L1 datasheet/temperature/physical-validation limitations below still apply. The cart is quantity-complete and orderable, not a new hardware qualification. Final checkout charges and delivery timing remain to be checked by the user. Amazon carts were not modified.

The live guest cart now contains 17 in-stock lines and no backorders. No order was placed. The cart remains at https://www.lcsc.com/cart in the user's browser session.

## Quantity and cost

The order supports **two boards**, excluding the separately purchased ESP32-C3 SuperMini modules and NMEA pigtails. TP1 is a bare copper pad and requires no purchased component. Quantities assume no assembly losses.

| References | LCSC part | Quantity in cart | Per board | Boards supported |
|---|---|---:|---:|---:|
| U1 | C2671714 | 2 | 1 | 2 |
| U2 | C7500927 | 2 | 1 | 2 |
| U3,U4 | C2071056 | 4 | 2 | 2 |
| D3 | C28933048 | 5 | 1 | 5 |
| L1 | C2932173 | 5 | 1 | 5 |
| C22,C23,C27,C32,C33 | C12891 | 20 | 5 | 4 |
| C20,C21 | C138687 | 4 | 2 | 2 |
| D5 | C14238 | 20 | 1 | 20 |
| C4,C5,C24,C26,C28,C30,C31 | C14663 | 50 | 7 | 7 |
| D1 | C152104 | 10 | 1 | 10 |
| C25,C29,C34 | C15850 | 20 | 3 | 6 |
| R3,R4 | C23140 | 100 | 2 | 50 |
| R2 | C25804 | 100 | 1 | 100 |
| F1 | C3032873 | 5 | 1 | 5 |
| R20,R21 | C4258541 | 20 | 2 | 10 |
| SW3 | C963206 | 5 | 1 | 5 |
| L2,L3 | C167874 | 10 | 2 | 5 |

LCSC merchandise: EUR 20.90 minus EUR 0.35 discount = **EUR 20.55**. Estimated shipping to Germany: **EUR 9.80**, Global Direct Standard Line, 7-15 business days. Cart total: **EUR 30.35**. The postal code is not entered; final taxes, import charges, delivery date and checkout total are not verified.

User's PCB plus stencil quote: EUR 45.75 including its shipping/taxes. Combined displayed outlay: **EUR 76.10**, or EUR 38.05 per assembled board when allocating the whole purchase to two boards. Difference from the user's EUR 142 PCBA quote: EUR 65.90 before additional LCSC charges, soldering consumables and labour. Both options exclude the ESP32 and NMEA connector. Leftover components and bare boards remain assets, not additional complete assemblies.

## L1 replacement

Removed out-of-stock TDK ACT45B-510-2P-TL003 (C76584), quantity 2. Added **PROD Tech PSCIAQ4532-510Z (C2932173)**, minimum quantity 5, EUR 1.49 after displayed discount. The product page reported 5,005 pieces available; the final cart confirms the requested quantity is in stock.

Sources: [product](https://www.lcsc.com/product-detail/C2932173.html), [manufacturer datasheet supplied by LCSC](https://www.lcsc.com/datasheet/C2932173.pdf), local inspection copy `../../tmp/lcsc-comparison/C2932173.pdf`.

Manufacturer datasheet pages 3 and 5: 51 uH +50/-30%, 2.8 kohm typical at 10 MHz, 1 ohm maximum DCR, 200 mA rated current, 80 V rated voltage; windings **1-4 and 2-3**, same as the R5 connectivity. Body 4.5 +/-0.2 by 3.2 +/-0.2 mm, maximum height 3.0 mm. These are compatible nominal CAN-choke characteristics, not evidence of identical EMC performance.

Mechanical check against `orion-r5-design.json`: existing pads are 1.35 by 0.90 mm at x = +/-2.275, y = +/-1.25 mm. Replacement nominal terminals are 1.0 by 1.0 mm at the body corners. Nominal overlap is approximately 0.65 by 0.80 mm per pad. The part fits the existing pads for manual assembly; the manufacturer's recommended land pattern (1.4 mm square pads on 3.5 by 2.2 mm centres) is different. This is a geometric review, not a reflow-process qualification or a physical fit test.

Temperature discrepancy: LCSC lists -25 to +105 C, while manufacturer datasheet pages 8-9 state -40 to +125 C including self heating. Do not claim the original TDK -40 to +150 C capability for this substitution. Until clarified, use the conservative intersection (-25 to +105 C) for this part. The assembled board's allowable temperature is not established by this procurement check.

The cjiang FACT4532 alternative was not selected: its sheet gives windings 1-2 and 4-3 without a numbered physical pin map. Matching package dimensions alone did not establish a safe direct substitution.

## L2/L3 and excluded items

- C167874 FNR4030S4R7MT remains in stock, quantity 10. The previous electrical/land-pattern review is recorded in `lcsc-preisvergleich-2026-09-23.md`.
- All three inductors can therefore be sourced in this LCSC cart. Amazon searches for the original ACT45B did not yield a verifiable exact listing; no unverified Amazon choke was selected.
- Buy two of the user's specified ESP32-C3 SuperMini modules and two appropriate NMEA Micro-C pigtails separately. Solder paste/flux and enclosure hardware are not included.
- LCSC's page displays a September 25-October 7 holiday notice; the shipping estimate is not a guaranteed arrival date.

## Progress and open verification

- Completed: live cart stock check, L1 replacement review, removal of backorder, final cart verification and board-count calculation.
- Existing Altium native design and manufacturing files were not modified. Record the replacement on the manual assembly BOM; original fabrication geometry remains unchanged.
- After assembly: inspect L1 solder joints and verify CAN communication and power rails. No physical prototype or EMC test was performed during procurement.
- Open at checkout: final delivered price and delivery date. No payment or supplier message was sent.
