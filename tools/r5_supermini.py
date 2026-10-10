"""Selected Amazon B0FN4F6244 C3 SuperMini: direct-solder carrier interface.

The seller identifies the module, its planar size and C3 circuit; the exact
castellation/USB stack is not a controlled manufacturer drawing. The dimensions
below therefore separate source facts from conservative carrier design choices.
No pin headers, open carrier holes, replacement ESP module or invented LCSC ID.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'hardware/altium-r5'
PRODUCT_URL = 'https://www.amazon.de/4PCS-Supermini-ESP32-C3-Entwicklungsboard/dp/B0FN4F6244'
NOLOGO_URL = 'https://www.nologo.tech/product/esp32/esp32c3/esp32c3supermini/esp32C3SuperMini.html'
FOOTPRINT = 'SUPERC3_B0FN4F6244_CAST16_SMD'
LEFT = ('5', '6', '7', '8', '9', '10', '20', '21')
RIGHT = ('5V', 'GND', '3V3', '4', '3', '2', '1', '0')
BOARD_W, BOARD_D = 18.0, 22.52
SEATING, PCB_THICKNESS = .10, 1.00
SILVER = [181, 188, 194]
GOLD = [207, 166, 68]
DARK = [33, 36, 40]


def box(name, x, y, width, depth, z0, z1, rgb, angle=0):
    a = math.radians(angle)
    points = [[x+px*math.cos(a)-py*math.sin(a), y+px*math.sin(a)+py*math.cos(a)]
              for px, py in [(-width/2, -depth/2), (width/2, -depth/2),
                             (width/2, depth/2), (-width/2, depth/2)]]
    return dict(name=name, outline=points, z0=z0, z1=z1, rgb=rgb)


def disk(name, x, y, radius, z0, z1, rgb):
    return dict(name=name,
                outline=[[x+radius*math.cos(i*math.pi/16), y+radius*math.sin(i*math.pi/16)] for i in range(32)],
                z0=z0, z1=z1, rgb=rgb)


def footprint():
    pads = []
    for side, order in [(-1, LEFT), (1, RIGHT)]:
        for i, number in enumerate(order):
            pads.append(dict(number=number, x=side*8.6, y=round(9.7006-2.54*i, 4),
                             sx=2.8, sy=1.8, drill=0, shape='RECTANGLE', paste=False))
    return dict(body=[BOARD_W, BOARD_D], height=4.4, pads=pads, holes=[], provisional=False,
                qualification='Reviewed engineering carrier land pattern; physical clone fit not production-qualified',
                note='Selected ASIN B0FN4F6244. 16 SMD lands only, 2.8x1.8 at X +/-8.6; 2.54 pitch from Nologo reference. '
                     'Outer castellation dimensions inferred from selected product photo, not a manufacturer land drawing. '
                     'Manual perimeter soldering; no stencil paste, no carrier PTH, no pin headers. '
                     'USB tails require the separate carrier cutout; see mechanical_interfaces.')


def mechanical_interfaces():
    return dict(
        coordinate_system='Module body centre; top view; USB +Y, ceramic antenna -Y; Z=carrier top',
        seating_gap_mm=SEATING,
        module_pcb_thickness_mm=PCB_THICKNESS,
        module_pcb_thickness_tolerance_mm=.2,
        usb=dict(mouth_center_local_mm=[0, 12.65, 2.75], outward_local_xy=[0, 1],
                 opening_width_mm=12, opening_height_mm=7,
                 position_tolerance_mm=[.5, .65, .4], assumed=True,
                 shell_bounds_local_mm=[-4.6, 4.65, 1.1, 4.6, 12.65, 4.4],
                 note='Illustrative shell envelope from C3 product/reference images. The seller publishes no exact USB Z/overhang drawing. '
                      'Opening includes plug-overmould clearance; never treat envelope as a connector manufacturer STEP.'),
        buttons=[dict(name='BOOT', center_local_mm=[-2.75, 2.3, 2.75]),
                 dict(name='RESET', center_local_mm=[2.75, 2.3, 2.75])],
        carrier_cutouts=[
            dict(name='MCU_USB_TAIL_CLEARANCE', bounds_local_mm=[-5.3, 4.9, 5.3, 13.4],
                 corner_radius_mm=.5, required=True, copper_clearance_mm=.3,
                 note='Open to carrier edge where possible; clearance for unknown USB shell tails/solder. '
                      'No carrier material, copper, or component in this area.'),
            dict(name='MCU_ANTENNA_WINDOW', bounds_local_mm=[-5, -11.26, 5, -7.5],
                 corner_radius_mm=.5, required=True, copper_clearance_mm=.3,
                 note='Through-carrier air window below ceramic antenna. In an edge-overhang layout the outside-board area already supplies this clearance.')],
        rf_keepout=dict(bounds_local_mm=[-6, -13.76, 6, -5.5], copper_layers='all',
                        components=True, metal=True, assumed=True,
                        note='Conservative local antenna reservation; no published numeric RF keepout for the exact clone. '
                             'Not a measured antenna tuning or radiated-performance qualification.'),
        underside_keepout=dict(bounds_local_mm=[-9, -11.26, 9, 11.26],
                               carrier_components=False, exposed_copper=False,
                               note='Carrier tracks may pass beneath the non-RF module only under intact solder mask; no exposed testpoints, vias, or pads except intended perimeter lands.'),
    )


def models():
    """Editable local extrusions, visually recognisable but not certified STEP."""
    b = [box('C3 SuperMini black PCB; direct solder, no headers', 0, 0, 18, 22.52, .1, 1.1, [27, 32, 32]),
         box('ESP32-C3 QFN32 package', .65, -3.45, 5, 5, 1.1, 2.05, DARK, 45),
         box('ceramic antenna substrate envelope', 0, -9.95, 7, 2.3, 1.1, 2.35, [213, 187, 134]),
         box('ceramic antenna red top', 0, -9.95, 6.05, 2.28, 2.35, 2.40, [177, 58, 65]),
         box('40 MHz crystal', -4.5, -7.25, 3.2, 2.5, 1.1, 1.9, SILVER),
         box('ME6211 regulator envelope', -5.45, -.5, 2.9, 1.6, 1.1, 2.2, DARK),
         box('USB-C shell bottom', 0, 8.65, 9.2, 8, 1.1, 1.32, SILVER),
         box('USB-C shell top', 0, 8.65, 9.2, 8, 4.18, 4.4, SILVER),
         box('USB-C shell left wall', -4.5, 8.65, .2, 8, 1.32, 4.18, SILVER),
         box('USB-C shell right wall', 4.5, 8.65, .2, 8, 1.32, 4.18, SILVER),
         box('USB-C rear insulator', 0, 5.05, 8.8, .8, 1.32, 4.18, DARK),
         box('USB-C tongue', 0, 9.45, 6.7, 5.8, 2.59, 2.91, DARK)]
    for i in range(12):
        b.append(box('USB visible contact '+str(i+1), -2.75+.5*i, 10.05, .22, 3.8, 2.91, 2.93, GOLD))
    for x in (-4.45, 4.45):
        for y in (5.8, 10.15):
            b.append(box('USB shell tail clearance envelope', x, y, .45, 1.0, -.65, 1.4, SILVER))
    for name, x in [('BOOT', -2.75), ('RESET', 2.75)]:
        b.extend([box(name+' switch base', x, 2.3, 4.3, 3.5, 1.1, 1.65, DARK),
                  box(name+' switch top', x, 2.3, 4.1, 3.3, 1.65, 2.15, SILVER),
                  disk(name+' actuator', x, 2.3, .85, 2.15, 2.75, DARK)])
    for p in footprint()['pads']:
        sign = 1 if p['x'] > 0 else -1
        b.extend([box('gold edge contact '+p['number'], sign*8.88, p['y'], .24, 1.55, .08, 1.12, GOLD),
                  box('top contact land '+p['number'], sign*8.15, p['y'], 1.7, 1.55, 1.1, 1.12, GOLD)])
    return b


def component(ref='MCU1', nets=None):
    nets = {'5V': '5V_MODULE', 'GND': 'GND_LOGIC', '3V3': '3V3_LOGIC',
            '6': 'GPIO6', '7': 'GPIO7'} if nets is None else nets
    names = {n: 'GPIO'+n if n.isdigit() else n for n in LEFT+RIGHT}
    c = dict(ref=ref, value='ESP32-C3 SuperMini', manufacturer='Meshnology (seller brand; OEM undisclosed)',
             mpn='ESP32-C3 SuperMini / ASIN B0FN4F6244',
             manufacturer_part_number_status='No controlled manufacturer ordering code disclosed; ASIN is product identity only',
             description='User-selected C3 SuperMini; original onboard USB/BOOT/RESET; direct castellated solder mounting',
             datasheet=PRODUCT_URL, source_url=PRODUCT_URL, footprint=FOOTPRINT,
             pins=[dict(number=n, name=names[n], net=nets.get(n), type=7 if n in ('5V', 'GND', '3V3') else 1) for n in LEFT+RIGHT],
             pcb_footprint=footprint(), bodies_3d=models(), mechanical_interfaces=mechanical_interfaces(),
             model_3d_status='Locally generated dimensional/visual engineering envelope; PCB thickness, USB shell and underside tails assumed',
             allow_body_overhang=True,
             assembly=dict(populate=False, lcsc='', lcsc_confirmed=False, source_url=PRODUCT_URL,
                           rotation_offset_deg=0, centroid_offset_mm=[0, 0],
                           stage='post-PCBA manual castellated module soldering',
                           note='User-supplied exact Amazon C3 module fitted after carrier PCBA. No verified JLC stock code; not included in automated pick-and-place. '
                                'Remove supplied header pins and excess solder completely; inspect flat underside before fitting. USB requires SERVICE power disconnection.'))
    # A pin-complete native symbol in physical row order. Pin numbers are the
    # actual module silkscreen designators, so SchLib/PcbLib mapping is exact.
    from altium_symbols import rectangle
    ps = []
    for side, order in [(-1, LEFT), (1, RIGHT)]:
        ps += [dict(number=n, x=side*90, y=140-40*i, orientation=2 if side<0 else 0,
                    show_name=True, show_number=True) for i, n in enumerate(order)]
    c['schematic_symbol'] = dict(kind='functional_module', pins=ps,
                                graphics=[rectangle(-90, -165, 90, 165)], bbox=[-110, -165, 110, 165],
                                designator_pos=[-90, 200], value_pos=[-90, 180])
    c['schematic_label_offset'] = [-90, 205]
    return c


make_component = component


def selection():
    refs = OUT / 'references'
    sources = [
        ('selected_product_main', 'amazon-B0FN4F6244-main.jpg',
         'https://m.media-amazon.com/images/I/714mCjB4fHL._AC_SL1500_.jpg',
         'Exact selected listing main photo: C3 package, castellations, USB and header pins visible.'),
        ('selected_product_power_schematic', 'amazon-B0FN4F6244-schematic.jpg',
         'https://m.media-amazon.com/images/S/aplus-media-library-service-media/1523fc34-7d92-4e55-b555-d9e10fd045a8.__CR0,0,970,600_PT0_SX970_V1___.jpg',
         'C3 A+ power/USB/header schematic; VBUS equals header 5V before BAT60J.'),
        ('selected_product_core_schematic', 'amazon-B0FN4F6244-core-schematic.jpg',
         'https://m.media-amazon.com/images/S/aplus-media-library-service-media/a8108aab-b24a-4fa6-860b-2985be775f51.__CR0,0,970,600_PT0_SX970_V1___.jpg',
         'C3 A+ core schematic, not a dimension drawing.'),
        ('rejected_mixed_variant_image', 'amazon-B0FN4F6244-rejected-S3-pinout.jpg',
         'https://m.media-amazon.com/images/S/aplus-media-library-service-media/aa60e534-efe9-467b-8858-278aed2ac770.__CR0,0,970,600_PT0_SX970_V1___.jpg',
         'Rejected for C3 design: shows S3 and GPIO48; listing A+ assets mix variants.'),
        ('reference_dimension_drawing', 'nologo-reference-dimensions.png',
         'https://raw.githubusercontent.com/NologoTech/ESP32C3-Supermini/main/Hardware/ESP32-C3%E5%B0%BA%E5%AF%B8%E5%9B%BE.png',
         'Original Nologo reference only. 18x22.50, inner row spacing15.24, 2.54 pitch; not proof of exact Meshnology clone tolerances.'),
        ('reference_bottom_pinout', 'nologo-reference-pinout.png',
         'https://www.nologo.tech/assets/img/esp32/esp32c3supermini/esp32c3foot1.png',
         'Nologo reference bottom-view picture. Mirrored relative to our top-view pin map.')]
    return dict(revision='R5 exact user-selected C3 module library v1', date='2026-09-23',
                identity=dict(asin='B0FN4F6244', selected_variant='4 x C3', seller_brand='Meshnology',
                              product_url=PRODUCT_URL, replacement_module=False, user_selection_confirmed=True),
                source_facts=dict(board_xy_mm=[18,22.52], processor='ESP32C3FN4', flash_mb=4,
                                  single_sided_components=True, blue_led_gpio=8,
                                  input_pin='5V', listing_external_input_range_v=[3.3,6],
                                  simultaneous_usb_and_external_power_permitted=False),
                pin_pitch_source='Native Nologo outline/header PcbDoc and dimension drawing, cross-checked against selected C3 photo and C3 schematic',
                engineering_choices=dict(carrier_pad_centres_x_mm=[-8.6,8.6], carrier_pad_size_mm=[2.8,1.8],
                                         outer_toe_nominal_mm=1, adjacent_pad_gap_mm=.74, carrier_pth_count=0,
                                         module_stencil_paste=False, assembly='Manual perimeter solder after carrier PCBA',
                                         placement_tolerance_assumed_mm=.2, clone_outline_tolerance_assumed_mm=.2),
                qualification=dict(library_design_complete=True, physical_sample_measured=False,
                                   production_fit_qualified=False, manufacturer_castellation_land_pattern_available=False,
                                   exact_usb_drawing_available=False, rf_performance_qualified=False,
                                   note='Identity is settled by user link. CAD proceeds with visible conservative engineering assumptions; do not relabel as measured supplier geometry.'),
                mechanical_interfaces=mechanical_interfaces(),
                sources=[dict(kind=kind, path=str((refs/fn).relative_to(ROOT)).replace('\\','/'), url=url,
                              sha256=hashlib.sha256((refs/fn).read_bytes()).hexdigest() if (refs/fn).exists() else None,
                              note=note) for kind,fn,url,note in sources],
                component=component())


def validate(c):
    pads=c['pcb_footprint']['pads']; pins=c['pins']; errors=[]
    if {p['number'] for p in pads} != set(LEFT+RIGHT): errors.append('Incorrect 16-pad identity')
    if {p['number'] for p in pads} != {p['number'] for p in pins}: errors.append('Symbol/footprint identity mismatch')
    if any(p.get('drill',0) or p.get('paste',True) for p in pads): errors.append('Carrier module must have no drill/stencil paste')
    for x in (-8.6,8.6):
        ys=sorted([p['y'] for p in pads if p['x']==x])
        if len(ys)!=8 or any(abs(b-a-2.54)>1e-8 for a,b in zip(ys,ys[1:])): errors.append('Wrong pad pitch')
    if any('header ' in b['name'].lower() for b in c['bodies_3d']): errors.append('Header geometry present')
    if any(b['z1']<=b['z0'] for b in c['bodies_3d']): errors.append('Invalid 3D body height')
    if errors: raise ValueError('; '.join(errors))
    return dict(passed=True, pad_count=len(pads), schematic_pin_count=len(pins), carrier_drills=0,
                paste_apertures=0, bodies_3d=len(c['bodies_3d']), qualification='Geometry/pin consistency only; no physical sample measurement')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=OUT/'module-selection.json')
    args=parser.parse_args()
    data=selection(); data['consistency_validation']=validate(data['component'])
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(json.dumps(dict(output=str(args.output),**data['consistency_validation']),ensure_ascii=False))
