"""Check the enclosure manual's digital structure, sources, and raster assets.

Run after the PDF builder and source-manifest writer have finished. This checker
does not render pages, judge illustration accuracy, test hyperlinks over the
network, or qualify a physical enclosure. Visual review remains a separate step.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
from urllib.parse import urlsplit

from PIL import Image
import pdfplumber
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs/enclosure-manual-assets"
PDF = ROOT / "output/pdf/Orion-R5-Enclosure-Assembly-Manual-EN.pdf"
REPORT = ASSETS / "qa-report.json"
CAD_IMAGES = (
    "rigid-kit", "flexible-kit", "base-inserts", "pcb-installation",
    "lid-exploded", "usb-gasket", "service_switch-gasket", "cable-exploded",
    "assembled",
)
SUSPICIOUS = {
    "\ufffd": "replacement character", "\u25a0": "black square",
    "\u25fc": "black medium square", "\u2588": "full block",
}
A4_POINTS = (210 / 25.4 * 72, 297 / 25.4 * 72)
BOUNDS_TOLERANCE_PT = 0.5


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def project_path(value: str) -> Path:
    """Resolve cross-platform manifest paths without reading outside this repo."""
    path = (ROOT / value.replace("\\", "/")).resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError(f"Source path is outside this repository: {value}")
    return path


def outlines(items):
    for item in items:
        if isinstance(item, list):
            yield from outlines(item)
        else:
            yield item


def https_uri(value: object) -> bool:
    if not isinstance(value, str) or any(c.isspace() for c in value):
        return False
    try:
        parsed = urlsplit(value)
        return bool(
            parsed.scheme == "https" and parsed.hostname and parsed.netloc
            and parsed.username is None and parsed.password is None
            and (parsed.port is None or 1 <= parsed.port <= 65535)
        )
    except ValueError:
        return False


def check_manual(pdf_path: Path) -> dict:
    checks = []
    watched = {}
    report = {
        "schema_version": 1,
        "checked_at_utc": datetime.now(timezone.utc).isoformat(),
        "pdf": relative(pdf_path),
        "validation_scope": "digital_only",
        "visual_review": {
            "required": True,
            "performed_by_this_script": False,
            "status": "required_separate_review",
        },
        "physical_validation": "not_performed; fit, retention and sealing remain separate",
        "link_validation_scope": "HTTPS URI syntax only; no network requests",
        "checks": checks,
        "counts": {},
    }

    def check(name, passed, **details):
        checks.append({"name": name, "passed": bool(passed), **details})

    def watch(path):
        digest = sha256(path)
        watched[path] = digest
        return digest

    try:
        report["pdf_sha256"] = watch(pdf_path)
        reader = PdfReader(pdf_path, strict=True)
        count = len(reader.pages)
        report["counts"]["pages"] = count
        check("page_count", count == 11, expected=11, actual=count)
        bad_sizes = []
        for number, page in enumerate(reader.pages, 1):
            width, height = float(page.mediabox.width), float(page.mediabox.height)
            if any(abs(a - b) > BOUNDS_TOLERANCE_PT
                   for a, b in zip((width, height), A4_POINTS)) or page.rotation % 360:
                bad_sizes.append({"page": number, "width_pt": width,
                                  "height_pt": height, "rotation": page.rotation})
        check("all_pages_portrait_a4", not bad_sizes,
              tolerance_pt=BOUNDS_TOLERANCE_PT, failures=bad_sizes)

        destinations = list(outlines(reader.outline))
        destination_pages = [reader.get_destination_page_number(item) for item in destinations]
        report["counts"]["outline_entries"] = len(destinations)
        check("outline_count_and_destinations",
              len(destinations) == 11 and sorted(p for p in destination_pages if p is not None)
              == list(range(11)), expected=11, actual=len(destinations),
              destination_pages=[None if p is None else p + 1 for p in destination_pages])

        links = []
        for number, page in enumerate(reader.pages, 1):
            for ref in page.get("/Annots", []):
                annotation = ref.get_object()
                if annotation.get("/Subtype") != "/Link":
                    continue
                action = annotation.get("/A", {})
                action = action.get_object() if hasattr(action, "get_object") else action
                uri = action.get("/URI")
                links.append({"page": number, "uri": str(uri) if uri is not None else None,
                              "valid_https": action.get("/S") == "/URI" and https_uri(uri)})
        report["counts"]["link_annotations"] = len(links)
        check("link_annotations_are_https", bool(links) and all(x["valid_https"] for x in links),
              annotations=links)

        empty_pages, glyphs, bad_bounds, all_text = [], [], [], []
        character_count = 0
        with pdfplumber.open(pdf_path) as document:
            for number, page in enumerate(document.pages, 1):
                text = page.extract_text() or ""
                all_text.append(text)
                if not text.strip():
                    empty_pages.append(number)
                for engine, extracted in (("pdfplumber", text),
                                           ("pypdf", reader.pages[number - 1].extract_text() or "")):
                    for char, description in SUSPICIOUS.items():
                        if char in extracted:
                            glyphs.append({"page": number, "extractor": engine,
                                           "codepoint": f"U+{ord(char):04X}",
                                           "description": description,
                                           "count": extracted.count(char)})
                for char in page.chars:
                    character_count += 1
                    bounds = [char["x0"], char["top"], char["x1"], char["bottom"]]
                    x0, top, x1, bottom = bounds
                    if not all(math.isfinite(x) for x in bounds) or (
                        x0 < -BOUNDS_TOLERANCE_PT or top < -BOUNDS_TOLERANCE_PT
                        or x1 > page.width + BOUNDS_TOLERANCE_PT
                        or bottom > page.height + BOUNDS_TOLERANCE_PT
                    ):
                        bad_bounds.append({"page": number, "text": char.get("text", ""),
                                           "bounds_pt": bounds})
        report["counts"].update(characters=character_count,
                                words=len("\n".join(all_text).split()),
                                suspicious_glyph_findings=len(glyphs),
                                out_of_bounds_characters=len(bad_bounds))
        check("all_pages_have_text", not empty_pages, empty_pages=empty_pages)
        check("no_replacement_or_black_square_glyphs", not glyphs, findings=glyphs)
        check("characters_within_page_bounds", not bad_bounds,
              tolerance_pt=BOUNDS_TOLERANCE_PT, failures=bad_bounds[:50],
              total_failures=len(bad_bounds))
    except Exception as exc:
        check("pdf_read_and_inspection", False, error=f"{type(exc).__name__}: {exc}")

    try:
        manifest_path = ASSETS / "source-manifest.json"
        watch(manifest_path)
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if not isinstance(manifest, dict) or not manifest:
            raise ValueError("Expected a nonempty path-to-SHA256 source manifest")
        sources = []
        for name, expected in manifest.items():
            item = {"path": name, "expected_sha256": expected, "matches": False}
            try:
                if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-fA-F]{64}", expected):
                    raise ValueError("Invalid SHA256 value")
                item["actual_sha256"] = watch(project_path(name))
                item["matches"] = item["actual_sha256"] == expected.lower()
            except Exception as exc:
                item["error"] = f"{type(exc).__name__}: {exc}"
            sources.append(item)
        report["counts"]["manifest_sources"] = len(sources)
        check("source_manifest_hashes_match", all(x["matches"] for x in sources), sources=sources)
    except Exception as exc:
        check("source_manifest_hashes_match", False, error=f"{type(exc).__name__}: {exc}")

    try:
        notes_path = ASSETS / "cad/image-notes.json"
        watch(notes_path)
        notes = json.loads(notes_path.read_text(encoding="utf-8"))
        images = notes.get("images", {})
        check("cad_image_catalog", set(images) == set(CAD_IMAGES),
              expected=list(CAD_IMAGES), actual=list(images))
        actual_cad_hash = watch(project_path(notes["source_cad"]))
        check("cad_image_source_matches", actual_cad_hash == notes["source_sha256"],
              expected_sha256=notes["source_sha256"], actual_sha256=actual_cad_hash)
        assets = [(ASSETS / "cover-generated.png", "generated_cover")]
        for name in CAD_IMAGES:
            asset_path = ASSETS / "cad" / images.get(name, {}).get("file", f"{name}.png")
            assets.append((asset_path, "cad_render"))
        asset_results = []
        for path, kind in assets:
            result = {"path": relative(path), "kind": kind, "valid": False}
            try:
                result["sha256"] = watch(path)
                with Image.open(path) as raster:
                    result.update(width_px=raster.width, height_px=raster.height,
                                  format=raster.format)
                    raster.verify()
                with Image.open(path) as raster:
                    raster.load()
                    result["valid"] = raster.width > 0 and raster.height > 0
            except Exception as exc:
                result["error"] = f"{type(exc).__name__}: {exc}"
            asset_results.append(result)
        report["counts"].update(raster_assets=len(asset_results), cad_rasters=9,
                                generated_cover_rasters=1,
                                valid_raster_assets=sum(x["valid"] for x in asset_results))
        check("ten_raster_assets_exist_and_decode",
              len(asset_results) == 10 and all(x["valid"] for x in asset_results),
              assets=asset_results)
    except Exception as exc:
        check("raster_asset_inspection", False, error=f"{type(exc).__name__}: {exc}")

    changed = []
    for path, before in watched.items():
        try:
            after = sha256(path)
            if before != after:
                changed.append(relative(path))
        except OSError:
            changed.append(relative(path))
    check("inputs_stable_during_check", not changed, changed_paths=changed,
          note="Rerun after the builder finishes if any input changed.")
    report["digital_checks_passed"] = all(item["passed"] for item in checks)
    report["status"] = ("digital_checks_passed_visual_review_required"
                        if report["digital_checks_passed"] else "digital_checks_failed")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdf", type=Path, default=PDF)
    parser.add_argument("--report", type=Path, default=REPORT)
    args = parser.parse_args()
    report = check_manual(args.pdf.resolve())
    args.report.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.report.with_suffix(args.report.suffix + ".tmp")
    temporary.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(args.report)
    print(json.dumps({"report": relative(args.report), "status": report["status"],
                      "counts": report["counts"],
                      "failed_checks": [x["name"] for x in report["checks"] if not x["passed"]]}))
    return 0 if report["digital_checks_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
