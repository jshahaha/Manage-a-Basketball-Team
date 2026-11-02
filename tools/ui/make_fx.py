"""Effect sprites for the UI: all drawn white so Roblox can tint them with ImageColor3.

glow    soft round glow to sit behind important buttons and rare cards
sparkle 4-point twinkle star
wisp    soft drifting puff of light
shine   diagonal light streak that sweeps across buttons and packs
rays    sunburst that spins behind a pack or card reveal

Run: python3 tools/ui/make_fx.py  (writes assets/ui/fx/*.png)
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ui", "fx")
os.makedirs(OUT, exist_ok=True)


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"))


def radial(size, falloff):
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    px = img.load()
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c) / c
            a = max(0.0, 1 - d) ** falloff
            px[x, y] = (255, 255, 255, int(255 * a))
    return img


# Glow: wide soft falloff.
save(radial(256, 2.2), "glow")

# Wisp: a soft blob squashed a little, blurred.
w = Image.new("RGBA", (128, 128), (255, 255, 255, 0))
d = ImageDraw.Draw(w)
d.ellipse((30, 40, 98, 88), fill=(255, 255, 255, 200))
w = w.filter(ImageFilter.GaussianBlur(14))
save(w, "wisp")

# Sparkle: two thin diamonds crossed, a bright core, and a small halo.
S = 128
sp = radial(S, 3.5)
sp = Image.blend(Image.new("RGBA", (S, S), (255, 255, 255, 0)), sp, 0.6)
d = ImageDraw.Draw(sp)
c = S / 2
for (lx, ly) in ((60, 6), (6, 60)):
    d.polygon([(c, c - ly), (c + lx * 0.12 if ly > lx else c + lx, c), (c, c + ly), (c - (lx * 0.12 if ly > lx else lx), c)], fill=(255, 255, 255, 255))
for (lx, ly) in ((6, 60),):
    d.polygon([(c - lx, c), (c, c - 6), (c + lx, c), (c, c + 6)], fill=(255, 255, 255, 255))
d.polygon([(c, c - 60), (c + 7, c), (c, c + 60), (c - 7, c)], fill=(255, 255, 255, 255))
d.polygon([(c - 60, c), (c, c - 7), (c + 60, c), (c, c + 7)], fill=(255, 255, 255, 255))
sp = sp.filter(ImageFilter.GaussianBlur(1.2))
save(sp, "sparkle")

# Shine: a soft diagonal streak on a wide transparent strip. It slides across a button without
# needing rotation (rotated children are not clipped in Roblox).
sh = Image.new("RGBA", (256, 128), (255, 255, 255, 0))
px = sh.load()
for y in range(128):
    for x in range(256):
        # distance from the slanted centre line x = 128 + (64 - y) * 0.5
        dx = abs(x - (128 + (64 - y) * 0.5))
        t = max(0.0, 1 - dx / 26)
        thin = max(0.0, 1 - abs(x - (128 + (64 - y) * 0.5) - 34) / 7)
        a = int(220 * t ** 2.2 + 160 * thin ** 2)
        px[x, y] = (255, 255, 255, min(255, a))
save(sh, "shine")

# Rays: 16 tapered beams from the centre, fading out to the edge.
R = 512
rays = Image.new("RGBA", (R, R), (255, 255, 255, 0))
d = ImageDraw.Draw(rays)
c = R / 2
n = 16
for i in range(n):
    a0 = 2 * math.pi * i / n
    half = math.pi / n * 0.45
    p1 = (c + math.cos(a0 - half) * R, c + math.sin(a0 - half) * R)
    p2 = (c + math.cos(a0 + half) * R, c + math.sin(a0 + half) * R)
    d.polygon([(c, c), p1, p2], fill=(255, 255, 255, 255))
mask = radial(R, 1.3)
alpha = Image.new("L", (R, R))
ra, ma = rays.getchannel("A"), mask.getchannel("A")
alpha = Image.frombytes("L", (R, R), bytes(int(a * b / 255) for a, b in zip(ra.tobytes(), ma.tobytes())))
rays.putalpha(alpha.filter(ImageFilter.GaussianBlur(2)))
save(rays, "rays")
print("wrote", sorted(os.listdir(OUT)))
