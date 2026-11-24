extends Node2D

## 关卡里的萤火虫:单独一个轻量节点,每帧只画几十个点。

const W := 2560.0
const C_FLY := Color("#e2d882")

var _flies: Array[Vector3] = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	for i in 46:
		_flies.append(Vector3(
			rng.randf_range(60.0, W - 60.0),
			rng.randf_range(240.0, 1120.0),
			rng.randf_range(0.0, TAU)))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for f in _flies:
		var a := 0.30 + 0.35 * sin(_t * 2.2 + f.z)
		var x: float = f.x + sin(_t * 0.8 + f.z) * 16.0
		var y: float = f.y + cos(_t * 0.6 + f.z) * 12.0
		draw_rect(Rect2(x, y, 3, 3), Color(C_FLY.r, C_FLY.g, C_FLY.b, a))
		draw_rect(Rect2(x + 3, y, 2, 2), Color(C_FLY.r, C_FLY.g, C_FLY.b, a * 0.35))
