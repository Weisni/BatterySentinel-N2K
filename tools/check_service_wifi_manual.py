"""End-to-end PDF/QR QA with synthetic credentials only.

Run with --decoder-dir tmp/qr-qa if zxing-cpp is installed there.
Requires pdftoppm, zxing-cpp, pypdf, pdfplumber and Pillow.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--decoder-dir', type=Path)
args = parser.parse_args()
if args.decoder_dir:
    sys.path.insert(0, str(args.decoder_dir.resolve()))
import zxingcpp
from PIL import Image
from pypdf import PdfReader
import pdfplumber
from create_service_wifi_manual import create_manual, validate_credentials, PRIVATE, TEMPLATE

root = Path(__file__).resolve().parents[1]
qa = root / 'tmp/service-wifi-qa'
qa.mkdir(parents=True, exist_ok=True)
ssid = 'OrionBridge-A1B2C3'
password = 'QA;,:"\\<&> test value'
credentials = qa / 'fixture.service-wifi.json'
credentials.write_text(json.dumps({'ssid': ssid, 'password': password}), encoding='utf8')
result = subprocess.run([sys.executable, str(root/'tools/create_service_wifi_manual.py'),
                         '--credentials', str(credentials), '--output-dir', str(qa), '--force'],
                        capture_output=True, text=True, check=True)
assert password not in result.stdout and password not in result.stderr
manual = qa / f'{ssid}-Anleitung-DE.pdf'
label = qa / f'{ssid}-Zugangsseite-DE.pdf'
source, combined = PdfReader(TEMPLATE), PdfReader(manual)
assert len(source.pages) == 30 and len(combined.pages) == 31
assert len(combined.outline) == 31
assert len(combined.get_fields()) == 15
for name, field in source.get_fields().items():
    assert combined.get_fields()[name].get('/V') == field.get('/V')
with pdfplumber.open(label) as document:
    page = document.pages[0]
    assert ssid in page.extract_text() and 'QR-Code' in page.extract_text()
    for char in page.chars:
        assert -1 <= char['x0'] <= char['x1'] <= page.width+1
        assert -1 <= char['top'] <= char['bottom'] <= page.height+1

for pdf, page, prefix in [(manual, 31, 'device'), (TEMPLATE, 28, 'generic')]:
    subprocess.run(['pdftoppm', '-f', str(page), '-l', str(page), '-singlefile',
                    '-scale-to', '2000', '-png', str(pdf), str(qa/prefix)], check=True)
device_values = [r.text for r in zxingcpp.read_barcodes(Image.open(qa/'device.png'))]
expected_wifi = r'WIFI:T:WPA;S:OrionBridge-A1B2C3;P:QA\;\,\:\"\\<&> test value;;'
assert sorted(device_values) == sorted([expected_wifi, 'https://192.168.4.1/']), 'Independent decoder must reproduce both payloads including escaping'
assert [r.text for r in zxingcpp.read_barcodes(Image.open(qa/'generic.png'))] == ['https://192.168.4.1/']
try:
    create_manual(ssid, password, qa)
    raise AssertionError('Existing PDFs must not be overwritten by default')
except FileExistsError:
    pass
for invalid_ssid, invalid_password in [('OrionBridge-XXXXXX', password), (ssid, 'short'), (ssid, 'line\nbreak'), (ssid, 'ä'*20)]:
    try:
        validate_credentials(invalid_ssid, invalid_password)
        raise AssertionError('Invalid credentials accepted')
    except ValueError:
        pass
ignore = subprocess.run(['git', 'check-ignore', str(PRIVATE/'example.pdf'),
                         str(root/'output/private/device.service-wifi.json')],
                        capture_output=True, text=True, check=True)
assert len(ignore.stdout.splitlines()) == 2
report = {'credentials': 'synthetic only', 'generic_pages': 30, 'private_pages': 31,
          'outline_entries': 31, 'preserved_form_fields': 15,
          'independent_qr_decodes': 3, 'reserved_character_roundtrip': 'passed',
          'private_ignore_rules': 'passed', 'overwrite_and_invalid_input_checks': 'passed',
          'page_bounds': 'passed', 'physical_phone_connection': 'not tested'}
(qa/'qa.json').write_text(json.dumps(report, indent=2), encoding='utf8')
print(json.dumps(report))
