"""Package print-oriented enclosure STL parts as a P2S PETG/TPU project.

Input manifest: {"parts": [{"name": "...", "material": "PETG" or "TPU",
"path": "relative-to-manifest.stl", "quantity": 1}]}. Parts are already in
their intended printing orientation. This helper only translates them.

The prepared project has separate material plates. --slice asks the installed
Bambu Studio CLI to validate and re-export it, retaining editable meshes and
the native plate previews/toolpaths. It never sends a print to a printer.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import struct
import subprocess
import time
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PROFILES = Path("C:/Program Files/Bambu Studio/resources/profiles/BBL")
SLICER = Path("C:/Program Files/Bambu Studio/bambu-studio.exe")
CORE = "http://schemas.microsoft.com/3dmanufacturing/core/2015/02"
ET.register_namespace("", CORE)
BED = 256.0
MARGIN = 18.0
SPACING = 10.0
MATERIALS = ("PETG", "TPU")


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def read_stl(path):
    data = path.read_bytes()
    triangles = []
    if len(data) >= 84 and len(data) == 84 + 50 * struct.unpack_from("<I", data, 80)[0]:
        for pos in range(84, len(data), 50):
            f = struct.unpack_from("<12f", data, pos)
            triangles.append([f[3:6], f[6:9], f[9:12]])
    else:
        vertices = []
        for line in data.decode("ascii").splitlines():
            items = line.split()
            if items and items[0] == "vertex":
                vertices.append(tuple(map(float, items[1:4])))
        if len(vertices) % 3:
            raise ValueError(f"Malformed STL: {path}")
        triangles = [vertices[i:i + 3] for i in range(0, len(vertices), 3)]
    if not triangles:
        raise ValueError(f"Empty STL: {path}")
    points, faces, lookup = [], [], {}
    for triangle in triangles:
        face = []
        for point in triangle:
            # Preserve the STL coordinates exactly; identical STL vertices weld.
            point = tuple(point)
            if not all(math.isfinite(v) for v in point):
                raise ValueError(f"Non-finite STL coordinate: {path}")
            if point not in lookup:
                lookup[point] = len(points)
                points.append(point)
            face.append(lookup[point])
        faces.append(face)
    return points, faces


def mesh_check(points, faces):
    edges, directions = Counter(), Counter()
    volume = 0.0
    degenerate = 0
    for f in faces:
        a, b, c = (points[i] for i in f)
        ab, ac = [b[i] - a[i] for i in range(3)], [c[i] - a[i] for i in range(3)]
        cross = (ab[1] * ac[2] - ab[2] * ac[1], ab[2] * ac[0] - ab[0] * ac[2], ab[0] * ac[1] - ab[1] * ac[0])
        degenerate += sum(x * x for x in cross) < 1e-20
        volume += (a[0] * (b[1] * c[2] - b[2] * c[1]) + a[1] * (b[2] * c[0] - b[0] * c[2]) + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
        for i, j in ((f[0], f[1]), (f[1], f[2]), (f[2], f[0])):
            edges[tuple(sorted((i, j)))] += 1
            directions[(i, j)] += 1
    bad = sum(v != 2 for v in edges.values())
    inconsistent = sum(directions[(a, b)] != 1 or directions[(b, a)] != 1 for a, b in edges)
    bounds = [[min(p[i] for p in points) for i in range(3)], [max(p[i] for p in points) for i in range(3)]]
    return {"vertices": len(points), "triangles": len(faces), "nonmanifold_edges": bad,
            "inconsistent_edges": inconsistent, "degenerate_triangles": degenerate,
            "signed_volume_mm3": volume, "bounds_mm": bounds,
            "passed": bad == inconsistent == degenerate == 0 and volume > 0}


def flatten_profiles(profile_root):
    files = {p.stem: p for p in profile_root.rglob("*.json")}
    used = {}

    def load(name, ancestors=()):
        if name in ancestors:
            raise ValueError("Profile inheritance cycle")
        path = files[name]
        used[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()
        data = json.loads(path.read_text(encoding="utf-8"))
        result = {}
        if data.get("inherits"):
            result.update(load(data["inherits"], ancestors + (name,)))
        for included in data.get("include", []):
            result.update(load(included, ancestors + (name,)))
        result.update(data)
        result.pop("inherits", None)
        result.pop("include", None)
        return result

    machine = load("Bambu Lab P2S 0.4 nozzle")
    process = load("0.20mm Standard @BBL P2S")
    process.update({"name": "Orion marine prototype 0.20mm P2S", "from": "User",
                    "wall_loops": "5", "top_shell_layers": "6", "bottom_shell_layers": "6",
                    "sparse_infill_density": "35%", "sparse_infill_pattern": "gyroid",
                    "enable_support": "0", "enable_prime_tower": "0", "brim_type": "no_brim",
                    "initial_layer_speed": ["20", "20"], "initial_layer_infill_speed": ["25", "25"],
                    "outer_wall_speed": ["40", "40"], "inner_wall_speed": ["80", "80"],
                    "top_surface_speed": ["35", "35"], "sparse_infill_speed": ["100", "100"],
                    "internal_solid_infill_speed": ["80", "80"], "bridge_speed": ["25", "25"],
                    "default_acceleration": ["3000", "3000"], "outer_wall_acceleration": ["1000", "1000"],
                    "seam_position": "aligned", "elefant_foot_compensation": "0.1"})
    filaments = [load("Generic PETG @BBL P2S"), load("Generic TPU @BBL P2S")]
    for filament, colour in zip(filaments, ["#2A414A", "#58BFB5"]):
        filament["filament_colour"] = [colour]
    # Conservative starting volumetric caps; retain the official P2S temperatures.
    filaments[0]["filament_max_volumetric_speed"] = ["8", "8"]
    filaments[1]["filament_max_volumetric_speed"] = ["2", "2"]
    return machine, process, filaments, used


def arrange(parts, separate_materials=True):
    plates = []
    for material in MATERIALS if separate_materials else ("ALL",):
        selected = [p for p in parts if not separate_materials or p["material"] == material]
        if not selected:
            continue
        plate = {"material": material, "parts": []}
        x, y, row_height = MARGIN, MARGIN, 0.0
        for part in sorted(selected, key=lambda p: (-p["size"][1], -p["size"][0], p["name"])):
            w, h, _ = part["size"]
            if w > BED - 2 * MARGIN or h > BED - 2 * MARGIN:
                raise ValueError(f"Part exceeds P2S usable layout: {part['name']}")
            if x + w > BED - MARGIN:
                x, y, row_height = MARGIN, y + row_height + SPACING, 0.0
            if y + h > BED - MARGIN:
                plates.append(plate)
                plate = {"material": material, "parts": []}
                x, y, row_height = MARGIN, MARGIN, 0.0
            part["position"] = [x, y]
            plate["parts"].append(part)
            x += w + SPACING
            row_height = max(row_height, h)
        if plate["parts"]:
            plates.append(plate)
    for index, plate in enumerate(plates):
        cols = math.ceil(math.sqrt(len(plates)))
        plate["index"] = index + 1
        plate["origin"] = [(index % cols) * BED * 1.2, -(index // cols) * BED * 1.2]
        # Center the complete layout while keeping every part's print orientation.
        xmax = max(p["position"][0] + p["size"][0] for p in plate["parts"])
        ymax = max(p["position"][1] + p["size"][1] for p in plate["parts"])
        dx, dy = (BED - xmax - MARGIN) / 2, (BED - ymax - MARGIN) / 2
        for part in plate["parts"]:
            part["position"][0] += dx
            part["position"][1] += dy
            part["plate"] = index + 1
    return plates


def q(tag):
    return f"{{{CORE}}}{tag}"


def metadata(parent, **values):
    for key, value in values.items():
        ET.SubElement(parent, "metadata", key=key, value=str(value))


def create_project(path, plates, machine, process, filaments, manifest, portable=False):
    model = ET.Element(q("model"), unit="millimeter", attrib={"{http://www.w3.org/XML/1998/namespace}lang": "en-US"})
    ET.SubElement(model, q("metadata"), name="Application").text = "Orion enclosure packaging helper" if portable else "BambuStudio-02.07.01.57"
    ET.SubElement(model, q("metadata"), name="Title").text = "Orion R5 boat enclosure prototype"
    if not portable:
        ET.SubElement(model, q("metadata"), name="BambuStudio:3mfVersion").text = "1"
    resources, build = ET.SubElement(model, q("resources")), ET.SubElement(model, q("build"))
    settings = ET.Element("config")
    next_id = 1
    for plate in plates:
        for part in plate["parts"]:
            object_id = next_id
            next_id += 1
            part["object_id"] = object_id
            obj = ET.SubElement(resources, q("object"), id=str(object_id), type="model", name=part["name"])
            mesh = ET.SubElement(obj, q("mesh"))
            vertices = ET.SubElement(mesh, q("vertices"))
            minimum = part["check"]["bounds_mm"][0]
            for point in part["points"]:
                ET.SubElement(vertices, q("vertex"), **{k: f"{point[i] - minimum[i]:.8g}" for i, k in enumerate("xyz")})
            triangles = ET.SubElement(mesh, q("triangles"))
            for face in part["faces"]:
                ET.SubElement(triangles, q("triangle"), **{f"v{i + 1}": str(v) for i, v in enumerate(face)})
            x, y = part["position"]
            if not portable or len(plates) > 1:
                x += plate["origin"][0]
                y += plate["origin"][1]
            ET.SubElement(build, q("item"), objectid=str(object_id), transform=f"1 0 0 0 1 0 0 0 1 {x:.6f} {y:.6f} 0", printable="1")
            obj_settings = ET.SubElement(settings, "object", id=str(object_id))
            metadata(obj_settings, name=part["name"], extruder=MATERIALS.index(part["material"]) + 1)
            if part["material"] == "TPU":
                metadata(obj_settings, sparse_infill_density="100%", sparse_infill_pattern="cubic",
                         wall_loops="3", top_shell_layers="6", bottom_shell_layers="6",
                         outer_wall_speed="25,25", inner_wall_speed="30,30", top_surface_speed="25,25",
                         internal_solid_infill_speed="30,30", sparse_infill_speed="30,30")
            part_settings = ET.SubElement(obj_settings, "part", id=str(object_id), subtype="normal_part")
            metadata(part_settings, name=part["name"], source_file=Path(part["path"]).name)
            ET.SubElement(part_settings, "mesh_stat", face_count=str(len(part["faces"])), edges_fixed="0", degenerate_facets="0", facets_removed="0", facets_reversed="0", backwards_edges="0")
    for plate in plates:
        p = ET.SubElement(settings, "plate")
        title = "PETG rigid enclosure" if plate["material"] == "PETG" else "TPU 95A seals - external spool"
        metadata(p, plater_id=plate["index"], plater_name=title, locked="false")
        for part in plate["parts"]:
            instance = ET.SubElement(p, "model_instance")
            metadata(instance, object_id=part["object_id"], instance_id="0", identify_id=part["object_id"])
    ET.SubElement(settings, "assemble")
    ignored = {"name", "type", "from", "instantiation", "setting_id", "description", "version", "compatible_printers", "filament_id"}
    config = {k: v for d in [machine, process] for k, v in d.items() if k not in ignored}
    for key in set(filaments[0]) | set(filaments[1]):
        if key in ignored:
            continue
        v0, v1 = filaments[0].get(key), filaments[1].get(key)
        if isinstance(v0, list) and isinstance(v1, list):
            # These values seed the two filament slots. The native CLI imports
            # the complete per-filament profiles before creating the deliverable;
            # P2S extruder-variant metadata must be resolved by Bambu Studio.
            config[key] = v0 + v1
    config.update({"printer_settings_id": machine["name"], "print_settings_id": process["name"],
                   "filament_settings_id": [f["name"] for f in filaments], "filament_ids": [f["filament_id"] for f in filaments],
                   "filament_map": ["1", "1"], "filament_volume_map": ["0", "0"],
                   "curr_bed_type": "Textured PEI Plate", "inherits_group": ["", "", "", ""],
                   "different_settings_to_system": ["", "", "", ""]})
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/><Default Extension="config" ContentType="application/xml"/><Default Extension="json" ContentType="application/json"/></Types>')
        z.writestr("_rels/.rels", '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
        z.writestr("3D/3dmodel.model", ET.tostring(model, encoding="utf-8", xml_declaration=True))
        if not portable:
            z.writestr("Metadata/model_settings.config", ET.tostring(settings, encoding="utf-8", xml_declaration=True))
            z.writestr("Metadata/project_settings.config", json.dumps(config, indent=2))
            z.writestr("Metadata/orion_manifest.json", json.dumps(manifest, indent=2))


def run_slicer(slicer, project, outputdir, outputname, machine_path=None, process_path=None, filament_paths=None):
    outputdir.mkdir(parents=True, exist_ok=True)
    result_file = outputdir / "result.json"
    if result_file.exists():
        result_file.unlink()
    command = [str(slicer), str(project), "--debug", "2", "--curr-bed-type", "Textured PEI Plate", "--slice", "0",
               "--outputdir", str(outputdir), "--export-3mf", outputname]
    if machine_path:
        command += ["--load-settings", str(machine_path) + ";" + str(process_path),
                    "--load-filaments", ";".join(map(str, filament_paths))]
    start = time.time()
    kwargs = {"creationflags": subprocess.CREATE_NO_WINDOW} if hasattr(subprocess, "CREATE_NO_WINDOW") else {}
    result = subprocess.run(command, capture_output=True, timeout=900, **kwargs)
    data = json.loads(result_file.read_text()) if result_file.exists() else {}
    data.update({"process_return_code": result.returncode, "elapsed_seconds": round(time.time() - start, 2), "command": command})
    write_json(outputdir / "native-slice-validation.json", data)
    if result.returncode != 0 or data.get("return_code") != 0:
        raise RuntimeError(f"Native slicing failed: {data.get('error_string', result.returncode)}; see {outputdir}")
    return data


def verify_native(project, expected_parts, expected_plates):
    with zipfile.ZipFile(project) as z:
        bad = z.testzip()
        if bad:
            raise ValueError(f"3MF ZIP CRC failed: {bad}")
        config = json.loads(z.read("Metadata/project_settings.config"))
        settings = ET.fromstring(z.read("Metadata/model_settings.config"))
        plates = settings.findall("plate")
        objects = settings.findall("object")
        if len(objects) != expected_parts or len(plates) != expected_plates:
            raise ValueError("Native 3MF changed expected object/plate count")
        stats = []
        material_ids = {int(o.get("id")): int(next(m.get("value") for m in o.findall("metadata") if m.get("key") == "extruder")) for o in objects}
        for i, plate in enumerate(plates, 1):
            meta = {m.get("key"): m.get("value") for m in plate.findall("metadata")}
            gcode = z.read(meta["gcode_file"])
            if len(gcode) < 1000 or b"G1" not in gcode:
                raise ValueError(f"Plate {i} has no usable native toolpath")
            ids = {int(next(m.get("value") for m in inst.findall("metadata") if m.get("key") == "object_id")) for inst in plate.findall("model_instance")}
            slots = {material_ids[j] for j in ids}
            if len(slots) != 1:
                raise ValueError(f"Plate {i} mixes rigid and flexible materials")
            slot = slots.pop()
            expected_temp = (255, 240)[slot - 1]
            lines = gcode.decode("utf-8").splitlines()
            for key, expected in {"nozzle_temperature": (255, 240), "textured_plate_temp": (70, 35),
                                  "filament_max_volumetric_speed": (8, 2)}.items():
                line = next(s for s in lines if s.startswith(f"; {key} ="))
                values = list(map(float, line.split("=", 1)[1].strip().split(",")))
                if values[slot - 1] != expected[slot - 1]:
                    raise ValueError(f"Plate {i} has incorrect material setting: {line}")
            stats.append({"plate": i, "name": meta.get("plater_name"), "objects": len(plate.findall("model_instance")),
                          "gcode_bytes": len(gcode), "material": MATERIALS[slot - 1], "nozzle_temperature_c": expected_temp,
                          "bed_temperature_c": (70, 35)[slot - 1], "maximum_volumetric_speed_mm3_s": (8, 2)[slot - 1]})
        repairs = [dict(m.attrib) for m in settings.findall(".//mesh_stat") if any(int(m.get(k, "0")) != 0 for k in ("edges_fixed", "degenerate_facets", "facets_removed", "facets_reversed", "backwards_edges"))]
        if repairs:
            raise ValueError("Bambu Studio reported mesh repair")
        return {"zip_crc_passed": True, "printer": config.get("printer_settings_id"), "nozzle_diameter": config.get("nozzle_diameter"),
                "materials": config.get("filament_type"), "plates": stats, "mesh_repair_required": False,
                "sha256": hashlib.sha256(project.read_bytes()).hexdigest()}


def verify_native_geometry(project, manifest_path, tolerance_mm=0.00005):
    """Compare every native mesh with its STL, allowing translation/serialization.

    Check actual transformed coordinates and oriented triangle connectivity,
    rather than relying on mesh-stat metadata supplied to the slicer. Vertex
    matching uses a spatial grid and checks neighboring cells so rounding at a
    quantization boundary cannot hide or falsely report a geometry change.
    """
    manifest_path = Path(manifest_path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    sources = {}
    for part in manifest["parts"]:
        for copy in range(part.get("quantity", 1)):
            name = part["name"] + (f" {copy + 1}" if part.get("quantity", 1) > 1 else "")
            sources[name] = (manifest_path.parent / part["path"]).resolve()
    production = "http://schemas.microsoft.com/3dmanufacturing/production/2015/06"
    identity = [1., 0., 0., 0., 1., 0., 0., 0., 1.]
    rows = []

    def transform(points, value):
        m = list(map(float, value.split())) if value else identity + [0., 0., 0.]
        if len(m) != 12 or max(abs(a - b) for a, b in zip(m[:9], identity)) > 1e-10:
            raise ValueError("Native project introduced a rotation, mirror, scale, or shear")
        return [tuple(p[i] + m[9 + i] for i in range(3)) for p in points]

    def normalize(points):
        lo = [min(p[i] for p in points) for i in range(3)]
        return [tuple(p[i] - lo[i] for i in range(3)) for p in points]

    def cyclic(face):
        a, b, c = face
        return min((a, b, c), (b, c, a), (c, a, b))

    with zipfile.ZipFile(project) as z:
        settings = ET.fromstring(z.read("Metadata/model_settings.config"))
        names = {o.get("id"): next(m.get("value") for m in o.findall("metadata") if m.get("key") == "name") for o in settings.findall("object")}
        models = {}

        def get_model(path):
            if path not in models:
                models[path] = ET.fromstring(z.read(path))
                if models[path].get("unit", "millimeter") != "millimeter":
                    raise ValueError("Native 3MF changed units")
            return models[path]

        def geometry(path, object_id):
            model = get_model(path)
            obj = next(o for o in model.findall(f"{q('resources')}/{q('object')}") if o.get("id") == object_id)
            mesh = obj.find(q("mesh"))
            if mesh is not None:
                points = [tuple(float(v.get(k)) for k in "xyz") for v in mesh.findall(f"{q('vertices')}/{q('vertex')}")]
                faces = [tuple(int(t.get(f"v{i}")) for i in (1, 2, 3)) for t in mesh.findall(f"{q('triangles')}/{q('triangle')}")]
                return points, faces
            points, faces = [], []
            for comp in obj.findall(f"{q('components')}/{q('component')}"):
                child_path = comp.get(f"{{{production}}}path", path).lstrip("/")
                cp, cf = geometry(child_path, comp.get("objectid"))
                cp = transform(cp, comp.get("transform"))
                faces.extend(tuple(i + len(points) for i in f) for f in cf)
                points.extend(cp)
            return points, faces

        model = get_model("3D/3dmodel.model")
        for item in model.findall(f"{q('build')}/{q('item')}"):
            name = names[item.get("objectid")]
            source = sources[name]
            sp, sf = read_stl(source)
            np, nf = geometry("3D/3dmodel.model", item.get("objectid"))
            np = transform(np, item.get("transform"))
            native_bounds = [[min(p[i] for p in np) for i in range(3)], [max(p[i] for p in np) for i in range(3)]]
            sp, np = normalize(sp), normalize(np)
            if len(sp) != len(np) or len(sf) != len(nf):
                raise ValueError(f"Native 3MF changed mesh counts for {name}")
            grid = {}
            for i, point in enumerate(sp):
                key = tuple(math.floor(v / tolerance_mm) for v in point)
                grid.setdefault(key, []).append(i)
            mapping, used, max_error = {}, set(), 0.
            for i, point in enumerate(np):
                key = tuple(math.floor(v / tolerance_mm) for v in point)
                candidates = []
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        for dz in (-1, 0, 1):
                            for j in grid.get((key[0] + dx, key[1] + dy, key[2] + dz), []):
                                if j not in used:
                                    error = max(abs(point[k] - sp[j][k]) for k in range(3))
                                    if error <= tolerance_mm:
                                        candidates.append((error, j))
                if not candidates:
                    raise ValueError(f"Native 3MF changed a vertex for {name}")
                error, j = min(candidates)
                mapping[i] = j
                used.add(j)
                max_error = max(max_error, error)
            if Counter(cyclic(f) for f in sf) != Counter(cyclic(tuple(mapping[i] for i in f)) for f in nf):
                raise ValueError(f"Native 3MF changed oriented triangle topology for {name}")
            source_check, native_check = mesh_check(sp, sf), mesh_check(np, nf)
            volume_error = abs(native_check["signed_volume_mm3"] - source_check["signed_volume_mm3"]) / source_check["signed_volume_mm3"]
            if volume_error > 1e-5 or not native_check["passed"]:
                raise ValueError(f"Native 3MF changed volume/manifold validity for {name}")
            rows.append({"name": name, "passed": True, "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                         "vertices": len(sp), "triangles": len(sf), "maximum_coordinate_error_mm": max_error,
                         "source_volume_mm3": source_check["signed_volume_mm3"], "native_volume_mm3": native_check["signed_volume_mm3"],
                         "relative_volume_error": volume_error, "source_size_mm": source_check["bounds_mm"][1],
                         "native_size_mm": native_check["bounds_mm"][1], "native_placed_bounds_mm": native_bounds,
                         "oriented_triangle_connectivity_unchanged": True, "print_orientation_unchanged": True})
    if {r["name"] for r in rows} != set(sources):
        raise ValueError("Native mesh/source names differ")
    return {"passed": True, "native_project_sha256": hashlib.sha256(Path(project).read_bytes()).hexdigest(),
            "coordinate_tolerance_mm": tolerance_mm, "maximum_relative_volume_error": 1e-5, "part_count": len(rows), "parts": rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--profiles", type=Path, default=PROFILES)
    parser.add_argument("--slicer", type=Path, default=SLICER)
    parser.add_argument("--slice", action="store_true")
    args = parser.parse_args()
    manifest_path = args.manifest.resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    parts = []
    for p in manifest["parts"]:
        material = p["material"].upper()
        if material not in MATERIALS:
            raise ValueError(f"Unsupported material {material}")
        path = (manifest_path.parent / p["path"]).resolve()
        points, faces = read_stl(path)
        check = mesh_check(points, faces)
        if not check["passed"]:
            raise ValueError(f"Mesh validation failed for {path}: {check}")
        for copy in range(p.get("quantity", 1)):
            name = p["name"] + (f" {copy + 1}" if p.get("quantity", 1) > 1 else "")
            parts.append({"name": name, "path": str(path), "material": material, "points": points, "faces": faces,
                          "size": [check["bounds_mm"][1][i] - check["bounds_mm"][0][i] for i in range(3)], "check": check})
    plates = arrange(parts)
    machine, process, filaments, source_profiles = flatten_profiles(args.profiles)
    settings_dir = out / "profiles"
    settings_dir.mkdir(exist_ok=True)
    write_json(settings_dir / "p2s-machine.json", machine)
    write_json(settings_dir / "enclosure-process.json", process)
    for material, filament in zip(MATERIALS, filaments):
        write_json(settings_dir / f"{material.lower()}-filament.json", filament)
    write_json(settings_dir / "source-profile-sha256.json", source_profiles)
    native_dir = out / "native-validation"
    native_dir.mkdir(exist_ok=True)
    source_project = native_dir / "packaging-input.3mf"
    create_project(source_project, plates, machine, process, filaments, manifest)
    for plate in plates:
        create_project(out / f"Orion-R5-plate-{plate['index']}-{plate['material']}-portable.3mf", [plate], machine, process, filaments, manifest, portable=True)
    portable_parts = [dict(p) for p in parts]
    portable_plates = arrange(portable_parts, separate_materials=False)
    create_project(out / "Orion-R5-all-parts-portable.3mf", portable_plates, machine, process, filaments, manifest, portable=True)
    report = {"parts": [{k: v for k, v in p.items() if k not in {"points", "faces", "object_id"}} for p in parts],
              "plate_count": len(plates), "native_slice_verified": False,
              "assumptions": ["Bambu P2S with 0.4 mm nozzle", "Textured PEI plate", "Generic PETG rigid parts", "Generic TPU 95A seals, external spool", "No physical fit, compression or leak-test claim"]}
    if args.slice:
        result = run_slicer(args.slicer, source_project, native_dir, "Orion-R5-enclosure-P2S-verified.3mf",
                            settings_dir / "p2s-machine.json", settings_dir / "enclosure-process.json",
                            [settings_dir / f"{m.lower()}-filament.json" for m in MATERIALS])
        native = native_dir / "Orion-R5-enclosure-P2S-verified.3mf"
        report["native_project"] = verify_native(native, len(parts), len(plates))
        # Reopen and slice without external profiles to prove settings survive.
        roundtrip_dir = native_dir / "roundtrip"
        roundtrip_result = run_slicer(args.slicer, native, roundtrip_dir, "Orion-R5-P2S-complete.3mf")
        roundtrip = roundtrip_dir / "Orion-R5-P2S-complete.3mf"
        report["roundtrip_project"] = verify_native(roundtrip, len(parts), len(plates))
        report["native_geometry_comparison"] = verify_native_geometry(roundtrip, manifest_path)
        final = out / "Orion-R5-P2S-complete.3mf"
        final.write_bytes(roundtrip.read_bytes())
        with zipfile.ZipFile(final) as z:
            for plate in plates:
                (out / f"print-plate-{plate['index']}-{plate['material']}.png").write_bytes(z.read(f"Metadata/plate_{plate['index']}.png"))
        report["native_slice_verified"] = True
        report["native_slice_result"] = result
        report["native_roundtrip_result"] = roundtrip_result
    write_json(out / "print-package-validation.json", report)
    print(json.dumps({"output": str(out), "parts": len(parts), "plates": len(plates), "native_slice_verified": args.slice}))


if __name__ == "__main__":
    main()
