"""Original vector branding and outline typography for Orion R5.

Run with the FreeCAD Python runtime (fontTools, Shapely, PySide6 available).
Only assets/branding is written. No font binaries are copied into the project.
PCB text remains a native editable TrueType Text object; text_regions() supplies
the corresponding fabrication/drawing polygons, including counters (holes).
"""
from __future__ import annotations

import argparse
from functools import lru_cache
import hashlib
import html
import json
import math
from pathlib import Path

from fontTools.pens.basePen import BasePen
from fontTools.ttLib import TTFont
from shapely import affinity
from shapely.geometry import LineString, Polygon, box
from shapely.ops import split,triangulate,unary_union

REPO=Path(__file__).resolve().parents[1]
ASSETS=REPO/'assets/branding'
FONT_PATH=Path('C:/Windows/Fonts/ARLRDBD.TTF')
FONT_NAME='Arial Rounded MT Bold'
CANVAS=(8.,9.4)
STROKE=.48
SHIELD=[('M',(1.5,1.2)),('L',(6.5,1.2)),('Q',(7.25,1.2),(7.25,1.95)),
    ('L',(7.25,4.8)),('C',(7.25,6.8),(6.,8.2),(4.,9.1)),
    ('C',(2.,8.2),(.75,6.8),(.75,4.8)),('L',(.75,1.95)),
    ('Q',(.75,1.2),(1.5,1.2)),('Z',)]
PULSE=[('M',(2.,4.9)),('L',(2.75,4.9)),('L',(3.45,3.25)),
       ('L',(4.45,6.1)),('L',(5.05,4.6)),('L',(6.,4.6))]


def polygons(geometry):
    if geometry.is_empty:return []
    if geometry.geom_type=='Polygon':return [geometry]
    if not hasattr(geometry,'geoms'):return []
    return [p for g in geometry.geoms for p in polygons(g)]


def region_data(geometry):
    return [{'points':[[round(x,6),round(y,6)] for x,y in p.exterior.coords],
             'holes':[[[round(x,6),round(y,6)] for x,y in h.coords] for h in p.interiors]}
            for p in polygons(geometry)]


def regions_geometry(regions):
    return unary_union([Polygon(r['points'],r.get('holes',[])) for r in regions])


def transformed(geometry,x=0,y=0,rotation=0,mirror=False):
    if mirror:geometry=affinity.scale(geometry,xfact=-1,yfact=1,origin=(0,0))
    geometry=affinity.rotate(geometry,rotation,origin=(0,0))
    return affinity.translate(geometry,xoff=x,yoff=y)


def path_d(commands):
    return ' '.join(c[0]+' '.join(f'{x:g},{y:g}' for x,y in c[1:]) for c in commands)


def flatten_path(commands,steps=80):
    points=[]
    for command in commands:
        op=command[0]
        if op in ('M','L'):points.append(command[1])
        elif op in ('Q','C'):
            control=[points[-1],*command[1:]]
            for i in range(1,steps+1):
                t=i/steps
                work=control[:]
                while len(work)>1:
                    work=[((1-t)*a[0]+t*b[0],(1-t)*a[1]+t*b[1]) for a,b in zip(work,work[1:])]
                points.append(work[0])
        elif op=='Z':points.append(points[0])
    return points


def logo_geometry(width_mm=7,x=0,y=0,rotation=0,mirror=False):
    # A battery terminal merges into the shield rim. The separated inner pulse
    # stays robust even at 6 mm nominal canvas width and can be embossed as is.
    rim=LineString(flatten_path(SHIELD)).buffer(STROKE/2,resolution=32)
    pulse=LineString(flatten_path(PULSE)).buffer(STROKE/2,resolution=32)
    terminal=box(2.8,.31,5.2,1.35).buffer(-.24).buffer(.24,resolution=32)
    shape=unary_union([rim,pulse,terminal])
    shape=affinity.scale(shape,xfact=1,yfact=-1,origin=(0,0))
    shape=affinity.translate(shape,yoff=CANVAS[1])
    shape=affinity.scale(shape,xfact=width_mm/CANVAS[0],yfact=width_mm/CANVAS[0],origin=(0,0))
    return transformed(shape,x,y,rotation,mirror)


def logo_regions(item=None,**kwargs):
    """Return common PCB/enclosure regions; item accepts width or width_mm."""
    if item is not None:
        options={k:item[k] for k in ('x','y','rotation','mirror') if k in item}
        options['width_mm']=item.get('width_mm',item.get('width',7))
        options.setdefault('mirror',item.get('layer','TOP').upper() in ('BOTTOM','BOTTOMOVERLAY'))
        options.update(kwargs);kwargs=options
    return region_data(logo_geometry(**kwargs))


class OutlinePen(BasePen):
    """Adaptive quadratic/cubic flattening with a physical chord-error bound."""
    def __init__(self,glyph_set,tolerance):
        super().__init__(glyph_set)
        self.tolerance=tolerance
        self.contours=[]
        self.current=[]

    def _moveTo(self,p):self.current=[tuple(p)]
    def _lineTo(self,p):self.current.append(tuple(p))
    def _closePath(self):
        if len(self.current)>2:
            if self.current[-1]!=self.current[0]:self.current.append(self.current[0])
            self.contours.append(self.current)
        self.current=[]
    def _endPath(self):self._closePath()

    def _curve(self,control,depth=0):
        a,b=control[0],control[-1]
        dx,dy=b[0]-a[0],b[1]-a[1]
        length=math.hypot(dx,dy)
        error=max((abs(dx*(p[1]-a[1])-dy*(p[0]-a[0]))/length
                   if length else math.dist(a,p)) for p in control[1:-1])
        if error<=self.tolerance or depth>=20:
            self.current.append(tuple(b));return
        levels=[list(control)]
        while len(levels[-1])>1:
            levels.append([((a[0]+b[0])/2,(a[1]+b[1])/2) for a,b in zip(levels[-1],levels[-1][1:])])
        self._curve([row[0] for row in levels],depth+1)
        self._curve([row[-1] for row in levels[::-1]],depth+1)

    def _qCurveToOne(self,a,b):self._curve([self.current[-1],a,b])
    def _curveToOne(self,a,b,c):self._curve([self.current[-1],a,b,c])


@lru_cache(maxsize=4)
def load_font(path=str(FONT_PATH)):
    return TTFont(path)


def font_metadata(path=FONT_PATH):
    path=Path(path);font=load_font(str(path))
    names={}
    for item in font['name'].names:
        if item.platformID==3 and item.langID==1033:
            names[str(item.nameID)]=item.toUnicode()
    return {'family':names.get('1'),'style':names.get('2'),'full_name':names.get('4'),
        'postscript_name':names.get('6'),'version':names.get('5'),
        'copyright':names.get('0'),'license_description':names.get('13'),
        'license_url':names.get('14'),'local_source':str(path),
        'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'units_per_em':font['head'].unitsPerEm,'ascent_units':font['hhea'].ascent,
        'descent_units':font['hhea'].descent,'win_ascent_units':font['OS/2'].usWinAscent,
        'win_descent_units':font['OS/2'].usWinDescent,'embedding_fsType':font['OS/2'].fsType,
        'redistributed_font_binary':False,
        'note':'Uses the installed Windows font; no TTF file is included. Outlined artwork is exported. Native Altium retains actual editable Text objects.'}


@lru_cache(maxsize=1)
def calibrated_font():
    path=ASSETS/'altium-native-font.json'
    return json.loads(path.read_text('utf8')) if path.is_file() else None


def text_geometry(item,font_path=FONT_PATH,tolerance_mm=.001):
    """Return filled glyph polygons in mm, retaining the original text case.

    The saved native cache is authoritative for the calibrated font. Scaling
    its geometry serves layout/drawing previews; final fabrication reads the
    final PCB's own cache using r5_native_typography.read_native_text_artwork.
    Explicit font_geometry='fonttools' is an uncalibrated development option.
    """
    cache=calibrated_font()
    if cache and Path(font_path)==FONT_PATH and item.get('font_geometry')!='fonttools':
        missing=set(item['text'])-set(cache['glyphs'])
        if missing:raise ValueError('Native font cache lacks glyphs '+repr(sorted(missing))+'; read the actual native PCB, do not substitute typography')
        cursor=0;parts=[]
        for char in item['text']:
            glyph=cache['glyphs'][char]
            parts.append(affinity.translate(regions_geometry(glyph['regions']),xoff=cursor))
            cursor+=glyph['advance_mm']
        shape=unary_union(parts)
        if shape.is_empty:raise ValueError('Empty text is not supported')
        shape=affinity.translate(shape,xoff=-shape.bounds[0])
        scale=item['height']/cache['reference_height_mm']
        if scale<=0:raise ValueError('Text height must be positive')
        shape=affinity.scale(shape,xfact=scale,yfact=scale,origin=(0,0))
        bottom=item.get('layer','TOP').upper() in ('BOTTOM','BOTTOMOVERLAY')
        return transformed(shape,item.get('x',0),item.get('y',0),item.get('rotation',0),item.get('mirror',bottom))
    font=load_font(str(font_path));glyph_set=font.getGlyphSet();cmap=font.getBestCmap()
    scale=item['height']/item.get('height_units',font['head'].unitsPerEm)
    if scale<=0:raise ValueError('Text height must be positive')
    cursor=0;parts=[]
    for char in item['text']:
        name=cmap.get(ord(char))
        if name is None:raise ValueError('Font lacks character '+repr(char))
        pen=OutlinePen(glyph_set,tolerance_mm/scale)
        glyph_set[name].draw(pen)
        # TrueType contours follow an alternating fill/counter hierarchy.
        # XOR retains counters in B, a, e, etc.; separate letters are united.
        glyph=Polygon()
        for contour in pen.contours:
            contour_shape=Polygon(contour)
            if not contour_shape.is_valid:
                raise ValueError('Invalid glyph contour: '+repr(char))
            glyph=glyph.symmetric_difference(contour_shape)
        parts.append(affinity.translate(glyph,xoff=cursor))
        cursor+=font['hmtx'].metrics[name][0]
    shape=affinity.scale(unary_union(parts),xfact=scale,yfact=scale,origin=(0,0))
    # This explicit offset can be fixed by the native baseline/anchor probe.
    shape=affinity.translate(shape,yoff=item.get('baseline_offset_mm',0))
    bottom=item.get('layer','TOP').upper() in ('BOTTOM','BOTTOMOVERLAY')
    return transformed(shape,item.get('x',0),item.get('y',0),item.get('rotation',0),item.get('mirror',bottom))


def text_regions(item,**kwargs):
    return region_data(text_geometry(item,**kwargs))


def native_text_record(item):
    """Actual editable Altium ASCII Text, not drawn letter tracks/regions."""
    from altium_pcb import record,base,mil
    layer=item.get('layer','TOP').upper()
    layer={'TOP':'TOPOVERLAY','BOTTOM':'BOTTOMOVERLAY'}.get(layer,layer)
    return record('Text',**base(layer),X=mil(item['x']),Y=mil(item['y']),
        HEIGHT=mil(item['height']),WIDTH=mil(.15),FONT='DEFAULT',TEXT=item['text'],
        ROTATION=item.get('rotation',0),MIRROR=item.get('mirror',layer=='BOTTOMOVERLAY'),
        USETTFONTS=True,FONTNAME=FONT_NAME,BOLD=False,ITALIC=False,INVERTED=False)


actual_text_record=native_text_record


def hole_free_polygons(geometry):
    result=[]
    pending=polygons(geometry)
    while pending:
        polygon=pending.pop()
        if not polygon.interiors:result.append(polygon);continue
        # A cut across a counter creates a few ordinary filled polygons,
        # instead of hundreds of triangles around each curved character/rim.
        x=Polygon(polygon.interiors[0]).representative_point().x
        low,high=polygon.bounds[1],polygon.bounds[3]
        pieces=polygons(split(polygon,LineString([(x,low-1),(x,high+1)])))
        if len(pieces)>1:
            pending.extend(pieces);continue
        for triangle in triangulate(polygon):
            for part in polygons(triangle.intersection(polygon)):
                if part.area>1e-12:
                    if part.interiors:raise ValueError('Triangulation left an unexpected hole')
                    result.append(part)
    if unary_union(result).symmetric_difference(geometry).area>1e-8:
        raise ValueError('Hole-free native-region conversion changed artwork')
    return result


def native_logo_records(item):
    from altium_pcb import base
    from altium_routed_pcb import contour_record
    layer=item.get('layer','TOP').upper()
    layer={'TOP':'TOPOVERLAY','BOTTOM':'BOTTOMOVERLAY'}.get(layer,layer)
    geometry=regions_geometry(logo_regions(item))
    return [contour_record('Region',list(p.exterior.coords),**base(layer),NAME='',KEEPOUT=False)
            for p in hole_free_polygons(geometry)]


def emit_gerber_regions(gerber,regions):
    """Compatible with export_jlcpcb_r4.Gerber; holes remain clear counters."""
    for region in regions:gerber.region(region['points'],region.get('holes',[]))


def geometry_svg_path(geometry,height):
    commands=[]
    for polygon in polygons(geometry):
        for ring in [polygon.exterior,*polygon.interiors]:
            points=list(ring.coords)
            commands.append('M'+' L'.join(f'{x:.5f},{height-y:.5f}' for x,y in points)+' Z')
    return ' '.join(commands)


def svg_document(shape,width,height,foreground='#101d26',background=None,title='Battery Sentinel'):
    rect=f'<rect width="{width}" height="{height}" fill="{background}"/>' if background else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}mm" height="{height}mm" '
        f'viewBox="0 0 {width} {height}" role="img"><title>{html.escape(title)}</title>{rect}'
        f'<path d="{geometry_svg_path(shape,height)}" fill="{foreground}" fill-rule="evenodd"/></svg>\n')


def render_png(svg_path,png_path,width_px=1800):
    from PySide6.QtCore import QByteArray,QRectF
    from PySide6.QtGui import QImage,QPainter
    from PySide6.QtSvg import QSvgRenderer
    renderer=QSvgRenderer(QByteArray(svg_path.read_bytes()))
    bounds=renderer.viewBoxF();height_px=round(width_px*bounds.height()/bounds.width())
    image=QImage(width_px,height_px,QImage.Format_ARGB32);image.fill(0)
    painter=QPainter(image);painter.setRenderHint(QPainter.Antialiasing)
    renderer.render(painter,QRectF(0,0,width_px,height_px));painter.end()
    if not image.save(str(png_path)):raise ValueError('PNG output failed')


def build():
    ASSETS.mkdir(parents=True,exist_ok=True)
    logo=logo_geometry(width_mm=8)
    if not logo.is_valid:raise ValueError('Invalid logo geometry')
    # Source remains legible SVG curves, not a raster or font-based icon.
    source=(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 9.4" width="8mm" height="9.4mm" '
        'role="img" aria-labelledby="title desc"><title id="title">Battery Sentinel</title>'
        '<desc id="desc">Original monochrome battery and guardian shield with a monitoring pulse.</desc>'
        '<g fill="none" stroke="currentColor" stroke-width="0.48" stroke-linecap="round" stroke-linejoin="round">'
        f'<path d="{path_d(SHIELD)}"/><path d="{path_d(PULSE)}"/></g>'
        '<rect x="2.8" y="0.31" width="2.4" height="1.04" rx="0.24" fill="currentColor"/></svg>\n')
    (ASSETS/'battery-sentinel.svg').write_text(source,encoding='utf8')
    geometry={'format':'Battery Sentinel geometry v1','units':'mm','coordinates':'Cartesian XY; origin lower left; no mirroring',
        'canvas_mm':list(CANVAS),'source_nominal_width_mm':8,'regions':region_data(logo),
        'shapes':region_data(logo),'bounds':list(logo.bounds),
        'construction':{'shield':SHIELD,'monitor':PULSE,'stroke_mm':STROKE},
        'pcb':{'recommended_canvas_width_mm':7,'minimum_canvas_width_mm':6,
            'stroke_at_minimum_width_mm':.36,'minimum_clearance_to_other_artwork_mm':.3},
        'enclosure':{'recommended_canvas_width_mm':14,'minimum_canvas_width_mm':12,
            'emboss_height_mm':.6,'recess_depth_mm':.5,'stroke_at_12_mm_width_mm':.72},
        'provenance':'Original project artwork constructed from basic curves; no external icon or logo used.'}
    (ASSETS/'battery-sentinel.paths.json').write_text(json.dumps(geometry,indent=2)+'\n',encoding='utf8')
    (ASSETS/'font-metadata.json').write_text(json.dumps(font_metadata(),indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    # A drawing-only specimen makes physical dimensions and curve quality clear.
    mark=logo_geometry(width_mm=11,x=5,y=4)
    main={'text':'BatterySentinel-N2K','height':3.8,'x':20,'y':12,'layer':'TOP'}
    revision={'text':'Orion-R5','height':3.2,'x':20,'y':6.5,'layer':'TOP'}
    combined=unary_union([mark,text_geometry(main),text_geometry(revision)])
    wordmark={'units':'mm','coordinates':'Cartesian XY; origin lower left',
        'canvas_mm':[61,22],'bounds':list(combined.bounds),'shapes':region_data(combined),
        'text_items':[main,revision],'font_binary_included':False,
        'note':'Drawing/enclosure master; includes the logo and both outlined labels using calibrated native letter contours. Scaling serves graphics; final PCB fabrication reads its own saved native text cache.'}
    (ASSETS/'branding.paths.json').write_text(json.dumps(wordmark,indent=2)+'\n',encoding='utf8')
    preview=ASSETS/'branding-preview.svg'
    preview.write_text(svg_document(combined,61,22,foreground='#f1f8f8',background='#0b222b'),encoding='utf8')
    render_png(preview,ASSETS/'branding-preview.png')
    render_png(ASSETS/'battery-sentinel.svg',ASSETS/'battery-sentinel.png',800)
    specimen={'text':'H0gp BatterySentinel-N2K','height':2.,'x':2.,'y':3.,'layer':'TOP'}
    shape=text_geometry(specimen)
    verified=calibrated_font() is not None
    probe={'item':specimen,'native_ascii_text':native_text_record(specimen),
        'geometry_source':'Altium saved native glyph cache' if verified else 'uncalibrated fontTools',
        'coordinate_convention':'left ink edge X; baseline Y' if verified else 'font baseline and natural glyph sidebearing',
        'bounds_mm':list(shape.bounds),'regions':region_data(shape),
        'native_coupon_calibration_verified':verified,
        'required_check':'Final fabrication must read each actual Text contour from the saved native PCB. See native-typography-verification.json for five-object coupon parity.'}
    (ASSETS/'altium-font-probe.json').write_text(json.dumps(probe,indent=2)+'\n',encoding='utf8')
    from export_jlcpcb_r4 import Gerber
    gerber=Gerber('Legend,Top');emit_gerber_regions(gerber,region_data(shape))
    gerber.write(ASSETS/'altium-font-probe.GTO')
    from verify_jlcpcb_r4 import parse_gerber
    readback=parse_gerber(ASSETS/'altium-font-probe.GTO')['geometry']
    delta=readback.symmetric_difference(regions_geometry(region_data(shape))).area
    if delta>1e-9:raise ValueError('Gerber glyph-region readback differs')
    native_logo=unary_union(hole_free_polygons(logo))
    validation={'passed':logo.is_valid and shape.is_valid,'original_logo':True,
        'font_binary_copied':False,'logo_regions':len(polygons(logo)),
        'glyph_regions':len(polygons(shape)),'glyph_counters':sum(len(p.interiors) for p in polygons(shape)),
        'curve_tolerance_mm':.001,'font_sha256':font_metadata()['sha256'],
        'gerber_outline_readback_difference_mm2':delta,
        'native_logo_decomposition_difference_mm2':native_logo.symmetric_difference(logo).area,
        'native_coupon_calibration_verified':verified,'final_pcb_geometry_verification_required':True,
        'outputs':['battery-sentinel.svg','battery-sentinel.paths.json','branding-preview.svg','branding-preview.png','altium-font-probe.json','altium-font-probe.GTO']}
    (ASSETS/'branding-validation.json').write_text(json.dumps(validation,indent=2)+'\n',encoding='utf8')
    return validation


def build_native_probe():
    from collections import Counter
    from altium_pcb import record
    from altium_routed_pcb import fields
    folder=REPO/'tmp/r5-typography-probe';folder.mkdir(parents=True,exist_ok=True)
    target=folder/'R5-Typography-Probe.PcbDoc'
    if target.is_file() and target.read_bytes().startswith(bytes.fromhex('d0cf11e0a1b11ae1')):
        raise ValueError('Refusing to overwrite the saved native binary typography coupon')
    source=REPO/'hardware/altium-r4/source/Orion-Bridge-R4.PcbDoc'
    rows=[]
    for line in source.read_text('cp1252').splitlines():
        field=fields(line)
        if field.get('RECORD')!='Board':continue
        if 'FILENAME' in field:field['FILENAME']=target.name
        field.pop('RECORD');rows.append(record('Board',**field))
    specimens=[
        {'text':'HHHH','x':2.,'y':25.,'height':2.,'layer':'TOP'},
        {'text':'H0gp BatterySentinel-N2K','x':2.,'y':19.,'height':2.,'layer':'TOP'},
        {'text':'Orion-R5','x':2.,'y':13.,'height':2.,'layer':'TOP'},
        {'text':'H0gp','x':35.,'y':5.,'height':2.,'rotation':90.,'layer':'TOP'},
        {'text':'Orion-R5','x':28.,'y':3.,'height':2.,'layer':'BOTTOM'},
    ]
    for specimen in specimens:rows.append(actual_text_record(specimen))
    rows.extend(native_logo_records({'x':35,'y':19,'width':7,'layer':'TOP'}))
    count=Counter();output=[]
    for line in rows:
        field=fields(line);kind=field.pop('RECORD')
        if kind!='Board':field['INDEXFORSAVE']=count[kind];count[kind]+=1
        output.append(record(kind,**field))
    target.write_bytes(('\r\n'.join(output)+'\r\n').encode('cp1252'))
    expectations={'source':str(target),'font':font_metadata(),'board_mm':[48,32],
        'text_count':len(specimens),'native_primitive_counts':dict(count),
        'font_height_units':2048,'native_parity_verified':False,
        'specimens':[dict(item=s,bounds_mm=list(text_geometry(s).bounds),regions=text_regions(s)) for s in specimens],
        'note':'Only Board records, five actual TTF Text objects and logo Regions; no components, nets, pads or copper. Baseline convention is provisional until saved native TTTextOutline comparison.'}
    (folder/'probe-expectations.json').write_text(json.dumps(expectations,indent=2)+'\n',encoding='utf8')
    return {'path':str(target),'texts':len(specimens),'regions':count['Region'],'font_units_per_em':2048,
            'directions':'Three normal top strings, one top 90deg string, one mirrored bottom string. All Size/HEIGHT 2mm.'}


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build',action='store_true')
    parser.add_argument('--native-probe',action='store_true')
    args=parser.parse_args()
    if args.build:print(json.dumps(build(),indent=2))
    if args.native_probe:print(json.dumps(build_native_probe(),indent=2))
