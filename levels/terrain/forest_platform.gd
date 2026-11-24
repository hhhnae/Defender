extends StaticBody2D
## 森林地形组件:自绘泥土 + 苔藓顶面(素材由 Aseprite 绘制,32px 平铺)。

const SOIL: Texture2D = preload("res://levels/forest/soil.png")
const MOSS: Texture2D = preload("res://levels/forest/moss_top.png")

@export var size := Vector2(128, 24)
@export var one_way := false

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var rs := RectangleShape2D.new()
	rs.size = size
	_shape.shape = rs
	_shape.one_way_collision = one_way
	_shape.one_way_collision_margin = 4.0
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)
	draw_texture_rect(SOIL, rect, true)
	var moss_h := minf(h, 12.0)
	draw_texture_rect(MOSS, Rect2(-w * 0.5, -h * 0.5, w, moss_h), true)
	if not one_way:
		draw_rect(Rect2(-w * 0.5, h * 0.5 - 4.0, w, 3.0), Color(0, 0, 0, 0.4))
