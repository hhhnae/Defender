extends Area2D
## 藤蔓 / 绳梯:玩家进入范围后可以上下攀爬(画面上直接用 Aseprite 素材平铺)。

const VINE_TEX: Texture2D = preload("res://levels/forest/vine.png")
const LADDER_TEX: Texture2D = preload("res://levels/forest/ladder.png")
const UI_FONT := preload("res://levels/ui/ui_font.gd")

enum Kind { VINE, LADDER }

@export var kind := Kind.VINE
## 关掉后只保留交互,不画素材(关卡里已画好藤蔓时用)
@export var visible_art := true
## 攀爬区大小(宽 × 高),以节点位置为中心
@export var size := Vector2(56, 240)

@onready var _shape: CollisionShape2D = $CollisionShape2D
var _near := false
var _font: Font
var _player: Node2D = null


func _ready() -> void:
	z_index = 4
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	var rs := RectangleShape2D.new()
	rs.size = size
	_shape.shape = rs
	_font = UI_FONT.make(true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if visible_art:
		queue_redraw()


func _process(_delta: float) -> void:
	if _near:
		# 角色已经离开(例如快速跳过)时,提示要自动收起
		if _player == null or not is_instance_valid(_player) or not overlaps_body(_player):
			_near = false
			_player = null
		queue_redraw()


func _draw() -> void:
	if not visible_art:
		_draw_hint()
		return
	var tex: Texture2D = LADDER_TEX if kind == Kind.LADDER else VINE_TEX
	var w: float = float(tex.get_width())
	var draw_w: float = minf(w, size.x)
	var x0 := -draw_w * 0.5
	var y := -size.y * 0.5
	while y < size.y * 0.5:
		var h := minf(float(tex.get_height()), size.y * 0.5 - y)
		draw_texture_rect(tex, Rect2(x0, y, draw_w, h), false)
		y += float(tex.get_height())


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_climb_zone"):
		body.call("set_climb_zone", self)
		_near = true
		_player = body as Node2D
		queue_redraw()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("clear_climb_zone"):
		body.call("clear_climb_zone", self)
		_near = false
		_player = null
		queue_redraw()


## 靠近时在头顶显示一小行提示
func _draw_hint() -> void:
	if not _near or _font == null:
		return
	var text := "按 J 攀爬"
	var fs := 13
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var y := -size.y * 0.5 - 26.0
	if _player != null and is_instance_valid(_player):
		y = to_local(_player.global_position).y - 104.0
	draw_rect(Rect2(-w * 0.5 - 8.0, y - 16.0, w + 16.0, 22.0), Color(0.02, 0.04, 0.06, 0.78))
	draw_rect(Rect2(-w * 0.5 - 8.0, y - 16.0, w + 16.0, 22.0), Color(0.4, 0.9, 1.0, 0.45), false, 1.0)
	draw_string(_font, Vector2(-w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		Color(0.85, 0.97, 1.0, 0.95))
