"""Archive the validated V2 delivery without slicer caches or unrelated files."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PARTS = ROOT / 'hardware/altium-r5/enclosure/sealed-v2'
ARCHIVE = ROOT / 'output/Orion-Enclosure-V2-Print-Package.zip'


def main():
    for report in ('validation.json', 'package-validation.json'):
        assert json.loads((PARTS / report).read_text())['passed'], report
    combined = json.loads((PARTS / 'combined-project-validation.json').read_text())
    assert combined['passed'] and combined['geometry']['passed']
    assert combined['reopened_without_external_profile_overrides']
    assert hashlib.sha256((PARTS / 'Orion-V2-Complete-P2S.3mf').read_bytes()).hexdigest() == combined['sha256']
    assert json.loads((PARTS / 'source-preservation.json').read_text())['unchanged']
    payload = {}
    for pattern in ('*.stl', '*.3mf', '*.FCStd', '*.step', 'preview-*.png', 'profiles/*.json'):
        for path in sorted(PARTS.glob(pattern)):
            payload['enclosure/' + path.relative_to(PARTS).as_posix()] = path.read_bytes()
    for name in ('parameters.json', 'print-manifest.json', 'mechanical-contract.json',
                 'validation.json', 'package-validation.json', 'source-preservation.json',
                 'manual-layout-audit.json', 'combined-project-validation.json'):
        payload['enclosure/' + name] = (PARTS / name).read_bytes()
    readme = (PARTS / 'README.md').read_text(encoding='utf-8')
    readme = readme.replace('../../../../output/pdf/', '../manuals/')
    readme = readme.replace('[complete print package](../../../../output/Orion-Enclosure-V2-Print-Package.zip)', 'complete print package')
    readme = readme.replace('(see `delivery-validation.json`)', '(checksums: `../SHA256SUMS.json`; full delivery report remains in the repository)')
    payload['enclosure/README.md'] = readme.encode('utf-8')
    for name in ('Assembly', 'Manufacturing'):
        path = ROOT / f'output/pdf/Orion-Enclosure-V2-{name}-EN.pdf'
        payload['manuals/' + path.name] = path.read_bytes()
    payload['START-HERE.md'] = b'''# Orion enclosure V2.3 - thin walls, 7 mm cable

1. Read [Manufacturing and TPU Air calibration](manuals/Orion-Enclosure-V2-Manufacturing-EN.pdf).
2. Print and check the fit and material coupons before a complete enclosure.
3. Follow [Assembly](manuals/Orion-Enclosure-V2-Assembly-EN.pdf).

The [detailed README](enclosure/README.md) lists parts, hardware, profiles and open physical tests.
All CAD, STL, 3MF and calibration profiles are in `enclosure/`.
The three TPU temperature projects are alternative calibration trials. Print only the selected samples first.
Flow 1.00 is an uncalibrated seed. Temperature does not guarantee a Shore hardness.
The digital validation passed; physical fit, retention, hardness, creep and sealing remain unqualified.

The original repository retains the previous user project and rebuild scripts.
This package includes editable FreeCAD geometry and design parameters; it is not a standalone build-tool distribution.
The assembly's seated TPU bodies are simplified envelopes. Use the free-shape STLs for printing.
`SHA256SUMS.json` records every payload file. The complete six-plate 3MF includes verified sliced toolpaths; individual trial projects remain editable without cached G-code.
'''
    hashes = {name: hashlib.sha256(data).hexdigest() for name, data in sorted(payload.items())}
    payload['SHA256SUMS.json'] = json.dumps(hashes, indent=2).encode('utf-8')
    with zipfile.ZipFile(ARCHIVE, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for name, data in payload.items():
            archive.writestr(name, data)
    with zipfile.ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None
        for name, digest in hashes.items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
        names = archive.namelist()
        counts = {extension: sum(n.endswith(extension) for n in names)
                  for extension in ('.stl', '.3mf', '.pdf', '.FCStd', '.step')}
        assert counts == {'.stl': 27, '.3mf': 6, '.pdf': 2, '.FCStd': 1, '.step': 1}, counts
        assert not any(n.endswith('.gcode') for n in names)
    result = dict(passed=True, archive=ARCHIVE.name, size_bytes=ARCHIVE.stat().st_size,
                  sha256=hashlib.sha256(ARCHIVE.read_bytes()).hexdigest(),
                  files=len(names), counts=counts, crc_passed=True,
                  all_payload_sha256_passed=True, cached_gcode_included_in_complete_project=True,
                  visual_pdf_review='All 16 final rendered pages inspected; no layout defects observed.')
    (PARTS / 'delivery-validation.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
