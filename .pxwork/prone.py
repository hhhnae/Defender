"""Prone pose: real sprite parts from hit.png, rotated and retouched."""
import numpy as np
from PIL import Image
import px

SRC = r"D:\Godot project\Defender\player\character\hit.png"
EXP = r"D:\Godot project\Defender\.pxwork"
src = np.array(Image.open(SRC).convert("RGBA"))
F0 = src[0:66, 0:66]

HEAD = F0[7:26, 21:43]        # 19 x 22
DRESS = np.rot90(F0[27:43, 26:38], k=-1)   # 12 x 16
LEG = np.rot90(F0[44:56, 23:31], k=-1)     # 8 x 12


def put(c, block, x, y, over=None):
    """Paste, optionally limiting to a column range."""
    h, w = block.shape[:2]
    for j in range(h):
        for i in range(w):
            p = block[j, i]
            if p[3] == 0:
                continue
            tx, ty = x + i, y + j
            if over and not (over[0] <= tx <= over[1]):
                continue
            c[ty, tx] = p


def build_prone(head_x=32, head_bottom=55, dress_x=20, leg_x=10):
    c = px.blank()
    put(c, LEG, leg_x, 48)
    put(c, DRESS, dress_x, 44)
    # wipe the neck-hole / collar leftovers at the dress shoulder end
    for y in range(43, 49):
        for x in range(dress_x + 11, dress_x + 17):
            if 0 <= x < 66 and c[y, x][3]:
                c[y, x] = px.MAROON if y > 46 else px.DRESS
    # scarf sliver at the neck, between shoulders and head
    for y in range(45, 52):
        for x in range(dress_x + 13, dress_x + 17):
            if 0 <= x < 66 and c[y, x][3]:
                c[y, x] = px.SCARFS if y > 47 else px.SCARF
    put(c, HEAD, head_x, head_bottom - 18)
    return c


if __name__ == "__main__":
    c = build_prone()
    p = EXP + r"\p1.png"
    px.save(c, p)
    px.preview([p], EXP + r"\p1_x8.png", scale=8, cols=1)
    im = Image.open(p)
    crop = im.crop((0, 38, 60, 60))
    crop = crop.resize((crop.width * 16, crop.height * 16), Image.NEAREST)
    bg = Image.new("RGBA", crop.size, (40, 40, 48, 255)); bg.alpha_composite(crop)
    bg.save(EXP + r"\p1_zoom.png")
    print("ok")
