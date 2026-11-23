extends Node2D

## FRESHMAN_WORLD —— 新手训练舱:按顺序教会移动 / 跳跃 / 攻击 / 闪避 / 技能(Q 假死) / 离开。

const SAFE_WORLD := "res://levels/safe_world.tscn"
const UI_FONT := preload("res://levels/ui/ui_font.gd")
const DUMMY_SCRIPT := preload("res://levels/freshman/dummy.gd")
const PAUSE_MENU := preload("res://levels/ui/pause_menu.tscn")

const ROOM := Vector2(1920.0, 720.0)
const FLOOR_Y := 600.0
const EXIT_POS := Vector2(1840.0, 600.0)

const C_CYAN := Color("#5fe4ff")
const C_AMBER := Color("#ffb648")
const C_TEXT := Color(0.78, 0.98, 1.0, 1.0)
const C_MUTED := Color(0.42, 0.6, 0.7, 0.9)

const ZONES := [
	{"x0": 300.0, "x1": 410.0, "label": "MOVE"},
	{"x0": 600.0, "x1": 830.0, "label": "JUMP"},
	{"x0": 860.0, "x1": 1260.0, "label": "ATTACK"},
	{"x0": 1290.0, "x1": 1530.0, "label": "DODGE"},
	{"x0": 1560.0, "x1": 1800.0, "label": "SKILL"},
]

const STEPS := [
	{"title": "移动", "hint": "按 A / D 左右移动,走进前方的光带"},
	{"title": "跳跃", "hint": "按 W 跳上台子"},
	{"title": "近战", "hint": "按 J / K / L 攻击训练假人,命中 3 次"},
	{"title": "闪避", "hint": "按 Shift 向移动方向闪避"},
	{"title": "技能", "hint": "按 Q 使用「假死」,再按 J / K / L 起身"},
	{"title": "离开", "hint": "走到最右侧传送门,按 F 返回安全区"},
]

@onready var _backdrop: Node2D = $Backdrop
@onready var _portal: Node2D = $Portal
@onready var _player: CharacterBody2D = $Player

var _t := 0.0
var _step := 0
var _hits := 0
var _finished := false
var _font: Font
var _font_bold: Font

var _objective: Label
var _hint: Label
var _checklist: VBoxContainer
var _check_labels: Array[Label] = []
var _fade: ColorRect
var _pause_menu: CanvasLayer
var _dummies: Array[Node] = []


func _ready() -> void:
	_font = UI_FONT.make(false)
	_font_bold = UI_FONT.make(true)
	_backdrop.draw.connect(_draw_room)
	_portal.draw.connect(_draw_portal)
	_build_ui()
	_spawn_dummies()
	_build_pause_menu()
	_fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.35)
	_refresh_ui()
	# 从最左端走进训练舱
	if _player != null and _player.has_method("begin_walk_in"):
		_player.call("begin_walk_in", 150.0, 150.0)


func _spawn_dummies() -> void:
	for x in [900.0, 1000.0, 1100.0]:
		var dummy := Node2D.new()
		dummy.set_script(DUMMY_SCRIPT)
		dummy.position = Vector2(x, FLOOR_Y)
		add_child(dummy)
		dummy.connect("hit_registered", _on_dummy_hit)
		_dummies.append(dummy)


func _build_pause_menu() -> void:
	_pause_menu = PAUSE_MENU.instantiate() as CanvasLayer
	add_child(_pause_menu)


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("ui_cancel") and _pause_menu != null:
		_pause_menu.call("open")


func _process(delta: float) -> void:
	_t += delta
	_portal.queue_redraw()
	if _finished:
		return
	var px := _player.global_position.x
	match _step:
		0:
			if px > 330.0:
				_advance()
		1:
			if _player.global_position.y < 548.0:
				_advance()
		2:
			if _hits >= 3:
				_advance()
		3:
			if px > 1240.0 and Input.is_action_just_pressed("dodge"):
				_advance()
		4:
			if px > 1520.0 and bool(_player.get("_feigning")):
				_advance()
		5:
			if absf(px - EXIT_POS.x) < 150.0 and Input.is_action_just_pressed("interact"):
				_complete()


func _on_dummy_hit() -> void:
	_hits += 1
	if _step == 2:
		_refresh_ui()


func _advance() -> void:
	if _step >= STEPS.size() - 1:
		return
	_step += 1
	_refresh_ui()


func _refresh_ui() -> void:
	if _objective == null:
		return
	var cfg: Dictionary = STEPS[_step]
	_objective.text = "%d / %d   %s" % [_step + 1, STEPS.size(), String(cfg["title"])]
	_hint.text = String(cfg["hint"])
	if _step == 2:
		_hint.text = "%s  (%d / 3)" % [String(cfg["hint"]), mini(_hits, 3)]
	for i in _check_labels.size():
		var label := _check_labels[i]
		if i < _step:
			label.text = "✓  " + String(STEPS[i]["title"])
			label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.72, 0.95))
		elif i == _step:
			label.text = "▶  " + String(STEPS[i]["title"])
			label.add_theme_color_override("font_color", C_AMBER)
		else:
			label.text = "○  " + String(STEPS[i]["title"])
			label.add_theme_color_override("font_color", Color(0.3, 0.44, 0.54, 0.9))


func _complete() -> void:
	if _finished:
		return
	_finished = true
	Engine.set_meta("freshman_done", true)
	_player.set_physics_process(false)
	_objective.text = "训练完成"
	_hint.text = "正在返回安全区…"
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file(SAFE_WORLD)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Hud"
	layer.layer = 20
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# 左上:进度清单
	_checklist = VBoxContainer.new()
	_checklist.position = Vector2(48, 44)
	_checklist.add_theme_constant_override("separation", 6)
	root.add_child(_checklist)
	var title := Label.new()
	title.text = "训练清单"
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.5, 0.78, 0.9, 0.95))
	_checklist.add_child(title)
	for i in STEPS.size():
		var label := Label.new()
		label.text = "○  " + String(STEPS[i]["title"])
		label.add_theme_font_override("font", _font)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", C_MUTED)
		_checklist.add_child(label)
		_check_labels.append(label)

	# 顶部中央:当前目标
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -360
	box.offset_right = 360
	box.offset_top = 36
	box.offset_bottom = 140
	box.add_theme_constant_override("separation", 6)
	root.add_child(box)

	_objective = Label.new()
	_objective.text = "1 / 6   移动"
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.add_theme_font_override("font", _font_bold)
	_objective.add_theme_font_size_override("font_size", 26)
	_objective.add_theme_color_override("font_color", C_AMBER)
	_objective.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.08, 0.9))
	_objective.add_theme_constant_override("outline_size", 6)
	box.add_child(_objective)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_override("font", _font)
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", C_TEXT)
	_hint.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.08, 0.9))
	_hint.add_theme_constant_override("outline_size", 5)
	box.add_child(_hint)

	# 右下:提示
	var tip := Label.new()
	tip.text = "ESC 暂停"
	tip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tip.offset_left = -160
	tip.offset_top = -52
	tip.offset_right = -40
	tip.offset_bottom = -28
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tip.add_theme_font_override("font", _font)
	tip.add_theme_font_size_override("font_size", 13)
	tip.add_theme_color_override("font_color", Color(0.35, 0.5, 0.6, 0.85))
	root.add_child(tip)

	# 黑幕
	var fade_layer := CanvasLayer.new()
	fade_layer.name = "Fade"
	fade_layer.layer = 40
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)


# ---------------------------------------------------------------- 绘制

func _draw_room() -> void:
	var d := _backdrop
	# 背景渐变
	for y in range(0, int(FLOOR_Y)):
		var t := float(y) / FLOOR_Y
		d.draw_rect(Rect2(0.0, float(y), ROOM.x, 1.0), Color("#050a12").lerp(Color("#0a1624"), t))
	# 网格
	for x in range(0, int(ROOM.x), 80):
		d.draw_line(Vector2(float(x), 0.0), Vector2(float(x), FLOOR_Y), Color(0.2, 0.45, 0.55, 0.07), 1.0)
	for y in range(0, int(FLOOR_Y), 80):
		d.draw_line(Vector2(0.0, float(y)), Vector2(ROOM.x, float(y)), Color(0.2, 0.45, 0.55, 0.07), 1.0)
	# 顶部灯带
	for i in 8:
		var x := 120.0 + float(i) * 220.0
		d.draw_rect(Rect2(x, 34.0, 120.0, 4.0), Color(C_CYAN, 0.7))
		d.draw_rect(Rect2(x - 10.0, 26.0, 140.0, 20.0), Color(C_CYAN, 0.05))
	# 墙面标识
	d.draw_string(_font_bold, Vector2(70.0, 132.0), "FRESHMAN_WORLD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(C_CYAN, 0.13))
	d.draw_string(_font, Vector2(74.0, 166.0), "// 训练舱 · 基础操作",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(C_CYAN, 0.22))

	# 地面
	for y in range(int(FLOOR_Y), int(ROOM.y)):
		var t := float(y - FLOOR_Y) / (ROOM.y - FLOOR_Y)
		d.draw_rect(Rect2(0.0, float(y), ROOM.x, 1.0), Color("#0e1a28").lerp(Color("#050a12"), t))
	for k in range(-30, 31):
		var xb := 960.0 + float(k) * 96.0
		var xt := 960.0 + float(k) * 30.0
		d.draw_line(Vector2(xt, FLOOR_Y), Vector2(xb, ROOM.y), Color(0.2, 0.5, 0.62, 0.14), 1.0)
	d.draw_rect(Rect2(0.0, FLOOR_Y - 2.0, ROOM.x, 3.0), Color(C_CYAN, 0.4))

	# 区域地贴
	for zone in ZONES:
		var x0 := float(zone["x0"])
		var x1 := float(zone["x1"])
		d.draw_rect(Rect2(x0, FLOOR_Y - 5.0, x1 - x0, 5.0), Color(C_AMBER, 0.35))
		var steps := int((x1 - x0) / 18.0)
		for i in steps:
			if i % 2 == 0:
				var dx := x0 + float(i) * 18.0
				d.draw_rect(Rect2(dx, FLOOR_Y - 10.0, 9.0, 4.0), Color(C_AMBER, 0.55))
		var label := String(zone["label"])
		d.draw_string(_font_bold, Vector2(x0, FLOOR_Y - 26.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(C_AMBER, 0.55))

	# 跳台
	d.draw_rect(Rect2(620.0, 500.0, 210.0, 16.0), Color("#16303f"))
	d.draw_rect(Rect2(620.0, 500.0, 210.0, 16.0), Color(0.32, 0.78, 0.92, 0.8), false, 2.0)
	d.draw_rect(Rect2(620.0, 496.0, 210.0, 5.0), Color(C_CYAN, 0.55))
	d.draw_rect(Rect2(636.0, 516.0, 10.0, 84.0), Color("#0c1a26"))
	d.draw_rect(Rect2(804.0, 516.0, 10.0, 84.0), Color("#0c1a26"))


func _draw_portal() -> void:
	var d := _portal
	var c := Vector2(EXIT_POS.x, 468.0)
	var near := _player != null and absf(_player.global_position.x - EXIT_POS.x) < 150.0
	var pulse := 0.5 + 0.5 * sin(_t * 2.6)

	# 地面光环
	d.draw_set_transform(Vector2(c.x, FLOOR_Y - 2.0), 0.0, Vector2(1.0, 0.26))
	for i in 5:
		d.draw_circle(Vector2.ZERO, 96.0 - float(i) * 14.0, Color(C_CYAN, 0.04 + float(i) * 0.015))
	d.draw_arc(Vector2.ZERO, 96.0, 0.0, TAU, 48, Color(C_CYAN, 0.5), 3.0)
	d.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 门环
	d.draw_arc(c, 96.0, 0.0, TAU, 72, Color(C_CYAN, 0.35), 5.0)
	d.draw_arc(c, 96.0, 0.0, TAU, 72, Color(C_CYAN, 0.65), 2.0)
	for i in 12:
		var a0 := _t * 0.8 + TAU * float(i) / 12.0
		d.draw_arc(c, 86.0, a0, a0 + 0.12, 5, Color(C_CYAN, 0.45), 2.0)
	d.draw_arc(c, 66.0, _t * 1.4, _t * 1.4 + 2.4, 20, Color(C_AMBER, 0.3), 3.0)
	d.draw_circle(c, 34.0, Color(C_CYAN, 0.06 + 0.05 * pulse))
	d.draw_circle(c, 14.0, Color(0.9, 1.0, 1.0, 0.3 + 0.15 * pulse))

	if near and _step >= 5 and not _finished:
		d.draw_string(_font_bold, Vector2(c.x - 88.0, c.y - 122.0), "[ F ]  返回安全区",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(C_AMBER, 0.85 + 0.15 * pulse))
