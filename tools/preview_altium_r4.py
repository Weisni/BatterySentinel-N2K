"""Render both actual R4 SchDocs and merge a reviewable two-page PDF."""
from pathlib import Path
import json
import subprocess
from pypdf import PdfWriter
from preview_altium_r2 import Renderer,RUNTIME

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'hardware/altium-r4'
reports=[];writer=PdfWriter()
for suffix in ['Power','Logic']:
    source=OUT/f'Orion-Bridge-R4-{suffix}.SchDoc'
    pdf=OUT/f'Schaltplan-R4-{suffix}.pdf'
    report=Renderer(source,pdf).draw()
    subprocess.run([str(RUNTIME/'native/poppler/Library/bin/pdftoppm.exe'),'-png','-singlefile','-r','105',str(pdf),str(pdf.with_suffix(''))],check=True)
    report['png']=str(pdf.with_suffix('.png'));reports.append(report)
    writer.append(pdf)
with (OUT/'Schaltplan-R4.pdf').open('wb') as stream:writer.write(stream)
(OUT/'schematic-render-validation.json').write_text(json.dumps(reports,indent=2)+'\n',encoding='utf8')
print(json.dumps([{k:r[k] for k in ['source','pdf','approximate_text_overlap_candidates','powerports_inside_component_bodies']} for r in reports],indent=2))
