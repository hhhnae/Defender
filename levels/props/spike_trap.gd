extends Area2D
## 尖刺陷阱:踩到/碰到就扣血并弹开,画面上用 Aseprite 的尖刺素材平铺。

const SPIKE_TEX: Texture2D = preload("res://levels/forest/spike.png")

@export var damage := 12
@export var size := Vector2(96, 20)
@export var cooldown := 0.7
## 关掉后只保留伤害判定,不画素材
@export var visible_art := true

var _cool := 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	var rs := RectangleShape2D.new()
	rs.size = size
	_shape.shape = rs
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if visible_art:
		queue_redraw()


func _physics_process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if _cool > 0.0:
		return
	for body in get_overlapping_bodies():
		_hit(body)
		if _cool > 0.0:
			break


func _hit(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if not body.has_method("take_damage"):
		return
	if _cool > 0.0:
		return
	_cool = cooldown
	body.call("take_damage", damage, global_position)


func _draw() -> void:
	if not visible_art:
		return
	var tex: Texture2D = SPIKE_TEX
	var w: float = float(tex.get_width())
	var y: float = size.y * 0.5 - float(tex.get_height())
	var x: float = -size.x * 0.5
	while x < size.x * 0.5:
		draw_texture_rect(tex, Rect2(x, y, minf(w, size.x * 0.5 - x), float(tex.get_height())), false)
		x += w
