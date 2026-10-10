"""Add a flush white PETG lid inlay to the user's saved four-plate project.

The input archive is immutable. Unrelated ZIP entries, meshes, plate records,
object settings and instance transforms are preserved. Native slicing uses a
disposable copy because the installed Orca version predates the user's file.
"""
from __future__ import annotations

import argparse
from collections import Counter
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET
import zipfile

from package_orion_enclosure import read_stl, mesh_check, write_json

CORE = "http://schemas.microsoft.com/3dmanufacturing/core/2015/02"
PROD = "http://schemas.microsoft.com/3dmanufacturing/production/2015/06"
BBL = "http://schemas.bambulab.com/package/2021"
REL = "http://schemas.openxmlformats.org/package/2006/relationships"
for prefix, uri in (("", CORE), ("p", PROD), ("BambuStudio", BBL)):
    ET.register_namespace(prefix, uri)
ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "hardware/altium-r5/enclosure/sealed-print"
SOURCE = FOLDER / "Orion-R5-P2S-complete.3mf"
OUTPUT = FOLDER / "Orion-R5-P2S-flush-colour.3mf"
ORCA = Path("C:/Program Files/OrcaSlicer/orca-slicer.exe")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def q(tag):
    return f"{{{CORE}}}{tag}"


def metas(element):
    return {m.get("key"): m.get("value") for m in element.findall("metadata") if m.get("key")}


def set_meta(element, key, value):
    match = next((m for m in element.findall("metadata") if m.get("key") == key), None)
    if match is None:
        match = ET.SubElement(element, "metadata", key=key)
    match.set("value", str(value))


def xml_bytes(root):
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def filament_keys():
    """Use installed filament-profile ownership, never array length alone."""
    profile_root = ORCA.parent / "resources/profiles/BBL"
    files = {p.stem: p for p in profile_root.rglob("*.json")}
    keys = set()

    def visit(name):
        data = json.loads(files[name].read_text(encoding="utf-8"))
        keys.update(data)
        if data.get("inherits"):
            visit(data["inherits"])
        for include in data.get("include", []):
            visit(include)

    for name in ("Generic PETG @BBL P2S", "Generic TPU @BBL P2S"):
        visit(name)
    keys -= {"type", "name", "inherits", "include", "from", "setting_id", "instantiation", "version", "compatible_printers"}
    keys.update({"filament_map", "filament_volume_map", "filament_nozzle_map", "filament_settings_id", "filament_ids", "filament_colour_type", "filament_multi_colour", "default_filament_colour", "filament_printable"})
    # Orca-only material fields, and newer P2S per-material cooling controls,
    # are not all present in the installed BBL inheritance chain.
    keys.update({"activate_air_filtration_during_print", "activate_air_filtration_on_completion",
                 "activate_chamber_temp_control", "adaptive_pressure_advance", "adaptive_pressure_advance_bridges",
                 "adaptive_pressure_advance_model", "adaptive_pressure_advance_overhangs", "chamber_minimal_temperature",
                 "chamber_temperature", "dont_slow_down_outer_wall", "enable_overhang_bridge_fan", "enable_pressure_advance",
                 "idle_temperature", "initial_layer_fan_speed", "internal_bridge_fan_speed", "ironing_fan_speed",
                 "pressure_advance", "support_material_interface_fan_speed", "textured_cool_plate_temp",
                 "textured_cool_plate_temp_initial_layer"})
    return keys


def extend_material(config, colour):
    before = copy.deepcopy(config)
    assert config["filament_type"] == ["PETG", "TPU"]
    owned = filament_keys()
    changed = []
    # Current P2S per-filament arrays are contiguous blocks, one or two extruder
    # variants per material. Clone PETG's entire block; retain both original
    # blocks exactly. Printer/process arrays are deliberately not touched.
    for key, value in list(config.items()):
        if key not in owned and not key.startswith("filament_"):
            continue
        if not isinstance(value, list) or not value or len(value) % 2:
            continue
        if key == "filament_map_2":
            continue
        count = len(value) // 2
        config[key] = value + copy.deepcopy(value[:count])
        changed.append(key)
    config["filament_colour"][-1] = colour
    for key in ("filament_multi_colour", "default_filament_colour"):
        if key in config:
            config[key][-1] = colour
    if "filament_colour_type" in config:
        config["filament_colour_type"][-1] = "1"
    if "filament_self_index" in config:
        config["filament_self_index"][-2:] = ["3", "3"]
    matrix = before["flush_volumes_matrix"]
    assert len(matrix) == 4
    config["flush_volumes_matrix"] = [matrix[0], matrix[1], "650", matrix[2], matrix[3], "650", "300", matrix[1], "0"]
    config["enable_prime_tower"] = "1"
    config["wipe_tower_x"][0] = "30"
    config["wipe_tower_y"][0] = "207"
    return {key: {"before": before.get(key), "after": value} for key, value in config.items() if value != before.get(key)}


def prepare(source, markings, output, colour):
    source_hash = sha(source.read_bytes())
    with zipfile.ZipFile(source) as z:
        payload = {n: z.read(n) for n in z.namelist()}
        infos = {n: z.getinfo(n) for n in z.namelist()}
    original = copy.deepcopy(payload)
    config = json.loads(payload["Metadata/project_settings.config"])
    settings = ET.fromstring(payload["Metadata/model_settings.config"])
    model = ET.fromstring(payload["3D/3dmodel.model"])
    resources = model.find(q("resources"))
    lid_settings = next(o for o in settings.findall("object") if metas(o).get("name") == "lid")
    lid_id = lid_settings.get("id")
    lid_obj = next(o for o in resources if o.get("id") == lid_id)
    components = lid_obj.find(q("components"))
    old_component = list(components)[0]
    body_path = old_component.get(f"{{{PROD}}}path").lstrip("/")
    body_model = ET.fromstring(payload[body_path])
    native_points = [tuple(float(v.get(k)) for k in "xyz") for v in body_model.findall(f".//{q('vertex')}")]
    source_points, source_faces = read_stl(FOLDER / "lid.stl")
    source_min = [min(p[i] for p in source_points) for i in range(3)]
    native_min = [min(p[i] for p in native_points) for i in range(3)]
    shift = [native_min[i] - source_min[i] for i in range(3)]
    points, faces = read_stl(markings)
    check = mesh_check(points, faces)
    assert check["passed"], check
    placed = [tuple(p[i] + shift[i] for i in range(3)) for p in points]
    maximum_id = max(int(o.get("id")) for path, data in payload.items() if path.endswith(".model") for o in ET.fromstring(data).findall(f".//{q('object')}"))
    part_id = str(maximum_id + 1)
    new_path = "3D/Objects/lid_flush_markings.model"
    new_model = ET.Element(q("model"), unit="millimeter")
    new_resources = ET.SubElement(new_model, q("resources"))
    obj = ET.SubElement(new_resources, q("object"), id=part_id, type="model")
    mesh = ET.SubElement(obj, q("mesh"))
    vs = ET.SubElement(mesh, q("vertices"))
    for p in placed:
        ET.SubElement(vs, q("vertex"), **{k: f"{p[i]:.10g}" for i, k in enumerate("xyz")})
    ts = ET.SubElement(mesh, q("triangles"))
    for f in faces:
        ET.SubElement(ts, q("triangle"), **{f"v{i + 1}": str(v) for i, v in enumerate(f)})
    ET.SubElement(components, q("component"), attrib={f"{{{PROD}}}path": "/" + new_path, "objectid": part_id, "transform": "1 0 0 0 1 0 0 0 1 0 0 0"})
    new_part = ET.SubElement(lid_settings, "part", id=part_id, subtype="normal_part")
    for key, value in {"name": "Flush white PETG - logo and lettering", "extruder": "3", "source_file": markings.name,
                       "matrix": "1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1", "source_object_id": "-1", "source_volume_id": "-1"}.items():
        set_meta(new_part, key, value)
    ET.SubElement(new_part, "mesh_stat", face_count=str(len(faces)), edges_fixed="0", degenerate_facets="0", facets_removed="0", facets_reversed="0", backwards_edges="0")
    changes = extend_material(config, colour)
    first_plate = settings.findall("plate")[0]
    set_meta(first_plate, "filament_maps", "1 1 1")
    set_meta(first_plate, "filament_volume_maps", "0 0 0")
    for md in list(first_plate.findall("metadata")):
        if md.get("key") in {"thumbnail_file", "thumbnail_no_light_file", "top_file", "pick_file"}:
            first_plate.remove(md)
    for md in list(model.findall(q("metadata"))):
        if md.get("name") in {"Thumbnail_Middle", "Thumbnail_Small"}:
            model.remove(md)
    rel_path = "3D/_rels/3dmodel.model.rels"
    relationships = ET.fromstring(payload[rel_path])
    ET.SubElement(relationships, f"{{{REL}}}Relationship", Target="/" + new_path,
                  Id="rel-lid-flush-colour", Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel")
    payload[new_path] = xml_bytes(new_model)
    # The slicer's Expat relationship parser expects unprefixed element names.
    # ElementTree otherwise writes ns0:Relationship (valid XML, unsupported by
    # this native parser), causing all externally referenced meshes to vanish.
    rel_xml = xml_bytes(relationships)
    payload[rel_path] = rel_xml.replace(b"ns0:", b"").replace(b"xmlns:ns0=", b"xmlns=")
    payload["3D/3dmodel.model"] = xml_bytes(model)
    payload["Metadata/model_settings.config"] = xml_bytes(settings)
    payload["Metadata/project_settings.config"] = json.dumps(config, indent=2).encode()
    # Force native regeneration only for the changed plate; the other plates'
    # thumbnails and their saved metadata are kept byte-for-byte.
    preview_names = ["Metadata/plate_1.png", "Metadata/plate_1_small.png", "Metadata/plate_no_light_1.png",
                     "Metadata/top_1.png", "Metadata/pick_1.png"]
    for name in preview_names:
        payload.pop(name, None)
    root_rels = ET.fromstring(payload["_rels/.rels"])
    for rel in list(root_rels):
        if rel.get("Target", "").lstrip("/") in preview_names:
            root_rels.remove(rel)
    payload["_rels/.rels"] = xml_bytes(root_rels).replace(b"ns0:", b"").replace(b"xmlns:ns0=", b"xmlns=")
    relationship_targets = []
    for name, data in payload.items():
        if name.endswith(".rels"):
            for rel in ET.fromstring(data):
                target = rel.get("Target", "").lstrip("/")
                assert target in payload, (name, target)
                relationship_targets.append(target)
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as z:
        for name, data in payload.items():
            if name in infos:
                z.writestr(infos[name], data)
            else:
                z.writestr(name, data)
    if sha(source.read_bytes()) != source_hash:
        raise ValueError("Source project changed during preparation")
    report = {"source_sha256": source_hash, "source_size": source.stat().st_size,
              "output": str(output), "output_sha256": sha(output.read_bytes()), "new_part_id": part_id,
              "original_lid_object_id": lid_id, "original_lid_mesh_path": body_path,
              "original_lid_mesh_sha256": sha(original[body_path]), "original_lid_mesh_byte_identical": payload[body_path] == original[body_path],
              "markings_source_sha256": sha(markings.read_bytes()), "markings_mesh": check,
              "source_stl_to_native_local_translation_mm": shift, "project_setting_changes": changes,
              "plate_count": len(settings.findall("plate")), "build_object_count": len(model.find(q("build"))),
              "unchanged_zip_entries": [n for n in original if payload.get(n) == original[n]],
              "changed_zip_entries": [n for n in original if n in payload and payload[n] != original[n]], "added_zip_entries": [new_path],
              "removed_stale_plate_1_preview_entries": preview_names,
              "internal_relationship_targets_exist": True, "relationship_targets": relationship_targets,
              "original_project_preserved": True, "native_slicing": None}
    old_settings = ET.fromstring(original["Metadata/model_settings.config"])
    for a, b in zip(old_settings.findall("plate")[1:], settings.findall("plate")[1:]):
        assert xml_bytes(a) == xml_bytes(b), "User plate metadata changed"
    old_model = ET.fromstring(original["3D/3dmodel.model"])
    assert xml_bytes(old_model.find(q("build"))) == xml_bytes(model.find(q("build"))), "User instance transforms changed"
    for a, b in zip(old_settings.findall("object"), settings.findall("object")):
        if a.get("id") != lid_id:
            assert xml_bytes(a) == xml_bytes(b), "Other object settings changed"
    report["all_build_transforms_unchanged"] = True
    report["test_plates_and_other_object_settings_unchanged"] = True
    return report


def invoke_orca(project, output_dir, name, plate="0"):
    output_dir.mkdir(parents=True, exist_ok=True)
    command = [str(ORCA), str(project), "--allow-newer-file", "--raft-first-layer-expansion", "0", "--tree-support-wall-count", "0",
               "--slice", str(plate), "--debug", "2", "--outputdir", str(output_dir), "--export-3mf", name]
    started = time.time()
    result = subprocess.run(command, creationflags=subprocess.CREATE_NO_WINDOW, capture_output=True, timeout=900)
    invocation = {"command": command, "returncode": result.returncode, "elapsed_seconds": time.time() - started,
                  "stdout": result.stdout.decode(errors="replace"), "stderr": result.stderr.decode(errors="replace"),
                  "compatibility_overrides": {"raft_first_layer_expansion": "0", "tree_support_wall_count": "0"},
                  "overrides_applied_only_to_disposable_output": True}
    write_json(output_dir / "invocation.json", invocation)
    if result.returncode:
        raise RuntimeError(f"Orca slicing failed; see {output_dir / 'invocation.json'}")
    return output_dir / name, invocation


def verify_native(native, output, report):
    """Check the native round trip and actual deposited paths, not just metadata."""
    with zipfile.ZipFile(native) as z:
        slice_info = ET.fromstring(z.read("Metadata/slice_info.config"))
        plates = []
        for i, plate in enumerate(slice_info.findall("plate"), 1):
            md = metas(plate)
            assert md["outside"] == "false"
            assert md["support_used"] == "false"
            code = z.read(f"Metadata/plate_{i}.gcode").decode()
            plate_result = {"plate": i, "gcode_sha256": sha(code.encode()),
                            "gcode_bytes": len(code), "filaments": [x.attrib for x in plate.findall("filament")],
                            "layer_filament_lists": [x.attrib for x in plate.findall("layer_filament_lists/layer_filament_list")],
                            "warnings": [x.attrib for x in plate.findall("warning")],
                            "outside": False, "support_used": False,
                            "temperature_commands": sorted(set(line.strip() for line in code.splitlines()
                                    if re.match(r"^\s*(M140|M190|M104|M109)\s", line)))}
            plates.append(plate_result)
            if i == 1:
                tool, layer, current_object = 0, None, None
                deposition = Counter()
                for line in code.splitlines():
                    if line.startswith("; Z_HEIGHT:"):
                        layer = float(line.split(":", 1)[1])
                    match = re.match(r"^T(\d+)$", line.strip())
                    if match:
                        tool = int(match[1])
                    if line.startswith("; printing object "):
                        current_object = line[len("; printing object "):].split(" id:")[0]
                    if line.startswith("; stop printing object"):
                        current_object = None
                    if current_object == "lid" and re.match(r"G[123] ", line) and re.search(r"[XY][-+.]?\d", line):
                        extrusion = re.search(r"\bE([-+.\d]+)", line)
                        if extrusion and float(extrusion[1]) > 0:
                            deposition[(tool, layer)] += 1
                white_layers = sorted({layer for (tool, layer) in deposition if tool == 2})
                assert white_layers == [0.2, 0.4], white_layers
                assert all(deposition[(0, layer)] > 0 for layer in white_layers)
                assert {int(f["id"]) for f in plate_result["filaments"]} == {1, 3}
                plate_result["lid_positive_xy_extrusion_moves"] = [
                    {"slot": tool + 1, "z_mm": layer, "moves": n}
                    for (tool, layer), n in sorted(deposition.items())]
                plate_result["white_deposition_only_first_two_layers"] = True
                layout = json.loads(z.read("Metadata/plate_1.json"))
                tower = next(o for o in layout["bbox_objects"] if o["name"] == "wipe_tower")["bbox"]
                assert all(0 <= v <= 256 for v in tower)
                for obj in layout["bbox_objects"]:
                    if obj["name"] == "wipe_tower":
                        continue
                    box = obj["bbox"]
                    assert tower[2] <= box[0] or box[2] <= tower[0] or tower[3] <= box[1] or box[3] <= tower[1]
                plate_result["prime_tower_bbox_mm"] = tower
                plate_result["prime_tower_inside_bed_clear_of_objects"] = True
        assert len(plates) == 4
        assert [len(p["filaments"]) for p in plates] == [2, 1, 1, 1]
        native_settings = ET.fromstring(z.read("Metadata/model_settings.config"))
        native_lid = next(o for o in native_settings.findall("object") if metas(o).get("name") == "lid")
        native_parts = native_lid.findall("part")
        assert len(native_parts) == 2
        assert metas(native_parts[1])["extruder"] == "3"
        assert all(int(v) == 0 for p in native_settings.findall("object/part")
                   for k, v in p.find("mesh_stat").attrib.items() if k != "face_count")

        def lid_world_meshes(archive):
            settings = ET.fromstring(archive.read("Metadata/model_settings.config"))
            root_model = ET.fromstring(archive.read("3D/3dmodel.model"))
            lid = next(o for o in settings.findall("object") if metas(o).get("name") == "lid")
            obj = next(o for o in root_model.find(q("resources")) if o.get("id") == lid.get("id"))
            item = next(i for i in root_model.find(q("build")) if i.get("objectid") == lid.get("id"))
            result = []
            for comp in obj.find(q("components")):
                model = ET.fromstring(archive.read(comp.get(f"{{{PROD}}}path").lstrip("/")))
                mesh = next(o for o in model.find(q("resources")) if o.get("id") == comp.get("objectid")).find(q("mesh"))
                points = [tuple(float(v.get(k)) for k in "xyz") for v in mesh.find(q("vertices"))]
                faces = [tuple(int(t.get(f"v{k}")) for k in (1, 2, 3)) for t in mesh.find(q("triangles"))]
                for element in (comp, item):
                    m = [float(v) for v in element.get("transform", "1 0 0 0 1 0 0 0 1 0 0 0").split()]
                    points = [tuple(sum(p[j] * m[j * 3 + k] for j in range(3)) + m[9 + k] for k in range(3)) for p in points]
                result.append((points, faces))
            return result

        with zipfile.ZipFile(output) as target:
            expected = lid_world_meshes(target)
            actual = lid_world_meshes(z)
        geometry = []
        for name, (ep, ef), (ap, af) in zip(("original lid body", "flush markings"), expected, actual):
            assert len(ep) == len(ap) and ef == af
            error = max(abs(a - b) for p, p2 in zip(ep, ap) for a, b in zip(p, p2))
            assert error < 0.00005, (name, error)
            geometry.append({"part": name, "vertices": len(ep), "triangles": len(ef),
                             "triangle_indices_identical": True, "maximum_world_vertex_error_mm": error,
                             "tolerance_mm": 0.00005, "passed": True})
        report["native_lid_roundtrip_geometry"] = geometry
        report["native_slice_qa"] = plates
        report["no_native_mesh_repair"] = True
        report["preview_cache"] = {"changed_plate_1": "Stale images removed. Older Windows CLI did not regenerate images; live geometry is authoritative.",
                                   "plates_2_to_4": "Original preview images retained byte-for-byte."}
        report["final_contains_cached_gcode"] = False
        report["native_toolpaths"] = "Disposable validation output only; final project retains newer saved settings and is ready to slice in the user's slicer."
        report["output_sha256"] = sha(output.read_bytes())
        report["passed"] = True
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--markings", type=Path, default=FOLDER / "flush-colour/lid_markings.stl")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--colour", default="#F5F5F2")
    parser.add_argument("--slice", action="store_true")
    args = parser.parse_args()
    report = prepare(args.source, args.markings, args.output, args.colour)
    artifact_dir = args.output.parent / "flush-colour"
    report_path = artifact_dir / "project-preservation-validation.json"
    write_json(report_path, report)
    if args.slice:
        native, invocation = invoke_orca(args.output.resolve(), artifact_dir.resolve() / "native-validation", "disposable-native.3mf")
        report["native_slicing"] = invocation
        report["native_slicing"]["output"] = str(native)
        report = verify_native(native, args.output, report)
        write_json(report_path, report)
    print(json.dumps({"output": str(args.output), "parts": report["build_object_count"], "plates": report["plate_count"], "source_unchanged": True}))


if __name__ == "__main__":
    main()
