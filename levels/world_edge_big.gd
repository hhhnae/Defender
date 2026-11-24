extends Node2D

## 外层节点·大地图:5120×2880,按手绘草图凿出 6 个房间 + 5 条走廊。
## 整张图用泥土素材铺满,只有房间和走廊是空的;红框是出生点,灰框是传送门。
## 竖直落差处补了木踏板,保证双向都能走通。

const W := 5120.0
const H := 2880.0
const DIRT_PATH := "res://picture/kenney_dirt.png"
const UI_FONT := preload("res://levels/ui/ui_font.gd")

const SPAWN := Vector2(650.0, 1965.0)
const PORTAL := Vector2(4550.0, 900.0)

const C_CYAN := Color("#5fe4ff")
const C_AMBER := Color("#ffb648")
const C_GREEN := Color("#5dffb0")
const C_RED := Color("#ff5a5a")
const C_GRAY := Color("#cfd6dd")

## 房间(草图里的白框)
const ROOMS := [
	{"rect": Rect2(1750, 240, 1280, 660), "label": "北厅", "accent": 0},
	{"rect": Rect2(3470, 440, 1210, 460), "label": "东北厅 · 传送门", "accent": 3},
	{"rect": Rect2(570, 930, 700, 1035), "label": "西厅 · 出生点", "accent": 1},
	{"rect": Rect2(1730, 1665, 1600, 735), "label": "中枢大厅", "accent": 2},
	{"rect": Rect2(4070, 1305, 630, 270), "label": "东侧小室", "accent": 0},
	{"rect": Rect2(4480, 1515, 620, 1125), "label": "东厅", "accent": 0},
]

## 走廊(草图里的细长连接),地面高度与所连房间对齐
const CORRIDORS := [
	Rect2(2960, 750, 560, 150),
	Rect2(2300, 900, 300, 1500),
	Rect2(1220, 1815, 570, 150),
	Rect2(3280, 2130, 950, 270),
	Rect2(4070, 1520, 200, 880),
]

## 落差处的木踏板(单向可穿),把竖井变成能爬的梯子
const LEDGES := [
	# 北厅 ↔ 中枢的竖井
	Rect2(2340, 1030, 220, 16),
	Rect2(2340, 1160, 220, 16),
	Rect2(2340, 1290, 220, 16),
	Rect2(2340, 1420, 220, 16),
	Rect2(2340, 1550, 220, 16),
	Rect2(2340, 1680, 220, 16),
	Rect2(2340, 1810, 220, 16),
	Rect2(2340, 1940, 220, 16),
	Rect2(2340, 2070, 220, 16),
	Rect2(2340, 2200, 220, 16),
	# 中枢大厅左侧,爬回西厅走廊
	Rect2(1780, 2325, 300, 16),
	Rect2(1860, 2195, 300, 16),
	Rect2(1780, 2065, 300, 16),
	# 东侧小室 ↔ 东向走廊
	Rect2(4090, 2270, 160, 16),
	Rect2(4090, 2140, 160, 16),
	Rect2(4090, 2010, 160, 16),
	Rect2(4090, 1880, 160, 16),
	Rect2(4090, 1750, 160, 16),
	Rect2(4090, 1620, 160, 16),
]

@onready var _player: CharacterBody2D = $Player

var _font: Font
var _font_bold: Font
var _dirt: Texture2D


func _ready() -> void:
	_font = UI_FONT.make(false)
	_font_bold = UI_FONT.make(true)
	_dirt = _load_texture(DIRT_PATH)
	queue_redraw()
	_build_collision()
	if _player != null:
		_player.global_position = SPAWN


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null


func _accent(index: int) -> Color:
	match index:
		1:
			return C_GREEN
		2:
			return C_CYAN
		3:
			return C_AMBER
	return Color("#5bc8e8")


func _all_rects() -> Array:
	var out := []
	for room in ROOMS:
		out.append(room["rect"])
	for c in CORRIDORS:
		out.append(c)
	return out


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# 1) 整张图铺满泥土
	if _dirt != null:
		draw_texture_rect(_dirt, Rect2(0, 0, W, H), true, Color(0.62, 0.55, 0.5))
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.42, 0.26, 0.18))

	# 2) 挖空:走廊先画,房间压在上面
	for r in CORRIDORS:
		_carve(r, false)
	for room in ROOMS:
		_carve(room["rect"], true)

	# 3) 木踏板
	for l in LEDGES:
		_ledge(l)

	# 4) 外框
	draw_rect(Rect2(8, 8, W - 16, H - 16), Color(C_CYAN, 0.22), false, 6.0)

	# 5) 房间虚线框 + 标签
	for room in ROOMS:
		var r: Rect2 = room["rect"]
		var col := _accent(int(room["accent"]))
		_dashed_rect(r, Color(col, 0.85), 16.0, 10.0, 3.0)
		draw_string(_font_bold, r.position + Vector2(20.0, 44.0), String(room["label"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(col, 0.9))

	# 6) 出生点(红框)/ 传送门(灰框)标记
	_marker_rect(Rect2(SPAWN - Vector2(34, 62), Vector2(68, 62)), C_RED, "出生点")
	_marker_rect(Rect2(PORTAL - Vector2(34, 62), Vector2(68, 62)), C_GRAY, "传送门")

	# 7) 中枢到各房间的示意连线
	var hub: Rect2 = ROOMS[3]["rect"]
	var hub_c := hub.position + hub.size * 0.5
	for i in ROOMS.size():
		if i == 3:
			continue
		var rr: Rect2 = ROOMS[i]["rect"]
		draw_line(hub_c, rr.position + rr.size * 0.5, Color(C_CYAN, 0.06), 6.0)


func _marker_rect(r: Rect2, color: Color, text: String) -> void:
	draw_rect(r, Color(color.r, color.g, color.b, 0.12))
	draw_rect(r, color, false, 3.0)
	draw_string(_font_bold, r.position + Vector2(-6.0, -12.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)


## 挖出一块空间:深色地面 + 内壁阴影,像被从泥土里凿出来的房间
func _carve(r: Rect2, is_room: bool) -> void:
	draw_rect(r, Color(0.04, 0.07, 0.10, 1.0))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 10.0)), Color(0.0, 0.0, 0.0, 0.55))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 14.0), Vector2(r.size.x, 14.0)),
		Color(0.30, 0.20, 0.14, 0.85))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 14.0), Vector2(r.size.x, 3.0)),
		Color(0.55, 0.42, 0.3, 0.8))
	if is_room:
		draw_rect(Rect2(r.position + Vector2(10, 10), r.size - Vector2(20, 20)),
			Color(C_CYAN, 0.05), false, 2.0)
		var gx := r.position.x + 96.0
		while gx < r.end.x - 24.0:
			draw_line(Vector2(gx, r.position.y + 24.0), Vector2(gx, r.end.y - 24.0),
				Color(C_CYAN, 0.05), 2.0)
			gx += 96.0
		var gy := r.position.y + 96.0
		while gy < r.end.y - 24.0:
			draw_line(Vector2(r.position.x + 24.0, gy), Vector2(r.end.x - 24.0, gy),
				Color(C_CYAN, 0.05), 2.0)
			gy += 96.0


## 木踏板:泥土 + 顶上一道草色
func _ledge(r: Rect2) -> void:
	draw_rect(r, Color(0.30, 0.20, 0.14, 1.0))
	if _dirt != null:
		draw_texture_rect(_dirt, r, true, Color(0.72, 0.62, 0.55))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 5.0)), Color(0.40, 0.68, 0.42))


func _dashed_rect(rect: Rect2, color: Color, dash: float, gap: float, width: float) -> void:
	var step := dash + gap
	var x := rect.position.x
	while x < rect.end.x:
		var x2: float = minf(x + dash, rect.end.x)
		draw_line(Vector2(x, rect.position.y), Vector2(x2, rect.position.y), color, width)
		draw_line(Vector2(x, rect.end.y), Vector2(x2, rect.end.y), color, width)
		x += step
	var y := rect.position.y
	while y < rect.end.y:
		var y2: float = minf(y + dash, rect.end.y)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x, y2), color, width)
		draw_line(Vector2(rect.end.x, y), Vector2(rect.end.x, y2), color, width)
		y += step


# ---------------------------------------------------------------- 碰撞

## 把「泥土区域」光栅化成 32px 格子,贪心合并成矩形碰撞体,
## 这样玩家只能待在挖空的房间和走廊里。
func _build_collision() -> void:
	var cell := 32.0
	var cols := int(W / cell)
	var rows := int(H / cell)
	var rects := _all_rects()

	var solid := []
	solid.resize(rows)
	for j in rows:
		var line := PackedByteArray()
		line.resize(cols)
		for i in cols:
			var c := Vector2((float(i) + 0.5) * cell, (float(j) + 0.5) * cell)
			var inside := false
			for r in rects:
				if (r as Rect2).has_point(c):
					inside = true
					break
			line[i] = 0 if inside else 1
		solid[j] = line

	var used := []
	used.resize(rows)
	for j in rows:
		var u := PackedByteArray()
		u.resize(cols)
		used[j] = u

	var holder := Node2D.new()
	holder.name = "Collision"
	add_child(holder)

	for j in rows:
		var i := 0
		while i < cols:
			if solid[j][i] == 1 and used[j][i] == 0:
				var w := 0
				while i + w < cols and solid[j][i + w] == 1 and used[j][i + w] == 0:
					w += 1
				var h := 1
				while j + h < rows:
					var ok := true
					for k in w:
						if solid[j + h][i + k] == 0 or used[j + h][i + k] == 1:
							ok = false
							break
					if not ok:
						break
					h += 1
				for yy in h:
					for xx in w:
						used[j + yy][i + xx] = 1
				_add_wall(holder, Rect2(float(i) * cell, float(j) * cell, float(w) * cell, float(h) * cell))
				i += w
			else:
				i += 1

	# 踏板:单向碰撞
	for l in LEDGES:
		_add_wall(holder, l, true)


func _add_wall(parent: Node2D, rect: Rect2, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	shape.position = rect.position + rect.size * 0.5
	if one_way:
		shape.one_way_collision = true
		shape.one_way_collision_margin = 6.0
	body.add_child(shape)
	parent.add_child(body)
