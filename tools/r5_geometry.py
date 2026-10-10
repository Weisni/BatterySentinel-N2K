"""One mechanical outline for R5 routing, Altium, CAM and enclosure checks."""
from __future__ import annotations
from shapely.geometry import Polygon,box


def rounded_rect(x1,y1,x2,y2,radius):
    if not radius:return box(x1,y1,x2,y2)
    return box(x1+radius,y1+radius,x2-radius,y2-radius).buffer(radius,quad_segs=32)


def board_geometry(data,inset=0):
    b=data['board']
    if b.get('outline_points_mm'):
        result=Polygon(b['outline_points_mm'],[c['outline_points_mm'] for c in b.get('cutouts_mm',[])])
    else:
        result=rounded_rect(0,0,b['width_mm'],b['height_mm'],b.get('corner_radius_mm',0))
    if not result.is_valid:raise ValueError('R5 board contour is invalid')
    return result.buffer(-inset,quad_segs=32) if inset else result


def apply_outline(board):
    outer=rounded_rect(0,0,board['width_mm'],board['height_mm'],board['corner_radius_mm'])
    usb=rounded_rect(44.4,14.1,54.0,25.9,.6)
    outer=outer.difference(usb)
    antenna=rounded_rect(28.0,14.5,33.0,25.5,.5)
    board['outline_points_mm']=[[round(x,7),round(y,7)] for x,y in outer.exterior.coords]
    board['cutouts_mm']=[dict(name='SuperMini antenna relief',outline_points_mm=[[round(x,7),round(y,7)] for x,y in antenna.exterior.coords])]
    board['mechanical_features']=[
        dict(name='USB shell underside clearance',bounds_mm=[44.4,14.1,54,25.9],corner_radius_mm=.6,kind='edge_notch'),
        dict(name='Antenna substrate relief',bounds_mm=[28,14.5,33,25.5],corner_radius_mm=.5,kind='internal_cutout')]
    return board


def install_routing_geometry():
    """Select R5 geometry only in this process; historical files stay untouched."""
    import route_altium_r3 as router
    import route_altium_r4 as previous
    router.board_geometry=board_geometry
    previous.board_geometry=board_geometry
