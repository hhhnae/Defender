extends Area2D

## 宝箱:靠近显示提示,按 J 打开,弹出获得插件的横幅并写入 Plugins。

signal opened

const UI_FONT := preload("res://levels/ui/ui_font.gd")
const CHEST_CLOSED: Texture2D = preload("res://levels/forest/chest_closed.png")
const CHEST_OPEN: Texture2D = preload("res://levels/forest/chest_open.png")

@export var plugin_id := "plugin_time_boost"
@export var size := Vector2(120, 120)

var _opened := false
var _near := false
var _player: Node2D = null
var _font: Font
var _burst := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	_font = UI_FONT.make(true)
	var rs := RectangleShape2D.new()
	rs.size = size
	_shape.shape = rs
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pg := get_node_or_null("/root/Plugins")
	if pg != null and bool(pg.call("has", plugin_id)):
		_opened = true
		_sprite.texture = CHEST_OPEN
	else:
		_sprite.texture = CHEST_CLOSED
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _process(delta: float) -> void:
	if _burst > 0.0:
		_burst = maxf(0.0, _burst - delta)
		queue_redraw()
	if not _near or _opened or _player == null:
		return
	if Input.is_action_just_pressed("attack_light"):
		_open()


func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body as Node2D
		_near = true
		queue_redraw()


func _on_exit(body: Node) -> void:
	if body == _player:
		_player = null
		_near = false
		queue_redraw()


func _open() -> void:
	if _opened:
		return
	_opened = true
	_sprite.texture = CHEST_OPEN
	_burst = 0.9
	queue_redraw()
	var plugins := get_node_or_null("/root/Plugins")
	if plugins != null:
		plugins.call("grant", plugin_id)
		# 插件属于终极技能,进整备库,默认装进空的终极槽
		var lo := get_node_or_null("/root/Loadout")
		var item: Dictionary = plugins.call("to_item", plugin_id)
		if lo != null and not item.is_empty():
			lo.call("grant", item)
			if lo.call("has_ultimate", plugin_id) == false and int(lo.call("first_empty", "ultimate")) >= 0:
				lo.call("equip", item, "ultimate")
	_show_banner()
	opened.emit()


# ---------------------------------------------------------------- 横幅

func _show_banner() -> void:
	var plugins := get_node_or_null("/root/Plugins")
	var data: Dictionary = {}
	if plugins != null:
		data = plugins.call("get_data", plugin_id)
	var title := String(data.get("name", "时域强化"))
	var sub := String(data.get("sub", "TIME DOMAIN BOOST"))
	var desc := String(data.get("desc", ""))

	var layer := CanvasLayer.new()
	layer.name = "PluginBanner"
	layer.layer = 40
	add_child(layer)

	var panel := Panel.new()
	panel.size = Vector2(430, 104)
	panel.position = Vector2(425, 520)
	layer.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.09, 0.94)
	style.border_color = Color(0.45, 0.9, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var icon := TextureRect.new()
	icon.texture = load("res://levels/ui/icons/icon_time_boost.png")
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(16, 20)
	icon.size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(icon)

	var t1 := Label.new()
	t1.text = "获得插件 · " + title
	t1.position = Vector2(94, 20)
	t1.add_theme_font_override("font", _font)
	t1.add_theme_font_size_override("font_size", 20)
	t1.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0, 1.0))
	panel.add_child(t1)

	var t2 := Label.new()
	t2.text = sub
	t2.position = Vector2(96, 46)
	t2.add_theme_font_override("font", _font)
	t2.add_theme_font_size_override("font_size", 11)
	t2.add_theme_color_override("font_color", Color(0.55, 0.85, 0.95, 0.8))
	panel.add_child(t2)

	var t3 := Label.new()
	t3.text = desc
	t3.position = Vector2(96, 62)
	t3.add_theme_font_override("font", _font)
	t3.add_theme_font_size_override("font_size", 12)
	t3.add_theme_color_override("font_color", Color(0.72, 0.86, 0.9, 0.95))
	panel.add_child(t3)

	panel.modulate.a = 0.0
	panel.position.y = 540.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "position:y", 520.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	tw.chain().tween_interval(2.6)
	tw.chain().tween_property(panel, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(func() -> void:
		layer.queue_free()
	)


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	if _opened and _burst > 0.0:
		var t := 1.0 - _burst / 0.9
		var r := 18.0 + t * 70.0
		var col := Color(0.55, 0.95, 1.0, (1.0 - t) * 0.9)
		draw_arc(Vector2(0, -18), r, 0.0, TAU, 28, col, 3.0)
		draw_arc(Vector2(0, -18), r * 0.6, 0.0, TAU, 22, col, 2.0)
	if _near and not _opened:
		var text := "按 J 开启"
		var fs := 13
		var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var y := -58.0
		if _player != null and is_instance_valid(_player):
			y = to_local(_player.global_position).y - 104.0
		draw_rect(Rect2(-tw * 0.5 - 8.0, y - 16.0, tw + 16.0, 22.0), Color(0.02, 0.04, 0.06, 0.78))
		draw_rect(Rect2(-tw * 0.5 - 8.0, y - 16.0, tw + 16.0, 22.0), Color(0.45, 0.95, 1.0, 0.45), false, 1.0)
		draw_string(_font, Vector2(-tw * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(0.88, 0.98, 1.0, 0.95))
