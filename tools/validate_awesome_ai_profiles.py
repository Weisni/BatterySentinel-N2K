"""Resolve the two deliverable presets against installed Quack and slice a coupon."""
from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import subprocess
import time
import zipfile

from build_awesome_ai_profiles import ENCLOSURE, OUT, PRESERVED_KEYS, SURFACE_KEYS, overlay, read, write


def main():
    files = {p.stem: p for p in Path("C:/Program Files/QuackSlicer/resources/profiles/BBL").rglob("*.json")}

    def load(name):
        data = read(files[name])
        base = load(data["inherits"]) if data.get("inherits") else {}
        for included in data.get("include", []):
            base = overlay(base, load(included))
        return {k: v for k, v in overlay(base, data).items() if k not in {"include", "inherits"}}

    def validate(height):
        profile = OUT / f"{height}mm Optimized @BBL P2S - Awesome AI.json"
        preset = read(profile)
        resolved = overlay(load(preset["inherits"]), preset)
        resolved.pop("inherits", None)
        tag = "020" if height == "0.2" else "012"
        folder = OUT / f"validation/quack-{tag}"
        (folder / "data").mkdir(parents=True, exist_ok=True)
        flat = folder / "resolved-deliverable.json"
        write(flat, resolved)
        command = ["C:/Program Files/QuackSlicer/quack-slicer.exe", str(ENCLOSURE / "fit_coupon.stl"),
                   "--datadir", str(folder / "data"), "--debug", "2", "--curr-bed-type", "Textured PEI Plate",
                   "--slice", "0", "--outputdir", str(folder), "--export-3mf", "validation.3mf",
                   "--load-settings", str(ENCLOSURE / "profiles/p2s-machine.json") + ";" + str(flat),
                   "--load-filaments", str(ENCLOSURE / "profiles/petg-filament.json")]
        started = time.time()
        process = subprocess.run(command, capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW, timeout=180)
        invocation = {"command": command, "returncode": process.returncode, "seconds": time.time() - started,
                      "stdout": process.stdout.decode(errors="replace"), "stderr": process.stderr.decode(errors="replace")}
        write(folder / "invocation.json", invocation)
        if process.returncode:
            return {"profile": profile.name, "passed": False, "returncode": process.returncode,
                    "error": invocation["stderr"][-1800:], "stdout": invocation["stdout"][-1200:]}
        with zipfile.ZipFile(folder / "validation.3mf") as archive:
            assert archive.testzip() is None
            actual = json.loads(archive.read("Metadata/project_settings.config"))
            gcode_names = [n for n in archive.namelist() if n.endswith(".gcode")]
            assert gcode_names
            gcode = "\n".join(archive.read(n).decode(errors="replace") for n in gcode_names)
        checked = {}

        def normal(value):
            if isinstance(value, list):
                return tuple(normal(x) for x in value)
            try:
                return float(str(value).rstrip("%"))
            except ValueError:
                return value

        for key in set(SURFACE_KEYS) | set(PRESERVED_KEYS) | {
            "layer_height", "top_shell_layers", "bottom_shell_layers", "bottom_surface_pattern",
            "top_shell_thickness", "bottom_shell_thickness", "enable_arc_fitting", "prime_tower_flat_ironing"
        }:
            if key not in preset:
                continue
            expected, result = normal(preset[key]), normal(actual[key])
            if not isinstance(expected, tuple) and isinstance(result, tuple):
                expected = (expected,) * len(result)
            if isinstance(expected, tuple) and not isinstance(result, tuple):
                result = (result,) * len(expected)
            assert expected == result, (profile.name, key, expected, result)
            checked[key] = actual[key]
        assert "G1" in gcode and ("Top surface" in gcode or "Top Surface" in gcode)
        result = {"profile": profile.name, "sha256": hashlib.sha256(profile.read_bytes()).hexdigest(),
                  "passed": True, "native_slicer": "Installed QuackSlicer", "seconds": invocation["seconds"],
                  "verified_settings": checked, "gcode_members": gcode_names,
                  "method": "Resolve delivered JSON against installed native parent; native slice and exported-setting readback",
                  "gui_import_tested": False, "physical_print_tested": False}
        if (folder / "result.json").exists():
            result["native_result"] = read(folder / "result.json")
        return result

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(validate, ("0.2", "0.12")))
    report = {"passed": all(x["passed"] for x in results), "profiles": results,
              "compatibility_notes": [
                  "Quack uses 0 for automatic support-wall count; inherited native default retained, supports disabled.",
                  "Bambu reduce_infill_retraction_mode=Auto has no direct Quack boolean equivalent; native defaults retained.",
                  "Bambu executable failed to start with exit -2 and no diagnostic output on this host; native slicing uses Quack.",
                  "Coupon uses existing generic PETG validation input; delivered process files contain no filament settings."]}
    write(OUT / "validation-report.json", report)
    print(json.dumps({"passed": report["passed"], "profiles": [
        {k: p[k] for k in ("profile", "passed", "error", "stdout", "seconds") if k in p} for p in results]}, indent=2))
    if not report["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
