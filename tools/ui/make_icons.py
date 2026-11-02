"""Draws the HUD icons and the currency bar as PNGs into assets/ui/icons/.

Run: python3 tools/ui/make_icons.py
Icons are 256x256, drawn at 3x and scaled down so the edges stay smooth. Each one has a soft
charcoal outline, a light-to-dark body gradient, a gloss highlight and a small drop shadow, so
they read as chunky 3D-ish stickers next to the buttons (tools/ui/make_ui_art.py).
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ui", "icons")
os.makedirs(OUT, exist_ok=True)
N = 256
S = 3
W = N * S
OUTLINE = (35, 38, 46, 255)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def canvas():
    return Image.new("RGBA", (W, W), (0, 0, 0, 0))


def mask_of(draw_fn):
    m = Image.new("L", (W, W), 0)
    draw_fn(ImageDraw.Draw(m), 255)
    return m


def grad_fill(mask, top, bottom, angle=90):
    """Vertical (or diagonal) gradient clipped to mask."""
    g = Image.new("RGBA", (W, W))
    d = ImageDraw.Draw(g)
    for y in range(W):
        d.line([(0, y), (W, y)], fill=mix(top, bottom, y / (W - 1)))
    if angle != 90:
        g = g.rotate(90 - angle, resample=Image.BICUBIC)
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    out.paste(g, (0, 0), mask)
    return out


def outline_of(mask, px):
    return mask.filter(ImageFilter.MaxFilter(px * 2 + 1))


def shadow_of(mask, dx=0, dy=10, blur=10, alpha=110):
    sh = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    a = mask.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: v * alpha // 255)
    sh.putalpha(a)
    return ImageChops.offset(sh, dx, dy)


def gloss(mask, top_frac=0.48, alpha=90):
    """White highlight on the upper part of a shape."""
    bb = mask.getbbox()
    if not bb:
        return Image.new("RGBA", (W, W), (0, 0, 0, 0))
    x0, y0, x1, y1 = bb
    g = Image.new("L", (W, W), 0)
    ImageDraw.Draw(g).ellipse([x0 + (x1 - x0) * 0.12, y0 + (y1 - y0) * 0.04, x1 - (x1 - x0) * 0.12, y0 + (y1 - y0) * top_frac], fill=alpha)
    g = g.filter(ImageFilter.GaussianBlur(6 * S))
    g = ImageChops.multiply(g, mask)
    out = Image.new("RGBA", (W, W), (255, 255, 255, 0))
    out.putalpha(g)
    return out


def sticker(layers, mask, ol=7):
    """Stack: drop shadow, charcoal outline, then the coloured layers."""
    img = canvas()
    om = outline_of(mask, ol * S // 2)
    img.alpha_composite(shadow_of(om, dy=5 * S, blur=4 * S))
    o = Image.new("RGBA", (W, W), OUTLINE)
    img.paste(o, (0, 0), om)
    for l in layers:
        img.alpha_composite(l)
    return img


def save(img, name):
    img.resize((N, N), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))


def s(v):
    return int(v * S)


# --- Coin: gold disc, rim, embossed basketball seams --------------------------------------
def coin():
    c = (s(128), s(124))
    R = s(96)
    m = mask_of(lambda d, f: d.ellipse([c[0] - R, c[1] - R, c[0] + R, c[1] + R], fill=f))
    body = grad_fill(m, hexc("ffe27a"), hexc("e8a21c"))
    r2 = s(74)
    inner = mask_of(lambda d, f: d.ellipse([c[0] - r2, c[1] - r2, c[0] + r2, c[1] + r2], fill=f))
    face = grad_fill(inner, hexc("f5b52e"), hexc("ffd75a"))
    seams = canvas()
    sd = ImageDraw.Draw(seams)
    col = hexc("c98512")
    w = s(7)
    sd.line([c[0] - r2 + s(8), c[1], c[0] + r2 - s(8), c[1]], fill=col, width=w)
    sd.line([c[0], c[1] - r2 + s(8), c[0], c[1] + r2 - s(8)], fill=col, width=w)
    sd.arc([c[0] - r2 - s(30), c[1] - r2 + s(10), c[0] - s(18), c[1] + r2 - s(10)], -60, 60, fill=col, width=w)
    sd.arc([c[0] + s(18), c[1] - r2 + s(10), c[0] + r2 + s(30), c[1] + r2 - s(10)], 120, 240, fill=col, width=w)
    seams.putalpha(ImageChops.multiply(seams.getchannel("A"), inner))
    ring = canvas()
    ImageDraw.Draw(ring).ellipse([c[0] - r2, c[1] - r2, c[0] + r2, c[1] + r2], outline=hexc("b8780f"), width=s(5))
    save(sticker([body, face, seams, ring, gloss(m)], m), "coin")


# --- Gem: faceted diamond ----------------------------------------------------------------
def gem():
    cx = s(128)
    top, mid, bot = s(48), s(104), s(222)
    L, Rr = s(30), s(226)
    tl, tr = s(78), s(178)
    outline_pts = [(tl, top), (tr, top), (Rr, mid), (cx, bot), (L, mid)]
    m = mask_of(lambda d, f: d.polygon(outline_pts, fill=f))
    img_layers = []
    facets = [
        ([(tl, top), (cx, top), (s(104), mid), (L, mid)], "ff9fe0", "ff6fc8"),
        ([(cx, top), (tr, top), (Rr, mid), (s(152), mid)], "ffc4ee", "ff8fd5"),
        ([(cx, top), (s(152), mid), (s(104), mid)], "ffe1f6", "ffb3e6"),
        ([(L, mid), (s(104), mid), (cx, bot)], "e84fb0", "b8327f"),
        ([(s(104), mid), (s(152), mid), (cx, bot)], "ff7fcf", "d9459e"),
        ([(s(152), mid), (Rr, mid), (cx, bot)], "c73a92", "9c2a72"),
    ]
    for pts, a, b in facets:
        fm = mask_of(lambda d, f, p=pts: d.polygon(p, fill=f))
        img_layers.append(grad_fill(fm, hexc(a), hexc(b)))
    edges = canvas()
    ed = ImageDraw.Draw(edges)
    for pts, _, _ in facets:
        ed.polygon(pts, outline=(255, 255, 255, 70))
    sp = canvas()
    spd = ImageDraw.Draw(sp)
    spd.polygon([(s(92), s(66)), (s(98), s(80)), (s(112), s(86)), (s(98), s(92)), (s(92), s(106)), (s(86), s(92)), (s(72), s(86)), (s(86), s(80))], fill=(255, 255, 255, 230))
    save(sticker(img_layers + [edges, gloss(m, 0.4, 60), sp], m), "gem")


# --- Trophy (Elo) --------------------------------------------------------------------------
def trophy():
    def shape(d, f):
        d.pieslice([s(62), s(-10), s(194), s(150)], 0, 180, fill=f)  # cup
        d.rectangle([s(62), s(40), s(194), s(70)], fill=f)
        d.rectangle([s(116), s(140), s(140), s(184)], fill=f)  # stem
        d.rounded_rectangle([s(78), s(180), s(178), s(214)], s(8), fill=f)  # base
        d.ellipse([s(28), s(52), s(80), s(116)], outline=f, width=s(14))  # handles
        d.ellipse([s(176), s(52), s(228), s(116)], outline=f, width=s(14))
    m = mask_of(shape)
    body = grad_fill(m, hexc("fff0a0"), hexc("e09a12"))
    star = canvas()
    sd = ImageDraw.Draw(star)
    pts = []
    for k in range(10):
        r = s(24) if k % 2 == 0 else s(10)
        a = -math.pi / 2 + k * math.pi / 5
        pts.append((s(128) + r * math.cos(a), s(92) + r * math.sin(a)))
    sd.polygon(pts, fill=hexc("fffbe0"))
    save(sticker([body, star, gloss(m, 0.42, 80)], m), "trophy")


# --- Shop: striped awning storefront ---------------------------------------------------------
def shop():
    def shape(d, f):
        d.rounded_rectangle([s(50), s(98), s(206), s(214)], s(10), fill=f)
        d.polygon([(s(34), s(100)), (s(58), s(46)), (s(198), s(46)), (s(222), s(100))], fill=f)
    m = mask_of(shape)
    wall = grad_fill(mask_of(lambda d, f: d.rounded_rectangle([s(50), s(98), s(206), s(214)], s(10), fill=f)), hexc("fff6e8"), hexc("e6d9c4"))
    aw = canvas()
    ad = ImageDraw.Draw(aw)
    stripes = 5
    for k in range(stripes):
        x0 = s(34) + k * (s(188) / stripes)
        x1 = x0 + s(188) / stripes
        tx0 = s(58) + k * (s(140) / stripes)
        tx1 = tx0 + s(140) / stripes
        ad.polygon([(x0, s(100)), (tx0, s(46)), (tx1, s(46)), (x1, s(100))], fill=hexc("ff7a52") if k % 2 == 0 else hexc("fff2e6"))
    for k in range(stripes):  # scalloped edge
        x0 = s(34) + k * (s(188) / stripes)
        ad.pieslice([x0, s(84), x0 + s(188) / stripes, s(118)], 0, 180, fill=hexc("ff7a52") if k % 2 == 0 else hexc("fff2e6"))
    door = canvas()
    dd = ImageDraw.Draw(door)
    dd.rounded_rectangle([s(108), s(140), s(148), s(214)], s(6), fill=hexc("5aa8e8"))
    dd.rounded_rectangle([s(64), s(132), s(98), s(170)], s(5), fill=hexc("8fd0ff"))
    dd.rounded_rectangle([s(158), s(132), s(192), s(170)], s(5), fill=hexc("8fd0ff"))
    full = mask_of(lambda d, f: (shape(d, f), d.pieslice([s(34), s(84), s(222), s(118)], 0, 180, fill=f)))
    save(sticker([wall, aw, door, gloss(full, 0.35, 50)], full), "shop")


# --- Pack: two foil packs fanned -----------------------------------------------------------
def pack():
    img = canvas()
    layers = []
    full = Image.new("L", (W, W), 0)
    for ang, col_a, col_b, dx in ((-14, "7cc6ff", "3e8fe0", -26), (10, "ffb36b", "ff7a3d", 26)):
        pm = Image.new("L", (W, W), 0)
        ImageDraw.Draw(pm).rounded_rectangle([s(78), s(36), s(178), s(214)], s(10), fill=255)
        pm = pm.rotate(ang, resample=Image.BICUBIC, center=(s(128), s(200)))
        pm = ImageChops.offset(pm, s(dx), 0)
        body = grad_fill(pm, hexc(col_a), hexc(col_b))
        crimp = canvas()
        cd = ImageDraw.Draw(crimp)
        for y in (s(36), s(200)):
            for x in range(s(80), s(178), s(9)):
                cd.rectangle([x, y, x + s(4), y + s(14)], fill=(255, 255, 255, 90))
        crimp = crimp.rotate(ang, resample=Image.BICUBIC, center=(s(128), s(200)))
        crimp = ImageChops.offset(crimp, s(dx), 0)
        crimp.putalpha(ImageChops.multiply(crimp.getchannel("A"), pm))
        ball = canvas()
        bd = ImageDraw.Draw(ball)
        bd.ellipse([s(104), s(88), s(152), s(136)], fill=hexc("f08a3a"), outline=OUTLINE, width=s(4))
        bd.line([s(104), s(112), s(152), s(112)], fill=OUTLINE, width=s(3))
        bd.line([s(128), s(88), s(128), s(136)], fill=OUTLINE, width=s(3))
        ball = ball.rotate(ang, resample=Image.BICUBIC, center=(s(128), s(200)))
        ball = ImageChops.offset(ball, s(dx), 0)
        o = outline_of(pm, s(3))
        ol = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        ol.paste(Image.new("RGBA", (W, W), OUTLINE), (0, 0), o)
        layers += [ol, body, crimp, ball, gloss(pm, 0.4, 60)]
        full = ImageChops.lighter(full, pm)
    img.alpha_composite(shadow_of(outline_of(full, s(3)), dy=5 * S, blur=4 * S))
    for l in layers:
        img.alpha_composite(l)
    save(img, "pack")


# --- Club: jersey ----------------------------------------------------------------------------
def club():
    pts = [(s(80), s(40)), (s(104), s(40)), (s(128), s(62)), (s(152), s(40)), (s(176), s(40)), (s(226), s(82)), (s(200), s(118)), (s(182), s(104)), (s(182), s(218)), (s(74), s(218)), (s(74), s(104)), (s(56), s(118)), (s(30), s(82))]
    m = mask_of(lambda d, f: d.polygon(pts, fill=f))
    body = grad_fill(m, hexc("7fd0ff"), hexc("2f86d8"))
    trim = canvas()
    td = ImageDraw.Draw(trim)
    td.line([(s(104), s(42)), (s(128), s(64)), (s(152), s(42))], fill=hexc("ffffff"), width=s(8))
    td.line([(s(182), s(104)), (s(200), s(118))], fill=hexc("ffffff"), width=s(6))
    td.line([(s(74), s(104)), (s(56), s(118))], fill=hexc("ffffff"), width=s(6))
    num = canvas()
    nd = ImageDraw.Draw(num)
    # a chunky "1" drawn as shapes so no font is needed
    nd.polygon([(s(120), s(98)), (s(142), s(92)), (s(142), s(186)), (s(122), s(186)), (s(122), s(118)), (s(110), s(122))], fill=hexc("ffffff"))
    save(sticker([body, trim, num, gloss(m, 0.4, 60)], m), "club")


# --- Quests: clipboard with checks ---------------------------------------------------------
def quests():
    m = mask_of(lambda d, f: d.rounded_rectangle([s(58), s(42), s(198), s(220)], s(14), fill=f))
    board = grad_fill(m, hexc("ffb3e3"), hexc("e85fb4"))
    paper_m = mask_of(lambda d, f: d.rounded_rectangle([s(74), s(66), s(182), s(206)], s(8), fill=f))
    paper = grad_fill(paper_m, hexc("ffffff"), hexc("eef0f4"))
    clip = canvas()
    cd = ImageDraw.Draw(clip)
    cd.rounded_rectangle([s(98), s(30), s(158), s(62)], s(8), fill=hexc("9aa3b2"), outline=OUTLINE, width=s(4))
    marks = canvas()
    md = ImageDraw.Draw(marks)
    for k, done in enumerate((True, True, False)):
        y = s(92) + k * s(36)
        md.rounded_rectangle([s(86), y, s(110), y + s(24)], s(5), outline=OUTLINE, width=s(4))
        if done:
            md.line([(s(90), y + s(12)), (s(97), y + s(20)), (s(112), y - s(2))], fill=hexc("4cc35a"), width=s(6))
        md.rounded_rectangle([s(120), y + s(8), s(170), y + s(16)], s(4), fill=hexc("c7ccd6"))
    save(sticker([board, paper, marks, clip, gloss(m, 0.3, 40)], m), "quests")


# --- Play: basketball -------------------------------------------------------------------------
def play():
    c = (s(128), s(128))
    R = s(98)
    m = mask_of(lambda d, f: d.ellipse([c[0] - R, c[1] - R, c[0] + R, c[1] + R], fill=f))
    body = grad_fill(m, hexc("ffa45c"), hexc("e0601e"))
    seams = canvas()
    sd = ImageDraw.Draw(seams)
    w = s(8)
    sd.line([c[0] - R, c[1], c[0] + R, c[1]], fill=OUTLINE, width=w)
    sd.line([c[0], c[1] - R, c[0], c[1] + R], fill=OUTLINE, width=w)
    sd.arc([c[0] - R - s(52), c[1] - R + s(8), c[0] - s(26), c[1] + R - s(8)], -62, 62, fill=OUTLINE, width=w)
    sd.arc([c[0] + s(26), c[1] - R + s(8), c[0] + R + s(52), c[1] + R - s(8)], 118, 242, fill=OUTLINE, width=w)
    seams.putalpha(ImageChops.multiply(seams.getchannel("A"), m))
    save(sticker([body, seams, gloss(m, 0.46, 80)], m), "ball")


# --- Codes: ticket ------------------------------------------------------------------------------
def codes():
    def shape(d, f):
        d.rounded_rectangle([s(28), s(70), s(228), s(186)], s(16), fill=f)
    m = mask_of(shape)
    # notches
    nm = mask_of(lambda d, f: (d.ellipse([s(14), s(110), s(46), s(146)], fill=f), d.ellipse([s(210), s(110), s(242), s(146)], fill=f)))
    m = ImageChops.subtract(m, nm)
    body = grad_fill(m, hexc("b6f08c"), hexc("5cbf4a"))
    det = canvas()
    dd = ImageDraw.Draw(det)
    for y in range(s(80), s(180), s(14)):
        dd.line([s(84), y, s(84), y + s(7)], fill=(255, 255, 255, 170), width=s(4))
    # "?" made of shapes
    dd.arc([s(126), s(92), s(178), s(140)], 180, 90, fill=hexc("ffffff"), width=s(12))
    dd.line([s(152), s(140), s(152), s(152)], fill=hexc("ffffff"), width=s(12))
    dd.ellipse([s(145), s(160), s(159), s(174)], fill=hexc("ffffff"))
    save(sticker([body, det, gloss(m, 0.4, 60)], m), "codes")


# --- Currency bar: dark glossy pill (9-slice) -----------------------------------------------------
def bar():
    w, h = 240, 88
    Wb, Hb = w * S, h * S
    img = Image.new("RGBA", (Wb, Hb), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = Hb // 2 - s(4)
    sh = Image.new("RGBA", (Wb, Hb), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([s(4), s(10), Wb - s(4), Hb - s(2)], r, fill=(0, 0, 0, 90))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(s(3))))
    d.rounded_rectangle([0, 0, Wb - 1, Hb - s(6)], r, fill=OUTLINE)
    inner = [s(5), s(5), Wb - 1 - s(5), Hb - s(11)]
    fm = Image.new("L", (Wb, Hb), 0)
    ImageDraw.Draw(fm).rounded_rectangle(inner, r - s(5), fill=255)
    g = Image.new("RGBA", (Wb, Hb))
    gd = ImageDraw.Draw(g)
    for y in range(Hb):
        gd.line([(0, y), (Wb, y)], fill=mix(hexc("4c5263"), hexc("2c303b"), y / (Hb - 1)))
    img.paste(g, (0, 0), fm)
    gl = Image.new("L", (Wb, Hb), 0)
    ImageDraw.Draw(gl).rounded_rectangle([s(14), s(8), Wb - s(14), int(Hb * 0.42)], r, fill=60)
    gl = gl.filter(ImageFilter.GaussianBlur(s(3)))
    white = Image.new("RGBA", (Wb, Hb), (255, 255, 255, 0))
    white.putalpha(ImageChops.multiply(gl, fm))
    img.alpha_composite(white)
    img.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, "bar.png"))


for fn in (coin, gem, trophy, shop, pack, club, quests, play, codes, bar):
    fn()
print("bar 240x88: SliceCenter = Rect(44, 0, 196, 82)")
print("wrote", sorted(os.listdir(OUT)))
