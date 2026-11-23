"""Deliverable builder: 主动趴下 (voluntary lie-down), 4 frames of 66x66.

Outputs into player/character/:
  prone.png          4 frames x 66x66 (same layout as idle.png / hit.png)
  prone.aseprite     editable source (written by Aseprite CLI)
  prone_frames.tres  SpriteFrames, animation "prone", 10 fps, no loop
"""
import numpy as np
from PIL import Image
import px
from prone import put, HEAD, DRESS, LEG

CHAR = r"D:\Godot project\Defender\player\character"
GROUND = 55

idle = np.array(Image.open(CHAR + r"\idle.png").convert("RGBA"))[:, 0:66]


def prone_core(head_x=31):
    c = px.blank()
    put(c, LEG, 10, 48)
    put(c, DRESS, 20, 44)
    for y in range(43, 49):
        for x in range(31, 37):
            if c[y, x][3]:
                c[y, x] = px.MAROON if y > 46 else px.DRESS
    for x, y in ((35, 44), (36, 44), (36, 45)):
        c[y, x] = (0, 0, 0, 0)
    foreign = {px.WHITE, px.WHITE2, px.SCARF, px.SCARFS, px.GREY,
               px.BOOT, px.BOOT2, px.BOOT3, px.PALE, px.SKIN, px.SKIN2, px.SKIN3}
    for y in range(44, 56):
        for x in range(24, 37):
            if tuple(c[y, x]) in foreign:
                c[y, x] = px.MAROON if y > 49 else px.DRESS
    put(c, HEAD, head_x, GROUND - 18)
    return c


def crouch(src, cut_top=47, cut_bottom=51, lean=2):
    """Squat: drop the body by folding the leg rows, boots stay planted."""
    drop = cut_bottom - cut_top + 1
    out = np.zeros_like(src)
    out[cut_bottom + 1:GROUND + 1] = src[cut_bottom + 1:GROUND + 1]
    for y in range(0, cut_top):
        ny = y + drop
        if ny <= cut_bottom:
            row = src[y]
            if lean:
                out[ny, lean:] = row[:-lean]
            else:
                out[ny] = row
    return out


def propped(base, amount=5, x_full=27, x_end=34):
    """Chest and head lifted off the floor, hips and legs flat."""
    out = np.zeros_like(base)
    for x in range(66):
        if x <= x_full:
            s = 0
        elif x >= x_end:
            s = amount
        else:
            s = amount * (x - x_full) / (x_end - x_full)
        s = int(round(s))
        for y in range(66):
            ny = y - s
            if 0 <= ny < 66:
                out[ny, x] = base[y, x]
    return out


def frames():
    prone = prone_core()
    return [idle.copy(), crouch(idle), propped(prone, 5), prone]


TRES = '''[gd_resource type="SpriteFrames" format=3]

[ext_resource type="Texture2D" path="res://player/character/prone.png" id="1_prone"]

[sub_resource type="AtlasTexture" id="Atlas_prone_0"]
atlas = ExtResource("1_prone")
region = Rect2(0, 0, 66, 66)

[sub_resource type="AtlasTexture" id="Atlas_prone_1"]
atlas = ExtResource("1_prone")
region = Rect2(66, 0, 66, 66)

[sub_resource type="AtlasTexture" id="Atlas_prone_2"]
atlas = ExtResource("1_prone")
region = Rect2(132, 0, 66, 66)

[sub_resource type="AtlasTexture" id="Atlas_prone_3"]
atlas = ExtResource("1_prone")
region = Rect2(198, 0, 66, 66)

[resource]
animations = [{
"frames": [{
"duration": 1.0,
"texture": SubResource("Atlas_prone_0")
}, {
"duration": 1.0,
"texture": SubResource("Atlas_prone_1")
}, {
"duration": 1.0,
"texture": SubResource("Atlas_prone_2")
}, {
"duration": 1.0,
"texture": SubResource("Atlas_prone_3")
}],
"loop": 0,
"name": &"prone",
"speed": 10.0
}]
'''


def main():
    fs = frames()
    sheet = np.zeros((66, 66 * len(fs), 4), dtype=np.uint8)
    for i, f in enumerate(fs):
        sheet[:, i * 66:(i + 1) * 66] = f
    png = CHAR + r"\prone.png"
    Image.fromarray(sheet, "RGBA").save(png)
    with open(CHAR + r"\prone_frames.tres", "w", encoding="utf-8", newline="\n") as fh:
        fh.write(TRES)
    print("wrote", png)


if __name__ == "__main__":
    main()
