"""Tiny pixel-art helpers: RGBA canvas, ASCII paint, preview sheets."""
import numpy as np
from PIL import Image

# Palette sampled from player/character/hit.png
OUT    = (54, 32, 55, 255)      # outline
DRESS  = (127, 12, 67, 255)     # dress mid
RED    = (192, 41, 72, 255)     # dress light
SCARF  = (184, 192, 239, 255)
WHITE  = (255, 255, 255, 255)
SKIN   = (255, 178, 142, 255)
BELLY  = (255, 247, 0, 255)
GREY   = (214, 214, 214, 255)
EYE    = (31, 88, 169, 255)
BELL   = (248, 180, 0, 255)
WHITE2 = (246, 246, 246, 255)
PALE   = (255, 222, 191, 255)
CYAN   = (85, 205, 255, 255)
SCARFS = (130, 142, 182, 255)
SKIN2  = (246, 158, 113, 255)
MAROON = (106, 5, 53, 255)
DARK   = (87, 2, 43, 255)
SKIN3  = (231, 137, 111, 255)
BOOT   = (197, 197, 197, 255)
BOOT2  = (221, 221, 221, 255)
BOOT3  = (173, 173, 173, 255)
SOFT   = (83, 62, 84, 255)
SOFT2  = (113, 97, 114, 255)

LEGEND = {
    '.': (0, 0, 0, 0),
    'o': OUT,
    'd': DRESS,
    'r': RED,
    'm': MAROON,
    'k': DARK,
    'w': WHITE,
    'W': WHITE2,
    's': SKIN,
    'S': SKIN2,
    't': SKIN3,
    'p': PALE,
    'c': SCARF,
    'C': SCARFS,
    'e': EYE,
    'x': CYAN,
    'y': BELLY,
    'b': BELL,
    'g': BOOT,
    'G': BOOT2,
    'h': BOOT3,
    'u': SOFT,
    'v': SOFT2,
    'L': GREY,
}


def blank(w=66, h=66):
    return np.zeros((h, w, 4), dtype=np.uint8)


def paste(dst, src, x, y, skip_empty=True):
    """Paste src RGBA array onto dst at top-left (x, y)."""
    sh, sw = src.shape[:2]
    dh, dw = dst.shape[:2]
    for j in range(sh):
        ty = y + j
        if ty < 0 or ty >= dh:
            continue
        for i in range(sw):
            tx = x + i
            if tx < 0 or tx >= dw:
                continue
            px = src[j, i]
            if skip_empty and px[3] == 0:
                continue
            dst[ty, tx] = px
    return dst


def paint(canvas, rows, x0=0, y0=0, legend=LEGEND):
    """Paint ASCII rows (list of str) with legend, top-left at (x0, y0)."""
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in ' \t':
                continue
            canvas[y0 + j, x0 + i] = legend[ch]
    return canvas


def to_image(canvas):
    return Image.fromarray(canvas, 'RGBA')


def save(canvas, path):
    to_image(canvas).save(path)


def preview(paths, out, scale=6, bg=(40, 40, 48, 255), cols=2, pad=6, frame=66):
    ims = []
    for p in paths:
        im = Image.open(p).convert('RGBA')
        n = im.width // frame
        for i in range(n):
            ims.append(im.crop((i * frame, 0, (i + 1) * frame, im.height)))
    rows = (len(ims) + cols - 1) // cols
    cw, ch = frame * scale, frame * scale
    sheet = Image.new('RGBA', (cols * cw + pad * (cols + 1), rows * ch + pad * (rows + 1)), bg)
    for k, fr in enumerate(ims):
        big = fr.resize((cw, ch), Image.NEAREST)
        x = pad + (k % cols) * (cw + pad)
        y = pad + (k // cols) * (ch + pad)
        sheet.alpha_composite(big, (x, y))
    sheet.save(out)
    return out
