"""Read actual Altium-saved TrueType contours for R5 fabrication output.

The reader handles the LettersGeometry / Texts6 serialization observed in the
saved Altium 26.10.1 typography coupon. It rejects unsupported geometry or metric
mismatches; it never substitutes a guessed font or modifies a native document.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct

from shapely import affinity
from shapely.geometry import Polygon
from shapely.ops import unary_union

from altium_libraries import read_cfb_streams
from verify_altium_binary_r3 import primitives,UNIT
from r5_branding import ASSETS,FONT_NAME,font_metadata,region_data,transformed


def native_groups(streams):
    count=struct.unpack('<I',streams['LettersGeometry/Header'])[0]
    raw=streams['LettersGeometry/Data'];offset=0;groups=[]
    for group_index in range(count):
        glyph_count=struct.unpack_from('<I',raw,offset)[0];offset+=4
        glyphs={}
        if not 0<glyph_count<65536:raise ValueError('Unsupported native glyph count')
        for _ in range(glyph_count):
            start=offset
            char=chr(struct.unpack_from('<H',raw,start)[0])
            bearing,vertical,advance=struct.unpack_from('<iii',raw,start+2)
            length,reserved,inner,contour_count=struct.unpack_from('<IIII',raw,start+14)
            if reserved or inner!=length-4 or contour_count>1000:
                raise ValueError('Unsupported LettersGeometry glyph header')
            end=start+22+length;offset=start+30
            hole_flags=struct.unpack_from('<'+'I'*contour_count,raw,offset);offset+=4*contour_count
            contours=[];geometry=Polygon()
            for hole in hole_flags:
                if hole not in (0,1):raise ValueError('Invalid native contour hole flag')
                points_count=struct.unpack_from('<I',raw,offset)[0];offset+=4
                if not 3<=points_count<100000:raise ValueError('Invalid native contour vertex count')
                points=[struct.unpack_from('<dd',raw,offset+16*i) for i in range(points_count)]
                offset+=16*points_count
                if any(not math.isfinite(v) for p in points for v in p):raise ValueError('Invalid native point')
                polygon=Polygon(points)
                if not polygon.is_valid:raise ValueError('Native glyph contour is not simple')
                geometry=geometry.symmetric_difference(polygon)
                contours.append({'hole':bool(hole),'points':points})
            if offset!=end:raise ValueError('Native glyph-length mismatch')
            glyphs[char]={'bearing_units':bearing,'vertical_units':vertical,'advance_units':advance,
                          'contours':contours,'geometry_units':geometry}
        text_count=struct.unpack_from('<I',raw,offset)[0];offset+=4
        indexes=list(struct.unpack_from('<'+'I'*text_count,raw,offset));offset+=4*text_count
        groups.append({'index':group_index,'glyphs':glyphs,'text_indexes':indexes})
    if offset!=len(raw):raise ValueError('Unrecognized trailing LettersGeometry bytes')
    return groups


def read_native_text_artwork(path):
    """Return exact saved glyph regions and transforms; no font installation needed."""
    path=Path(path);streams=read_cfb_streams(path);groups=native_groups(streams)
    mapping={}
    for group in groups:
        for index in group['text_indexes']:
            if index in mapping:raise ValueError('Duplicate native text/cache link')
            mapping[index]=group
    wide={};raw=streams.get('WideStrings6/Data',b'');offset=0
    while offset<len(raw):
        index,length=struct.unpack_from('<II',raw,offset);offset+=8
        wide[index]=raw[offset:offset+length].decode('utf-16le').rstrip('\0');offset+=length
    texts=[]
    for index,(raw,ascii_text) in enumerate(primitives(streams['Texts6/Data'],5,2)):
        if len(raw)!=252:raise ValueError('Unsupported Texts6 record size')
        if not raw[43]:
            if raw[0] in (33,34):raise ValueError('Overlay stroke text is unsupported; do not omit it from fabrication')
            continue
        if index not in mapping:raise ValueError('TrueType text has no stored geometry')
        name=raw[46:110].decode('utf-16le').split('\0')[0]
        if not name:raise ValueError('Native TrueType font identity is unresolved')
        wide_index=struct.unpack_from('<I',raw,115)[0]
        text=wide.get(wide_index,ascii_text[1:1+ascii_text[0]].decode('cp1252'))
        group=mapping[index];glyphs=group['glyphs'];cursor=0;parts=[]
        for char in text:
            if char not in glyphs:raise ValueError('Native cache lacks glyph '+repr(char))
            glyph=glyphs[char]
            parts.append(affinity.translate(glyph['geometry_units'],xoff=cursor))
            cursor+=glyph['advance_units']
        local=unary_union(parts)
        if local.is_empty:raise ValueError('Empty native text is not supported')
        min_x,min_y,max_x,max_y=local.bounds
        width,height=struct.unpack_from('<ii',raw,124)
        metric_error=max(abs(max_x-min_x-width),abs(max_y-min_y-height))
        if metric_error>1.1:raise ValueError('Cached glyph metrics differ from actual native Text bounds')
        x,y,size=[v*UNIT for v in struct.unpack_from('<iii',raw,13)]
        rotation=struct.unpack_from('<d',raw,27)[0];mirror=bool(raw[35])
        # Native text X is the left ink edge, not the first glyph's sidebearing.
        # Y remains the baseline. The stored lower-left marker confirms this
        # convention independently for normal, rotated and mirrored specimens.
        local=affinity.translate(local,xoff=-min_x)
        local=affinity.scale(local,xfact=UNIT,yfact=UNIT,origin=(0,0))
        actual=transformed(local,x,y,rotation,mirror)
        angle=math.radians(rotation)
        lower=(x-min_y*UNIT*math.sin(angle),y+min_y*UNIT*math.cos(angle))
        stored_lower=tuple(v*UNIT for v in struct.unpack_from('<ii',raw,244))
        anchor_error=math.dist(lower,stored_lower)
        if anchor_error>3*UNIT:raise ValueError('Native text anchor/justification is unsupported')
        layer={33:'TOPOVERLAY',34:'BOTTOMOVERLAY'}.get(raw[0],'LAYER'+str(raw[0]))
        texts.append({'index':index,'text':text,'layer':layer,'x':x,'y':y,'height':size,
            'rotation':rotation,'mirror':mirror,'font_name':name,'true_type':True,
            'bold':bool(raw[44]),'italic':bool(raw[45]),'cache_group':group['index'],
            'native_width_mm':width*UNIT,'native_ink_height_mm':height*UNIT,
            'native_lower_left_mm':stored_lower,'bounds':list(actual.bounds),'regions':region_data(actual),
            'metric_error_native_units':metric_error,'anchor_error_mm':anchor_error})
    return {'source':str(path),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'cache_groups':len(groups),'text_count':len(texts),'texts':texts,
            'native_embedded_font_stream_present':bool(streams.get('EmbeddedFonts6/Data')),
            'passed':True,'method':'Saved native LettersGeometry contours and advances, checked against Texts6 dimensions and transformed lower-left anchors'},groups


def calibrate(path):
    evidence,groups=read_native_text_artwork(path)
    if len(groups)!=1 or len(evidence['texts'])!=5:
        raise ValueError('Calibration expects the five-text, one-font coupon')
    heights={round(t['height'],5) for t in evidence['texts']}
    if len(heights)!=1 or any(t['font_name']!=FONT_NAME for t in evidence['texts']):
        raise ValueError('Calibration coupon font/height mismatch')
    reference_height=evidence['texts'][0]['height']
    cache={'format':'Altium native rounded-font outline cache v1','font':font_metadata(),
        'native_coupon_sha256':evidence['source_sha256'],'reference_height_mm':reference_height,
        'coordinates':'Cartesian XY; baseline Y, natural glyph bearing; normalize string ink minX to zero before placing',
        'glyphs':{char:{'advance_mm':g['advance_units']*UNIT,
                       'regions':region_data(affinity.scale(g['geometry_units'],xfact=UNIT,yfact=UNIT,origin=(0,0)))}
                  for char,g in groups[0]['glyphs'].items()},
        'scope':'Exact for cached glyphs at coupon height; scaling previews is supported. Final fabrication reads its own saved native PCB cache for every actual text height.'}
    (ASSETS/'altium-native-font.json').write_text(json.dumps(cache,indent=2)+'\n',encoding='utf8')
    from export_jlcpcb_r4 import Gerber
    from r5_branding import emit_gerber_regions,regions_geometry
    from verify_jlcpcb_r4 import parse_gerber
    for layer,extension in [('TOPOVERLAY','GTO'),('BOTTOMOVERLAY','GBO')]:
        gerber=Gerber('Legend,'+('Top' if extension=='GTO' else 'Bot'))
        selected=[r for t in evidence['texts'] if t['layer']==layer for r in t['regions']]
        emit_gerber_regions(gerber,selected)
        target=ASSETS/('altium-native-text-proof.'+extension);gerber.write(target)
        delta=parse_gerber(target)['geometry'].symmetric_difference(regions_geometry(selected)).area
        if delta>1e-9:raise ValueError('Native cached text/Gerber readback differs')
        evidence.setdefault('gerber_readback',{})[extension]={'difference_mm2':delta,'passed':True}
    evidence['baseline_calibration']='Text X is left ink edge (remove natural first-glyph bearing); Y is baseline.'
    evidence['quantization']='Actual native contours retained; raw fontTools UPEM scaling is not used as final manufacturing geometry.'
    evidence['reference_height_mm']=reference_height
    evidence['font_file_redistributed']=False
    (ASSETS/'native-typography-verification.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
    return {k:v for k,v in evidence.items() if k not in ('texts',)}


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('native_coupon',type=Path)
    args=parser.parse_args()
    print(json.dumps(calibrate(args.native_coupon),indent=2))
