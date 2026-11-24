extends Node2D

## 外层节点 —— 幽暗古森的静态装饰(树干、树屋、毒沼、篝火、月光等)。
## 参考图:巨树、盘根、藤蔓、腐木栈桥、树洞、坍塌树屋、苔藓石阶、毒沼、尖刺坑、隐藏墙、捷径门、篝火。
## 关卡 2560×1440:主角出生在最左端,传送门在最右端。

const W := 2560.0
const H := 1440.0
const GROUND := 1180.0
const UI_FONT := preload("res://levels/ui/ui_font.gd")

# ---- 暗色板(与参考图一致) ----
const C_VOID := Color("#06080a")
const C_SKY0 := Color("#0a0e11")
const C_SKY1 := Color("#0d1216")
const C_SKY2 := Color("#10161a")
const C_FAR := Color("#0e1316")
const C_FAR2 := Color("#12181a")
const C_EARTH := Color("#171918")
const C_EARTH2 := Color("#1d201d")
const C_EARTH3 := Color("#101212")
const C_BARK := Color("#292019")
const C_BARK_HI := Color("#3a2e22")
const C_BARK_LO := Color("#180f0a")
const C_MOSS := Color("#293d2b")
const C_MOSS_HI := Color("#3e5a38")
const C_MOSS_LO := Color("#1a2a1e")
const C_LEAF := Color("#0d170f")
const C_LEAF_HI := Color("#172718")
const C_WOOD := Color("#372819")
const C_WOOD_HI := Color("#4f3a25")
const C_WOOD_LO := Color("#21170f")
const C_ROPE := Color("#473b28")
const C_STONE := Color("#2c3033")
const C_STONE_HI := Color("#424749")
const C_STONE_LO := Color("#1c1f22")
const C_FIRE := Color("#d8822e")
const C_FIRE_HI := Color("#f6ca62")
const C_CYAN := Color("#42c6bc")
const C_CYAN_HI := Color("#92f0e2")
const C_BLOOD := Color("#942420")
const C_BLOOD_HI := Color("#c63a2e")
const C_TOXIN := Color("#1e3428")
const C_TOXIN_HI := Color("#34583e")
const C_FLY := Color("#e2d882")
const C_MOON := Color("#7d9cb2")

var _font: Font
var _mushrooms: Array[Vector3] = []


func _ready() -> void:
	_font = UI_FONT.make(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	_mushrooms = [
		Vector3(300, GROUND, 0), Vector3(1010, GROUND, 0), Vector3(1700, GROUND, 0),
		Vector3(470, 1060, 0), Vector3(1410, 1210, 0), Vector3(2240, 1100, 0),
	]
	queue_redraw()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	_draw_sky()
	_draw_far_trees()
	_draw_earth()
	_draw_canopy()
	_draw_trunks()
	_draw_swamp()
	_draw_treehouse()
	_draw_hollow()
	_draw_cave()
	_draw_hidden_wall()
	_draw_shortcut_door()
	_draw_bonfire()
	_draw_plants()
	_draw_beams()


func _draw_sky() -> void:
	draw_rect(Rect2(0, 0, W, H), C_SKY0)
	draw_rect(Rect2(0, 340, W, H - 340), C_SKY1)
	draw_rect(Rect2(0, 760, W, H - 760), C_SKY2)


func _draw_far_trees() -> void:
	var xs: Array[float] = [90.0, 620.0, 1180.0, 1620.0, 2020.0, 2440.0]
	for x: float in xs:
		var tw := 60.0 + fmod(x, 37.0) * 2.0
		var pts := PackedVector2Array([
			Vector2(x - tw * 0.5, 1220), Vector2(x - tw * 0.3, 220),
			Vector2(x, 90), Vector2(x + tw * 0.3, 220), Vector2(x + tw * 0.5, 1220),
		])
		draw_colored_polygon(pts, C_FAR)
		# 远处的枝条
		draw_line(Vector2(x, 300), Vector2(x + tw * 1.6, 250), C_FAR, 6.0)
		draw_line(Vector2(x, 420), Vector2(x - tw * 1.5, 380), C_FAR, 5.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x + tw * 0.8, 300), Vector2(x + tw * 1.8, 250),
			Vector2(x + tw * 1.7, 268), Vector2(x + tw * 0.9, 316),
		]), C_FAR2)


## 地下土层:整条关卡的"实心地面",平台会盖在上面
func _draw_earth() -> void:
	var spans := [
		Vector2(0, 640), Vector2(760, 1400), Vector2(1650, 2000), Vector2(2000, 2560),
	]
	for s in spans:
		var x0: float = s.x
		var x1: float = s.y
		var top := GROUND
		if x0 >= 2000.0:
			top = 1100.0
		draw_rect(Rect2(x0, top, x1 - x0, H - top), C_EARTH)
		draw_rect(Rect2(x0, top, x1 - x0, 8), C_EARTH3)
		# 深处的暗色抖动
		var y := top + 180.0
		while y < H:
			for x in range(int(x0), int(x1), 24):
				if int(x + y) % 48 == 0:
					draw_rect(Rect2(x, y, 8, 8), C_EARTH3)
			y += 48.0
	# 尖刺坑与毒沼的低洼地
	draw_rect(Rect2(640, 1180, 120, H - 1180), C_VOID)
	draw_rect(Rect2(1400, 1180, 250, H - 1180), C_EARTH)


func _draw_canopy() -> void:
	var x := -40.0
	while x < W + 40.0:
		var h := 90.0 + fposmod(x * 0.7, 70.0)
		var pts := PackedVector2Array([
			Vector2(x, 0), Vector2(x + 60, 0), Vector2(x + 40, h * 0.6),
			Vector2(x + 20, h * 0.35), Vector2(x, 0),
		])
		draw_colored_polygon(pts, C_LEAF)
		x += 70.0
	for i in 120:
		var fx := fposmod(float(i) * 137.0, W)
		var fy := fposmod(float(i) * 53.0, 120.0)
		draw_rect(Rect2(fx, fy, 6, 6), C_LEAF_HI if i % 3 == 0 else C_LEAF)
	# 垂藤
	for vx: float in [160.0, 520.0, 900.0, 1180.0, 1520.0, 1980.0, 2320.0]:
		var ln := 160.0 + fposmod(vx, 90.0)
		var y := 60.0
		while y < 60.0 + ln:
			draw_rect(Rect2(vx + sin(y * 0.05) * 8.0, y, 3, 6), C_MOSS_LO)
			y += 6.0


func _draw_trunk(x: float, top: float, bottom: float, half_w: float, back := false) -> void:
	var bark := C_BARK_LO if back else C_BARK
	var hi := C_BARK if back else C_BARK_HI
	var lo := Color("#120c08") if back else C_BARK_LO
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - half_w, bottom), Vector2(x - half_w + 6, top + 60),
		Vector2(x - half_w * 0.5, top), Vector2(x + half_w * 0.5, top),
		Vector2(x + half_w - 6, top + 60), Vector2(x + half_w, bottom),
	]), bark)
	# 树皮竖纹
	var i := -half_w + 10.0
	while i < half_w - 8.0:
		var ry := top + 60.0
		while ry < bottom:
			var seg := 30.0 + fposmod(i * 13.0 + ry, 60.0)
			if fmod(i + ry, 3.0) < 1.2:
				draw_rect(Rect2(x + i, ry, 3, seg), lo)
			ry += seg + 18.0
		i += 22.0
	draw_rect(Rect2(x - half_w + 6, top + 70, 5, bottom - top - 110), hi)
	# 根部外扩
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var rx := x + s * (half_w - 2.0)
			var ry := bottom - 10.0 - float(k) * 12.0
			var ln := 60.0 + float(k) * 30.0
			draw_line(Vector2(rx, ry), Vector2(rx + s * ln * 0.5, ry + 14), lo, 10.0)
			draw_line(Vector2(rx + s * ln * 0.5, ry + 14), Vector2(rx + s * ln, ry + 34), lo, 7.0)


func _draw_trunks() -> void:
	_draw_trunk(380, 40, 1180, 70)
	_draw_trunk(880, 10, 1180, 86)
	_draw_trunk(2300, 30, 1100, 62)
	for x: float in [150.0, 620.0, 1150.0, 1750.0, 2040.0]:
		_draw_trunk(x, 60, 1180, 26, true)

	# 横向粗枝(充当高层平台)
	var branches: Array[Vector2] = [
		Vector2(380, 1060), Vector2(980, 1060), Vector2(590, 948), Vector2(1150, 948),
		Vector2(780, 828), Vector2(1325, 828), Vector2(980, 708),
		Vector2(1800, 1060), Vector2(2075, 948), Vector2(2275, 828),
	]
	for b: Vector2 in branches:
		draw_line(Vector2(b.x - 90, b.y + 10), Vector2(b.x + 90, b.y + 4), C_BARK, 16.0)
		draw_line(Vector2(b.x - 90, b.y + 2), Vector2(b.x + 90, b.y - 2), C_BARK_HI, 4.0)
		for k in 12:
			draw_rect(Rect2(b.x - 84 + float(k) * 14.0, b.y - 2, 6, 5), C_MOSS)


func _draw_swamp() -> void:
	var x := 1400.0
	while x < 1650.0:
		var wob := sin(x * 0.05) * 6.0
		draw_rect(Rect2(x, 1210 + wob, 4, 230), C_TOXIN)
		draw_rect(Rect2(x, 1210 + wob, 4, 5), C_TOXIN_HI)
		x += 4.0
	for i in 14:
		var bx := 1410.0 + fmod(float(i) * 71.0, 230.0)
		var by := 1240.0 + fmod(float(i) * 37.0, 90.0)
		draw_rect(Rect2(bx, by, 6, 3), C_TOXIN_HI)


func _draw_treehouse() -> void:
	var x := 900.0
	var y := 1060.0
	# 地板
	draw_rect(Rect2(x, y, 180, 12), C_WOOD)
	draw_rect(Rect2(x, y, 180, 3), C_WOOD_HI)
	# 立柱
	draw_rect(Rect2(x + 8, y - 110, 10, 110), C_WOOD_LO)
	draw_rect(Rect2(x + 160, y - 96, 10, 96), C_WOOD_LO)
	# 破墙
	for k in 10:
		var bx := x + 20 + float(k) * 14.0
		var hgt := 34.0 + fmod(float(k) * 23.0, 62.0)
		draw_rect(Rect2(bx, y - hgt, 10, hgt), C_WOOD)
		draw_rect(Rect2(bx, y - hgt, 10, 3), C_WOOD_HI)
	# 塌掉的屋顶
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 20, y - 120), Vector2(x + 50, y - 190),
		Vector2(x + 120, y - 160), Vector2(x + 140, y - 128),
		Vector2(x + 96, y - 140), Vector2(x + 34, y - 144),
	]), C_WOOD_LO)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 20, y - 120), Vector2(x + 50, y - 190),
		Vector2(x + 64, y - 178), Vector2(x - 4, y - 116),
	]), C_WOOD)
	# 窗
	draw_rect(Rect2(x + 64, y - 88, 28, 34), C_VOID)
	draw_rect(Rect2(x + 70, y - 78, 8, 8), Color(0.42, 0.34, 0.18, 0.9))
	# 掉落的木板
	draw_rect(Rect2(x + 96, y + 22, 44, 8), C_WOOD_LO)
	# 梯子
	draw_rect(Rect2(x - 16, y - 10, 6, 130), C_ROPE)
	draw_rect(Rect2(x + 8, y - 10, 6, 130), C_ROPE)
	var ly := y + 6.0
	while ly < y + 118.0:
		draw_rect(Rect2(x - 16, ly, 30, 4), C_ROPE)
		ly += 18.0


func _draw_hollow() -> void:
	# 树洞通道(树干底部的黑拱)
	draw_colored_polygon(PackedVector2Array([
		Vector2(812, 1180), Vector2(818, 1090), Vector2(844, 1064),
		Vector2(886, 1078), Vector2(898, 1110), Vector2(898, 1180),
	]), C_VOID)
	draw_colored_polygon(PackedVector2Array([
		Vector2(812, 1180), Vector2(818, 1090), Vector2(844, 1064),
		Vector2(852, 1068), Vector2(828, 1096), Vector2(822, 1180),
	]), C_BARK_LO)


func _draw_cave() -> void:
	var x := 2050.0
	var y := 1100.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x, y + 80), Vector2(x + 16, y - 10), Vector2(x + 70, y - 40),
		Vector2(x + 130, y - 20), Vector2(x + 150, y + 30), Vector2(x + 150, y + 80),
	]), C_VOID)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 16, y + 84), Vector2(x + 4, y - 12), Vector2(x + 70, y - 56),
		Vector2(x + 132, y - 34), Vector2(x + 156, y + 24), Vector2(x + 158, y + 84),
		Vector2(x + 146, y + 80), Vector2(x + 128, y - 12),
		Vector2(x + 68, y - 34), Vector2(x + 22, y + 4), Vector2(x + 14, y + 84),
	]), C_STONE)
	for i in 26:
		var rx := x + fmod(float(i) * 41.0, 150.0)
		var ry := y - 30.0 + fmod(float(i) * 29.0, 100.0)
		draw_rect(Rect2(rx, ry, 6, 4), C_STONE_HI if i % 4 == 0 else C_STONE_LO)
	# 洞口苔藓
	for i in 10:
		draw_rect(Rect2(x + fmod(float(i) * 53.0, 150.0), y + 60.0, 8, 6), C_MOSS_LO)


func _draw_hidden_wall() -> void:
	var r := Rect2(1240, 830, 66, 110)
	draw_rect(r, C_STONE)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 8)), C_STONE_HI)
	for k in 5:
		var c := Vector2(1250 + fmod(float(k) * 37.0, 44.0), 850 + float(k) * 18.0)
		draw_line(c, c + Vector2(8 - float(k) * 3.0, 14), Color("#0f1113"), 3.0)
	for k in 8:
		draw_rect(Rect2(1244 + fmod(float(k) * 31.0, 58.0), 920, 8, 6), C_MOSS_LO)


func _draw_shortcut_door() -> void:
	var x := 1352.0
	var y := GROUND
	draw_rect(Rect2(x, y - 108, 64, 108), C_WOOD_LO)
	draw_rect(Rect2(x + 6, y - 100, 52, 96), C_WOOD)
	var by := y - 92.0
	while by < y - 4.0:
		draw_rect(Rect2(x + 6, by, 52, 4), C_WOOD_LO)
		by += 16.0
	draw_rect(Rect2(x + 10, y - 78, 44, 7), C_STONE)   # 铁箍
	draw_rect(Rect2(x + 10, y - 38, 44, 7), C_STONE)
	draw_rect(Rect2(x + 46, y - 56, 6, 6), C_STONE_HI)  # 门闩
	draw_rect(Rect2(x + 28, y - 112, 6, 58), C_STONE_LO)


func _draw_bonfire() -> void:
	var x := 190.0
	var y := GROUND
	for i in range(-16, 17, 4):
		draw_rect(Rect2(x + i, y, 8, 5), Color("#383632"))
	for i: float in [-18.0, -8.0, 8.0, 18.0]:
		draw_rect(Rect2(x + i, y - 8, 10, 8), C_STONE)
	draw_line(Vector2(x - 14, y - 2), Vector2(x + 14, y - 8), C_WOOD_LO, 5.0)
	draw_line(Vector2(x - 14, y - 8), Vector2(x + 14, y - 2), C_WOOD_LO, 5.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 8, y - 6), Vector2(x, y - 44), Vector2(x + 8, y - 6),
		Vector2(x + 3, y - 12), Vector2(x - 3, y - 12),
	]), C_FIRE)
	draw_rect(Rect2(x - 3, y - 30, 6, 16), C_FIRE_HI)
	# 插剑
	draw_rect(Rect2(x + 26, y - 46, 6, 46), C_STONE_HI)
	draw_rect(Rect2(x + 18, y - 50, 22, 7), C_STONE)


func _draw_plants() -> void:
	for m in _mushrooms:
		var x: float = m.x
		var y: float = m.y
		var cyan := m.z < 0.5
		for k in 3:
			var mx := x + float(k) * 12.0 - 12.0
			var h := 8.0 + float(k) * 3.0
			draw_rect(Rect2(mx, y - h, 4, h), Color("#c6cebc"))
			draw_rect(Rect2(mx - 5, y - h - 6, 14, 7), C_CYAN if cyan else C_BLOOD)
			draw_rect(Rect2(mx - 5, y - h - 7, 14, 2), C_CYAN_HI if cyan else C_BLOOD_HI)
	# 草簇
	var gx := 40.0
	while gx < W:
		if fmod(gx, 37.0) < 14.0:
			var gh := 6.0 + fposmod(gx, 9.0)
			draw_rect(Rect2(gx, GROUND - gh, 3, gh), C_LEAF)
		gx += 18.0


func _draw_beams() -> void:
	var beams: Array[Vector2] = [Vector2(700, 120), Vector2(1180, 100), Vector2(1900, 120), Vector2(2380, 90)]
	for b: Vector2 in beams:
		draw_colored_polygon(PackedVector2Array([
			Vector2(b.x - 30, b.y), Vector2(b.x + 30, b.y),
			Vector2(b.x + 70, 1180), Vector2(b.x - 10, 1180),
		]), Color(0.55, 0.68, 0.78, 0.045))
