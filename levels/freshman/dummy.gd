extends Node2D

## 训练假人:只用来给新手关打,挨打会闪白并发出信号。

signal hit_registered

var _hits := 0
var _flash := 0.0
var _shake := 0.0


func _ready() -> void:
	add_to_group("enemy")
	var area := Area2D.new()
	area.name = "Hurtbox"
	area.collision_layer = 4
	area.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(58.0, 96.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -52.0)
	area.add_child(shape)
	add_child(area)


func take_hit(_damage: int, _facing: int, _knockback: float, _launch: float) -> void:
	_hits += 1
	_flash = 0.22
	_shake = 0.18
	queue_redraw()
	hit_registered.emit()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		_shake = maxf(0.0, _shake - delta)
		queue_redraw()


func _draw() -> void:
	var body := Color("#16303f")
	var edge := Color(0.32, 0.78, 0.92, 0.9)
	var amber := Color("#ffb648")
	if _flash > 0.0:
		body = body.lerp(Color(1, 1, 1, 1), 0.7)
	var jitter := sin(_shake * 60.0) * 2.0 if _shake > 0.0 else 0.0

	# 底座
	draw_rect(Rect2(-34.0, -10.0, 68.0, 10.0), Color("#0c1a26"))
	draw_rect(Rect2(-34.0, -10.0, 68.0, 10.0), edge, false, 1.0)
	# 支架
	draw_rect(Rect2(-6.0 + jitter, -46.0, 12.0, 36.0), body)
	# 躯干
	draw_rect(Rect2(-30.0 + jitter, -96.0, 60.0, 52.0), body)
	draw_rect(Rect2(-30.0 + jitter, -96.0, 60.0, 52.0), edge, false, 2.0)
	# 靶心
	for i in 3:
		var r := 18.0 - float(i) * 5.0
		var col := amber if i % 2 == 0 else Color(0.85, 0.95, 1.0, 0.85)
		draw_arc(Vector2(jitter, -70.0), r, 0.0, TAU, 28, col, 2.0)
	# 头
	draw_rect(Rect2(-14.0 + jitter, -122.0, 28.0, 22.0), body)
	draw_rect(Rect2(-14.0 + jitter, -122.0, 28.0, 22.0), edge, false, 1.0)
	draw_rect(Rect2(-8.0 + jitter, -116.0, 16.0, 5.0), amber)
	# 灯
	if _flash <= 0.0:
		draw_circle(Vector2(jitter, -111.0), 2.0, Color(1.0, 0.72, 0.32, 0.9))
