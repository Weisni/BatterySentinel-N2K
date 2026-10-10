"""Shared electrical symbols for the Orion Altium schematic and local SchLib.

Coordinates are relative to the component origin, in native schematic units
(one unit = 10 mil). Pin x/y is the BODY END, not the electrical hotspot.
Orientation 0/1/2/3 points right/up/left/down towards the hotspot hx/hy.
All electrical hotspots lie on the 10-unit schematic grid. Graphic polyline
vertices need not lie on that grid. No graphic primitive is an electrical wire.

symbol_for(component) returns:
  pins: number/name/type, x/y, hx/hy, orientation, length, show_name/show_number
  graphics: native SchDoc record dictionaries, relative to the component origin
  bbox: (left, bottom, right, top), including pins but excluding parameters
  designator_pos / value_pos: relative, horizontal text origins
  kind: semantic symbol type

Manufacturer-specific pin arrangements remain identical to the design model.
PESD2CAN24T-Q contains two back-to-back TVS branches with common cathode 3,
following Nexperia's graphic symbol, datasheet 9 February 2024, page 2.
"""

from __future__ import annotations

import math


COLOR = 128
PIN_VECTORS = ((1, 0), (0, 1), (-1, 0), (0, -1))


def poly(points, width=1):
    result = {"RECORD": 6, "LineWidth": width, "Color": COLOR,
              "LocationCount": len(points)}
    for i, (x, y) in enumerate(points, 1):
        result[f"X{i}"] = int(round(x))
        result[f"Y{i}"] = int(round(y))
    return result


def rectangle(left, bottom, right, top):
    return {"RECORD": 14, "Location.X": left, "Location.Y": bottom,
            "Corner.X": right, "Corner.Y": top, "LineWidth": 1,
            "Color": COLOR, "AreaColor": 16777215, "IsSolid": "F"}


def label(x, y, text):
    return {"RECORD": 4, "Location.X": x, "Location.Y": y,
            "Color": COLOR, "FontID": 1, "Text": text}


def circle(x, y, radius=3):
    return poly([(x + radius * math.cos(a * math.pi / 8),
                  y + radius * math.sin(a * math.pi / 8)) for a in range(17)])


def coil(x1=-20, x2=20, y=0, side=1, loops=4):
    """Four semicircular windings represented by native graphic polylines."""
    radius = (x2 - x1) / (2 * loops)
    points = []
    for i in range(loops):
        center = x1 + radius * (1 + 2 * i)
        points.extend((center - radius * math.cos(j * math.pi / 8),
                       y + side * radius * math.sin(j * math.pi / 8)) for j in range(9))
    return poly(points)


def pin(number, x, y, orientation, length=20, show_name=False, show_number=True, name=None):
    dx, dy = PIN_VECTORS[orientation]
    result = dict(number=str(number), x=x, y=y, orientation=orientation, length=length,
                  hx=x + dx * length, hy=y + dy * length,
                  show_name=show_name, show_number=show_number)
    if name is not None:
        result["name"] = name
    return result


def diode_graphics(*, cathode=(0, 10), anode=(0, -10), style="standard", scale=1):
    """Graphic diode body; triangle points from anode toward the cathode bar.

    The centre-to-centre span specifies a scale/rotation transform from the
    normal vertical 20-unit symbol. This helper intentionally emits no pins.
    """
    cx, cy = cathode
    ax, ay = anode
    vx, vy = (cx - ax) / 20, (cy - ay) / 20
    mx, my = (cx + ax) / 2, (cy + ay) / 2

    def convert(points):
        return [(mx + x * vy * scale + y * vx, my - x * vx * scale + y * vy) for x, y in points]

    graphics = [poly(convert([(-10, -10), (10, -10), (0, 10), (-10, -10)]))]
    if style in ("zener", "tvs"):
        graphics.append(poly(convert([(-10, 5), (-10, 10), (10, 10), (10, 15)])))
    elif style == "schottky":
        graphics.append(poly(convert([(-6, 4), (-10, 4), (-10, 10),
                                       (10, 10), (10, 16), (6, 16)])))
    else:
        graphics.append(poly(convert([(-10, 10), (10, 10)])))
    return graphics


def finish(component, kind, pins, graphics, bbox, designator_pos, value_pos):
    source = {str(p["number"]): p for p in component["pins"]}
    if len(source) != len(component["pins"]) or set(source) != {p["number"] for p in pins}:
        raise ValueError(f"Symbol pin mismatch for {component['ref']}: "
                         f"design={set(source)}, symbol={set(p['number'] for p in pins)}")
    for p in pins:
        p.setdefault("name", source[p["number"]]["name"])
        p["type"] = source[p["number"]].get("type", 4)
        if p["hx"] % 10 or p["hy"] % 10:
            raise ValueError(f"Off-grid electrical hotspot {component['ref']}.{p['number']}")
    return dict(kind=kind, pins=pins, graphics=graphics, bbox=bbox,
                designator_pos=designator_pos, value_pos=value_pos)


def symbol_for(component):
    """Return a fresh symbol tree suitable for both placed and library symbols."""
    if component.get('schematic_symbol'):
        import copy
        spec=copy.deepcopy(component['schematic_symbol'])
        pins=[pin(**p) for p in spec['pins']]
        return finish(component,spec['kind'],pins,spec['graphics'],tuple(spec['bbox']),
                      tuple(spec.get('designator_pos',[-50,80])),tuple(spec.get('value_pos',[-50,65])))
    ref = component["ref"]
    value = component["value"].upper()
    args = (component,)

    if ref.startswith("R"):
        # IEC resistor, horizontal signal flow.
        return finish(*args, "resistor_iec",
                      [pin(1, -20, 0, 2), pin(2, 20, 0, 0)],
                      [rectangle(-20, -8, 20, 8)], (-40, -8, 40, 8), (-20, 20), (-20, -25))

    if ref.startswith("C"):
        polarized = any(p["name"] == "+" for p in component["pins"])
        g = [poly([(-14, 5), (14, 5)]), poly([(0, 20), (0, 5)]),
             poly([(0, -20), (0, -8 if polarized else -5)])]
        if polarized:
            g += [poly([(-14, -4), (-10, -6), (-5, -7), (0, -8), (5, -7), (10, -6), (14, -4)]),
                  poly([(12, 14), (22, 14)]), poly([(17, 9), (17, 19)])]
        else:
            g += [poly([(-14, -5), (14, -5)])]
        return finish(*args, "capacitor_polarized" if polarized else "capacitor",
                      [pin(1, 0, 20, 1), pin(2, 0, -20, 3)], g,
                      (-14, -40, 22 if polarized else 14, 40), (30, 10), (30, -5))

    if ref == "F1":
        return finish(*args, "fuse",
                      [pin(1, -20, 0, 2), pin(2, 20, 0, 0)],
                      [rectangle(-20, -8, 20, 8), poly([(-20, 0), (20, 0)])],
                      (-40, -8, 40, 8), (-20, 20), (-20, -25))

    if ref == "L2":
        return finish(*args, "inductor",
                      [pin(1, -20, 0, 2), pin(2, 20, 0, 0)],
                      [coil()], (-40, 0, 40, 5), (-20, 20), (-20, -25))

    if ref == "L1":
        # Pins 1-4 and 2-3 are the coupled windings, no DC cross-connection.
        g = [coil(y=20), coil(y=-20, side=-1),
             poly([(-20, 5), (20, 5)]), poly([(-20, -5), (20, -5)]),
             circle(-17, 32, 2), circle(-17, -32, 2)]
        return finish(*args, "common_mode_choke",
                      [pin(1, -20, 20, 2), pin(4, 20, 20, 0),
                       pin(2, -20, -20, 2), pin(3, 20, -20, 0)],
                      g, (-40, -34, 40, 34), (-20, 45), (-20, -50))

    if ref in ("Z1", "D1"):
        style = "zener" if ref == "Z1" else "tvs"
        g = diode_graphics(style=style)
        g += [poly([(0, 20), (0, 10)]), poly([(0, -20), (0, -10)])]
        return finish(*args, style, [pin(1, 0, 20, 1), pin(2, 0, -20, 3)],
                      g, (-10, -40, 10, 40), (25, 10), (25, -5))

    if ref == "D2":
        g = diode_graphics(cathode=(10, 0), anode=(-10, 0), style="schottky")
        g += [poly([(-20, 0), (-10, 0)]), poly([(10, 0), (20, 0)])]
        return finish(*args, "schottky", [pin(2, -20, 0, 2), pin(1, 20, 0, 0)],
                      g, (-40, -10, 40, 10), (-20, 20), (-20, -25))

    if ref == "D3" or "PESD2CAN24" in value:
        # Exactly the Nexperia topology: each line has an anti-series diode
        # pair; the two right-hand cathodes share pin 3. Orient the two input
        # terminals upwards and the common cathode downwards for a bus shunt.
        g = []
        for x in (-20, 20):
            g += diode_graphics(cathode=(x, 20), anode=(x, 2), style="zener", scale=.75)
            g += diode_graphics(cathode=(x, -20), anode=(x, -2), style="zener", scale=.75)
            g += [poly([(x, 2), (x, -2)]), poly([(x, 30), (x, 20)]),
                  poly([(x, -20), (x, -30), (0, -30)])]
        g += [poly([(0, -30), (0, -40)])]
        return finish(*args, "dual_can_tvs",
                      [pin(1, -20, 30, 1), pin(2, 20, 30, 1), pin(3, 0, -40, 3)],
                      g, (-30, -60, 30, 50), (45, 15), (45, 0))

    if ref == "Q1" or "DMP6023" in value:
        # Horizontal P-channel enhancement MOSFET. The bulk arrow points out
        # of the channel (P type); the body diode conducts D -> S. Tab 4 is
        # explicitly exposed and is physically/electrically tied to drain 2.
        g = [poly([(-30, 0), (-15, 0), (-15, -10)]),
             poly([(30, 0), (15, 0), (15, -10)]),
             poly([(-15, -10), (-6, -10)]), poly([(-3, -10), (3, -10)]),
             poly([(6, -10), (15, -10)]), poly([(-18, -20), (18, -20)]),
             poly([(0, -40), (0, -20)]),
             poly([(0, -10), (0, 0), (15, 0)]),
             poly([(-4, -5), (0, 0), (4, -5)]),
             poly([(-15, 0), (-15, 20), (-6, 20)]),
             poly([(6, 20), (15, 20), (15, 0)]),
             poly([(-30, 20), (-15, 20)]), label(-45, 32, "TAB"),
             label(-28, -12, "D"), label(23, -12, "S"), label(8, -37, "G")]
        g += diode_graphics(cathode=(6, 20), anode=(-6, 20), scale=.65)
        return finish(*args, "pmos_with_body_diode",
                      [pin(2, -30, 0, 2, name="D"), pin(3, 30, 0, 0, name="S"),
                       pin(1, 0, -40, 3, name="G"), pin(4, -30, 20, 2, name="TAB=D")],
                      g, (-50, -60, 50, 45), (15, 40), (15, 25))

    if ref == "JP1":
        g = [poly([(-20, 0), (-13, 0)]), poly([(13, 0), (20, 0)]),
             circle(-10, 0), circle(10, 0),
             poly([(-10, 4), (-10, 10), (10, 10), (10, 4)])]
        return finish(*args, "removable_jumper", [pin(1, -20, 0, 2), pin(2, 20, 0, 0)],
                      g, (-40, -3, 40, 10), (-20, 25), (-20, -25))

    if ref.startswith("TP"):
        return finish(*args, "test_point", [pin(1, 0, 0, 3, show_number=False)],
                      [circle(0, 5, 5)], (-5, -20, 5, 10), (15, 5), (15, -10))

    if ref == "J1":
        ys = (40, 20, 0, -20, -40)
        g = [rectangle(-10, -55, 10, 55)]
        g += [circle(3, y, 3) for y in ys]
        g += [poly([(6, y), (10, y)]) for y in ys]
        return finish(*args, "connector_5_pin",
                      [pin(n, 10, y, 0, show_name=False) for n, y in enumerate(ys, 1)],
                      g, (-10, -55, 30, 55), (-10, 70), (-10, -75))

    if ref == "U1":
        g = [rectangle(-60, -60, 60, 60),
             poly([(-4, -60), (-4, 60)]), poly([(4, -60), (4, 60)])]
        ps = [pin(8, -60, 40, 2, show_name=True), pin(7, -60, 10, 2, show_name=True),
              pin(6, -60, -10, 2, show_name=True), pin(5, -60, -40, 2, show_name=True),
              pin(1, 60, 40, 0, show_name=True), pin(2, 60, 10, 0, show_name=True),
              pin(3, 60, -10, 0, show_name=True), pin(4, 60, -40, 0, show_name=True)]
        return finish(*args, "isolated_can_transceiver", ps, g,
                      (-80, -60, 80, 60), (-60, 80), (-60, 65))

    if ref == "U2":
        g = [rectangle(-60, -60, 60, 60), poly([(-4, -60), (-4, 60)]),
             poly([(4, -60), (4, 60)]), label(-42, -2, "DC"), label(22, -2, "DC")]
        ps = [pin(1, -60, 30, 2, show_name=True), pin(2, -60, -30, 2, show_name=True),
              pin(7, 60, 30, 0, show_name=True), pin(6, 60, -30, 0, show_name=True),
              pin(4, -30, -60, 3, show_name=True, name="CTRL"),
              pin(5, 30, -60, 3, show_name=True, name="NC")]
        return finish(*args, "isolated_dc_dc_converter", ps, g,
                      (-80, -80, 80, 60), (-60, 80), (-60, 65))

    if ref == "U3":
        ps = [pin(1, -50, 10, 2, show_name=True), pin(3, 50, 10, 0, show_name=True),
              pin(2, -20, -30, 3, show_name=True),
              pin(4, 20, -30, 3, show_name=True, name="TAB")]
        return finish(*args, "linear_regulator", ps, [rectangle(-50, -30, 50, 30)],
                      (-70, -50, 70, 30), (-50, 50), (-50, 35))

    if ref == "MCU1":
        numbers = {str(p["number"]) for p in component["pins"]}
        extra_numbers = [n for n in ("5", "4", "3", "2", "1", "0", "8", "9", "10", "20", "21")
                         if n in numbers]
        half_height = max(60, 10 * (len(extra_numbers) - 1) + 20)
        ps = [pin("6", -70, 20, 2, show_name=True, name="GPIO6 / TX"),
              pin("7", -70, -20, 2, show_name=True, name="GPIO7 / RX"),
              pin("3V3", -40, half_height, 1, show_name=True),
              pin("5V", 40, half_height, 1, show_name=True),
              pin("GND", 0, -half_height, 3, show_name=True)]
        ps += [pin(n, 70, 10 * (len(extra_numbers) - 1) - i * 20, 0,
                   show_name=True, name="GPIO" + n) for i, n in enumerate(extra_numbers)]
        return finish(*args, "esp32_c3_module", ps,
                      [rectangle(-70, -half_height, 70, half_height)],
                      (-90, -half_height - 20, 90 if extra_numbers else 70, half_height + 20),
                      (80, half_height + 20), (80, half_height + 5))

    raise ValueError(f"No appropriate schematic symbol defined for {ref}: {value}")
