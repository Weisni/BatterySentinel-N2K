"""Build the native model/U8g2 preview; requires GCC, G++ and Pillow.

Uses the installed, pinned U8g2 graphics source and fonts, with no board access.
The PNG is a synthetic contact sheet; the GIF shows the seven-page cycle at two seconds per page.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import shutil
import subprocess

from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gcc", default=shutil.which("gcc"))
    parser.add_argument("--gxx", default=shutil.which("g++"))
    parser.add_argument("--output", type=Path, default=root / "output/firmware/debug-oled/1.2.0-debug.1")
    args = parser.parse_args()
    if not args.gcc or not args.gxx:
        parser.error("GCC and G++ are required; provide --gcc and --gxx paths")
    library = root / ".pio/libdeps/orion_debug_oled/U8g2"
    properties = dict(line.split("=", 1) for line in (library / "library.properties").read_text().splitlines() if "=" in line)
    if properties.get("version") != "2.36.5":
        raise RuntimeError("Preview requires the firmware's pinned U8g2 2.36.5")
    clib = library / "src/clib"
    build = root / "build/debug-display/preview"
    build.mkdir(parents=True, exist_ok=True)
    objects = []
    sources = ["u8g2_font", "u8g2_fonts", "u8g2_setup", "u8g2_buffer", "u8g2_hvline",
               "u8g2_ll_hvline", "u8g2_intersection", "u8g2_kerning", "u8x8_setup", "u8x8_8x8",
               "u8x8_display", "u8x8_capture", "u8x8_cad", "u8x8_byte", "u8x8_gpio", "u8x8_u16toa"]
    for source in sources:
        obj = build / f"{source}.o"
        subprocess.run([args.gcc, "-std=c99", "-O2", "-ffunction-sections", "-fdata-sections",
                        "-I", str(clib), "-c", str(clib / f"{source}.c"), "-o", str(obj)], check=True)
        objects.append(str(obj))
    executable = build / "render_debug_oled.exe"
    subprocess.run([args.gxx, "-std=c++17", "-O2", "-Wall", "-Wextra", "-Werror",
                    "-ffunction-sections", "-fdata-sections", "-I", str(clib),
                    "-I", str(root / "lib/DebugDisplay/src"), str(root / "tools/render_debug_oled.cpp"),
                    *objects, "-Wl,--gc-sections", "-o", str(executable)], check=True)
    subprocess.run([str(executable), str(build)], check=True)
    records = list(csv.reader((build / "frames.tsv").open(encoding="utf-8"), delimiter="\t"))
    font = ImageFont.load_default(size=17)
    title_font = ImageFont.load_default(size=24)
    small = ImageFont.load_default(size=14)
    bg, ink, muted = "#111827", "#e5edf5", "#aab8ca"

    def display(filename: str, scale: int) -> Image.Image:
        pixels = Image.open(build / filename).convert("L")
        screen = Image.new("RGB", pixels.size, "#000000")
        screen.paste("#ffffff", (0, 0), pixels)
        return screen.resize((72 * scale, 40 * scale), Image.Resampling.NEAREST)

    # Enlarged nearest-neighbour pixels keep this faithful to the 72 x 40 raster.
    cell_w, cell_h, margin, header = 392, 260, 24, 96
    sheet = Image.new("RGB", (margin * 2 + cell_w * 4, header + cell_h * 4 + 60), bg)
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 18), "Orion Bridge OLED / synthetic preview", font=title_font, fill=ink)
    draw.text((margin, 54), "Actual U8g2 2.36.5 fonts at 72 x 40 pixels. Values are invented; this is not a device photograph.", font=font, fill=muted)
    for index, record in enumerate(records):
        x, y = margin + (index % 4) * cell_w, header + (index // 4) * cell_h
        draw.text((x, y), record[1], font=font, fill=ink)
        sheet.paste(display(record[0], 5), (x, y + 32))
    draw.text((margin, sheet.height - 40), "Top status stays visible. Pages advance every 2 seconds. N+ means recent CAN reception; it does not confirm Garmin delivery.", font=small, fill=muted)
    args.output.mkdir(parents=True, exist_ok=True)
    sheet.save(args.output / "oled-preview.png")

    frames = []
    for record in records[:7]:
        canvas = Image.new("RGB", (624, 430), bg)
        draw = ImageDraw.Draw(canvas)
        draw.text((24, 16), "Synthetic OLED preview / 2 seconds per page", font=title_font, fill=ink)
        draw.text((24, 54), record[1], font=font, fill=muted)
        canvas.paste(display(record[0], 8), (24, 86))
        draw.text((24, 410), "Actual U8g2 fonts / 72 x 40 pixels / no hardware validation", font=small, fill=muted)
        frames.append(canvas)
    frames[0].save(args.output / "oled-preview.gif", save_all=True, append_images=frames[1:],
                   duration=2000, loop=0, disposal=2)
    print(f"Wrote {args.output / 'oled-preview.png'}")
    print(f"Wrote {args.output / 'oled-preview.gif'}")


if __name__ == "__main__":
    main()
