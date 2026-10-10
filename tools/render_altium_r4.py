"""Render R4 exact PCB/drill geometry and locally generated component models.

Run with FreeCAD 1.1 bin/python.exe. Models are approximate package envelopes.
"""
import argparse
import hashlib
import json
from pathlib import Path
from render_altium_r3 import render

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('design',type=Path)
    parser.add_argument('--routing',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    data=json.loads(args.design.read_text(encoding='utf-8'))
    routing=json.loads(args.routing.read_text(encoding='utf-8')) if args.routing else None
    result=render(data,args.output,routing,revision='R4')
    result['design_sha256']=hashlib.sha256(args.design.read_bytes()).hexdigest()
    if args.routing:result['routing_sha256']=hashlib.sha256(args.routing.read_bytes()).hexdigest()
    (args.output/'3D-render-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))
