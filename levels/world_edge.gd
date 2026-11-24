extends Node2D

## 外层节点 —— 幽暗古森(横版银河恶魔城式关卡)。
## 2560×1440:主角出生在最左端,传送门在最右端。
## 场景装饰由子节点 Decor(world_edge_decor.gd)一次性绘制,萤火虫单独动画。

const GROUND := 1045.0

@onready var _player: CharacterBody2D = $Player


const S := 2.6666667
## 摄像机在主角上方多看的距离(抬高取景)
const CAM_LIFT := -130.0


func _ready() -> void:
	_build_ground()
	_lift_camera()


## 把主角的摄像机整体上移,开局就能看到上层枝干
func _lift_camera() -> void:
	var player := get_node_or_null("Player")
	if player == null:
		return
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.position = Vector2(0.0, CAM_LIFT)
	cam.reset_smoothing()


## 参考图里的地面剖面(ref 坐标)
func _ground_left(x: float) -> float:
	if x < 150.0:
		return 392.0
	if x < 196.0:
		return 392.0 - (x - 150.0) * 0.6
	if x < 262.0:
		return 365.0
	if x < 332.0:
		return 372.0 + sin((x - 262.0) * 0.07) * 3.0
	return 376.0


func _ground_right(x: float) -> float:
	if x < 470.0:
		return 384.0
	if x < 596.0:
		return 396.0
	if x < 700.0:
		return 404.0
	if x < 800.0:
		return 424.0
	if x < 852.0:
		return 396.0
	if x < 880.0:
		return 368.0
	return 344.0


## 用 CollisionPolygon2D 沿着剖面铺连续地面(之前的分段矩形会漏缝)
func _build_ground() -> void:
	var body := StaticBody2D.new()
	body.name = "GroundBody"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var spans := [
		[0.0, 372.0, 0],     # 左段地面(含出生点斜坡)
		[424.0, 596.0, 1],   # 中段
		[640.0, 700.0, 1],   # 毒沼左侧
		[800.0, 960.0, 1],   # 毒沼右侧台地
	]
	for span in spans:
		var x0: float = span[0]
		var x1: float = span[1]
		var kind: int = span[2]
		var top := PackedVector2Array()
		var x := x0
		while x < x1:
			var gy: float = _ground_left(x) if kind == 0 else _ground_right(x)
			top.append(Vector2(x * S, gy * S))
			x += 6.0
		var last: float = _ground_left(x1) if kind == 0 else _ground_right(x1)
		top.append(Vector2(x1 * S, last * S))
		var poly := PackedVector2Array()
		for p2 in top:
			poly.append(p2)
		poly.append(Vector2(x1 * S, 540.0 * S))
		poly.append(Vector2(x0 * S, 540.0 * S))
		var cp := CollisionPolygon2D.new()
		cp.polygon = poly
		cp.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		body.add_child(cp)
