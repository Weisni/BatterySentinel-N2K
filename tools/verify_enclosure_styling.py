"""Verify styling-specific access, fastener seating and unchanged seal geometry."""
import json,zipfile,hashlib,math
import build_orion_enclosure_v2 as b

def main():
    doc=b.App.openDocument(str(b.OUT/'Orion-Enclosure-V2.FCStd'))
    shape=lambda name:doc.getObject(name).Shape
    rows=[]
    for kind,sx,side,along,z,surface in [('usb',18,'X+',20,None,66.4),('service_switch',13,'Y+',39,None,51.4)]:
        c=json.loads((b.OUT/'mechanical-contract.json').read_text())[kind]
        along=c['center_along_edge'];z=9.6+c['center_above_pcb']
        for x in (-sx,sx):
            probe=b.face_mount(b.cyl(x,0,3.5,3.98,.01).cut(b.cyl(x,0,1.8,3.97,.03)),side,along,z,surface)
            coverage=shape(kind+'_cover').common(probe).Volume/probe.Volume
            assert coverage>.999,(kind,x,coverage)
            rows.append(dict(check='service washer seat',part=kind,x=x,coverage=coverage))
    for y in (-21,57):
        driver=b.cyl(18,y,3.5,4.1,36)
        for name in ('base','lid_body','usb_cover','service_switch_cover'):
            overlap=shape(name).common(driver).Volume
            assert overlap<1e-6,(name,y,overlap)
        rows.append(dict(check='mounting driver access',axis=[18,y],clear_diameter_mm=7))
    for y in (-11,47):
        probe=b.cyl(18,y,1.65,29.9,3.4)
        assert shape('lid_body').common(probe).Volume<1e-7
        rows.append(dict(check='actual centred lid hole',axis=[18,y]))
    # Measure material sections through the actual CAD, not parameter values.
    # Exclude the deliberately thicker bosses, port pads and upper sealing rim.
    for x,y,axis,expected,label in [(5,-8,'Y',3.,'front free field'),
            (-11,-8,'Y',3.,'front free field'),(30,-8,'Y',3.,'front free field'),
            (-11,44,'Y',3.,'rear free field'),(5,44,'Y',3.,'rear free field'),
            (-17,-8,'Y',3.6,'front texture rib'),(-24,0,'X',3.,'cable end free wall'),
            (60,-3,'X',3.,'USB end free wall')]:
        for z in (8,16,22):
            a=b.V(x,y,z);c=b.V(x,y,z)
            setattr(a,axis.lower(),getattr(a,axis.lower())-4)
            setattr(c,axis.lower(),getattr(c,axis.lower())+4)
            thickness=shape('base').common(b.Part.makeLine(a,c)).Length
            assert abs(thickness-expected)<.01,(label,x,y,z,thickness,expected)
            rows.append(dict(check='actual wall section',location=[x,y,z],axis=axis,
                             label=label,thickness_mm=thickness))
    for x,expected in ((18,-16.4),(5,-10.),(-17,-10.6)):
        section=shape('base').common(b.Part.makeLine(b.V(x,-18,16),b.V(x,-4,16)))
        outer=min(v.Point.y for v in section.Vertexes)
        assert abs(outer-expected)<.01,(x,outer,expected)
        rows.append(dict(check='projecting boss and shallow texture',x=x,outer_y_mm=outer))
    floor=shape('base').common(b.Part.makeLine(b.V(30,18,-1),b.V(30,18,7))).Length
    assert abs(floor-3.)<.01
    rows.append(dict(check='floor thickness',thickness_mm=floor))
    for y in (8,28):
        probe=b.Part.makeBox(10.99,5.98,6.98,b.V(-22.995,y-2.99,3.01))
        # The clamp's blind vertical insert pilot occupies the right-hand end.
        probe=probe.cut(b.cyl(-12,y,2.01,7.49,6.9))
        coverage=shape('base').common(probe).Volume/probe.Volume
        assert coverage>.999,(y,coverage)
        rows.append(dict(check='continuous clamp buttress to thin end wall',y=y,coverage=coverage))
    for a,c,expected,label in [((5,-12,28.55),(5,-3,28.55),6.6,'long-side sealing rim'),
            ((-28,0,28.55),(-19,0,28.55),6.,'end sealing rim')]:
        thickness=shape('base').common(b.Part.makeLine(b.V(*a),b.V(*c))).Length
        assert abs(thickness-expected)<.01,(label,thickness)
        rows.append(dict(check='local rim section below groove',label=label,thickness_mm=thickness))
    corner=[]
    for z in (23.20001,27.49999):
        ray=b.Part.makeLine(b.V(-27,-11,z),b.V(-15,1,z))
        inner=max((v.Point for v in shape('base').common(ray).Vertexes),key=lambda p:p.x)
        corner.append(inner)
    delta=corner[1]-corner[0]
    angle=math.degrees(math.atan2(math.hypot(delta.x,delta.y),delta.z))
    assert angle<=45.,angle
    rows.append(dict(check='actual diagonal rim support slope',angle_from_vertical_deg=angle,
                     horizontal_setback_mm=math.hypot(delta.x,delta.y),rise_mm=delta.z))
    # The 6 mm cable seal pocket has its own 2 mm shoulder. The service
    # insert pilots retain 1.3 mm of solid backing in an 8 mm local plinth.
    for kind,side,along,z,surface,sx in [('cable','X-',18,14,-30.4,0),
            ('usb','X+',20,9.6+json.loads((b.OUT/'mechanical-contract.json').read_text())['usb']['center_above_pcb'],66.4,18),
            ('switch','Y+',39,10.3,51.4,13)]:
        local=b.cyl(sx,0,1.9,-7.99,1.28) if kind!='cable' else b.cyl(0,0,6.,-7.99,1.98).cut(b.cyl(0,0,3.9,-8,2))
        probe=b.face_mount(local,side,along,z,surface)
        coverage=shape('base').common(probe).Volume/probe.Volume
        assert coverage>.999,(kind,coverage)
        rows.append(dict(check='local port backing',part=kind,coverage=coverage))
    report=json.loads((b.OUT/'validation.json').read_text())
    report['styling_access_checks']=rows
    baseline=b.ROOT/'output/Orion-Enclosure-V2.2-Print-Package.zip'
    with zipfile.ZipFile(baseline) as z:
        old=json.loads(z.read('enclosure/validation.json'))['meshes']['base']['volume_mm3']
    current=shape('base').Volume
    assert current<old
    report['thin_wall_volume_comparison']=dict(reference_archive=baseline.name,
        reference_sha256=hashlib.sha256(baseline.read_bytes()).hexdigest(),
        old_base_cad_volume_mm3=old,new_base_cad_volume_mm3=current,
        reduction_percent=100*(1-current/old),
        note='Solid CAD volume, not measured print mass; sparse infill and paths affect filament savings')
    (b.OUT/'validation.json').write_text(json.dumps(report,indent=2))
    print('Actual thin walls, local backing, washer seats, driver access and centred holes passed.')
if __name__=='__main__':main()
