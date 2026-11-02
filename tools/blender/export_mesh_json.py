# Reads the prop FBX files made by lobby_props.py and writes one JSON file per prop with its
# triangles, so Studio can build the meshes directly (EditableMesh) without the 3D importer.
# Run headless:  blender -b --factory-startup --python export_mesh_json.py -- <fbx_dir> <out_dir>
# JSON: {"name": "Tree", "parts": [{"name": "Trunk", "color": [r,g,b], "v": [x,y,z,...], "t": [i,j,k,...]}]}
# Coordinates are converted to Roblox axes (Y up) and studs (1 Blender unit = 1 stud).
import bpy, bmesh, json, os, sys

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
src = args[0] if len(args) > 0 else os.path.expanduser("~/MBT_props/fbx")
out = args[1] if len(args) > 1 else os.path.expanduser("~/MBT_props/json")
os.makedirs(out, exist_ok=True)

for fn in sorted(os.listdir(src)):
    if not fn.lower().endswith(".fbx"):
        continue
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.ops.import_scene.fbx(filepath=os.path.join(src, fn))
    parts = []
    for ob in bpy.context.scene.objects:
        if ob.type != "MESH":
            continue
        dg = bpy.context.evaluated_depsgraph_get()
        me = ob.evaluated_get(dg).to_mesh()
        bm = bmesh.new()
        bm.from_mesh(me)
        bm.transform(ob.matrix_world)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        verts, tris = [], []
        for f in bm.faces:  # flat shading: three fresh vertices per triangle
            for lv in f.verts:
                x, y, z = lv.co
                verts += [round(x, 3), round(z, 3), round(-y, 3)]
            n = len(verts) // 3
            tris += [n - 3, n - 2, n - 1]
        bm.free()
        ob.evaluated_get(dg).to_mesh_clear()
        col = [0.6, 0.6, 0.6]
        if ob.active_material:
            col = [round(c, 3) for c in ob.active_material.diffuse_color[:3]]
        base = ob.name.split(".")[0]
        parts.append({"name": base, "color": col, "v": verts, "t": tris})
    name = os.path.splitext(fn)[0]
    with open(os.path.join(out, name + ".json"), "w") as fh:
        json.dump({"name": name, "parts": parts}, fh, separators=(",", ":"))
    print("WROTE", name, sum(len(p["t"]) // 3 for p in parts), "tris")
print("DONE", out)
