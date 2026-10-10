"""Render native SchDoc ASCII geometry to PDF and PNG for visual QA.

This is a geometry/font approximation, not an Altium screenshot, ERC, DRC or
open/save validation. It renders exactly the supplied records; it does not
repair source placement, hide overlaps, or change the source document.

Usage:
  python tools/preview_altium_r2.py
  python tools/preview_altium_r2.py path/to/board.SchDoc --dpi 200
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess

from reportlab.lib.colors import Color, HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "hardware/altium-r2/Orion-Bridge-R2.SchDoc"
RUNTIME = Path.home() / ".cache/codex-runtimes/codex-primary-runtime/dependencies"
COORD_TO_PT = .72  # Altium schematic coordinate unit = 10 mil.


def read_records(source):
    rows = []
    for line in Path(source).read_text(encoding="cp1252").splitlines():
        row = {key.upper(): value for field in line.split("|") if "=" in field
               for key, value in [field.split("=", 1)]}
        if "RECORD" in row:
            rows.append(row)
    return rows


def number(row, key, fallback=0):
    return float(row.get(key, fallback))


def truth(value):
    return str(value).upper() in {"T", "TRUE", "1"}


def color(value):
    packed = int(value)
    return Color((packed & 255) / 255, ((packed >> 8) & 255) / 255, ((packed >> 16) & 255) / 255)


class Renderer:
    def __init__(self, source, output):
        self.source, self.output = Path(source), Path(output)
        self.rows = read_records(source)
        self.sheet = next(row for row in self.rows if row.get("RECORD") == "31")
        self.width = number(self.sheet, "CUSTOMX", 2230)
        self.height = number(self.sheet, "CUSTOMY", 1570)
        self.fonts = {}
        self.text_boxes = []
        self.missing_records = Counter()
        self.margin = 14
        # Native 10-mil geometry and actual font point sizes are preserved.
        # Arbitrary PDF page size permits unambiguous inspection at any zoom.
        self.canvas = Canvas(str(output), pagesize=(self.width * COORD_TO_PT + 2 * self.margin,
                                                   self.height * COORD_TO_PT + 2 * self.margin + 22))
        self.canvas.setTitle("Orion Bridge R2 - schematic geometry preview")
        self.canvas.setAuthor("BatterySentinel-N2K")
        self.canvas.setSubject("Approximate native SchDoc geometry, not Altium-rendered")
        self.canvas.setFont("Helvetica", 7)
        self.canvas.setFillColor(HexColor("#59636b"))
        self.canvas.drawString(self.margin, 9,
            "Geometrievorschau aus SchDoc-Daten | Kein Altium-Rendering und keine ERC-/DRC-Pruefung")
        self.canvas.translate(self.margin, self.margin + 22)
        self.canvas.scale(COORD_TO_PT, COORD_TO_PT)
        self.canvas.setLineJoin(1)
        self.canvas.setLineCap(1)
        self.canvas.setStrokeColor(HexColor("#ccd2d8"))
        self.canvas.setLineWidth(.5)
        self.canvas.rect(0, 0, self.width, self.height, stroke=1, fill=0)
        self.load_fonts()

    def load_fonts(self):
        count = int(self.sheet.get("FONTIDCOUNT", 3))
        for i in range(1, count + 1):
            bold = truth(self.sheet.get(f"BOLD{i}"))
            italic = truth(self.sheet.get(f"ITALIC{i}"))
            filename = "arialbi.ttf" if bold and italic else "arialbd.ttf" if bold else "ariali.ttf" if italic else "arial.ttf"
            path = Path("C:/Windows/Fonts") / filename
            name = "OrionArial" + ("Bold" if bold else "") + ("Italic" if italic else "")
            if path.exists():
                if name not in pdfmetrics.getRegisteredFontNames():
                    pdfmetrics.registerFont(TTFont(name, str(path)))
            else:
                name = "Helvetica-Bold" if bold else "Helvetica"
            self.fonts[i] = (name, number(self.sheet, f"SIZE{i}", 9) / COORD_TO_PT)

    def style(self, row):
        self.canvas.setStrokeColor(color(row.get("COLOR", 128)))
        self.canvas.setFillColor(color(row.get("AREACOLOR", row.get("COLOR", 128))))
        self.canvas.setLineWidth({0: .4, 1: .8, 2: 1.5, 3: 2.5}.get(int(row.get("LINEWIDTH", 1)), .8))
        if int(row.get("LINESTYLE", 0)):
            self.canvas.setDash(5, 4)
        else:
            self.canvas.setDash()

    def polyline(self, points):
        if len(points) < 2:
            return
        path = self.canvas.beginPath()
        path.moveTo(*points[0])
        for point in points[1:]:
            path.lineTo(*point)
        self.canvas.drawPath(path, stroke=1, fill=0)

    def text(self, x, y, caption, font_id=1, packed_color=128, align="left", rotation=0, label_kind="text"):
        font, size = self.fonts.get(int(font_id), self.fonts[1])
        self.canvas.saveState()
        self.canvas.translate(x, y)
        self.canvas.rotate(rotation)
        self.canvas.setFont(font, size)
        self.canvas.setFillColor(color(packed_color))
        width = pdfmetrics.stringWidth(caption, font, size)
        offset = -width if align == "right" else -width / 2 if align == "center" else 0
        self.canvas.drawString(offset, 0, caption)
        self.canvas.restoreState()
        if rotation == 0:
            self.text_boxes.append(dict(text=caption, kind=label_kind,
                bbox=[x + offset, y - size * .22, x + offset + width, y + size * .8]))

    def pin(self, row):
        x, y = number(row, "LOCATION.X"), number(row, "LOCATION.Y")
        flags = int(row.get("PINCONGLOMERATE", 0))
        direction = flags & 3
        dx, dy = ((1, 0), (0, 1), (-1, 0), (0, -1))[direction]
        length = number(row, "PINLENGTH", 20)
        self.polyline([(x, y), (x + dx * length, y + dy * length)])
        # Fields 8/16 select pin name/number visibility. Location is the body
        # end. Horizontal names stay inside the body. Vertical labels follow
        # a compact readable horizontal approximation (Altium may rotate them).
        if flags & 8:
            fid = int(row.get("NAME_CUSTOMFONTID", 3))
            if direction in (0, 2):
                self.text(x - 5 if direction == 0 else x + 5, y - 3,
                    row.get("NAME", ""), fid, align="right" if direction == 0 else "left", label_kind="pin_name")
            else:
                self.text(x, y - 16 if direction == 1 else y + 6,
                    row.get("NAME", ""), fid, align="center", label_kind="pin_name")
        if flags & 16:
            fid = int(row.get("DESIGNATOR_CUSTOMFONTID", 3))
            if direction in (0, 2):
                self.text(x + dx * length / 2, y + 4, row.get("DESIGNATOR", ""),
                    fid, align="center", label_kind="pin_number")
            else:
                self.text(x + 4, y + dy * length / 2 - 3, row.get("DESIGNATOR", ""),
                    fid, label_kind="pin_number")

    def power(self, row):
        x, y = number(row, "LOCATION.X"), number(row, "LOCATION.Y")
        direction = int(row.get("ORIENTATION", 1))
        angle = math.radians(90 * (direction - 1))
        # Local symbol points up. All four native orientations are supported.
        def p(px, py):
            return (x + px * math.cos(angle) - py * math.sin(angle),
                    y + px * math.sin(angle) + py * math.cos(angle))
        self.polyline([p(0, 0), p(0, 10)])
        if int(row.get("STYLE", 2)) == 4:
            for py, span in [(10, 10), (14, 6), (18, 2)]:
                self.polyline([p(-span, py), p(span, py)])
        else:
            self.polyline([p(-10, 10), p(10, 10)])
        if truth(row.get("SHOWNETNAME", "T")):
            caption = row.get("TEXT", "")
            if direction == 3:
                self.text(x, y - 32, caption, int(row.get("FONTID", 3)), align="center", label_kind="power_name")
            elif direction == 1:
                self.text(x, y + 19, caption, int(row.get("FONTID", 3)), align="center", label_kind="power_name")
            else:
                self.text(x + (22 if direction == 0 else -22), y - 4, caption,
                    int(row.get("FONTID", 3)), align="left" if direction == 0 else "right", label_kind="power_name")

    def draw(self):
        ignored = {"1", "31", "44", "45", "46", "48"}
        for row in self.rows:
            kind = row["RECORD"]
            self.style(row)
            if kind in ignored:
                continue
            if kind in ("6", "27"):
                count = int(row.get("LOCATIONCOUNT", 2))
                self.polyline([(number(row, f"X{i}"), number(row, f"Y{i}")) for i in range(1, count + 1)])
            elif kind == "13":
                self.polyline([(number(row, "LOCATION.X"), number(row, "LOCATION.Y")),
                               (number(row, "CORNER.X"), number(row, "CORNER.Y"))])
            elif kind == "14":
                x, y = number(row, "LOCATION.X"), number(row, "LOCATION.Y")
                self.canvas.rect(x, y, number(row, "CORNER.X") - x, number(row, "CORNER.Y") - y,
                    stroke=1, fill=int(truth(row.get("ISSOLID", "F"))))
            elif kind == "2":
                self.pin(row)
            elif kind == "17":
                self.power(row)
            elif kind == "29":
                self.canvas.setFillColor(color(row.get("COLOR", 8388608)))
                self.canvas.circle(number(row, "LOCATION.X"), number(row, "LOCATION.Y"), 2.5, stroke=0, fill=1)
            elif kind == "22":
                x, y = number(row, "LOCATION.X"), number(row, "LOCATION.Y")
                self.polyline([(x - 4, y - 4), (x + 4, y + 4)])
                self.polyline([(x - 4, y + 4), (x + 4, y - 4)])
            elif kind in ("4", "25", "34", "41"):
                if truth(row.get("ISHIDDEN", "F")) or "LOCATION.X" not in row:
                    continue
                # Reference/value labels are always records, never inferred.
                self.text(number(row, "LOCATION.X"), number(row, "LOCATION.Y"), row.get("TEXT", ""),
                    int(row.get("FONTID", 1)), int(row.get("COLOR", 128)),
                    rotation=90 * int(row.get("ORIENTATION", 0)), label_kind="record_" + kind)
            else:
                self.missing_records[kind] += 1
        self.canvas.showPage()
        self.canvas.save()
        overlaps = []
        # Labels for vertical pins are approximate: flag only explicit source
        # text/parameters/net labels/power names, which have reliable geometry.
        boxes = [b for b in self.text_boxes if not b["kind"].startswith("pin_")]
        for i, a in enumerate(boxes):
            for b in boxes[i + 1:]:
                ab, bb = a["bbox"], b["bbox"]
                ix, iy = min(ab[2], bb[2]) - max(ab[0], bb[0]), min(ab[3], bb[3]) - max(ab[1], bb[1])
                if ix > 1 and iy > 1:
                    overlaps.append(dict(a=a["text"], b=b["text"], overlap_area=round(ix * iy, 1)))
        power_inside_body = []
        ref_for_owner = {r.get("OWNERINDEX"): r.get("TEXT", "") for r in self.rows if r["RECORD"] == "34"}
        rectangles = [r for r in self.rows if r["RECORD"] == "14" and r.get("OWNERINDEX") in ref_for_owner]
        for p in (r for r in self.rows if r["RECORD"] == "17"):
            px, py = number(p, "LOCATION.X"), number(p, "LOCATION.Y")
            for r in rectangles:
                x1, x2 = sorted((number(r, "LOCATION.X"), number(r, "CORNER.X")))
                y1, y2 = sorted((number(r, "LOCATION.Y"), number(r, "CORNER.Y")))
                if x1 <= px <= x2 and y1 <= py <= y2:
                    power_inside_body.append(dict(power=p.get("TEXT"), location=[px, py],
                                                  component=ref_for_owner[r["OWNERINDEX"]]))
        return dict(source=str(self.source), source_sha256=hashlib.sha256(self.source.read_bytes()).hexdigest(),
                    pdf=str(self.output), geometry_preview_only=True,
                    sheet_units=[self.width, self.height], ignored_unimplemented_records=dict(self.missing_records),
                    approximate_text_overlap_candidates=overlaps,
                    powerports_inside_component_bodies=power_inside_body)


def render(source=DEFAULT_SOURCE, dpi=180):
    source = Path(source)
    output = source.with_name("Schaltplan-R2-Vorschau.pdf")
    report = Renderer(source, output).draw()
    binary = shutil.which("pdftoppm") or str(RUNTIME / "native/poppler/Library/bin/pdftoppm.exe")
    png_prefix = output.with_suffix("")
    subprocess.run([binary, "-png", "-singlefile", "-r", str(dpi), str(output), str(png_prefix)], check=True)
    report["png"] = str(png_prefix.with_suffix(".png"))
    report["dpi"] = dpi
    report_path = source.with_name("Schaltplan-R2-Vorschau-QA.json")
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", nargs="?", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--dpi", type=int, default=180)
    args = parser.parse_args()
    print(json.dumps(render(args.source, args.dpi), ensure_ascii=False, indent=2))
