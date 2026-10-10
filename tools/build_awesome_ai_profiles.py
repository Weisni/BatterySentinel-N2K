"""Build importable P2S process presets from the proven enclosure and Smooth Surface.

Only process settings are exported; printer and filament presets stay independent.
The source snapshots and field-by-field comparison make the merge reproducible.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ENCLOSURE = ROOT / "hardware/altium-r5/enclosure/sealed-print"
OUT = ENCLOSURE / "awesome-ai-profiles"
SYSTEM = Path("C:/Program Files/Bambu Studio/resources/profiles/BBL")
META = {"name", "from", "type", "setting_id", "instantiation", "description",
        "version", "print_settings_id", "inherits", "include"}
SURFACE_KEYS = ("top_surface_speed", "top_surface_acceleration", "top_surface_line_width",
                "top_surface_pattern", "top_surface_density", "top_solid_infill_flow_ratio",
                "wall_generator", "min_bead_width", "wall_transition_angle", "ironing_type",
                "ironing_flow", "ironing_inset", "ironing_spacing", "ironing_speed")
PRESERVED_KEYS = ("wall_loops", "sparse_infill_density", "sparse_infill_pattern",
                  "initial_layer_print_height", "initial_layer_speed", "initial_layer_infill_speed",
                  "outer_wall_speed", "inner_wall_speed", "sparse_infill_speed",
                  "internal_solid_infill_speed", "bridge_speed", "default_acceleration",
                  "outer_wall_acceleration", "seam_position", "elefant_foot_compensation",
                  "enable_support", "brim_type", "enable_prime_tower")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def overlay(parent, child):
    result = dict(parent)
    for key, value in child.items():
        if isinstance(value, list) and "nil" in value:
            inherited = parent[key]
            assert isinstance(inherited, list) and len(inherited) == len(value), key
            value = [inherited[i] if v == "nil" else v for i, v in enumerate(value)]
        result[key] = value
    return result


def build():
    files = {p.stem: p for p in SYSTEM.rglob("*.json")}
    used = {}

    def load(name, stack=()):
        assert name not in stack, name
        path = files[name]
        used[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()
        data = read(path)
        merged = load(data["inherits"], stack + (name,)) if data.get("inherits") else {}
        for include in data.get("include", []):
            merged = overlay(merged, load(include, stack + (name,)))
        return {k: v for k, v in overlay(merged, data).items() if k not in {"inherits", "include"}}

    original = load("0.20mm Standard @BBL P2S")
    fine_original = load("0.12mm High Quality @BBL P2S")
    smooth_path = OUT / "sources/bambu-smooth-020.json"
    smooth_delta = read(smooth_path)
    smooth = overlay(original, smooth_delta)
    enclosure_path = ENCLOSURE / "profiles/enclosure-process.json"
    enclosure = read(enclosure_path)
    project_path = ENCLOSURE / "Orion-R5-P2S-flush-colour.3mf"
    with zipfile.ZipFile(project_path) as archive:
        current = json.loads(archive.read("Metadata/project_settings.config"))
    # The colour revision enables the tower; all other deliberate core overrides
    # still match the original enclosure process. No material data is imported.
    enclosure["enable_prime_tower"] = current["enable_prime_tower"]
    for key in PRESERVED_KEYS:
        assert enclosure[key] == current[key], (key, enclosure[key], current[key])

    merged = {k: v for k, v in enclosure.items() if k not in META}
    for key in SURFACE_KEYS:
        if key in smooth:
            merged[key] = smooth[key]
    # Smooth's High Flow entries are nil (unchanged factory values). Apply the
    # selected Standard surface settings to both variants, never reintroduce
    # factory 200 mm/s top surfaces into the conservative High Flow profile.
    for key in ("top_surface_speed", "top_surface_acceleration", "top_solid_infill_flow_ratio"):
        value = merged[key]
        merged[key] = [value[0], value[0]] if isinstance(value, list) else [value, value]

    report = {
        "source_selection": "Bambu Studio regular/account QuackSlicer copy; other same-name copies differ",
        "physical_evidence": "User reports excellent enclosure print except surface finish; merged profiles not printed yet",
        "sources": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in (smooth_path, enclosure_path, project_path)},
        "surface_keys": list(SURFACE_KEYS),
        "high_flow_policy": "Copy Standard surface values into both nozzle variants; source nil is inheritance, not zero",
        "preserved_core_keys": list(PRESERVED_KEYS),
        "profiles": [],
    }
    write(OUT / "sources/original-020-resolved.json", original)
    write(OUT / "sources/original-012-resolved.json", fine_original)
    write(OUT / "sources/smooth-020-resolved.json", smooth)

    for height, parent, parent_config, layers in (
        ("0.2", "0.20mm Standard @BBL P2S", original, "6"),
        ("0.12", "0.12mm High Quality @BBL P2S", fine_original, "10"),
    ):
        name = f"{height}mm Optimized @BBL P2S - Awesome AI"
        target = dict(merged)
        target.update(layer_height=height, top_shell_layers=layers, bottom_shell_layers=layers)
        if height == "0.12":
            target.update(top_shell_thickness="1.2", bottom_shell_thickness="1.2")
            # When support is manually enabled later, retain fine-layer contact
            # gaps rather than silently inheriting the .20-mm process gaps.
            for key in ("support_top_z_distance", "support_bottom_z_distance"):
                target[key] = fine_original[key]
        metadata = {"type": "process", "name": name, "print_settings_id": name,
                    "from": "User", "version": smooth_delta["version"]}
        preset = {**metadata, "inherits": parent}
        preset.update({k: v for k, v in target.items() if parent_config.get(k) != v})
        for key in ("compatible_printers", "print_extruder_id", "print_extruder_variant"):
            preset[key] = target[key]
        # Pin deliberate choices, even when the current parent happens to agree.
        for key in sorted(set(SURFACE_KEYS) | set(PRESERVED_KEYS) | {
            "layer_height", "top_shell_layers", "bottom_shell_layers", "top_shell_thickness", "bottom_shell_thickness",
            "bottom_surface_pattern", "enable_arc_fitting", "prime_tower_flat_ironing"
        }):
            if key in target:
                preset[key] = target[key]
        reconstructed = overlay(parent_config, preset)
        for key, value in target.items():
            assert reconstructed[key] == value, key
        for key in PRESERVED_KEYS:
            assert target[key] == enclosure[key], key
        assert float(height) * int(layers) >= 1.2 - 1e-9
        assert target["initial_layer_print_height"] == "0.2"
        assert all("nil" not in v for v in target.values() if isinstance(v, list))
        assert not any(k.startswith(("filament_", "machine_")) or k.endswith("gcode") for k in preset)
        write(OUT / (name + ".json"), preset)
        write(OUT / "validation-input" / (name + ".json"), {**target, **metadata})
        comparison = {k: {"original": original.get(k), "smooth_surface": smooth.get(k),
                          "enclosure": enclosure.get(k), "merged": target.get(k)}
                      for k in sorted(set(original) | set(smooth) | set(enclosure) | set(target))
                      if k not in META}
        report["profiles"].append({"name": name, "inherits": parent,
                                   "file": name + ".json", "layer_height": height,
                                   "top_bottom_layers": layers,
                                   "comparison": comparison})
    write(OUT / "sources/system-profile-sha256.json", used)
    write(OUT / "comparison.json", report)
    print(json.dumps({"output": str(OUT), "profiles": [p["file"] for p in report["profiles"]],
                      "checks": "inheritance roundtrip, core preservation, shell thickness, no material or machine overrides passed"}))


if __name__ == "__main__":
    build()
