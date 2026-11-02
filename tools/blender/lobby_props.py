# Builds the lobby props (low-poly, stylised) and exports one FBX per prop.
# Run headless:  blender -b --factory-startup --python lobby_props.py -- <out_dir>
# Units: 1 Blender unit = 1 stud. Each object name says what it is (Trunk, Leaves, Pole...),
# and the Studio import step colours MeshParts by that name.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, Matrix, noise

out = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.expanduser("~/MBT_props")
os.makedirs(out, exist_ok=True)
rng = random.Random(7)

def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)

def mat(name, rgb):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*rgb, 1)
        bsdf.inputs["Roughness"].default_value = 0.8
    return m

def finish(obj, name, material, smooth=False):
    obj.name = name
    obj.data.name = name
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for p in obj.data.polygons:
        p.use_smooth = smooth
    return obj

def apply(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.select_set(False)

def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    o.data.name = name
    return o

def lumpy(obj, amount, scale=1.6, seed=0):
    # Push vertices along their normals with noise for an organic, low-poly look.
    me = obj.data
    off = Vector((seed * 3.1, seed * 1.7, seed * 2.3))
    for v in me.vertices:
        n = noise.noise(v.co * scale + off)
        v.co += v.normal * n * amount

def cyl(r1, r2, depth, verts, loc, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot)
    return bpy.context.active_object

def box(size, loc, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    apply(o)
    return o

def bevel(o, w=0.05, seg=1):
    m = o.modifiers.new("b", "BEVEL")
    m.width = w
    m.segments = seg
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier="b")

def export(name):
    path = os.path.join(out, name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=False, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y",
        object_types={"MESH"}, mesh_smooth_type="FACE", use_mesh_modifiers=True)
    print("EXPORTED", path)

M = {
    "bark": mat("Bark", (0.30, 0.18, 0.10)),
    "leaf1": mat("Leaves", (0.18, 0.45, 0.14)),
    "leaf2": mat("LeavesLight", (0.30, 0.58, 0.18)),
    "pine": mat("Pine", (0.10, 0.33, 0.16)),
    "iron": mat("Iron", (0.05, 0.06, 0.09)),
    "glass": mat("LampGlass", (1.0, 0.86, 0.55)),
    "wood": mat("Wood", (0.55, 0.33, 0.16)),
    "steel": mat("Steel", (0.45, 0.48, 0.52)),
    "orange": mat("Ball", (0.85, 0.36, 0.08)),
    "pot": mat("Pot", (0.75, 0.40, 0.25)),
    "bin": mat("BinGreen", (0.12, 0.35, 0.22)),
}

# ---------- Round tree: tapered trunk, two branches, a cluster of lumpy leaf blobs ----------
def round_tree(name, seed):
    clear()
    r = random.Random(seed)
    parts = []
    trunk = cyl(1.0, 0.55, 9, 7, (0, 0, 4.5))
    parts.append(trunk)
    for a in (0.6, 2.8):
        b = cyl(0.45, 0.2, 4, 6, (math.cos(a) * 1.2, math.sin(a) * 1.2, 7.5), (0.7 * math.sin(a), -0.7 * math.cos(a), 0))
        parts.append(b)
    t = join(parts, "Trunk")
    finish(t, "Trunk", M["bark"])
    blobs1, blobs2 = [], []
    spots = [(0, 0, 11.5, 4.6), (2.6, 1.0, 10, 3.4), (-2.4, -1.2, 10.2, 3.6), (0.8, -2.6, 10.6, 3.2), (-0.8, 2.4, 12.6, 3.0), (0.2, 0.3, 14.2, 3.0)]
    for i, (x, y, z, s) in enumerate(spots):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=s * r.uniform(0.9, 1.1), location=(x, y, z))
        o = bpy.context.active_object
        o.scale = (1, 1, 0.82)
        apply(o)
        lumpy(o, 0.55, 0.45, seed + i)
        (blobs1 if i % 2 == 0 else blobs2).append(o)
    finish(join(blobs1, "Leaves"), "Leaves", M["leaf1"])
    finish(join(blobs2, "LeavesLight"), "LeavesLight", M["leaf2"])
    export(name)

# ---------- Pine: trunk and three stacked jagged cones ----------
def pine_tree(name):
    clear()
    finish(cyl(0.8, 0.4, 5, 7, (0, 0, 2.5)), "Trunk", M["bark"])
    cones = []
    for i, (z, r, h) in enumerate([(5.5, 5.2, 6), (9, 4.0, 5.5), (12.2, 2.8, 5)]):
        c = cyl(r, 0.0, h, 9, (0, 0, z))
        c.rotation_euler.z = i * 0.35
        apply(c)
        lumpy(c, 0.35, 0.6, i + 20)
        cones.append(c)
    finish(join(cones, "Leaves"), "Leaves", M["pine"])
    export(name)

# ---------- Street lamp: fluted base, tapered post, scroll arm, lantern ----------
def lamp(name):
    clear()
    iron = []
    iron.append(cyl(1.1, 0.9, 0.6, 8, (0, 0, 0.3)))
    iron.append(cyl(0.75, 0.45, 2.2, 8, (0, 0, 1.7)))
    iron.append(cyl(0.3, 0.22, 10, 8, (0, 0, 7.8)))
    iron.append(cyl(0.45, 0.45, 0.35, 8, (0, 0, 12.8)))
    # lantern frame
    iron.append(cyl(0.5, 0.9, 0.35, 6, (0, 0, 13.15)))
    for k in range(6):
        a = k / 6 * math.tau
        iron.append(box((0.12, 0.12, 2.0), (math.cos(a) * 0.85, math.sin(a) * 0.85, 14.3)))
    iron.append(cyl(1.25, 0.25, 1.1, 6, (0, 0, 15.85)))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=5, radius=0.3, location=(0, 0, 16.6))
    iron.append(bpy.context.active_object)
    finish(join(iron, "Iron"), "Iron", M["iron"])
    finish(cyl(0.8, 0.95, 2.0, 6, (0, 0, 14.3)), "Glass", M["glass"])
    export(name)

# ---------- Park bench: cast-iron ends, five wooden slats ----------
def bench(name):
    clear()
    ends = []
    for x in (-2.7, 2.7):
        ends.append(box((0.25, 0.25, 1.6), (x, -0.6, 0.8)))       # front leg
        ends.append(box((0.25, 0.25, 3.0), (x, 0.75, 1.5), (math.radians(-10), 0, 0)))  # back leg + back support
        ends.append(box((0.25, 1.7, 0.22), (x, 0.0, 1.55)))       # seat rail
        ends.append(box((0.25, 1.4, 0.2), (x, 0.0, 2.35)))        # arm rest
        ends.append(box((0.22, 0.22, 0.75), (x, -0.55, 1.95)))    # arm post
    finish(join(ends, "Iron"), "Iron", M["iron"])
    slats = []
    for k in range(3):
        s = box((6.2, 0.48, 0.16), (0, -0.55 + k * 0.55, 1.75))
        bevel(s, 0.05)
        slats.append(s)
    for k in range(2):
        s = box((6.2, 0.14, 0.45), (0, 0.85 + k * 0.08, 2.35 + k * 0.6), (math.radians(-10), 0, 0))
        bevel(s, 0.04)
        slats.append(s)
    finish(join(slats, "Wood"), "Wood", M["wood"])
    export(name)

# ---------- Trash bin ----------
def bin_(name):
    clear()
    body = cyl(1.0, 1.1, 3.2, 10, (0, 0, 1.6))
    finish(body, "Bin", M["bin"])
    trim = [cyl(1.15, 1.15, 0.2, 10, (0, 0, 3.25)), cyl(1.12, 1.12, 0.2, 10, (0, 0, 0.1))]
    lid = cyl(1.2, 0.5, 0.5, 10, (0, 0, 3.6))
    trim.append(lid)
    finish(join(trim, "Iron"), "Iron", M["iron"])
    export(name)

# ---------- Ball rack: steel frame, two rows of basketballs ----------
def ball_rack(name):
    clear()
    frame = []
    for x in (-2.4, 2.4):
        for y in (-0.6, 0.6):
            frame.append(box((0.18, 0.18, 3.4), (x, y, 1.7)))
    for z in (1.2, 2.6):
        for y in (-0.6, 0.6):
            frame.append(box((5.0, 0.15, 0.15), (0, y, z)))
    finish(join(frame, "Steel"), "Steel", M["steel"])
    balls = []
    for z in (1.75, 3.15):
        for i in range(4):
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.55, location=(-1.8 + i * 1.2, 0, z))
            balls.append(bpy.context.active_object)
    finish(join(balls, "Ball"), "Ball", M["orange"], smooth=True)
    export(name)

# ---------- Planter pot with a shrub ----------
def planter(name):
    clear()
    pot = cyl(1.6, 2.1, 2.4, 8, (0, 0, 1.2))
    bevel(pot, 0.08)
    finish(pot, "Pot", M["pot"])
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=2.2, location=(0, 0, 3.4))
    b = bpy.context.active_object
    lumpy(b, 0.5, 0.6, 5)
    finish(b, "Leaves", M["leaf2"])
    export(name)

round_tree("Tree", 1)
round_tree("Tree2", 2)
pine_tree("Pine")
lamp("Lamp")
bench("Bench")
bin_("Bin")
ball_rack("BallRack")
planter("Planter")
print("DONE", out)
