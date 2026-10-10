"""Structural and rendering QA for the generated German PDF manual."""
from pathlib import Path
import json
import re
import hashlib
from PIL import Image, ImageOps, ImageDraw
from pypdf import PdfReader
import pdfplumber

root=Path(__file__).resolve().parents[1]
pdf=root/'output/pdf/BatterySentinel-N2K-Orion-R5-Betriebs-und-Installationsanleitung-DE.pdf'
qa=root/'tmp/pdfs'
reader=PdfReader(pdf)
assert len(reader.pages)==30
assert len(reader.outline)==len(reader.pages)
fields=reader.get_fields()
assert len(fields)==15, list(fields)
assert all(fields[f'check_{i}']['/V']=='/Off' for i in range(9))
assert all(fields[f'record_{i}'].get('/V','')=='' for i in range(6))
widgets=[]
for n,p in enumerate(reader.pages,1):
    for ref in p.get('/Annots',[]):
        a=ref.get_object()
        if a.get('/Subtype')=='/Widget':
            assert '/AP' in a and '/N' in a['/AP']
            name=a.get('/T')
            assert name in fields
            assert a.get('/V','')==fields[name].get('/V','')
            widgets.append((n,name))
assert len(widgets)==15 and all(n==22 for n,_ in widgets)
texts=[]
with pdfplumber.open(pdf) as doc:
    for n,p in enumerate(doc.pages,1):
        text=p.extract_text() or ''
        assert len(text)>200, n
        assert '\ufffd' not in text
        texts.append(text)
        for ch in p.chars:
            assert ch['x0']>=-1 and ch['x1']<=p.width+1, (n,ch)
            assert ch['top']>=-1 and ch['bottom']<=p.height+1, (n,ch)
combined='\n\n'.join(texts)
normalized=' '.join(combined.split())
for term in ['SERVICE','115200','127508','Firmware-Update','Troubleshooting'.upper(),'32','OrionBridge-XXXXXX']:
    assert term in normalized, term
recovery_header=(root/'lib/BridgeAuth/src/BridgePasswordUpdate.h').read_text(encoding='utf8')
recovery_password=re.search(r'kRecoveryPassword\[\]\s*=\s*"([^"]+)"',recovery_header).group(1)
firmware_header=(root/'src/BridgeFirmwareIdentity.h').read_text(encoding='utf8')
# This manual covers the normal SuperMini, not the separately versioned OLED
# debug target. Read the explicit default branch instead of the first define.
firmware_version=re.search(r'#else\s*#define ORION_FIRMWARE_VERSION\s+"([^"]+)"',firmware_header).group(1)
for term in [recovery_password, 'Firmware '+firmware_version, 'Passwort ändern',
             'Passwort vergessen?', '12-128 UTF-8-Bytes', 'Bestätigungsfeld',
             'Nur das Administratorpasswort', 'bestehende Sitzungen enden']:
    assert term in normalized, term
for term in ['Auswertung: Spannung und Orion-Energie', 'Meldungen einstellen und bestätigen',
             'Netzwerkzeit ergänzt UTC', 'fünf Sekunden', '4-65 V', '1-1440 min',
             '30 s', '12,00 V', '12,30 V', '15,00 V', '14,70 V',
             'Am Garmin bestätigen ist nicht unterstützt', 'desselben Starts']:
    assert term in normalized, term
assert recovery_password in texts[9], 'Recovery password must be on the account help page'
for term in ['Ersteinrichtung mit QR-Code', 'Kiloohm sind keine Anschlussfreigabe',
             'CAN-ACK', '60 Ω', 'Messgerät darf Isolation nicht überbrücken']:
    assert term in normalized, term
for obsolete in ['NVS durch eine kundige Person zurücksetzen lassen',
                 'bewusste Speicher-Rücksetzung', 'BOOT setzt das Administratorkonto nicht zurück',
                 'sendet keine eigenen Batteriealarme']:
    assert obsolete not in combined, obsolete
# Published instructions describe only the actual Orion Bridge product. Keep
# internal hardware history and unrealized product concepts out of reader copy.
for pattern in [r'\bR[1-4]\b', r'\b8[ -]?MB\b', r'shunt',
                r'BatterySentinel-Batteriemonitor', r'Vorgängerversion',
                r'historisch\w* Versorgung', r'früher\w* Revision']:
    assert not re.search(pattern,normalized,re.IGNORECASE), pattern
(qa/'manual-extracted.txt').write_text(combined,encoding='utf8')
manifest=json.loads((root/'docs/manual-assets/source-manifest.json').read_text(encoding='utf8'))
assert manifest['pages']==len(reader.pages) and manifest['firmware']==firmware_version
for source,digest in manifest['sources'].items():
    assert hashlib.sha256((root/source).read_bytes()).hexdigest()==digest, source
for group in range((len(reader.pages)+5)//6):
    sheet=Image.new('RGB',(1260,1220),'#d4dfe5'); draw=ImageDraw.Draw(sheet)
    for i in range(6):
        n=group*6+i+1
        if n>len(reader.pages):
            break
        path=qa/f'manual-{n:02}.png'
        img=Image.open(path).convert('RGB'); img.thumbnail((400,566))
        x=10+(i%3)*420; y=24+(i//3)*610
        sheet.paste(img,(x,y)); draw.text((x,y-17),f'Page {n}',fill='black')
    sheet.save(qa/f'contact-{group+1}.png')
report={'pages':len(reader.pages),'outline_entries':len(reader.outline),'form_fields':len(fields),'widgets':widgets,'page_bounds':'passed','replacement_glyphs':0,'word_count':len(combined.split()),'firmware':firmware_version,'recovery_password_matches_firmware':True,'current_product_scope':'passed','source_hashes_verified':len(manifest['sources']),'rendering':f'{len(reader.pages)} PNGs rendered by Poppler; contact sheets require visual review'}
(qa/'manual-qa.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='widgets'},ensure_ascii=False))
