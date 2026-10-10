"""Write the Orion carrier as an editable native Altium PCB ASCII 5.0 document.

This is a placement starter, deliberately without copper routing or fabrication
outputs. The encoding and record fields follow Altium's native ASCII format as
observed in the original Novena board (not a KiCad/Eagle import wrapper):
https://github.com/novena-next/docs/blob/master/design_source/lidsense_board/ASCII-laptop-lidsense1.PcbDoc

Component coordinates and rotations are millimetres, viewed from above, with a
bottom-left origin. Source component UIDs must equal the schematic component
UIDs. Footprints are self-contained primitives in the PcbDoc; no external PCB
library is required to display or edit the placed instances.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import math
from pathlib import Path


def mil(mm: float) -> str:
    return f"{mm / 0.0254:.4f}mil"


def record(kind: str, **fields) -> str:
    def value(v):
        if isinstance(v, bool):
            return "TRUE" if v else "FALSE"
        result = str(v)
        if any(c in result for c in "|\r\n"):
            raise ValueError(f"Invalid ASCII record value: {result!r}")
        return result
    return "|RECORD=" + kind + "".join(f"|{k}={value(v)}" for k, v in fields.items())


def base(layer="TOP"):
    return dict(SELECTION=False, LAYER=layer, LOCKED=False,
                POLYGONOUTLINE=False, USERROUTED=True, UNIONINDEX=0)


@dataclass(frozen=True)
class Pad:
    number: str
    x: float
    y: float
    sx: float
    sy: float
    drill: float = 0
    shape: str = "RECTANGLE"
    drill_slot_length_mm: float = 0
    drill_slot_angle_deg: float = 0
    paste: bool = True


@dataclass(frozen=True)
class Footprint:
    pads: tuple[Pad, ...]
    body: tuple[float, float]
    height: float
    note: str
    provisional: bool = False


def two_pads(spacing, sx, sy, body, height=1, note="Generic package; final MPN review required", drill=0):
    return Footprint((Pad("1", -spacing / 2, 0, sx, sy, drill),
                      Pad("2", spacing / 2, 0, sx, sy, drill)), body, height, note, True)


def footprint(component: dict) -> Footprint:
    """Return explicit top-view pad geometry; never invent a SuperMini header."""
    ref, value = component["ref"], component["value"].upper()
    pattern = component.get("footprint", "").upper()
    if component.get('pcb_footprint'):
        spec = component['pcb_footprint']
        return Footprint(tuple(Pad(str(p['number']),p['x'],p['y'],p['sx'],p['sy'],
                                   p.get('drill',0),p.get('shape','RECTANGLE'),p.get('drill_slot_length_mm',0),
                                   p.get('drill_slot_angle_deg',0),p.get('paste',True)) for p in spec['pads']),
                         tuple(spec['body']),spec['height'],spec['note'],spec.get('provisional',False))
    if ref == "MCU1" or "SUPERMINI" in pattern:
        return Footprint((), (18, 24), 4, "RESERVATION ONLY - module/header/USB dimensions unverified", True)
    if ref.startswith("TP"):
        return Footprint((Pad("1", 0, 0, 2, 2, 0, "ROUND"),), (2, 2), 0,
                         "2 mm exposed top-copper test pad; no paste", True)
    if ref == "U1" or "ISO1042" in value:
        # TI DWV0008A: 1.27 pitch, 10.9 row-centre distance, 1.8 x 0.6 pads.
        pads = [Pad(str(i + 1), -5.45, 1.905 - i * 1.27, 1.8, .6) for i in range(4)]
        pads += [Pad(str(i + 5), 5.45, -1.905 + i * 1.27, 1.8, .6) for i in range(4)]
        return Footprint(tuple(pads), (7.5, 5.85), 2.8,
                         "TI DWV0008A manufacturer land pattern; pin 1 upper left")
    if ref == "U2" or "R3M" in value:
        # RECOM R3M rev. 1/2023 p5, recommended footprint (top view).
        positions = {"1": (-4.75, -3), "2": (-4.75, -1), "4": (-4.75, 3),
                     "5": (4.75, -3), "6": (4.75, -1), "7": (4.75, 1)}
        return Footprint(tuple(Pad(n, x, y, 5.7, 1.4) for n, (x, y) in positions.items()),
                         (13.2, 9.1), 10.2, "RECOM recommended R3M SMD land pattern; 3.8 mm inner pad gap")
    if ref in {"Q1", "U3"} or "SOT223" in pattern or "SOT-223" in pattern:
        # Generic SOT-223 outline; large tab is physical pin 4, electrically
        # tied to pin 2 by the component model (never omitted from the netlist).
        pads = tuple([Pad(str(i + 1), -2.3 + i * 2.3, -3.15, 1.2, 2.2) for i in range(3)]
                     + [Pad("4", 0, 3.15, 3.8, 2.2)])
        return Footprint(pads, (6.5, 3.5), 1.8,
                         "SOT-223 generic lands; confirm TI DCY / Diodes land pattern", True)
    if ref == "D3" or "SOT23" in pattern or "SOT-23" in pattern:
        return Footprint((Pad("1", -.95, -1, .6, 1.1), Pad("2", .95, -1, .6, 1.1),
                          Pad("3", 0, 1, .6, 1.1)), (2.9, 1.3), 1.1,
                         "SOT-23 generic lands; confirm Nexperia solder process", True)
    if ref == "L1" or "ACT45" in value:
        # TDK ACT45B drawing: outer land extent 5.9 x 3.4 mm,
        # Inner gaps 3.2 x 1.6 mm imply 1.35 x 0.9 mm pads.
        return Footprint((Pad("1", -2.275, 1.25, 1.35, .9), Pad("2", -2.275, -1.25, 1.35, .9),
                          Pad("3", 2.275, -1.25, 1.35, .9), Pad("4", 2.275, 1.25, 1.35, .9)),
                         (4.5, 3.2), 2.8, "TDK ACT45B recommended lands; windings 1-4 and 2-3")
    if ref == "J1":
        # A pigtail solder interface, NOT an invented Micro-C connector face.
        pads = tuple(Pad(str(i + 1), 0, 7 - i * 3.5, 2.5, 2.5, 1.3,
                         "RECTANGLE" if i == 0 else "ROUND") for i in range(5))
        return Footprint(pads, (5, 18), 5,
                         "TBD 5-wire pigtail pads; final connector, holes and strain relief required", True)
    if ref == "JP1":
        return two_pads(2.54, 1.8, 1.8, (5.08, 2.54), 6,
                        "TBD 2.54 mm service jumper; open BEFORE connecting USB", drill=1)
    if ref == "F1":
        return two_pads(5.08, 2.5, 2.5, (9, 4), 5,
                        "TBD fuse T0.8A >=60V; placeholder pads, not a selected fuse", drill=1.2)
    if ref == "L2":
        return two_pads(4, 2.2, 4.5, (5, 5), 3,
                        "TBD 15uH >=1A inductor; replace footprint after MPN selection")
    if ref == "D1" or "SMB" in pattern:
        return two_pads(4.2, 2.3, 2.8, (4.6, 3.6), 2.5,
                        "DO-214AA SMB generic lands; 1=cathode 2=anode; verify vendor")
    if ref == "D2" or "SMA" in pattern:
        return two_pads(4, 2.3, 1.9, (4.5, 2.6), 2.3,
                        "DO-214AC SMA generic lands; 1=cathode 2=anode; verify vendor")
    if ref == "Z1" or "SOD123" in pattern or "SOD-123" in pattern:
        return two_pads(3.1, 1.2, 1.2, (2.7, 1.6), 1.2,
                        "SOD-123 generic lands; 1=cathode 2=anode; verify vendor")
    if ref in {"C1", "C6"}:
        diameter = 8 if ref == "C1" else 6.3
        return two_pads(2.5, 1.8, 1.8, (diameter, diameter), 12,
                        f"TBD radial electrolytic {diameter} mm body, 2.5 mm pitch; 1=positive", drill=.9)
    if ref.startswith("R"):
        return two_pads(1.8, 1, 1.3, (2, 1.25), .6, "0805 generic resistor lands; MPN review")
    if "1210" in pattern:
        return two_pads(3, 1.5, 2.8, (3.2, 2.5), 2.5, "1210 generic capacitor lands; effective capacitance review")
    if ref == "C3" or "1206" in pattern:
        return two_pads(3, 1.5, 1.8, (3.2, 1.6), 1.6, "1206 generic capacitor lands; effective capacitance review")
    if ref.startswith("C"):
        return two_pads(1.8, 1, 1.3, (2, 1.25), 1.2, "0805 generic capacitor lands; MPN review")
    raise ValueError(f"No reviewed footprint mapping for {ref} {pattern}")


def transform(comp: dict, x: float, y: float) -> tuple[float, float]:
    placement = comp["pcb"]
    angle = math.radians(placement.get("rotation", 0))
    return (placement["x"] + x * math.cos(angle) - y * math.sin(angle),
            placement["y"] + x * math.sin(angle) + y * math.cos(angle))


def footprint_bounds(fp: Footprint) -> tuple[float, float, float, float]:
    """Enclose both the package and all solder lands, in local coordinates."""
    return (min([-fp.body[0] / 2] + [p.x - p.sx / 2 for p in fp.pads]),
            min([-fp.body[1] / 2] + [p.y - p.sy / 2 for p in fp.pads]),
            max([fp.body[0] / 2] + [p.x + p.sx / 2 for p in fp.pads]),
            max([fp.body[1] / 2] + [p.y + p.sy / 2 for p in fp.pads]))


def board_records(width, height, filename):
    header = base()
    header.update(FILENAME=filename, KIND="Protel_Advanced_PCB", VERSION="5.00",
                  ORIGINX=mil(0), ORIGINY=mil(0), DISPLAYUNIT=1,
                  ELECTRICALGRIDRANGE=mil(.2), ELECTRICALGRIDENABLED=True,
                  SNAPGRIDSIZE=98425.196850, SNAPGRIDSIZEX=98425.196850,
                  SNAPGRIDSIZEY=98425.196850, COMPONENTGRIDSIZE=98425.196850,
                  COMPONENTGRIDSIZEX=98425.196850, COMPONENTGRIDSIZEY=98425.196850,
                  TRACKGRIDSIZE=98425.196850, VIAGRIDSIZE=98425.196850,
                  DOTGRID=False, POLYGONTYPE="Polygon", HATCHSTYLE="None",
                  GRIDSIZE=mil(.25), TRACKWIDTH=mil(.25), PRIMITIVELOCK=True,
                  MINPRIMLENGTH=mil(.1), SHELVED=False, SPLITLINECOUNT=0,
                  SHOWSHEET=False, SHEETX=mil(0), SHEETY=mil(0),
                  SHEETWIDTH=mil(width + 20), SHEETHEIGHT=mil(height + 20))
    for i, (x, y) in enumerate([(0, 0), (width, 0), (width, height), (0, height), (0, 0)]):
        header.update({f"KIND{i}": 0, f"VX{i}": mil(x), f"VY{i}": mil(y),
                       f"CX{i}": mil(0), f"CY{i}": mil(0), f"SA{i}": 0, f"EA{i}": 0, f"R{i}": mil(0)})
    yield record("Board", **header)
    # The legacy stack description is read by Altium's native ASCII loader.
    # Only top (1) and bottom (32) are linked into the copper stack.
    layernames = {1: "Top Layer", 32: "Bottom Layer", 33: "Top Overlay", 34: "Bottom Overlay",
                  35: "Top Paste", 36: "Bottom Paste", 37: "Top Solder", 38: "Bottom Solder",
                  55: "Drill Guide", 56: "Keep-Out Layer", 57: "Board outline",
                  58: "Isolation and RF planning", 59: "Design notes",
                  69: "Component bodies", 71: "Courtyards", 73: "Drill Drawing", 74: "Multi-Layer"}
    layerfields = dict(LAYERSTACKSTYLE=0, SHOWTOPDIELECTRIC=False, SHOWBOTTOMDIELECTRIC=False,
                       TOPTYPE=3, TOPCONST=3.5, TOPHEIGHT=mil(.01), TOPMATERIAL="Solder Resist",
                       BOTTOMTYPE=3, BOTTOMCONST=3.5, BOTTOMHEIGHT=mil(.01), BOTTOMMATERIAL="Solder Resist")
    for i in range(1, 75):
        layerfields.update({f"LAYER{i}NAME": layernames.get(i, f"Unused {i}"),
                            f"LAYER{i}PREV": 1 if i == 32 else 0,
                            f"LAYER{i}NEXT": 32 if i == 1 else 0,
                            f"LAYER{i}MECHENABLED": i in {57, 58, 59, 69, 71},
                            f"LAYER{i}COPTHICK": mil(.035), f"LAYER{i}DIELTYPE": 0,
                            f"LAYER{i}DIELCONST": 4.3, f"LAYER{i}DIELHEIGHT": mil(1.53),
                            f"LAYER{i}DIELMATERIAL": "FR-4"})
        if i % 5 == 0:
            yield record("Board", **layerfields)
            layerfields = {}
    if layerfields:
        yield record("Board", **layerfields)


def build_pcb(data: dict, path: Path | str) -> dict:
    """Write a native .PcbDoc, return counts and explicit unresolved footprints."""
    path = Path(path)
    components = data["components"]
    refs = [c["ref"] for c in components]
    if len(set(refs)) != len(refs):
        raise ValueError("Duplicate component designator")
    uids = [c["uid"] for c in components]
    if len(set(uids)) != len(uids) or any(len(uid) != 8 or not uid.isalpha() or uid != uid.upper() for uid in uids):
        raise ValueError("Expected unique eight-uppercase-letter component UIDs")
    nets = sorted({p["net"] for c in components for p in c["pins"] if p.get("net")})
    net_id = {n: i for i, n in enumerate(nets)}
    board = data["board"]
    width, height = board["width_mm"], board["height_mm"]
    rows = list(board_records(width, height, path.name))
    for i, name in enumerate(nets):
        rows.append(record("Net", **base(), ID=i, INDEXFORSAVE=i, PRIMITIVELOCK=False,
                           NAME=name, VISIBLE=True, COLOR=7709086, LOOPREMOVAL=True,
                           TOPLAYER_MRWIDTH=mil(.25), BOTTOMLAYER_MRWIDTH=mil(.25)))
    pads, tracks, texts = [], [], []
    provisional = []

    def line(x1, y1, x2, y2, layer="MECHANICAL1", width=.15, component=None):
        args = base(layer)
        if component is not None:
            args["COMPONENT"] = component
        tracks.append(record("Track", **args, INDEXFORSAVE=len(tracks),
                             SOLDERMASKEXPANSIONMODE="None", PASTEMASKEXPANSIONMODE="None",
                             X1=mil(x1), Y1=mil(y1), X2=mil(x2), Y2=mil(y2), WIDTH=mil(width), SUBPOLYINDEX=0))

    def box(x1, y1, x2, y2, layer="MECHANICAL1", width=.15, component=None):
        for a, b in [((x1, y1), (x2, y1)), ((x2, y1), (x2, y2)),
                     ((x2, y2), (x1, y2)), ((x1, y2), (x1, y1))]:
            line(*a, *b, layer, width, component)

    def text(x, y, caption, layer="TOPOVERLAY", h=1, component=None, designator=False, comment=False):
        args = base(layer)
        if component is not None:
            args["COMPONENT"] = component
        if designator:
            args["DESIGNATOR"] = True
        if comment:
            args["COMMENT"] = True
        texts.append(record("Text", **args, INDEXFORSAVE=len(texts), X=mil(x), Y=mil(y),
                            HEIGHT=mil(h), WIDTH=mil(max(.15, h * .15)), FONT="DEFAULT",
                            ROTATION=0, MIRROR=False, TEXT=caption, USETTFONTS=False,
                            BOLD=False, ITALIC=False, INVERTED=False, FONTNAME="Arial"))

    for ci, comp in enumerate(components):
        fp = footprint(comp)
        pin_by_no = {str(p["number"]): p for p in comp["pins"]}
        if len(pin_by_no) != len(comp["pins"]):
            raise ValueError(f"{comp['ref']}: duplicate schematic pin number")
        if fp.pads and {p.number for p in fp.pads} != set(pin_by_no):
            raise ValueError(f"{comp['ref']}: schematic/PCB pin set mismatch: "
                             f"{set(pin_by_no)} vs {set(p.number for p in fp.pads)}")
        place = comp["pcb"]
        x, y, angle = place["x"], place["y"], place.get("rotation", 0)
        if not 0 <= x <= width or not 0 <= y <= height:
            raise ValueError(f"{comp['ref']}: outside board")
        source_sheet = comp.get("sheet", "Orion-Bridge")
        library_fields = {}
        if comp.get('source_schlib'):
            library_fields.update(SOURCECOMPONENTLIBRARY=comp['source_schlib'],
                                  SOURCEFOOTPRINTLIBRARY=comp['source_pcblib'])
        rows.append(record("Component", **base(), **library_fields, ID=ci, INDEXFORSAVE=ci,
                           X=mil(x), Y=mil(y), PATTERN=comp["footprint"], NAMEON=True,
                           COMMENTON=False, GROUPNUM=0, COUNT=0, ROTATION=angle,
                           HEIGHT=mil(fp.height), PRIMITIVELOCK=True, COMMENTAUTOPOSITION=3,
                           SOURCEDESIGNATOR=comp["ref"], SOURCEUNIQUEID="\\" + comp["uid"],
                           SOURCEHIERARCHICALPATH=source_sheet,
                           SOURCELIBREFERENCE=comp.get("libref", comp["value"]),
                           SOURCEDESCRIPTION=comp.get("description",comp["value"]), FOOTPRINTDESCRIPTION=fp.note))
        for p in fp.pads:
            px, py = transform(comp, p.x, p.y)
            attrs = base("MULTILAYER" if p.drill else "TOP")
            net = pin_by_no[p.number].get("net")
            if net:
                attrs["NET"] = net_id[net]
            attrs["COMPONENT"] = ci
            pads.append(record("Pad", **attrs, INDEXFORSAVE=len(pads),
                               NAME=p.number, X=mil(px), Y=mil(py), XSIZE=mil(p.sx), YSIZE=mil(p.sy),
                               SHAPE=p.shape, HOLESIZE=mil(p.drill), ROTATION=angle, PLATED=True,
                               SOLDERMASKEXPANSIONMODE="Rule",
                               PASTEMASKEXPANSIONMODE="None" if comp["ref"].startswith("TP") or p.drill or not p.paste else "Rule",
                               PADMODE=0, DRILLTYPE=0, HOLETYPE=2 if p.drill_slot_length_mm else 0,
                               HOLEWIDTH=mil(p.drill_slot_length_mm),HOLEROTATION=p.drill_slot_angle_deg,
                               DAISYCHAIN="Load"))
        # Bodies and courtyards are mechanical drawing primitives, not copper.
        local_bounds = footprint_bounds(fp)
        for layer in ["MECHANICAL13", "MECHANICAL15"]:
            if layer == "MECHANICAL13":
                left, bottom, right, top = -fp.body[0] / 2, -fp.body[1] / 2, fp.body[0] / 2, fp.body[1] / 2
            else:
                left, bottom, right, top = (local_bounds[0] - .5, local_bounds[1] - .5,
                                           local_bounds[2] + .5, local_bounds[3] + .5)
            corners = [transform(comp, px, py) for px, py in [(left, bottom), (right, bottom), (right, top), (left, top)]]
            for a, b in zip(corners, corners[1:] + corners[:1]):
                line(*a, *b, layer, .12, ci)
        world_bounds = [transform(comp, px, py) for px, py in
                        [(local_bounds[0], local_bounds[1]), (local_bounds[2], local_bounds[1]),
                         (local_bounds[2], local_bounds[3]), (local_bounds[0], local_bounds[3])]]
        if any(not (0 <= px <= width and 0 <= py <= height) for px, py in world_bounds) and not comp.get('allow_body_overhang',False):
            raise ValueError(f"{comp['ref']}: body or pad outside board")
        label_x, label_y = min(px for px, py in world_bounds), max(py for px, py in world_bounds) + .6
        if comp['ref'] == 'Q1':
            label_x, label_y = 18.5, 21.5
        elif comp['ref'] == 'C1':
            label_x, label_y = 14.5, 3
        text(label_x, label_y, comp["ref"], component=ci, designator=True)
        text(x, y, comp["value"], "MECHANICAL13", .8, component=ci, comment=True)
        if fp.provisional or "TBD" in place.get("status", "").upper():
            provisional.append({"ref": comp["ref"], "footprint": comp["footprint"], "note": fp.note})
        if not fp.pads:
            text(x - 8, y - 1, "RESERVATION ONLY", "MECHANICAL2", .8)
            text(x - 8, y - 3, "NO HEADER PADS", "MECHANICAL2", .8)

    box(0, 0, width, height)
    for x, y in board.get("holes_mm", []):
        pads.append(record("Pad", **base("MULTILAYER"), INDEXFORSAVE=len(pads), NAME="",
                           X=mil(x), Y=mil(y), XSIZE=mil(3.2), YSIZE=mil(3.2),
                           SHAPE="ROUND", HOLESIZE=mil(3.2), ROTATION=0, PLATED=False,
                           SOLDERMASKEXPANSIONMODE="Manual", SOLDERMASKEXPANSION_MANUAL=mil(.1),
                           PASTEMASKEXPANSIONMODE="None", PADMODE=0, DRILLTYPE=0, HOLETYPE=0))
    # Planning regions intentionally contain NO ground planes or copper fills.
    # The native all-layer Keep-Out tracks reserve the copper isolation band;
    # 0.25 mm clearance on either side yields a 6 mm target, 3.8 mm at U2.
    u2 = next((c for c in components if c["ref"] == "U2"), None)
    boundary = u2["pcb"]["x"] if u2 else width / 2
    u2_y = u2["pcb"]["y"] if u2 else height / 4
    for x in [boundary - 3, boundary + 3]:
        line(x, 0, x, height, "MECHANICAL2", .1)
    # Use straight keepout primitives only, retaining rounded cap clearance.
    # The narrowed span extends beyond U2 to avoid broad endcaps hitting pads.
    lower, upper = max(0, u2_y - 8), min(height, u2_y + 8)
    if lower > 2.75:
        line(boundary, 2.75, boundary, lower - 2.75, "KEEPOUT", 5.5)
    if height - upper > 2.75:
        line(boundary, upper + 2.75, boundary, height - 2.75, "KEEPOUT", 5.5)
    line(boundary, max(1.65, lower), boundary, min(height - 1.65, upper), "KEEPOUT", 3.3)
    box(width - 24, height - 17, width, height, "MECHANICAL2")
    text(width - 23, height - 3, "RF KEEP CLEAR - VERIFY", "MECHANICAL2", .8)
    text(8, height - 4, data.get('pcb_title', "ORION BRIDGE R1 - PLACEMENT DRAFT"), h=1.1)
    text(8, height - 8, "UNROUTED / NOT FOR FABRICATION", h=1)
    text(5, -5, "MECH1: outline; MECH2: planning; MECH13: body; MECH15: courtyard", "MECHANICAL3", 1)
    text(5, -8, data.get('pcb_review_note', "MCU1 has no pads. Generic footprints and supply operation remain to be reviewed."), "MECHANICAL3", 1)
    text(5, -11, "No PCB 120R termination. JP1 open BEFORE USB. GND_BUS and GND_LOGIC stay isolated.", "MECHANICAL3", 1)

    for i, (kind, extra) in enumerate([
        ("Clearance", {"NETSCOPE": "DifferentNets", "GAP": mil(.25)}),
        ("Width", {"MINLIMIT": mil(.25), "MAXLIMIT": mil(2), "PREFEREDWIDTH": mil(.3)}),
        ("ShortCircuit", {"ALLOWED": False}), ("UnRoutedNet", {}),
        ("SolderMaskExpansion", {"EXPANSION": mil(.075)}),
    ]):
        args = dict(INDEXFORSAVE=i, RULEKIND=kind, NETSCOPE="AnyNet", LAYERKIND="SameLayer",
                    SCOPE1COUNT=1, SCOPE1_0_KIND="Board", SCOPE1_0_VALUE="Board",
                    SCOPE2COUNT=1, SCOPE2_0_KIND="Board", SCOPE2_0_VALUE="Board",
                    NAME=kind, ENABLED=True, COMMENTLENGTH=0, COMMENT="")
        args.update(extra)
        rows.append(record("Rule", **base(), **args))
    rows.extend(pads)
    rows.extend(tracks)
    rows.extend(texts)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(("\r\n".join(rows) + "\r\n").encode("cp1252"))
    return {"path": str(path), "components": len(components), "nets": len(nets),
            "pads": len(pads), "copper_tracks": 0, "provisional_footprints": provisional,
            "format": "Native Altium PCB ASCII 5.0", "altium_open_validated": False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    print(json.dumps(build_pcb(json.loads(args.data.read_text(encoding="utf-8")), args.output), indent=2))
