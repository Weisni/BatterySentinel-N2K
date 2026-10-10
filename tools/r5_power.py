"""Create reviewed R5 power-part overrides without changing R4 source files."""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path
from altium_symbols import circle, poly, label

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'hardware/altium-r5'


def rect(x0, y0, x1, y1):
    return [[x0, y0], [x1, y0], [x1, y1], [x0, y1]]


def make_parts():
    source = json.loads((ROOT / 'hardware/altium-r4/orion-r4-design.json').read_text(encoding='utf-8'))
    by = {c['ref']: c for c in source['components']}
    power = json.loads((ROOT / 'hardware/altium-r4/power-components.json').read_text(encoding='utf-8'))
    refs = [c['ref'] for c in power['components'] if c['ref'] not in ('D2', 'D4')]
    refs += ['F1']
    parts = [copy.deepcopy(by[r]) for r in refs]
    for c in parts:
        c.pop('uid', None)
        c.pop('schematic', None)
        c['sheet'] = 'Orion-Bridge-R5-Power.SchDoc'
        c['source_schlib'] = 'Orion-Bridge-R5.SchLib'
        c['source_pcblib'] = 'Orion-Bridge-R5.PcbLib'
        if c['ref'] in ['U4', 'L3', 'C29', 'C30', 'C31', 'C32', 'C33']:
            for p in c['pins']:
                p['net'] = {'5V_SYS': '5V_ISO', '3V3_LOGIC': '5V_REG'}.get(p.get('net'), p.get('net'))
        if c['ref'] == 'U4':
            for key in ['value', 'manufacturer', 'mpn', 'lcsc', 'datasheet', 'assembly', 'stock_observation', 'procurement_status']:
                if key in by['U3']:
                    c[key] = copy.deepcopy(by['U3'][key])
            c['description'] = 'Isolated-side 5V buck / high-duty pass-through, feeding physical RUN/SERVICE disconnect'
            c['libref'] = 'R5_U4_AP63205WU_7'
            c['constraints'] = ['AP63205 fixed 5V: FB directly senses 5V_REG.', 'VIN and EN directly on 5V_ISO; no upstream OR diode.', 'C29/C30 at VIN/GND; C31 across BST/SW; L3 and C32/C33 compact.', 'Below regulation headroom, output follows input minus losses. This is not a buck-boost converter.']
            for key in ['MPN', 'Manufacturer Part Number']:
                c['parameters'][key] = c['mpn']
            c['parameters'].update({'Description': c['description'], 'Datasheet': c['datasheet'], 'Supplier Part Number 1': c['lcsc']})
        if c['ref'] == 'L3':
            c['selection_notes'] = 'AP63205 5V manufacturer reference uses 4.7uH and 2x22uF; selected Sunlord C57269 retained.'
        c['parameters']['Footprint Status'] = 'R5 uses reviewed R4 manufacturer land pattern; updated power connectivity'

    # Local input reservoir at module side of the service disconnect.
    c34 = copy.deepcopy(by['C29'])
    c34.update({'ref': 'C34', 'sheet': 'Orion-Bridge-R5-Power.SchDoc', 'description': '10uF local module5V reservoir after RUN/SERVICE switch'})
    for k in ['uid', 'schematic']:
        c34.pop(k, None)
    c34['pins'][0]['net'] = '5V_MODULE'
    c34['pins'][1]['net'] = 'GND_LOGIC'
    c34['source_schlib'] = 'Orion-Bridge-R5.SchLib'
    c34['source_pcblib'] = 'Orion-Bridge-R5.PcbLib'
    c34['parameters']['Description'] = c34['description']
    parts.append(c34)

    switch_url = 'https://static.chipdip.ru/lib/011/DOC043011829.pdf'
    pads = [
        {'number': str(n), 'x': x, 'y': -2.075, 'sx': 0.9, 'sy': 1.25, 'drill': 0, 'shape': 'RECTANGLE'}
        for n, x in [(1, -2.25), (2, -0.75), (3, 2.25)]
    ]
    for n, x, y in [(4, -3.8, 1.135), (5, -3.8, -1.135), (6, 3.8, 1.135), (7, 3.8, -1.135)]:
        pads.append({'number': str(n), 'x': x, 'y': y, 'sx': 0.8, 'sy': 0.93, 'drill': 0, 'shape': 'RECTANGLE'})
    switch = {
        'ref': 'SW3', 'value': 'RUN / SERVICE', 'footprint': 'GSWITCH_MK12C02_G020',
        'group': 'power', 'manufacturer': 'G-Switch', 'mpn': 'MK-12C02-G020', 'lcsc': 'C963206',
        'datasheet': switch_url, 'description': 'Side-actuated SPDT service supply disconnect, 1A at6V, original SuperMini USB service',
        'sheet': 'Orion-Bridge-R5-Power.SchDoc', 'source_schlib': 'Orion-Bridge-R5.SchLib', 'source_pcblib': 'Orion-Bridge-R5.PcbLib',
        'libref': 'SW3_RUN_SERVICE',
        'pins': [
            {'number': '1', 'name': 'RUN_IN', 'net': '5V_REG', 'type': 4},
            {'number': '2', 'name': 'COMMON', 'net': '5V_MODULE', 'type': 4},
            {'number': '3', 'name': 'SERVICE_NC', 'net': None, 'type': 4},
        ] + [{'number': str(n), 'name': 'SHIELD' + str(n-3), 'net': 'GND_LOGIC', 'type': 4} for n in range(4, 8)],
        'pcb_footprint': {
            'body': [6.6, 2.7], 'height': 1.4, 'pads': pads,
            'holes': [{'x': x, 'y': 0, 'drill': 1.0, 'plated': False, 'copper_clearance_mm': 0.25} for x in [-1.5, 1.5]],
            'provisional': False,
            'source_note': 'G-Switch MK-12C02-GXXX RevX1 2019-05-29 manufacturer drawing:3 signal lands0.9x1.25 at(-2.25,-2.075),(-0.75,-2.075),(2.25,-2.075);4 shell lands0.8x0.93 atx+/-3.8,y+/-1.135. Hole centres+/-1.5. NPTH1.0mm is explicit engineering clearance for0.70+/-0.05mm locating pegs (drawing omits hole diameter). Local actuator +Y; rot270 gives board+X. Supplier listing dimensions mix overall depth with height; actual Z1.4mm.',
            'note': 'All shell tabs tied only to GND_LOGIC. No paste in NPTH. Keep travel envelope clear. Pin numbers1/2/3 assigned left/common/right as manufacturer circuit A/B; mounting pads4-7 are local library assignments.'
        },
        'ratings': {'current_A_at6V': 1, 'voltage_V': 6, 'contact_resistance_max_ohm': 0.1, 'ambient_C': [-20, 70], 'reflow_max_C': 250},
        'assembly': {'populate': True, 'lcsc': 'C963206', 'lcsc_confirmed': True, 'source_url': 'https://jlcpcb.com/partdetail/gswitch-MK_12C02G020/C963206', 'rotation_offset_deg': 0, 'centroid_offset_mm': [0,0], 'note': 'Public current JLC metadata InStock, SMT, Economic+Standard, no fixture. Verify orientation against manufacturer pin side and preview; inventory is not reserved.'},
        'stock_observation': {'date': '2026-09-23', 'in_stock': True, 'method': 'Fresh JLC public JSON-LD Product and assembly metadata; exact MPN/brand/C-code matched'},
        'parameters': {'Manufacturer': 'G-Switch', 'MPN': 'MK-12C02-G020', 'Manufacturer Part Number': 'MK-12C02-G020', 'Description': 'RUN/SERVICE physical5V disconnect; SPDT1A6V side actuator', 'Datasheet': switch_url, 'Supplier 1': 'LCSC', 'Supplier Part Number 1': 'C963206', 'Footprint Status': 'Manufacturer solder lands; engineering1.0mmNPTH for0.7mm locating pegs'},
        'switch_positions': {'RUN': [['1','2']], 'SERVICE': [['2','3']]},
        'internal_connections': [['4','5','6','7']],
        'schematic_symbol': {
            'kind': 'SPDT_RUN_SERVICE',
            'pins': [
                {'number':'2','x':-40,'y':0,'orientation':2,'show_name':False},
                {'number':'1','x':40,'y':30,'orientation':0,'show_name':False},
                {'number':'3','x':40,'y':-30,'orientation':0,'show_name':False},
            ] + [{'number':str(n),'x':x,'y':-70,'orientation':3,'show_name':False} for n,x in [(4,-30),(5,-10),(6,10),(7,30)]],
            'graphics':[poly([(-40,0),(-10,0),(17,27)]),circle(-10,0,2),
                circle(20,30,2),circle(20,-30,2),poly([(22,30),(40,30)]),poly([(22,-30),(40,-30)]),
                label(-10,40,'RUN'),label(-10,-45,'SERVICE'),label(-32,-65,'SHELL')],
            'bbox':[-60,-90,60,50], 'designator_pos':[-40,80], 'value_pos':[-40,60],
        },
        'actuator': {'local_direction': '+Y', 'length_from_body_mm': 2.0, 'travel_mm': 1.5, 'width_mm': 1.3, 'center_x_positions_mm': [-0.75,0.75], 'z_center_mm': 0.7, 'note': 'A position electrically joins left terminal to common; B joins right terminal. Verify physical A/B travel sense once on purchased switch before final enclosure arrow labeling; RUN/SERVICE electrical pin assignment is fixed.'},
        'mechanical_interfaces': {'service_switch': {'mouth_center_local_mm': [0,3.35,0.7], 'outward_local_xy': [0,1], 'opening_width_mm': 6.5, 'opening_height_mm': 3.5, 'assumed': False, 'note': 'Datasheet swept actuator; no unverified left/right RUN arrows. Opening dimensions include case access allowance.'}},
        'bodies_3d': [
            {'name': 'switch black base', 'outline': rect(-3.3,-1.35,3.3,1.35), 'z0': 0.05,'z1': 1.25,'rgb':[32,35,40]},
            {'name': 'switch metal cover', 'outline': rect(-3.25,-1.30,3.25,1.30), 'z0': 1.25,'z1': 1.4,'rgb':[180,190,202]},
            {'name': 'RUN actuator A', 'outline': rect(-1.4,1.30,-0.1,3.35), 'z0': 0.15,'z1': 1.25,'rgb':[35,38,43]},
        ] + [{'name': 'switch solder terminal '+p['number'], 'outline':rect(p['x']-p['sx']/2,p['y']-p['sy']/2,p['x']+p['sx']/2,p['y']+p['sy']/2), 'z0':0.02,'z1':0.15,'rgb':[185,192,200]} for p in pads],
        'pcb': {'x':39.0,'y':33.5,'rotation':0,'status':'Root top-edge placement candidate; actuator toward +Y case wall'},
        'allow_body_overhang': True,
        'constraints': ['Physical OPEN supply in SERVICE; never rely only on disabling U4.', 'No USB connected in RUN. Switch SERVICE first, then connect USB.', 'GND_LOGIC remains connected; never switch ground or tie to bus return.', 'Mounting pegs need2xNPTH1.0mm atlocalx+/-1.5.', 'Top-edge placement leaves actuator protruding above board +Y; case opening must accommodate full 1.5mm travel.'],
    }
    parts.append(switch)
    # Initial compact power-cell positions are suggestions, not a completed layout.
    suggestions = {'U2': (22.035,4.2,0),'U4':(40.25,6.35,0),'L3':(36.25,7.45,0),
        'C27':(26.7,10.125,0),'C28':(29,9.8,0),'R20':(23.6,11.8,0),'R21':(23.6,14.4,0),
        'C29':(43.8,4.825,0),'C30':(44.025,6.25,0),'C31':(39.7,8.6,0),
        'C32':(34.2,3.9,0),'C33':(34.2,1.7,0),'C34':(46.8,10.0,0)}
    for c in parts:
        if c['ref'] in suggestions:
            x,y,rot = suggestions[c['ref']]
            c['pcb'] = {'x':x,'y':y,'rotation':rot,'status':'R5 power-block placement suggestion; root completes clearance/layout'}
    removed = ['D2','D4','J2','D6','SW1','SW2','R5','R6','R7','R8','R9','R10','R11','R12','C10']
    return {
        'revision':'R5 SuperMini regulated5V and RUN/SERVICE power implementation',
        'components':parts,
        'remove_r4_refs':removed,
        'replace_r4_refs':['U4'],
        'retain_r4_refs':['J1','U1','D3','L1','C4','C5','R2','R3','R4','TP1','C11','C12'],
        'integration_updates':{'MCU1.5V':'5V_MODULE','MCU1.3V3':'3V3_LOGIC (module output)','MCU1.GND':'GND_LOGIC','U1.VCC1':'3V3_LOGIC','C5':'retain100nF on3V3_LOGIC/GND_LOGIC','C11/C12':'retain local10uF/100nF on module3V3 output; no second3V3 regulator'},
        'interfaces':{'input':'NET_S -> F1 -> FUSED_IN -> D5 -> BUS_PROT','bus':'U3/AP63205 -> 5V_BUS -> U1 VCC2 and U2 primary','isolated':'U2 -> 5V_ISO with permanentR20/R21 and C27/C28','regulator':'5V_ISO -> U4/AP63205 -> 5V_REG','run':'5V_REG -> SW3 pin1 -> pin2 -> 5V_MODULE -> original SuperMini5V','service':'SW3 pin2 selects unconnected pin3; original module USB supplies module and its3V3 logic output','logic':'original module3V3 OUT -> 3V3_LOGIC -> ISO1042 VCC1'},
        'domain_gap_mm':3.2,
        'integration_notes':['SW3 is side-actuated MK-12C02-G020/C963206, not earlier top-actuated C963205 candidate.','No new MCU, carrier USB port or carrier ESP boot/reset circuit.','No5V_SYS or carrierUSB_VBUS nets remain after removing old OR diodes.','Route main5V rails at least0.5mm where possible;0.4mm minimum last-mile. FB is a quiet sense trace from C32/C33.','Preload is before U4 and SW3, active during RUN and SERVICE.','Conservative firmware reserve remainsLEN12; actual runtime load and prototype tests described in power-review.md.'],
    }


def make_review(d):
    """Record source review and explicit calculation assumptions, not hardware qualification."""
    by = {c['ref']: c for c in d['components']}
    expected = {
        'U2': {'1':'5V_BUS','2':'GND_BUS','4':'GND_LOGIC','6':'5V_ISO'},
        'U4': {'1':'5V_REG','2':'5V_ISO','3':'5V_ISO','4':'GND_LOGIC','5':'SW_LOGIC','6':'BST_LOGIC'},
        'L3': {'1':'SW_LOGIC','2':'5V_REG'},
        'C29': {'1':'5V_ISO','2':'GND_LOGIC'},'C30': {'1':'5V_ISO','2':'GND_LOGIC'},
        'C31': {'1':'BST_LOGIC','2':'SW_LOGIC'},
        'C32': {'1':'5V_REG','2':'GND_LOGIC'},'C33': {'1':'5V_REG','2':'GND_LOGIC'},
        'C34': {'1':'5V_MODULE','2':'GND_LOGIC'},
        'R20': {'1':'5V_ISO','2':'GND_LOGIC'},'R21': {'1':'5V_ISO','2':'GND_LOGIC'},
        'SW3': {'1':'5V_REG','2':'5V_MODULE','3':None,'4':'GND_LOGIC','5':'GND_LOGIC','6':'GND_LOGIC','7':'GND_LOGIC'},
    }
    checks=[]
    def check(name,ok):
        checks.append({'name':name,'passed':bool(ok)})
    for ref,nets in expected.items():
        check(ref+' manufacturer-reviewed circuit pin map', {p['number']:p.get('net') for p in by[ref]['pins']} == nets)
    for c in d['components']:
        check(c['ref']+' symbol/pad identity',sorted(p['number'] for p in c['pins'])==sorted(p['number'] for p in c['pcb_footprint']['pads']))
        check(c['ref']+' exact supplier match',c.get('lcsc')==c['assembly'].get('lcsc') and bool(c.get('mpn')))
    check('no old OR/3V3-regulator source', 'D2' not in by and 'D4' not in by and by['U4']['mpn']=='AP63205WU-7')
    check('no carrierUSB or5V_SYS net',not any(p.get('net') in ('USB_VBUS','5V_SYS') for c in d['components'] for p in c['pins']))
    check('SW3 two1mm NPTH',[(h['x'],h['y'],h['drill'],h['plated']) for h in by['SW3']['pcb_footprint']['holes']]==[(-1.5,0,1.0,False),(1.5,0,1.0,False)])
    check('SW3 schematic electrical grid',all(p['x']%10==0 and p['y']%10==0 for p in by['SW3']['schematic_symbol']['pins']))
    raw=4.625; load=.4; efficiency=.85; preload_r_min=75*.99
    preload_i=raw/preload_r_min
    total_i=5*load/efficiency/raw+preload_i
    output_w=raw*total_i
    bus_i=(output_w/.82+5*.0734)/.8/(9-.7)
    check('400mA calculation below U2 current with declared assumptions',total_i<.6)
    files=['power-components.json','references/GSWITCH-MK-12C02-GXXX-X1.pdf',
           'references/Diodes-AP6320x-DS41326-Rev3-2.pdf','references/EVISUN-B-S-3WR2-V1.0.pdf']
    sources=[
        {'id':'switch','url':'https://static.chipdip.ru/lib/011/DOC043011829.pdf','type':'manufacturer drawing hosted by distributor','revision':'MK-12C02-GXXX X1 2019-05-29','inspection':'Visually reviewed all dimensions, circuitA/B and ratings'},
        {'id':'switch_jlc','url':'https://jlcpcb.com/partdetail/gswitch-MK_12C02G020/C963206','type':'assembly supplier current observation','date':'2026-09-23','mpn':'MK-12C02-G020','lcsc':'C963206','in_stock':True,'assembly':'SMT Economic/Standard; no fixture','reservation':False},
        {'id':'buck','url':'https://www.diodes.com/datasheet/download/AP63200-AP63201-AP63203-AP63205.pdf','type':'manufacturer datasheet','revision':'DS41326 Rev3-2 November2024'},
        {'id':'isolation','url':'https://resources.ampheo.com/static/datasheets/evisun/20240927/b2405s-3wr2.pdf','type':'manufacturer datasheet hosted by distributor','revision':'EVISUN B_S-3WR2 V1.0'},
        {'id':'mcu_current','url':'https://www.espressif.com/sites/default/files/documentation/esp32-c3_datasheet_en.pdf','type':'manufacturer datasheet','revision':'v2.4','page':56},
        {'id':'mcu_supply_guidance','url':'https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32c3/schematic-checklist.html','type':'manufacturer design guidance'},
        {'id':'module','url':'https://www.amazon.de/4PCS-Supermini-ESP32-C3-Entwicklungsboard/dp/B0FN4F6244','type':'user-selected exact assembly, sellerC3 schematic cross-check','local_images':['references/amazon-B0FN4F6244-schematic.jpg','references/amazon-B0FN4F6244-core-schematic.jpg']},
    ]
    return {
        'revision':'R5 power source review v1','date':'2026-09-23','cad_implementation_selected':True,
        'physical_sample_tested':False,'electrical_prototype_qualified':False,
        'scope':'Circuit/part-source and integration-interface review; not nativeDRC or production qualification',
        'module_identity':'Amazon B0FN4F6244 Meshnology4xC3; unchanged originalSuperMini architecture',
        'sources':sources,'reviewed_pin_maps':expected,
        'part_identities':{r:{'mpn':c['mpn'],'lcsc':c['lcsc']} for r,c in by.items()},
        'calculation':{'module_current_A':load,'module_voltage_for_power_budget_V':5,'u4_efficiency_assumed':efficiency,
            'raw_voltage_V':raw,'preload_parallel_ohm_nom':75,'preload_ohm_min':preload_r_min,
            'preload_current_A':preload_i,'isolator_total_output_current_A':total_i,'isolator_output_power_W':output_w,
            'isolator_current_limit_A':.6,'minimum_u4_efficiency_required_for_case':5*load/(raw*(.6-preload_i)),
            'u2_efficiency_assumed':.82,'u3_efficiency_assumed':.8,'can_bus_current_A':.0734,
            'diode_drop_assumed_V':.7,'bus_voltage_V':9,'bus_current_before_small_fuse_copper_losses_A':bus_i,
            'published_esp_rf_example_A':.335,'rf_condition':'WiFi802.11b1Mbps21dBm,3.3V25C; not universalmax and not BLElimit',
            'LEN_reservation':12,'guaranteed_5V_500mA_continuous':False},
        'dropout_estimate':{'raw_V':4.625,'I_A':.4,'high_side_ohm_assumed':.25,'inductor_DCR_ohm':.078,
            'copper_ohm_assumed':.05,'switch_max_ohm':.1,'module_input_estimate_V':4.625-.4*(.25+.078+.05+.1),
            'guaranteed_bound':False,'reason':'High-side RDS and complete moduleLDO dropout/thermal conditions not bounded at all operating conditions'},
        'service':{'RUN':['1','2'],'SERVICE':['2','3'],'unused_pin':'3','ground_switching':False,
            'USB_in_RUN_permitted':False,'sequence':'SERVICE beforeUSB; disconnectUSB beforeRUN',
            'mechanical_travel_to_A_B_explicitly_documented':False,'action':'Confirm actualswitch continuity before any directionarrow label'},
        'layout':{'functional_isolation_copper_mm':3.2,'power_path_min_width_mm':.4,'power_path_preferred_width_mm':.5,
            'quiet_feedback_is_not_main_load_path':True,'preload_before_switch':True},
        'validation':{'checks':checks,'passed':all(c['passed'] for c in checks),'check_count':len(checks),
            'meaning':'Source-level connectivity/identity/calculation checks only'},
        'qualification_pending':['9/12/16V coldstart/restart/loadrelease waveforms','400mA loadstep and500mA transient margin measurements',
            'BLE+WiFiportal operation at configuredRF settings','ClosedcaseLDO/DC-DC/preload thermal measurements',
            'SERVICE USB-only andUSB+bus reverse-feed/inrush checks','Purchasedswitch A/B travel continuity'],
        'sha256':{f:hashlib.sha256((OUT/f).read_bytes()).hexdigest() for f in files if (OUT/f).exists()},
    }


if __name__ == '__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    d=make_parts()
    (OUT/'power-components.json').write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    review=make_review(d)
    (OUT/'power-review.json').write_text(json.dumps(review,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(f"R5 power overrides: {len(d['components'])} components; {len(d['remove_r4_refs'])} old refs removed")
    print(f"Source review checks: {review['validation']['check_count']}; passed={review['validation']['passed']}")
    for c in review['validation']['checks']:
        if not c['passed']:print('FAIL '+c['name'])
