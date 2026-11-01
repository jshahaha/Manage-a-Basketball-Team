#!/usr/bin/env python3
"""Regenerate src/shared/AnimClips.lua from docs/prototypes/walkout3d.js.

The walkout prototype on the UI page is where clips are authored and previewed in 3D.
This converts its CLIPS table (three.js space, character faces +Z) to Roblox space
(character faces -Z): rotations (rx, ry, rz) -> (-rx, ry, -rz), positions (x, y, z) -> (-x, y, -z).
Needs node on PATH.  Usage: python3 scripts/gen_animclips.py
"""
import json, subprocess, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
js = ROOT / "docs/prototypes/walkout3d.js"
data = json.loads(subprocess.run(["node", "-e", f"global.window={{THREE:{{}}}};require({json.dumps(str(js))});process.stdout.write(JSON.stringify(window.Walkout3D.CLIPS))"], capture_output=True, text=True, check=True).stdout)
C = data
MAP = {'Root':'Root','Waist':'Waist','Neck':'Neck','RShoulder':'RightShoulder','RElbow':'RightElbow','LShoulder':'LeftShoulder','LElbow':'LeftElbow','RHip':'RightHip','RKnee':'RightKnee','LHip':'LeftHip','LKnee':'LeftKnee'}
MOVES = [('Sniper','Shoot'),('PostScorer','Dunk'),('Slasher','Dunk'),('FloorGeneral','Dribble'),('AllAround','Dribble'),('RimProtector','Block'),('Lockdown','Block'),('GlassCleaner','Block')]

def num(x):
    s = ('%.3f' % x).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'

def flipv(v):  # three.js -> Roblox position
    return [-v[0], v[1], -v[2]]

out = (ROOT / "src/shared/AnimClips.lua").read_text()
head, sep, tail = out.partition("AnimClips.Clips = {")
_, _, rest = tail.partition("\n}\n")
L = ["AnimClips.Clips = {"]
for name, c in C.items():
    L.append(f'\t{name} = {{')
    L.append(f'\t\tlength = {num(c["len"])},')
    if c.get('loop'): L.append('\t\tloop = true,')
    if c.get('hold'): L.append('\t\thold = true,')
    if 'view' in c: L.append(f'\t\tcameraYaw = {num(c["view"])},')
    if 'cam' in c:
        p, l = flipv(c['cam'][0]), flipv(c['cam'][1])
        L.append('\t\tcamera = { pos = { %s }, lookAt = { %s } },' % (', '.join(map(num, p)), ', '.join(map(num, l))))
    L.append('\t\tjoints = {')
    for j, keys in c['keys'].items():
        ks = ', '.join('{ %s, %s, %s, %s }' % (num(k[0]), num(-k[1]), num(k[2]), num(-k[3])) for k in keys)
        L.append(f'\t\t\t{MAP[j]} = {{ {ks} }},')
    L.append('\t\t},')
    if c.get('root'):
        ks = ', '.join('{ %s, %s, %s, %s, %s, %s }' % (num(k[0]), num(-k[1]), num(k[2]), num(-k[3]), num(k[4]), num(-k[5])) for k in c['root'])
        L.append(f'\t\troot = {{ {ks} }},')
    if c.get('ball'):
        ks = ', '.join('{ %s, "%s", %s, %s }' % (num(k[0]), k[1], num(k[2] if len(k) > 2 else 0), num(k[3] if len(k) > 3 else 0)) for k in c['ball'])
        L.append(f'\t\tball = {{ {ks} }},')
    if c.get('hoopAt'): L.append(f'\t\thoopAt = {{ {num(c["hoopAt"][0])}, "{c["hoopAt"][1]}" }},')
    if c.get('hoopOff'): L.append('\t\thoopOffset = { %s, %s },' % (num(-c['hoopOff'][0]), num(c['hoopOff'][1])))
    if c.get('shotHoop'): L.append('\t\tshotHoop = true,')
    if c.get('events'):
        ks = ', '.join('{ %s, "%s" }' % (num(e[0]), e[1]) for e in sorted(c['events']))
        L.append(f'\t\tevents = {{ {ks} }},')
    L.append('\t},')
L.append('}')
(ROOT / "src/shared/AnimClips.lua").write_text(head + "\n".join(L) + "\n" + rest)
print("wrote src/shared/AnimClips.lua with", len(C), "clips")
