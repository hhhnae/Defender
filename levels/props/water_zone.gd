extends Area2D

## 毒沼水域:进入后缓慢下沉、按空格上浮,并消耗氧气(氧气归零死亡)。

@export var size := Vector2(300, 250)

const UI_FONT := preload("res://levels/ui/ui_font.gd")
const C_CYAN := Color("#5fe4ff")
const C_GREEN := Color("#6ad06a")
const C_RED := Color("#ff5a5a")

var _shape: CollisionShape2D
var _player: Node2D = null
var _bar: Control = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	_shape = get_node_or_null("CollisionShape2D")
	if _shape != null:
		var rs := RectangleShape2D.new()
		rs.size = size
		_shape.shape = rs
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_build_ui()


## 水面世界高度(区域顶边)
func surface_y() -> float:
	return global_position.y - size.y * 0.5


func _on_enter(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_water_zone"):
		_player = body as Node2D
		body.call("set_water_zone", self)
		if _bar != null:
			_bar.player = body
			_bar.visible = true


func _on_exit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("clear_water_zone"):
		body.call("clear_water_zone", self)
		if _player == body:
			_player = null
		if _bar != null:
			_bar.player = null
			_bar.visible = false


# ---------------------------------------------------------------- 氧气 UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "WaterHud"
	layer.layer = 6
	add_child(layer)
	_bar = OxygenBar.new()
	_bar.visible = false
	layer.add_child(_bar)


class OxygenBar extends Control:
	var player: Node = null
	var font: Font
	var font_bold: Font

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		position = Vector2(20, 150)
		size = Vector2(272, 34)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if font == null:
			font = preload("res://levels/ui/ui_font.gd").make(false)
			font_bold = preload("res://levels/ui/ui_font.gd").make(true)
		var ox := 100.0
		if player != null and is_instance_valid(player):
			var raw: Variant = player.get("oxygen")
			if raw != null:
				ox = float(raw)
		var ratio: float = clampf(ox / 100.0, 0.0, 1.0)
		# 面板
		draw_rect(Rect2(0, 0, size.x, 30), Color(0.03, 0.06, 0.08, 0.82))
		draw_rect(Rect2(0, 0, size.x, 30), Color(0.35, 0.85, 1.0, 0.4), false, 1.0)
		draw_string(font_bold, Vector2(10, 20), "O₂", HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(0.8, 0.96, 1.0, 0.95))
		var bx := 44.0
		var bw := size.x - 56.0
		draw_rect(Rect2(bx, 10, bw, 10), Color(0.06, 0.12, 0.14, 1.0))
		var col := Color(0.42, 0.86, 0.68, 1.0)
		if ratio < 0.5:
			col = Color(0.95, 0.78, 0.30, 1.0)
		if ratio < 0.25:
			col = Color(0.95, 0.32, 0.28, 1.0)
		draw_rect(Rect2(bx, 10, bw * ratio, 10), col)
		draw_rect(Rect2(bx, 10, bw, 10), Color(0.4, 0.9, 1.0, 0.35), false, 1.0)
