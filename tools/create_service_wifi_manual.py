"""Create private, device-specific Orion Bridge Wi-Fi labels and German manuals.

No firmware changes, network access, serial access or credential logging.
With no arguments, open a local input window. --credentials accepts a UTF-8
JSON file containing exactly the device's actual SSID and stored AP password.
Requires reportlab and pypdf (available in the Codex bundled Python runtime).
"""
from __future__ import annotations

import argparse
import io
import json
from pathlib import Path
import re
from xml.sax.saxutils import escape

from pypdf import PdfReader, PdfWriter
from reportlab.graphics import renderPDF
from reportlab.graphics.barcode.qr import QrCodeWidget
from reportlab.graphics.shapes import Drawing
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / 'output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf'
PRIVATE = ROOT / 'output/private/service-wifi'
PORTAL = 'https://192.168.4.1/'


def validate_credentials(ssid: str, password: str) -> None:
    if not isinstance(ssid, str) or not re.fullmatch(r'OrionBridge-[0-9A-Fa-f]{6}', ssid):
        raise ValueError('Use the actual device SSID: OrionBridge- followed by six hexadecimal characters.')
    if not isinstance(password, str) or not 8 <= len(password) <= 63 or not all(32 <= ord(c) <= 126 for c in password):
        raise ValueError('Use the actual stored Wi-Fi password (8-63 printable ASCII characters).')


def wifi_payload(ssid: str, password: str) -> str:
    validate_credentials(ssid, password)
    def quoted(value: str) -> str:
        return ''.join('\\' + c if c in '\\;,:"' else c for c in value)
    return f'WIFI:T:WPA;S:{quoted(ssid)};P:{quoted(password)};;'


def qr_drawing(payload: str, size: float = 156) -> Drawing:
    code = QrCodeWidget(payload, barLevel='M', barBorder=4)
    x0, y0, x1, y1 = code.getBounds()
    drawing = Drawing(size, size, transform=[size/(x1-x0), 0, 0, size/(y1-y0), 0, 0])
    drawing.add(code)
    return drawing


def create_manual(ssid: str, password: str, output_dir: Path = PRIVATE,
                  template: Path = TEMPLATE, force: bool = False) -> tuple[Path, Path]:
    payload = wifi_payload(ssid, password)
    source = PdfReader(template)
    output_dir = Path(output_dir)
    label_path = output_dir / f'{ssid}-Zugangsseite-DE.pdf'
    manual_path = output_dir / f'{ssid}-Anleitung-DE.pdf'
    if not force and any(p.exists() for p in (label_path, manual_path)):
        raise FileExistsError('A device PDF already exists. Choose another folder or use --force after checking the device credentials.')
    for name, file in [('WifiBody', 'segoeui.ttf'), ('WifiBold', 'segoeuib.ttf')]:
        if name not in pdfmetrics.getRegisteredFontNames():
            pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/' + file))
    style = ParagraphStyle('wifi', fontName='WifiBody', fontSize=11, leading=16,
                           textColor=HexColor('#142e40'))
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=(595.276, 841.89))
    c.setTitle(f'{ssid} | Private Geräte-Zugangsseite')
    c.setFillColor(HexColor('#071521')); c.rect(0, 719, 595.276, 123, fill=1, stroke=0)
    c.setFillColor(HexColor('#68e3d1')); c.setFont('WifiBold', 23)
    c.drawString(43, 774, 'Ihre Orion-Bridge verbinden')
    c.setFont('WifiBody', 11); c.drawString(43, 749, ssid)
    def paragraph(text: str, y: float) -> None:
        p = Paragraph(text, style); _, h = p.wrap(509, 200)
        p.drawOn(c, 43, y-h)
    paragraph('Bridge normal starten. Bei geschlossenem WLAN: BOOT nach dem Start länger als zwei Sekunden halten. Dann den WLAN-Code scannen und die Verbindung bestätigen.', 696)
    renderPDF.draw(qr_drawing(payload), c, 68, 469)
    renderPDF.draw(qr_drawing(PORTAL), c, 369, 469)
    c.setFillColor(HexColor('#142e40')); c.setFont('WifiBold', 12)
    c.drawString(78, 451, '1. WLAN verbinden'); c.drawString(363, 451, '2. Portal öffnen')
    paragraph('Der linke Code übergibt WLAN-Kennung und Passwort. Der rechte Code öffnet erst nach der WLAN-Verbindung <b>https://192.168.4.1/</b>.', 426)
    paragraph('Bei „Kein Internet“ mit dem Bridge-WLAN verbunden bleiben. Lokale Zertifikatsausnahme nur für die erwartete Bridge prüfen. Beim ersten Administratorkonto BOOT vom Absenden bis zur Antwort halten; sonst normal anmelden.', 366)
    paragraph('<b>Manuelle WLAN-Eingabe</b><br/>Kennung: ' + escape(ssid) + '<br/>Passwort: ' + escape(password).replace(' ', '&#160;'), 286)
    paragraph('<b>Privat aufbewahren.</b> QR-Code und Klartext enthalten das WLAN-Passwort. Administrator-Passwort und Orion-Schlüssel sind separate Zugangsdaten. Nach Löschen des Gerätespeichers oder Änderung der WLAN-Zugangsdaten diese Seite neu erstellen.', 207)
    paragraph('Geräte-Zugangsseite zur Betriebs- und Installationsanleitung, Ausgabe 1.5. Einrichtung ohne Konsole setzt voraus, dass die installierende Person die tatsächlichen Geräte-Zugangsdaten bereitgestellt hat.', 115)
    c.showPage(); c.save(); buffer.seek(0)
    label = PdfReader(buffer)
    writer = PdfWriter(); writer.clone_document_from_reader(source)
    writer.add_page(label.pages[0])
    writer.add_outline_item('Geräte-Zugangsseite — ' + ssid, len(source.pages))
    combined = io.BytesIO(); writer.write(combined); combined.seek(0)
    result = PdfReader(combined)
    assert len(result.pages) == len(source.pages) + 1
    before, after = source.get_fields() or {}, result.get_fields() or {}
    assert set(before) == set(after), 'Manual form fields must be preserved'
    assert all(before[k].get('/V') == after[k].get('/V') for k in before)
    output_dir.mkdir(parents=True, exist_ok=True)
    label_path.write_bytes(buffer.getvalue())
    manual_path.write_bytes(combined.getvalue())
    return manual_path, label_path


def gui(output_dir: Path, template: Path, force: bool) -> None:
    import tkinter as tk
    from tkinter import messagebox
    window = tk.Tk(); window.title('Orion Bridge — Private Wi-Fi manual')
    window.geometry('530x265')
    tk.Label(window, text='Enter the actual stored device credentials. This does not configure the device.',
             wraplength=500, justify='left').pack(padx=15, pady=12, anchor='w')
    ssid = tk.StringVar(value='OrionBridge-'); password = tk.StringVar()
    for title, value, hidden in [('Device SSID', ssid, False), ('Stored Wi-Fi password', password, True)]:
        tk.Label(window, text=title).pack(padx=15, anchor='w')
        tk.Entry(window, textvariable=value, show='*' if hidden else '', width=65).pack(padx=15, pady=4)
    def generate() -> None:
        try:
            manual, label = create_manual(ssid.get(), password.get(), output_dir, template, force)
        except Exception as error:
            messagebox.showerror('No PDFs created', str(error)); return
        password.set('')
        messagebox.showinfo('Private PDFs created', f'Manual:\n{manual}\n\nAccess page:\n{label}\n\nVerify both QR codes on the intended phone before handover.')
    tk.Button(window, text='Create private device PDFs', command=generate).pack(pady=12)
    window.mainloop()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--credentials', type=Path, help='Local UTF-8 JSON file with ssid and password; never put the password in command arguments.')
    parser.add_argument('--output-dir', type=Path, default=PRIVATE)
    parser.add_argument('--template', type=Path, default=TEMPLATE)
    parser.add_argument('--force', action='store_true', help='Replace existing device PDFs.')
    args = parser.parse_args()
    if args.credentials is None:
        gui(args.output_dir, args.template, args.force); return
    credentials = json.loads(args.credentials.read_text(encoding='utf-8-sig'))
    if not isinstance(credentials, dict) or set(credentials) != {'ssid', 'password'}:
        parser.error('Credential JSON must contain exactly ssid and password.')
    try:
        manual, label = create_manual(credentials['ssid'], credentials['password'], args.output_dir, args.template, args.force)
    except (ValueError, FileExistsError) as error:
        parser.error(str(error))
    print(f'Created private manual: {manual}\nCreated private access page: {label}')


if __name__ == '__main__':
    main()
