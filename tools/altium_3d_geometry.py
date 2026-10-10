"""Exact carrier/drill solids shared by STEP export and product rendering.

Imported only by FreeCAD's Python runtime. Coordinates are millimetres.
"""
import math
import FreeCAD as App
import Part


def rounded_carrier(board):
    w, h = board['width_mm'], board['height_mm']
    t = board.get('thickness_mm', 1.6)
    r = min(board.get('corner_radius_mm', 0), w/2, h/2)
    if r <= 0:
        return Part.makeBox(w, h, t, App.Vector(0, 0, -t))
    shapes = [Part.makeBox(w-2*r, h, t, App.Vector(r, 0, -t)),
              Part.makeBox(w, h-2*r, t, App.Vector(0, r, -t))]
    shapes += [Part.makeCylinder(r, t, App.Vector(x, y, -t))
               for x in (r, w-r) for y in (r, h-r)]
    return shapes[0].multiFuse(shapes[1:]).removeSplitter()


def drill_solid(x, y, diameter, z, height, slot_length=0, slot_angle=0):
    """Slot length is total end-to-end length; angle is its long axis."""
    if slot_length <= diameter + 1e-9:
        return Part.makeCylinder(diameter/2, height, App.Vector(x, y, z))
    span = slot_length-diameter
    shape = Part.makeBox(span, diameter, height, App.Vector(-span/2, -diameter/2, z))
    shape = shape.fuse(Part.makeCylinder(diameter/2, height, App.Vector(-span/2, 0, z)))
    shape = shape.fuse(Part.makeCylinder(diameter/2, height, App.Vector(span/2, 0, z)))
    shape.rotate(App.Vector(0, 0, 0), App.Vector(0, 0, 1), slot_angle)
    shape.translate(App.Vector(x, y, 0))
    return shape.removeSplitter()


def world_drill(part, hole):
    placement = part.get('pcb', part.get('placement', {}))
    rotation = placement.get('rotation', 0)
    a = math.radians(rotation)
    x = placement['x'] + hole['x']*math.cos(a)-hole['y']*math.sin(a)
    y = placement['y'] + hole['x']*math.sin(a)+hole['y']*math.cos(a)
    return (x, y, hole['drill'], hole.get('drill_slot_length_mm', 0),
            rotation+hole.get('drill_slot_angle_deg', 0))
