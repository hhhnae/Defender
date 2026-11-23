extends Node2D

## SAFE_WORLD —— 开始游戏后的安全区主城。
##
## 科幻服务器大厅:成排机柜、悬空全息屏、传送门。玩家在厅内自由走动,
## 走到右侧传送门前按 F 进入 MAIN_WORLD(levels/game.tscn)。
## 场景内的美术全部用 _draw 程序化绘制,不依赖外部贴图。

const GAME_SCENE := "res://levels/game.tscn"
const MENU_SCENE := "res://main.tscn"
const UI_FONT := preload("res://levels/ui/ui_font.gd")
const SCANLINES := preload("res://shaders/scanlines.gdshader")
const LOADOUT_SCREEN := preload("res://levels/ui/loadout_screen.tscn")
const INTRO_SCENE := preload("res://intro.tscn")
const FRESHMAN_SCENE := "res://levels/freshman_world.tscn"

const ROOM := Vector2(1280.0, 720.0)
const FLOOR_Y := 600.0
const PORTAL_CENTER := Vector2(1010.0, 468.0)
const PORTAL_ANCHOR := Vector2(1010.0, 600.0)
## 回到安全区时的传送入场演出时长
const ARRIVAL_TIME := 1.15

const C_CYAN := Color("#5fe4ff")
const C_CYAN_DIM := Color("#2d7f9e")
const C_VIOLET := Color("#9d6bff")
const C_AMBER := Color("#ffb648")
const C_GREEN := Color("#5dffb0")
const C_EDGE := Color("#1b3a5f")
const C_PANEL := Color("#0b1728")
const C_PANEL_LIT := Color("#102238")
const C_WALL_TOP := Color("#05070e")
const C_WALL_BOT := Color("#0b1526")
const C_FLOOR_TOP := Color("#101a2b")
const C_FLOOR_BOT := Color("#060b14")
const C_METAL := Color("#16202f")

@onready var _backdrop: Node2D = $Backdrop
@onready var _portal: Node2D = $Portal
@onready var _fx: Node2D = $Fx
@onready var _player: CharacterBody2D = $Player

var _t := 0.0
var _entering := false

var _title_label: Label
var _prompt_label: Label
var _toast_label: Label
var _fade: ColorRect
var _loadout_ui: CanvasLayer
var _ui_font: Font
var _ui_font_bold: Font
var _motes: Array[Vector3] = []
var _active_spot := -1

# 可交互点:传送门 + 整备终端
var _spots: Array[Dictionary] = [
	{
		"pos": PORTAL_ANCHOR,
		"range": 165.0,
		"label": "[ F ]  进入 MAIN_WORLD",
		"kind": &"portal",
	},
	{
		"pos": Vector2(330.0, 600.0),
		"range": 95.0,
		"label": "[ F ]  查看整备终端",
		"kind": &"terminal",
	},
]


func _ready() -> void:
	_ui_font = UI_FONT.make(false)
	_ui_font_bold = UI_FONT.make(true)
	_backdrop.draw.connect(_draw_backdrop)
	_portal.draw.connect(_draw_portal)
	_fx.draw.connect(_draw_fx)
	_rng_motes()
	_build_ui()
	_arrive()
	_play_entrance()


func _rng_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261123
	for i in 54:
		_motes.append(Vector3(
			rng.randf_range(0.0, ROOM.x),
			rng.randf_range(0.0, ROOM.y),
			rng.randf_range(0.15, 0.9)))


func _process(delta: float) -> void:
	_t += delta
	_portal.queue_redraw()
	_fx.queue_redraw()
	_update_prompt(delta)
	if not _entering and Input.is_action_just_pressed("interact"):
		_activate_spot()


## 入场:从场景最左端走进来(不直接出现在传送门)。
func _play_entrance() -> void:
	if _player == null:
		return
	if _player.has_method("begin_walk_in"):
		_player.call("begin_walk_in", 240.0, 150.0)


func _update_prompt(delta: float) -> void:
	if _player == null or _entering:
		return
	var p := _player.global_position
	var best := -1
	var best_d := INF
	for i in _spots.size():
		var spot: Dictionary = _spots[i]
		var d: float = p.distance_to(spot["pos"] as Vector2)
		if d <= float(spot["range"]) and d < best_d:
			best_d = d
			best = i
	_active_spot = best
	var show := best >= 0
	if show:
		_prompt_label.text = String(_spots[best]["label"])
	var pulse := 0.78 + 0.22 * sin(_t * 5.0)
	var target := pulse if show else 0.0
	_prompt_label.modulate.a = move_toward(_prompt_label.modulate.a, target, delta * 9.0)


func _activate_spot() -> void:
	if _active_spot < 0:
		return
	var kind: StringName = _spots[_active_spot]["kind"]
	if kind == &"portal":
		# 第一次用传送门:先播一段对话,再把人送进新手训练舱。
		if bool(Engine.get_meta("freshman_done", false)):
			_enter_main_world()
		else:
			_play_freshman_intro()
	else:
		_open_loadout()


## 打开整备终端:左侧插槽 / 右侧已有技能。
func _open_loadout() -> void:
	if _loadout_ui == null:
		_loadout_ui = LOADOUT_SCREEN.instantiate() as CanvasLayer
		add_child(_loadout_ui)
	if _loadout_ui != null and _loadout_ui.has_method("open"):
		_loadout_ui.call("open")


func _enter_main_world() -> void:
	if _entering:
		return
	_entering = true
	_prompt_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.45)
	await tw.finished
	get_tree().change_scene_to_file(GAME_SCENE)


## 首次传送:鲸鱼娘交代一句,然后进训练舱。
func _play_freshman_intro() -> void:
	if _entering:
		return
	_entering = true
	if _player != null:
		_player.set_physics_process(false)
	var layer := CanvasLayer.new()
	layer.name = "Briefing"
	layer.layer = 45
	add_child(layer)
	var intro := INTRO_SCENE.instantiate()
	intro.set("custom_lines", PackedStringArray([
		"先来熟悉一下基础操作吧。",
		"训练舱的入口我给你打开了——移动、跳跃、攻击、闪避、技能，一样一样来。",
		"学完从出口回来，我在这儿等你。",
	]))
	intro.set("stay_in_scene", true)
	intro.set("header_tag", "// FRESHMAN PROGRAM")
	intro.set("loading_text", "> 正在打开训练舱…")
	layer.add_child(intro)
	await intro.finished
	layer.queue_free()
	Engine.set_meta("freshman_done", true)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	await tw.finished
	get_tree().change_scene_to_file(FRESHMAN_SCENE)


func _show_toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_toast_label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.8)
	tw.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func _arrive() -> void:
	_fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.22)
	_title_label.modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_interval(0.25)
	tw2.tween_property(_title_label, "modulate:a", 1.0, 0.7)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Overlay"
	layer.layer = 18
	add_child(layer)

	var scan := ColorRect.new()
	scan.name = "Scanlines"
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SCANLINES
	mat.set_shader_parameter("line_density", 0.22)
	mat.set_shader_parameter("vignette_strength", 0.55)
	scan.material = mat
	layer.add_child(scan)

	var ui := CanvasLayer.new()
	ui.name = "Hud"
	ui.layer = 20
	add_child(ui)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	# 左上角标题
	var box := VBoxContainer.new()
	box.position = Vector2(56, 40)
	box.add_theme_constant_override("separation", 6)
	root.add_child(box)

	_title_label = Label.new()
	_title_label.text = "SAFE_WORLD"
	_title_label.custom_minimum_size = Vector2(0, 58)
	_title_label.add_theme_font_override("font", _ui_font_bold)
	_title_label.add_theme_font_size_override("font_size", 46)
	_title_label.add_theme_color_override("font_color", C_CYAN)
	_title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.1, 0.9))
	_title_label.add_theme_constant_override("outline_size", 8)
	box.add_child(_title_label)

	var sub := Label.new()
	sub.text = "安全区 · 主城节点 07   //   SERVER HUB"
	sub.add_theme_font_override("font", _ui_font)
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.62, 0.76, 0.86, 0.92))
	box.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	box.add_child(gap)

	var line := ColorRect.new()
	line.color = Color(C_CYAN, 0.55)
	line.custom_minimum_size = Vector2(300, 2)
	line.position = Vector2(0, 0)
	box.add_child(line)

	var status := Label.new()
	status.text = "守望节点 07 · 值守中 · 在线服务器 128/128"
	status.add_theme_font_override("font", _ui_font)
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color(0.42, 0.6, 0.72, 0.95))
	box.add_child(status)

	# 中央交互提示
	_prompt_label = Label.new()
	_prompt_label.text = "[ F ]  进入 MAIN_WORLD"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_override("font", _ui_font_bold)
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt_label.add_theme_color_override("font_color", C_CYAN)
	_prompt_label.add_theme_color_override("font_outline_color", Color(0.01, 0.05, 0.09, 0.95))
	_prompt_label.add_theme_constant_override("outline_size", 8)
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.offset_left = -260
	_prompt_label.offset_right = 260
	_prompt_label.offset_top = -128
	_prompt_label.offset_bottom = -96
	_prompt_label.modulate.a = 0.0
	root.add_child(_prompt_label)

	# 提示气泡
	_toast_label = Label.new()
	_toast_label.text = ""
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_override("font", _ui_font)
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.95))
	_toast_label.add_theme_color_override("font_outline_color", Color(0.01, 0.05, 0.09, 0.95))
	_toast_label.add_theme_constant_override("outline_size", 6)
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_label.offset_left = -320
	_toast_label.offset_right = 320
	_toast_label.offset_top = -170
	_toast_label.offset_bottom = -140
	_toast_label.modulate.a = 0.0
	root.add_child(_toast_label)

	# 黑幕
	var fade_layer := CanvasLayer.new()
	fade_layer.name = "Fade"
	fade_layer.layer = 40
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)



# ---------------------------------------------------------------- 绘制:大厅

func _draw_backdrop() -> void:
	_draw_wall()
	_draw_ceiling()
	_draw_racks()
	_draw_screens()
	_draw_floor()
	_draw_signage()
	_draw_light_cones()


## 顶灯洒下来的体积光,让机柜大厅有纵深。
func _draw_light_cones() -> void:
	var d := _backdrop
	for i in 5:
		var x := 150.0 + float(i) * 240.0
		var pts := PackedVector2Array([
			Vector2(x + 10.0, 42.0),
			Vector2(x + 110.0, 42.0),
			Vector2(x + 210.0, FLOOR_Y),
			Vector2(x - 90.0, FLOOR_Y),
		])
		var cols := PackedColorArray([
			Color(C_CYAN, 0.075),
			Color(C_CYAN, 0.075),
			Color(C_CYAN, 0.0),
			Color(C_CYAN, 0.0),
		])
		d.draw_polygon(pts, cols)


func _draw_wall() -> void:
	var d := _backdrop
	# 墙面渐变
	for y in range(0, int(FLOOR_Y)):
		var t := float(y) / FLOOR_Y
		d.draw_rect(Rect2(0.0, float(y), ROOM.x, 1.0), C_WALL_TOP.lerp(C_WALL_BOT, t))
	# 后方机柜bay:暗色板块
	for i in 9:
		var x := 12.0 + float(i) * 142.0
		d.draw_rect(Rect2(x, 168.0, 128.0, 432.0), Color(C_PANEL, 0.55))
		d.draw_rect(Rect2(x, 168.0, 128.0, 432.0), Color(C_EDGE, 0.5), false, 1.0)
	# 竖向接缝
	for i in 7:
		var x := 60.0 + float(i) * 200.0
		d.draw_line(Vector2(x, 60.0), Vector2(x, FLOOR_Y), Color(C_EDGE, 0.35), 2.0)
	# 横向管线
	for y in [276.0, 404.0]:
		d.draw_line(Vector2(0, y), Vector2(ROOM.x, y), Color(C_EDGE, 0.28), 3.0)
		d.draw_line(Vector2(0, y - 2.0), Vector2(ROOM.x, y - 2.0), Color(C_CYAN_DIM, 0.12), 1.0)


func _draw_ceiling() -> void:
	var d := _backdrop
	d.draw_rect(Rect2(0, 0, ROOM.x, 46.0), Color("#04070d"))
	d.draw_rect(Rect2(0, 44.0, ROOM.x, 2.0), Color(C_EDGE, 0.6))
	for i in 6:
		var x := 60.0 + float(i) * 220.0
		d.draw_rect(Rect2(x, 0.0, 26.0, 46.0), Color("#070d18"))
	for i in 5:
		var x := 150.0 + float(i) * 240.0
		d.draw_rect(Rect2(x - 12.0, 28.0, 144.0, 18.0), Color(C_CYAN, 0.05))
		d.draw_rect(Rect2(x, 36.0, 120.0, 4.0), Color(C_CYAN, 0.85))
		d.draw_rect(Rect2(x, 40.0, 120.0, 2.0), Color(C_CYAN, 0.25))


func _draw_racks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 771
	var xs := [46.0, 150.0, 262.0, 374.0, 486.0, 598.0, 706.0]
	var heights := [286.0, 316.0, 268.0, 330.0, 300.0, 322.0, 276.0]
	for i in xs.size():
		_draw_rack(xs[i], heights[i], rng, i)
	# 右半区两根承重柱
	for x in [850.0, 1178.0]:
		_draw_pillar(x)
	# 机柜与地面接触处的压暗,防止"浮在空中"
	var d := _backdrop
	for i in 10:
		var y := 540.0 + float(i) * 6.0
		d.draw_rect(Rect2(0.0, y, ROOM.x, 6.0), Color(0, 0, 0, 0.028 * float(i + 1)))
	for i in xs.size():
		d.draw_rect(Rect2(float(xs[i]) - 4.0, FLOOR_Y - 5.0, 100.0, 5.0), Color(0, 0, 0, 0.45))


func _draw_rack(x: float, h: float, rng: RandomNumberGenerator, idx: int) -> void:
	var d := _backdrop
	var w := 92.0
	var y0 := FLOOR_Y - h
	# 机身
	d.draw_rect(Rect2(x, y0, w, h), Color("#0a1322"))
	d.draw_rect(Rect2(x, y0, w, h), Color(C_EDGE, 0.75), false, 1.0)
	d.draw_rect(Rect2(x + 5.0, y0 + 8.0, w - 10.0, h - 16.0), Color("#070e1a"))
	# 顶部横梁 + 冷光边
	d.draw_rect(Rect2(x - 3.0, y0 - 7.0, w + 6.0, 7.0), Color("#16283f"))
	d.draw_line(Vector2(x - 3.0, y0 - 7.0), Vector2(x + w + 3.0, y0 - 7.0), Color(C_CYAN, 0.5), 1.0)
	# 散热格栅
	var slot_y := y0 + 52.0
	while slot_y < y0 + h - 26.0:
		d.draw_rect(Rect2(x + 12.0, slot_y, w - 24.0, 2.0), Color("#0e1c2e"))
		d.draw_rect(Rect2(x + 12.0, slot_y + 3.0, w - 24.0, 1.0), Color("#060c15"))
		slot_y += 9.0
	# 状态灯
	var leds := 9
	for i in leds:
		var ly := y0 + 18.0 + float(i) * 7.0
		var on := rng.randf() > 0.35
		var col := C_CYAN
		var r := rng.randf()
		if r > 0.82:
			col = C_AMBER
		elif r > 0.66:
			col = C_GREEN
		var a := 0.95 if on else 0.16
		d.draw_rect(Rect2(x + w - 16.0, ly, 4.0, 3.0), Color(col, a))
		if on:
			d.draw_rect(Rect2(x + w - 18.0, ly - 1.0, 8.0, 5.0), Color(col, 0.10))
	# 机柜编号铭牌
	var plate := Rect2(x + 8.0, y0 + h - 20.0, 34.0, 11.0)
	d.draw_rect(plate, Color("#0d1c2f"))
	d.draw_rect(plate, Color(C_CYAN_DIM, 0.55), false, 1.0)
	d.draw_string(_ui_font, Vector2(x + 12.0, y0 + h - 11.0), "R-%02d" % (idx + 1),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(C_CYAN, 0.7))


func _draw_pillar(x: float) -> void:
	var d := _backdrop
	var w := 58.0
	d.draw_rect(Rect2(x, 150.0, w, FLOOR_Y - 150.0), Color("#0a1220"))
	d.draw_rect(Rect2(x, 150.0, w, FLOOR_Y - 150.0), Color(C_EDGE, 0.8), false, 1.0)
	for i in 6:
		var y := 190.0 + float(i) * 66.0
		d.draw_rect(Rect2(x + 10.0, y, w - 20.0, 3.0), Color(C_CYAN_DIM, 0.5))
		d.draw_rect(Rect2(x + 10.0, y + 4.0, w - 20.0, 22.0), Color("#08101c"))
	d.draw_rect(Rect2(x + w * 0.5 - 2.0, 150.0, 4.0, FLOOR_Y - 150.0), Color(C_CYAN, 0.18))


func _draw_screens() -> void:
	var d := _backdrop
	# 中央主屏
	var r := Rect2(430.0, 150.0, 380.0, 124.0)
	d.draw_rect(Rect2(r.position - Vector2(6, 6), r.size + Vector2(12, 12)), Color(C_CYAN, 0.05))
	d.draw_rect(r, Color("#06121d"))
	d.draw_rect(r, Color(C_CYAN_DIM, 0.9), false, 1.5)
	d.draw_string(_ui_font_bold, r.position + Vector2(14.0, 26.0), "DIMENSION LINK",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(C_CYAN, 0.9))
	d.draw_string(_ui_font, r.position + Vector2(286.0, 26.0), "ONLINE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(C_GREEN, 0.85))
	# 网格背景
	for i in 8:
		var gx := r.position.x + 14.0 + float(i) * 48.0
		d.draw_line(Vector2(gx, r.position.y + 36.0), Vector2(gx, r.position.y + r.size.y - 12.0),
			Color(C_CYAN_DIM, 0.16), 1.0)
	for i in 3:
		var gy := r.position.y + 46.0 + float(i) * 24.0
		d.draw_line(Vector2(r.position.x + 14.0, gy), Vector2(r.end.x - 14.0, gy),
			Color(C_CYAN_DIM, 0.16), 1.0)
	# 折线图
	var pts := PackedVector2Array()
	for i in 26:
		var px := r.position.x + 16.0 + float(i) * 13.6
		var py := r.position.y + 92.0 - sin(float(i) * 0.7) * 13.0 - float(i) * 0.9
		pts.append(Vector2(px, py))
	d.draw_polyline(pts, Color(C_CYAN, 0.85), 2.0)

	# 左侧整备终端:悬空全息板 + 落地控制台
	var p := Rect2(206.0, 300.0, 200.0, 112.0)
	d.draw_rect(Rect2(p.position - Vector2(5, 5), p.size + Vector2(10, 10)), Color(C_VIOLET, 0.05))
	d.draw_rect(p, Color("#080f1c"))
	d.draw_rect(p, Color(C_VIOLET, 0.45), false, 1.0)
	d.draw_string(_ui_font_bold, p.position + Vector2(12.0, 24.0), "LOADOUT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(C_VIOLET, 0.9))
	for i in 4:
		var y := p.position.y + 40.0 + float(i) * 15.0
		d.draw_rect(Rect2(p.position.x + 12.0, y, 88.0, 3.0), Color(0.6, 0.7, 0.8, 0.22))
		d.draw_rect(Rect2(p.position.x + 108.0, y, 80.0, 3.0), Color(C_VIOLET, 0.35))
	# 全息板与终端之间的微光
	d.draw_line(Vector2(306.0, 412.0), Vector2(306.0, 538.0), Color(C_VIOLET, 0.10), 2.0)

	# 控制台本体
	d.draw_rect(Rect2(276.0, 546.0, 108.0, 54.0), Color("#0b1420"))
	d.draw_rect(Rect2(276.0, 546.0, 108.0, 54.0), Color(C_EDGE, 0.9), false, 1.0)
	d.draw_rect(Rect2(284.0, 554.0, 92.0, 26.0), Color("#08161f"))
	for i in 4:
		var sy := 558.0 + float(i) * 6.0
		d.draw_rect(Rect2(288.0, sy, 84.0, 2.0), Color(C_CYAN, 0.22))
	d.draw_rect(Rect2(284.0, 586.0, 92.0, 8.0), Color("#0d1a29"))
	d.draw_rect(Rect2(284.0, 586.0, 92.0, 2.0), Color(C_VIOLET, 0.7))
	d.draw_rect(Rect2(270.0, FLOOR_Y - 5.0, 120.0, 5.0), Color(C_VIOLET, 0.28))
	d.draw_rect(Rect2(282.0, FLOOR_Y - 2.0, 96.0, 3.0), Color(C_VIOLET, 0.55))


func _draw_floor() -> void:
	var d := _backdrop
	for y in range(int(FLOOR_Y), int(ROOM.y)):
		var t := float(y - FLOOR_Y) / (ROOM.y - FLOOR_Y)
		d.draw_rect(Rect2(0.0, float(y), ROOM.x, 1.0), C_FLOOR_TOP.lerp(C_FLOOR_BOT, t))
	# 透视地砖:纵向
	for k in range(-9, 10):
		var xb := 640.0 + float(k) * 112.0
		var xt := 640.0 + float(k) * 34.0
		d.draw_line(Vector2(xt, FLOOR_Y), Vector2(xb, ROOM.y), Color(C_CYAN_DIM, 0.20), 1.0)
	# 透视地砖:横向
	for i in range(1, 13):
		var t := float(i) / 12.0
		var y := FLOOR_Y + (ROOM.y - FLOOR_Y) * pow(t, 1.9)
		d.draw_line(Vector2(0.0, y), Vector2(ROOM.x, y), Color(C_CYAN_DIM, 0.16 + 0.1 * t), 1.0)
	# 前沿高光
	d.draw_rect(Rect2(0.0, FLOOR_Y - 2.0, ROOM.x, 3.0), Color(C_CYAN, 0.45))
	d.draw_rect(Rect2(0.0, FLOOR_Y + 1.0, ROOM.x, 6.0), Color(C_CYAN, 0.06))
	# 灯光在地面的反射
	for i in 5:
		var x := 150.0 + float(i) * 240.0
		d.draw_rect(Rect2(x, FLOOR_Y, 120.0, 46.0), Color(C_CYAN, 0.035))
		d.draw_rect(Rect2(x + 20.0, FLOOR_Y, 80.0, 26.0), Color(C_CYAN, 0.03))


func _draw_signage() -> void:
	var d := _backdrop
	d.draw_string(_ui_font_bold, Vector2(54.0, 134.0), "SAFE_WORLD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(C_CYAN, 0.10))
	d.draw_string(_ui_font, Vector2(60.0, 166.0), "// 安全区 · 主城节点 07",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(C_CYAN, 0.16))
	# 地面接触线
	d.draw_rect(Rect2(0.0, 596.0, ROOM.x, 2.0), Color(0, 0, 0, 0.5))


# ---------------------------------------------------------------- 绘制:传送门

func _draw_portal() -> void:
	var d := _portal
	var c := PORTAL_CENTER
	var t := _t

	# 地面上的能量环
	d.draw_set_transform(Vector2(c.x, FLOOR_Y - 2.0), 0.0, Vector2(1.0, 0.26))
	for i in 7:
		var rr := 118.0 - float(i) * 13.0
		d.draw_circle(Vector2.ZERO, rr, Color(C_CYAN, 0.035 + float(i) * 0.012))
	d.draw_arc(Vector2.ZERO, 118.0, 0.0, TAU, 64, Color(C_CYAN, 0.55), 3.0)
	d.draw_arc(Vector2.ZERO, 86.0, 0.0, TAU, 64, Color(C_VIOLET, 0.35), 2.0)
	d.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 门框
	d.draw_rect(Rect2(c.x - 132.0, c.y - 150.0, 264.0, 300.0), Color(C_CYAN, 0.03))
	d.draw_rect(Rect2(c.x - 132.0, c.y - 150.0, 264.0, 300.0), Color(C_CYAN_DIM, 0.35), false, 2.0)

	# 外环
	d.draw_arc(c, 120.0, 0.0, TAU, 96, Color(C_CYAN, 0.30), 6.0)
	d.draw_arc(c, 120.0, 0.0, TAU, 96, Color(C_CYAN, 0.55), 2.0)
	# 旋转刻度
	var seg := 16
	for i in seg:
		var a0 := t * 0.7 + TAU * float(i) / float(seg)
		var a1 := a0 + 0.13
		var bright := 0.25 + 0.55 * (0.5 + 0.5 * sin(float(i) * 1.7 + t * 2.0))
		d.draw_arc(c, 110.0, a0, a1, 6, Color(C_CYAN, bright), 3.0)
	# 反向内环
	for i in 12:
		var a0 := -t * 1.1 + TAU * float(i) / 12.0
		d.draw_arc(c, 96.0, a0, a0 + 0.12, 5, Color(C_VIOLET, 0.4), 2.0)
	# 内部能量弧
	for i in 5:
		var a0 := t * (1.4 + 0.2 * float(i)) + float(i) * 1.3
		d.draw_arc(c, 74.0 - float(i) * 9.0, a0, a0 + 2.1, 18,
			Color(C_CYAN.lerp(C_VIOLET, float(i) / 5.0), 0.30), 3.0)
	# 核心
	var core := 0.5 + 0.5 * sin(t * 2.4)
	d.draw_circle(c, 46.0, Color(C_VIOLET, 0.06 + 0.04 * core))
	d.draw_circle(c, 30.0, Color(C_CYAN, 0.10 + 0.05 * core))
	d.draw_circle(c, 15.0, Color(0.85, 0.97, 1.0, 0.22 + 0.10 * core))
	d.draw_circle(c, 6.0, Color(1.0, 1.0, 1.0, 0.55))

	# 上升的数据粒子
	for i in 22:
		var ph := fmod(t * (0.35 + float(i) * 0.021) + float(i) * 0.37, 1.0)
		var py := FLOOR_Y - 10.0 - ph * 260.0
		var px := c.x + sin(float(i) * 2.1 + t * 1.3) * 70.0
		var a := (1.0 - ph) * 0.55
		d.draw_rect(Rect2(px, py, 2.0, 6.0), Color(C_CYAN, a))

	# 顶部标签
	d.draw_string(_ui_font_bold, Vector2(c.x - 78.0, c.y - 166.0), "MAIN_WORLD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(C_CYAN, 0.55 + 0.25 * core))
	d.draw_string(_ui_font, Vector2(c.x - 78.0, c.y - 148.0), "维度通道 04",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(C_CYAN, 0.4))


func _draw_fx() -> void:
	var d := _fx
	for m in _motes:
		var x: float = m.x + sin(_t * 0.25 + m.z * 12.0) * 12.0
		var y: float = fmod(m.y - _t * (6.0 + m.z * 12.0), ROOM.y)
		if y < 0.0:
			y += ROOM.y
		d.draw_circle(Vector2(x, y), 0.9 + m.z * 0.9, Color(0.72, 0.9, 1.0, 0.05 + m.z * 0.09))
