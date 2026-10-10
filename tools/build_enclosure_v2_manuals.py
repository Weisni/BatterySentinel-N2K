"""Create the V2 English assembly and manufacturing manuals from current CAD."""
from pathlib import Path
import json
from reportlab.pdfgen import canvas
import build_enclosure_assembly_manual as m

ROOT=Path(__file__).resolve().parents[1]
CASE=ROOT/'hardware/altium-r5/enclosure/sealed-v2'
OUT=ROOT/'output/pdf'
P=json.loads((CASE/'parameters.json').read_text())
AUDITS={}

def paragraph(y,text):return m.para(m.M,y,text)+13
def table(y,heads,rows,widths):return m.table(y,heads,rows,widths)+16
def image(y,name,height=260,caption=None):
    m.pic(CASE/name,m.M,y,m.CW,height,caption);return y+height+(32 if caption else 12)
def page(title,chapter):return m.begin(title,chapter)
def finish(kind,pages):
    m.txt(m.M,m.H-29,f'Orion enclosure V2.3 | {kind} | EN | 27 Sep 2026',8,'Body',m.MUTED)
    m.C.setFillColor(m.MUTED);m.C.setFont('Bold',8)
    m.C.drawRightString(m.W-m.M,23,f'{m.C.getPageNumber():02d} / {pages:02d}')
    m.C.showPage()
def start(name,title):
    OUT.mkdir(parents=True,exist_ok=True);m.AUDIT=[]
    m.C=canvas.Canvas(str(OUT/name),pagesize=(m.W,m.H));m.C.setTitle(title);m.C.setAuthor('BatterySentinel - Orion Bridge')
def save(name):
    m.C.save();AUDITS[name]=m.AUDIT

def assembly():
    name='Orion-Enclosure-V2-Assembly-EN.pdf';start(name,'Orion Bridge V2 enclosure - Assembly');N=8
    y=page('Enclosure assembly','V2.3 / 7 mm jacket / separate strain relief')
    y=image(y,'preview-exploded.png',310,'Actual V2 CAD. Amber: seals. Screws omitted; seated seal envelopes are illustrative, not a deformation simulation.')
    y=paragraph(y,'This manual applies to the current <b>V2.3</b> parts. The 88 x 57.2 x 33.2 mm main shell has 3 mm free wall fields, shallow ribs and six projecting screw bosses (96.8 x 68.8 mm envelope). Mounting tabs and covers extend farther. The sealing rim and connector pads are reinforced locally. The independent cable clamp, three-screw cap and centred flush artwork remain.')
    y=m.note(y,'Prototype acceptance','The CAD and print checks are recorded in validation.json and package-validation.json. Physical fit, insert retention, clamp force, creep and water sealing remain to be qualified. There is no tested IP rating.',True)+14
    paragraph(y,'Before assembly, follow the separate <b>Manufacturing and TPU Air calibration</b> manual. Use coupons before a complete case. Keep the previous printed parts separate: V2 face seals do not fit the old 1.0 mm grooves.')
    finish('Assembly',N)

    y=page('Parts and tools','01 / Select one complete revision')
    y=table(y,['Part / material','For one enclosure'],[
        ['base / PETG','1; includes PCB posts, lower saddle and clamp bosses'],
        ['lid_body + lid_markings / PETG','1 co-printed two-colour lid; keep the shared coordinates'],
        ['usb_cover, service_switch_cover / PETG','1 each; raised exterior reinforcement frame'],
        ['cable_pressure_cap / PETG','1; three M3 holes; flat annular contact face'],
        ['strain_relief_upper / PETG','1; upper ribbed jacket half-shell'],
        ['clamp_shims_0p2 or 0p4 / PETG','One matched pair; alternatives, not both sets'],
        ['lid_gasket, usb_gasket, service_switch_gasket / TPU Air','1 each; continuous rounded bead'],
        ['cable_seal_b6p8_L6p8 / TPU Air','1 initial choice; nine variants supplied for coupon selection']],[.49,.51])
    y=paragraph(y,'Calibration items are not enclosure components: entry_fit_coupon, face_stop_coupon_1p4 / 1p6, face_test_gasket, flow_wall_coupon and shore_comparison_pad. The sleeve filenames describe the <b>smallest bead bore</b> and <b>free axial length</b> in millimetres.')
    paragraph(y,'Tools: caliper, suitable insert installation tool, M2/M3 drivers, flat washers, magnifier, flat reference surface, dry absorbent paper, cable marker and controlled pull-test fixture. A Shore A durometer is needed to measure the stated hardness targets; finger feel is not a measurement.')
    finish('Assembly',N)

    y=page('Fasteners and insert trials','02 / All exterior insert pilots stay blind')
    y=table(y,['Location','Hardware / quantity','Nominal engagement'],[
        ['Lid','6 x M3 x 8 + 0.5 mm flat washer','4.3 mm into the pilot'],
        ['USB + switch covers','4 x M3 x 10 + 0.5 mm flat washer','5.5 mm; washer seat is 4.0 mm thick'],
        ['Cable pressure cap','3 x M3 x 10 + 0.5 mm flat washer','4.5 mm; washer seat is 5.0 mm thick'],
        ['Internal clamp','2 x M3 x 10 + 0.5 mm flat washer','3.3 mm with 0.2 mm shim'],
        ['PCB','4 x M2 x 5; head <= 4.0 mm','3.4 mm through 1.6 mm board'],
        ['Heat-set inserts','15 x M3; 4 x M2','Nominal body lengths 5.7 / 4.0 mm'],
        ['Boat mounting','2 suitable screws + washers','Choose for mounting surface; 3.6 mm slots']],[.25,.43,.32])
    y=paragraph(y,'M3 pilots: nominal diameter 4.0 x depth 6.7 mm. M2 pilots: 3.2 x 4.6 mm. These pilot sizes are provisional for the purchased insert bodies; thread designation alone does not establish compatibility. Use extra inserts for trials. The cap needs one more M3 set than before; the clamp needs two more.')
    y=m.note(y,'Check before heating','Measure the delivered inserts and screws. Validate insertion and resistance to tightening on the entry coupon. Install inserts flush and square, then allow them to cool. Do not drill a blind pilot through or bottom a screw in it. Use flat, not countersunk, heads. No tightening torque is qualified.',True)+12
    paragraph(y,'The engagement figures assume the stated washer thickness and fully seated inserts. Check actual lengths. A longer screw is not a remedy for a loose insert. Fasteners must suit the intended environment.')
    finish('Assembly',N)

    y=page('Cable seal installation','03 / Thread the bare end before soldering')
    y=image(y,'preview-entry-section.png',255,'CAD cutaway of the cable bay. The unsplit sleeve seals; the rigid clamp behind it takes cable load. Contact envelopes simplify TPU deformation.')
    y=m.step(y,1,'Disconnect all power','Unplug NMEA power and USB. SERVICE alone does not disconnect all power. Keep the PCB out for wet testing.')
    y=m.step(y,2,'Thread the cable','From outside to inside: pressure cap, unsplit TPU sleeve, enclosure wall. Feed the bare-wire end through; the connector does not pass through the small hole. Do not cut a slit into the sleeve.')
    y=m.step(y,3,'Seat the shoulder bead','The sleeve end with the raised annular face bead points into the enclosure pocket, toward its internal shoulder. Keep the jacket intact through both the sleeve and the internal clamp.')
    y=m.step(y,4,'Close the three-screw cap','Install the three screws and washers. Tighten in small alternating steps until the flat rigid lands meet the wall uniformly. Stop if the cap bows or an insert moves. Retention is adjusted at the separate clamp, not by overtightening the seal.')
    finish('Assembly',N)

    y=page('Internal strain relief','04 / Clamp only the intact jacket')
    y=image(y,'preview-inside.png',290,'Current PCB/component bodies and cable bay from CAD. Check the real solder tails, wire routing and driver access during the dry fit.')
    y=paragraph(y,'Place the jacket in the lower saddle. Fit a matched shim under each upper-clamp screw ear and position the ribbed upper half-shell. Start with the <b>0.4 mm</b> pair, then compare 0.2 mm and finally no shim only if retention is insufficient. Never use unequal shims.')
    y=paragraph(y,'Bring both screws down evenly. The bosses/shims limit travel; the shell must not bend. Smaller shims increase jacket compression. Choose the largest shim that prevents movement at the required service load without damaging the jacket. The bare nominal rib throat is approximately 6.7 mm; this is an adjustable trial geometry, not a universal cable clamp setting.')
    y=paragraph(y,'Mark the jacket at both sides of the clamp. On the coupon, test clamp retention independently with seal friction removed. Apply a controlled load representative of the installation and inspect movement, jacket damage and insert movement. Never pull on individual conductors or solder joints. Leave wire slack after the clamp and support the external cable near the enclosure.')
    m.note(y,'If adjustment cannot give safe retention','Stop and revise the saddle or add a properly sized dense liner. Do not tighten beyond the rigid stops or crush the jacket. Recheck retention after 24-48 hours and after representative temperature exposure.',True)
    finish('Assembly',N)

    y=page('Face seals and closure','05 / Bead orientation and controlled compression')
    y=table(y,['Seal','Orientation','Closed geometry'],[
        ['Lid','Flat carrier in base groove; rounded bead faces lid','1.8 mm free -> 1.4 mm closed'],
        ['USB cover','Flat carrier in cover groove; rounded bead faces case wall','1.8 mm free -> 1.4 mm closed'],
        ['Switch cover','As USB cover','1.8 mm free -> 1.4 mm closed'],
        ['Cable sleeve L6.8','Raised end-face bead toward internal shoulder','6.8 mm free -> 6.0 mm axial space']],[.20,.48,.32])
    y=paragraph(y,'Remove strings, support debris and raised seams without nicking the sealing faces. Reject distorted covers or interrupted beads. Seat each loop continuously, without stretch, twist or adhesive lumps. Do not double-stack seals.')
    y=m.step(y,1,'Close service covers','Fit each cover with two M3 screws and washers. Alternate small turns until its hard lands meet. The seal stays inside the screw holes; do not trap wires under a cover.')
    y=m.step(y,2,'Close the lid','Fit six M3 screws loosely, then tighten alternating opposite locations in several passes until the flange lands meet. Keep wire slack entirely inside the seal loop. Stop if any part bows.')
    y=m.note(y,'Do not mix V1 and V2 seals','V2 face grooves are 1.4 mm deep, with nominal 22.2% total-height squeeze. The old 1.2 mm flat seals and new 1.8 mm bead seals are not interchangeable. The 1.6 mm coupon is a comparison fixture, not the production groove depth.',True)+14
    paragraph(y,'Use the V2.3 base and lid as a matched set. Keep the sloped support below the lid rim intact. It stays below 45 degrees from vertical, including corners. Service planes and seals retain the styled coordinates (USB face 2.4 mm, switch face 3.4 mm outward from the original). Check plug reach and switch access. Open only when dry. Select SERVICE before USB; remove USB before RUN. Do not infer switch direction from the enclosure.')
    finish('Assembly',N)

    y=page('Empty-case acceptance','06 / Before installing electronics')
    for n,title,body in [
        (1,'Dry fit','Check the actual PCB, modules, plug, screws and wire routing. Verify each insert pilot remains closed and each cap reaches its hard stops. Remove the electronics again before wet tests.'),
        (2,'Exposure test','Put dry absorbent paper inside, away from seals, and close the empty case with its real cable. Apply the intended splash exposure. No unverified immersion depth, pressure or IP rating is assumed.'),
        (3,'Inspect','Dry the exterior before opening. Inspect the paper, cable pocket shoulder, lid, service covers, insert areas and FDM walls. Any moisture is a failure. Locate the leak rather than merely increasing screw torque.'),
        (4,'Repeat under use conditions','After cable flexing, controlled pulling, 24-48 hours of compression and opening/closing cycles, repeat the leak test. Inspect jacket and clamp marks. Record exposure, load, duration and ambient temperature.'),
        (5,'Final electrical assembly','Dry all parts completely. Terminate the cable according to the current Orion Bridge wiring guide, confirm continuity/polarity, mount the board with four M2 screws and retain conductor slack.'),
        (6,'Commission closed','After successful mechanical acceptance, check power, temperature, Wi-Fi/Bluetooth and NMEA/Garmin operation with the final closed enclosure at the intended installation location.')]:
        y=m.step(y,n,title,body)
    finish('Assembly',N)

    y=page('Acceptance record','07 / Retain with the assembled device')
    y=table(y,['Record','Result / date / initials'],[
        ['Cable OD / ovality; sleeve filename','________________________________'],
        ['Insert body dimensions; screw lengths','________________________________'],
        ['Lid / service / cable measured Shore A','________________________________'],
        ['Filament batch; profile names; drying','________________________________'],
        ['Clamp shim; applied pull load / duration','________________________________'],
        ['Jacket movement / damage / insert movement','________________________________'],
        ['24-48 h clamp and compression recheck','________________________________'],
        ['Initial empty-case exposure / result','________________________________'],
        ['Leak check after flexing and service cycles','________________________________'],
        ['Electrical / thermal / RF acceptance','________________________________']],[.58,.42])
    y=paragraph(y,'If foam seeps or fails recovery, use a qualified conventional seal/gland and revise its seat. Do not release a failed printed seal on the basis of Shore hardness alone.')
    paragraph(y,'Source of geometry: parameters.json, mechanical-contract.json, Orion-Enclosure-V2.FCStd and validation.json in sealed-v2. Dimensions are nominal CAD dimensions; physical tolerances and load ratings are not established by the digital model.')
    finish('Assembly',N);save(name)

def manufacture():
    name='Orion-Enclosure-V2-Manufacturing-EN.pdf';start(name,'Orion Bridge V2 enclosure - Manufacturing and TPU Air');N=8
    y=page('Manufacturing and TPU Air','V2.3 / P2S / 0.4 mm nozzle / calibration first')
    y=image(y,'preview-styled-presentation.png',260,'Actual V2.3 CAD: thin walls, projecting screw bosses, shallow rib fields and flush artwork. Screws and cable are reference hardware.')
    y=paragraph(y,'Material: <b>SainSmart Flex TPU Air / lightweight foaming TPU, advertised 77A-93A</b>. PETG carries the structural loads. The seal and clamp are independent. The file set includes production parts, nine alternative sleeves, fit fixtures, a flow coupon and a separate hardness comparison pad.')
    y=m.note(y,'Target hardness is not a temperature promise','The Shore ranges in this manual are engineering trial targets. They are not measured results or a supplier-certified temperature-to-hardness table. Accept a setting only after dimensional, compression, leak and retention checks. Do not transfer Siraya Tech TPU Air flow/hardness tables to SainSmart.',True)+15
    paragraph(y,'Files are prepared for reslicing after calibration, not direct printing of unverified cached G-code. Preserve the prior project and its user test plates. Select the real nozzle and build plate before every print; nozzle type changes require a new calibration.')
    finish('Manufacturing',N)

    y=page('Hardness targets by function','01 / Use moderate foaming first')
    y=table(y,['Part','Target Shore A','First temperature / comparison'],[
        ['Lid gasket','80-85 A','245 C; compare 235 and 255 C'],
        ['USB gasket','83-88 A','235 C; compare 245 C'],
        ['Switch gasket','83-88 A','235 C; compare 245 C'],
        ['Cable sealing sleeve','85-90 A','235 C; compare 245 C'],
        ['Optional clamp liner','Dense 95A; unfoamed','Use its own manufacturer profile'],
        ['Cap / clamp / case','PETG; no Shore A target','Use the supplied PETG process with calibrated filament']],[.31,.24,.45])
    y=paragraph(y,'The larger lid loop benefits from the lowest contact force. Small service seals need enough body to keep their continuous bead shape. The cable sleeve is slightly firmer to retain accurate bores and shoulder contact; it does not provide strain relief. These ranges are a starting design preference, not a validated optimum.')
    y=paragraph(y,'Do not aim for 77A everywhere. Maximum foam may lose dimensional accuracy, recovery or impermeability. If a 90A sample passes all functional tests while a softer sample seeps, choose the passing sample and record the departure from the target. Conversely, an in-range Shore value does not prove a watertight seal.')
    paragraph(y,'SainSmart supplies a 210-270 C nozzle range, 40-60 C bed range and moderate-speed guidance. The relationship between temperature and final hardness depends on speed, nozzle residence time, flow, cooling and print structure. The comparison temperatures here are experiments within that range, not certified hardness settings. [1]')
    finish('Manufacturing',N)

    y=page('TPU Air starting process','02 / Settings shared by the temperature trials')
    y=table(y,['Setting','Initial value / qualification'],[
        ['Nozzle / layer / line width','0.4 mm / 0.20 mm / nominal 0.42 mm; recalibrate for actual nozzle'],
        ['Temperature jobs','235, 245 and 255 C as separate profiles/jobs'],
        ['First layer / other nozzle temperature','Same temperature; stabilise before printing'],
        ['Bed','50 C on the selected compatible plate'],
        ['Walls / infill / top-bottom','3 walls / 100% / 5 and 5 layers'],
        ['Wall + solid infill speed','20 mm/s; first layer 15 mm/s'],
        ['Maximum volumetric speed','2.0 mm3/s ceiling; do not use PETG HF limits'],
        ['Cooling','30% after initial adhesion; auxiliary fan off'],
        ['Retraction','0.4 mm at 20 mm/s as a trial; tune for actual feed'],
        ['Flow ratio','1.00 is an UNCALIBRATED seed; calibrate before production'],
        ['Feed / drying','External spool, low drag; spool-specific drying instructions'],
        ['Surface','No ironing; no support scars on functional seal faces']],[.43,.57])
    y=paragraph(y,'100% infill removes intentionally sparse voids; individual extrusions can still foam. It neither prevents foaming nor guarantees a watertight surface. Avoid low infill or deliberate gaps as a softness control. There is no proven unfoamed skin in a uniformly hot printed seal.')
    paragraph(y,'Keep speed and cooling stable while comparing temperatures. Small-layer slowdown and the first-layer speed can change expansion. The supplied trials disable cooling-driven slowdown; inspect the actual preview and test the small service seals at their real speed. Stop a print if feed buckles or repeated underextrusion appears.')
    finish('Manufacturing',N)

    y=page('Temperature and flow calibration','03 / Complete this before full seal prints')
    steps=[
        ('Prepare dry material','Check the spool label and batch. Dry with this material/spool supplier instruction and feed from dry storage. Moisture bubbling is not controlled foaming; do not mistake it for a softer successful print.'),
        ('Establish a baseline','Print flow_wall_coupon at 235 C, 20 mm/s, 0.20 mm layers and seed flow 1.00. This small coupon contains a nominal 0.9 mm wall. Check the slicer actually generates continuous paths at the intended wall width.'),
        ('Correct expansion','Measure several wall positions and inspect the solid regions. If overexpanded, reduce flow progressively. Old flow x target/measured width is a rough first correction only; confirm again. Reject settings with gaps, swollen seams or unstable feed.'),
        ('Repeat at each temperature','Make independent 245 C and 255 C jobs and calibrate flow separately. Record nozzle type, speed, flow and dimensions. Never copy a 50% flow guess or assume one flow ratio fits all temperatures.'),
        ('Measure a comparison pad','With each calibrated setting, print shore_comparison_pad and the face/cable specimens. Use the procedure on the next page. The pad and thin seals can differ in thermal history; qualify the actual seal too.'),
        ('Select by function','For each seal choose the least aggressive foaming that reaches suitable compliance and passes the contact/leak/recovery tests. If targets are missed, adjust in 5 C steps within the supplier range and recalibrate flow. Treat 260-270 C as a later experiment, not the default.')]
    for n,(title,body) in enumerate(steps,1):y=m.step(y,n,title,body)
    finish('Manufacturing',N)

    y=page('Measuring Shore A','04 / A comparison, not a certified material test')
    y=paragraph(y,'Use the supplied <b>50 x 50 x 6 mm</b> flat comparison pad, printed with 100% infill and the same material/process as the trial. Bareiss describes flat specimens of at least 6 mm thickness for its Shore instruments. Follow your durometer manual for the presser foot, load, dwell time and test-point spacing. [2]')
    y=paragraph(y,'Allow all samples the same conditioning time and temperature; a practical internal comparison is after 24 hours in the same room. Support the pad flat on a rigid surface. Use a stand if available, approach perpendicular and avoid an edge, embossed mark, seam or visibly defective area. Never measure the 1.8 mm gasket against a hard table and call that the bulk Shore value.')
    y=paragraph(y,'Take at least five spaced readings using the instrument-prescribed dwell. Record all readings, the mean, range, dwell, room temperature and conditioning. Apply the same method throughout. If instrument instructions allow both, record separate 1-second and 15-second values; do not mix them in one average. Printed foam is structured and anisotropic, so these are process-comparison values, not certified ASTM/ISO material properties.')
    y=table(y,['Trial record','Write measured values'],[
        ['Temperature / nozzle type / speed','____________________________'],
        ['Flow / fan / batch / drying','____________________________'],
        ['Pad size / mass / conditioning','____________________________'],
        ['Readings 1 / 2 / 3 / 4 / 5','____________________________'],
        ['Mean / min-max / dwell / ambient','____________________________'],
        ['Actual gasket contact / leak / recovery','____________________________']],[.57,.43])
    m.note(y,'Without a durometer','Record hardness as unmeasured. A finger squeeze or scale fixture can compare force and recovery, but cannot establish Shore A. You can still screen the functional seals; do not label them with a fabricated Shore value.',True)
    finish('Manufacturing',N)

    y=page('Print orientation and rigid parts','05 / Separate PETG and TPU jobs')
    y=table(y,['Part','Orientation / critical point'],[
        ['Base + entry coupon','Outside floor on plate. Inspect horizontal insert/socket roofs.'],
        ['Two-colour lid','Exterior face down. Body and markings share one transform; never arrange markings independently.'],
        ['Service covers','Groove face down, exterior reinforcement up. Inspect the 3.4 mm groove-roof bridges before assembly.'],
        ['Pressure cap','Flat sealing side down, reinforcement ribs up. Keep washer seats flat.'],
        ['Upper cable clamp','Flat top down; open saddle upward, support-free.'],
        ['Face seals','Flat carrier down; rounded bead upward. No brim touching the bead.'],
        ['Cable sleeves','Cable axis vertical; raised shoulder bead up. No support in the bore.'],
        ['Shims','Flat. 0.2 mm is one layer; inspect for completeness. Never mix unequal thicknesses.']],[.32,.68])
    y=paragraph(y,'PETG: 0.20 mm layers, 6 walls, 6 top/bottom layers, 35% gyroid, outer/inner walls 40/80 mm/s, 12 mm3/s ceiling. Cap and upper clamp: 100% infill. Use compatible PETG colours. V2.3 has 3 mm free walls/floor, 0.6 mm texture, a local 6-6.6 mm sealing rim and 8 mm connector pads. Support slopes stay at or below 45 degrees from vertical. These are prototype dimensions; inspect layer bonding, flex and leaks before use.')
    paragraph(y,'Use the supplied print orientations and scale 100%. Choose the actual build plate and calibrated PETG/TPU filament. A smooth plate with an appropriate release layer may improve contact faces; remove parts after cooling without stretching seals. Do not automatically smooth, decimate or scale all parts to compensate for one bore.')
    finish('Manufacturing',N)

    y=page('Fit and compression experiments','06 / Select a sleeve and clamp setting')
    y=table(y,['Variable','Alternatives / purpose'],[
        ['Cable bead bore','6.9 / 6.8 / 6.7 mm for the measured 7 mm jacket'],
        ['Sleeve free length','6.6 / 6.8 / 7.0 mm into a 6.0 mm seat'],
        ['Axial squeeze','9.1% / 11.8% / 14.3% respectively'],
        ['Initial sleeve','b6p8_L6p8; compare adjacent alternatives if needed'],
        ['Face seal','1.8 mm free, 1.4 mm production stop; 22.2% nominal squeeze'],
        ['Face test fixture','Compare 1.4 and 1.6 mm stops with a straight section cut from the spare face_test_gasket; a flat plate supplies the load'],
        ['Clamp shims','0.4 mm first, then 0.2 mm, then none only if needed']],[.37,.63])
    y=paragraph(y,'The outer sleeve body has relief space. Its two internal rounded beads contact the jacket; the annular end bead contacts the pocket shoulder. Inspect both paths. A cable grip test does not establish shoulder sealing, and a watertight sleeve does not establish strain relief.')
    y=paragraph(y,'Test insert seating and cap closure on entry_fit_coupon. It reproduces the actual horizontal print orientation. Do not chase a leak by adding torque after the hard stops meet. Check flow, bead continuity, bore dimensions and jacket ovality first. Complete the final exposure test on the complete empty case, not only the open coupon.')
    paragraph(y,'Keep specimens compressed for 24-48 hours. Check load relaxation, cap bowing and seepage; after release, measure recovery at a fixed recorded time. Repeat under representative warmth and after opening/closing cycles. If a part takes excessive permanent set or leaks, its Shore target alone is irrelevant.')
    finish('Manufacturing',N)

    y=page('Release checklist and sources','07 / Evidence required before boat installation')
    for n,title,body in [
        (1,'Geometry and slicing','Confirm validation.json passes and package-validation.json identifies the actual slicer used. Open the prepared project, check object/material mapping, plate bounds, first-layer contact, bridges and every thin seal bead. Re-slice after any calibration change.'),
        (2,'Material process','Record final per-temperature flow, measured pad hardness or unmeasured status, and actual seal dimensions. No supplier-approved hardness/temperature curve is supplied for this printer/nozzle.'),
        (3,'Mechanical and water checks','Complete the assembly manual: insert fit, independent clamp retention, jacket inspection, 24-48 h recheck and empty-case leakage before/after cable flexing and service cycles.'),
        (4,'Fallback if foam fails','If water permeates the material or it loses compression, retain the separate clamp/stiff cap arrangement and redesign the seat for a selected conventional silicone/EPDM seal or commercial cable gland. Do not claim waterproofness from a closed STL.')]:
        y=m.step(y,n,title,body)
    y=paragraph(y,'<b>Sources checked 27 September 2026</b>')
    y=m.para(m.M,y,'[1] SainSmart, Lightweight TPU Filament / Foaming LW-TPU 77A-93A: <link href="https://www.sainsmart.com/products/lightweight-tpu-filament" color="#147d80">sainsmart.com/products/lightweight-tpu-filament</link>. Material range and general print guidance; not a validated P2S seal recipe.',style='small')+14
    y=m.para(m.M,y,'[2] Bareiss, Digital Durometer Hardness Tester: <link href="https://www.bareiss-testing.com/digital-durometer-hardness-tester/" color="#147d80">bareiss-testing.com/digital-durometer-hardness-tester/</link>. Specimen/instrument context; follow your own instrument instructions.',style='small')+14
    y=m.para(m.M,y,'Geometry and dimensions: sealed-v2/parameters.json, current PCB body model, CAD export and digital validation. Shore ranges, comparison temperatures and acceptance sequence are project engineering proposals requiring physical validation.',style='small')
    finish('Manufacturing',N);save(name)

if __name__=='__main__':
    assembly();manufacture()
    (CASE/'manual-layout-audit.json').write_text(json.dumps(AUDITS,indent=2))
    print('Created two 8-page manuals; paragraph/table overflow guards passed.')
