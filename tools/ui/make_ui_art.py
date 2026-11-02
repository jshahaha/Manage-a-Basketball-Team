"""Draws the Blacktop UI art as PNGs (buttons, panel, tape, chain-link) into assets/ui/.

Run: python3 tools/ui/make_ui_art.py
Buttons and the panel are 9-slice images: the corners stay sharp at any size. The slice
margins are printed so the Luau side (src/client/Theme.lua) can use the same numbers.
Everything is drawn at 2x and scaled down for smooth edges.
"""
import os, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ui")
os.makedirs(OUT, exist_ok=True)
S = 2  # supersample

def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def mix(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))

def shade(c, k):
    return (max(0, min(255, int(c[0] * k))), max(0, min(255, int(c[1] * k))), max(0, min(255, int(c[2] * k))), c[3])

def vgrad(w, h, top, bottom):
    g = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(g)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=mix(top, bottom, y / max(1, h - 1)))
    return g

def rrect_mask(w, h, box, r):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle(box, r, fill=255)
    return m

def speckle(w, h, seed, amount=0.06, size=1):
    rnd = random.Random(seed)
    n = Image.new("L", (w, h), 128)
    d = ImageDraw.Draw(n)
    for _ in range(int(w * h * amount / (size * size))):
        x, y = rnd.randrange(w), rnd.randrange(h)
        v = rnd.choice((70, 90, 170, 200))
        d.rectangle([x, y, x + size - 1, y + size - 1], fill=v)
    return n.filter(ImageFilter.GaussianBlur(0.6))

def apply_speckle(img, mask, seed, strength=0.18):
    w, h = img.size
    n = speckle(w, h, seed)
    rgb = img.convert("RGB")
    # overlay-ish: lighten/darken by noise around mid grey
    light = Image.merge("RGB", (n, n, n))
    blended = ImageChops.overlay(rgb, light)
    out = Image.blend(rgb, blended, strength).convert("RGBA")
    out.putalpha(img.getchannel("A"))
    return out

def button(name, face, w=160, h=96, pressed=False):
    """Chunky sticker slab: black outline, darker lip underneath, gradient face, gloss band,
    light inner edge and a grain texture."""
    W, H = w * S, h * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    r = 16 * S
    ol = 5 * S  # outline
    lip = 0 if pressed else 8 * S
    top = 0 if not pressed else 6 * S
    # drop shadow
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([2 * S, top + 6 * S, W - 2 * S, H - 1], r, fill=(0, 0, 0, 110))
    sh = sh.filter(ImageFilter.GaussianBlur(3 * S))
    img.alpha_composite(sh)
    d = ImageDraw.Draw(img)
    # outline body (covers lip + face)
    d.rounded_rectangle([0, top, W - 1, H - 1 - 4 * S], r, fill=hexc("111111"))
    # lip
    inner = [ol, top + ol, W - 1 - ol, H - 1 - 4 * S - ol]
    d.rounded_rectangle(inner, r - ol, fill=shade(face, 0.62))
    # face
    fbox = [ol, top + ol, W - 1 - ol, H - 1 - 4 * S - ol - lip]
    fw, fh = fbox[2] - fbox[0], fbox[3] - fbox[1]
    g = vgrad(fw, fh, shade(face, 1.12), shade(face, 0.9))
    m = rrect_mask(fw, fh, [0, 0, fw - 1, fh - 1], r - ol)
    g = apply_speckle(g, m, hash(name) & 0xffff, 0.22)
    img.paste(g, (fbox[0], fbox[1]), m)
    # gloss band on the top 40%
    gl = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gl)
    gd.rounded_rectangle([4 * S, 3 * S, fw - 4 * S, int(fh * 0.42)], r - ol - 2 * S, fill=(255, 255, 255, 70))
    gl = gl.filter(ImageFilter.GaussianBlur(1.2 * S))
    gm = Image.new("L", (fw, fh), 0)
    gm.paste(m, (0, 0))
    gl.putalpha(ImageChops.multiply(gl.getchannel("A"), gm))
    img.alpha_composite(gl, (fbox[0], fbox[1]))
    # light inner edge along the top
    d.rounded_rectangle([fbox[0] + 2 * S, fbox[1] + 2 * S, fbox[2] - 2 * S, fbox[3] - 2 * S], r - ol - 2 * S, outline=(255, 255, 255, 90), width=2 * S)
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, name + ".png"))
    return img

def panel():
    """Asphalt panel: black frame, bevelled inner edge, speckled asphalt with a few cracks."""
    w, h = 256, 256
    W, H = w * S, h * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = 18 * S
    d.rounded_rectangle([0, 0, W - 1, H - 1], r, fill=hexc("111111"))
    ib = [6 * S, 6 * S, W - 1 - 6 * S, H - 1 - 6 * S]
    iw, ih = ib[2] - ib[0], ib[3] - ib[1]
    g = vgrad(iw, ih, hexc("3b3e44"), hexc("2a2c30"))
    rnd = random.Random(4)
    gd = ImageDraw.Draw(g)
    for _ in range(int(iw * ih * 0.05)):
        x, y = rnd.randrange(iw), rnd.randrange(ih)
        v = rnd.randint(30, 95)
        gd.point((x, y), fill=(v, v, v + 4, 255))
    for _ in range(5):  # hairline cracks
        x, y = rnd.randrange(iw), rnd.randrange(ih)
        pts = [(x, y)]
        for _ in range(8):
            x += rnd.randint(-14, 14) * S // 2
            y += rnd.randint(4, 16) * S // 2
            pts.append((x, y))
        gd.line(pts, fill=(22, 23, 26, 255), width=S)
    g = g.filter(ImageFilter.GaussianBlur(0.5))
    m = rrect_mask(iw, ih, [0, 0, iw - 1, ih - 1], r - 6 * S)
    img.paste(g, (ib[0], ib[1]), m)
    d.rounded_rectangle(ib, r - 6 * S, outline=(255, 255, 255, 38), width=2 * S)
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, "panel.png"))

def tape(name, base):
    """Gaffer tape strip with fibres, a soft sheen and torn ends."""
    w, h = 320, 80
    W, H = w * S, h * S
    rnd = random.Random(hash(name) & 0xffff)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    g = vgrad(W, H, shade(base, 1.04), shade(base, 0.9))
    gd = ImageDraw.Draw(g)
    for _ in range(260):  # fibres along the tape
        y = rnd.randrange(H)
        x = rnd.randrange(W)
        L = rnd.randint(20, 120) * S
        c = shade(base, rnd.uniform(0.86, 1.06))
        gd.line([(x, y), (x + L, y)], fill=c, width=1)
    # torn edges: zig-zag polygon mask
    pts = []
    x = 0
    pts.append((0, 0))
    for y in range(0, H + 1, 6 * S):
        pts.append((rnd.randint(0, 8 * S), y))
    pts.append((0, H))
    left = pts
    m = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(m)
    poly = []
    for y in range(0, H + 1, 6 * S):
        poly.append((rnd.randint(0, 9 * S), y))
    for y in range(H, -1, -6 * S):
        poly.append((W - 1 - rnd.randint(0, 9 * S), y))
    md.polygon(poly, fill=255)
    # tiny edge waviness top/bottom
    md.rectangle([0, 0, W, 2 * S], fill=0)
    md.rectangle([0, H - 2 * S, W, H], fill=0)
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh.putalpha(m.filter(ImageFilter.GaussianBlur(2 * S)).point(lambda v: v * 0.45))
    img.alpha_composite(sh, (2 * S, 3 * S)) if False else None
    img.paste(g, (0, 0), m)
    # sheen
    sheen = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    ImageDraw.Draw(sheen).rectangle([0, int(H * 0.18), W, int(H * 0.34)], fill=(255, 255, 255, 46))
    sheen = sheen.filter(ImageFilter.GaussianBlur(3 * S))
    sheen.putalpha(ImageChops.multiply(sheen.getchannel("A"), m))
    img.alpha_composite(sheen)
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, name + ".png"))

def chainlink():
    """Tileable chain-link fence (transparent background)."""
    t = 48
    W = t * S
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = (30, 30, 34, 150)
    hi = (220, 225, 232, 70)
    for off in (-W, 0, W):
        d.line([(off, 0), (off + W, W)], fill=c, width=3 * S)
        d.line([(off + W, 0), (off, W)], fill=c, width=3 * S)
        d.line([(off + S, 0), (off + W + S, W)], fill=hi, width=S)
    img = img.resize((t, t), Image.LANCZOS)
    img.save(os.path.join(OUT, "chainlink.png"))

COLORS = {
    "yellow": "f5d33a", "orange": "ff6a3d", "lime": "9ee05a", "sky": "4fb8ff",
    "pink": "ff6fc8", "red": "ff4d4d", "slate": "3a3d44", "purple": "a24bff",
}
for n, c in COLORS.items():
    button("btn_" + n, hexc(c))
    button("btn_" + n + "_down", hexc(c), pressed=True)
panel()
tape("tape_cream", hexc("f3efe2"))
tape("tape_yellow", hexc("f5d33a"))
chainlink()
print("button 160x96: SliceCenter = Rect(24, 20, 136, 72)")
print("panel 256x256: SliceCenter = Rect(32, 32, 224, 224)")
print("wrote", sorted(os.listdir(OUT)))
