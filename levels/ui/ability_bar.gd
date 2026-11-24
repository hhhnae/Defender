extends Control

## 血量下方的技能条:读取 Abilities 的条目,画出图标 / 冷却遮罩 / 剩余秒数。
## 与具体技能无关——加技能只要在 Abilities.DEFS 里加一条。

const UI_FONT := preload("res://levels/ui/ui_font.gd")
const ICON := 44.0
const GAP := 10.0
const C_GOLD := Color("#ffc84a")

var _font: Font
var _font_bold: Font
var _textures := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(20, 96)
	size = Vector2(272, 64)
	_font = UI_FONT.make(false)
	_font_bold = UI_FONT.make(true)
	var ab := get_node_or_null("/root/Abilities")
	if ab != null:
		ab.changed.connect(func() -> void: queue_redraw())


func _process(_delta: float) -> void:
	var ab := get_node_or_null("/root/Abilities")
	if ab == null:
		return
	if int(ab.get("entries").size()) > 0:
		queue_redraw()


func _tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _textures.has(path):
		return _textures[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var img := Image.new()
		if img.load(path) == OK:
			tex = ImageTexture.create_from_image(img)
	_textures[path] = tex
	return tex


func _draw() -> void:
	var ab := get_node_or_null("/root/Abilities")
	if ab == null:
		return
	var entries: Array = ab.get("entries")
	var x := 0.0
	for e in entries:
		var entry: Dictionary = e
		var box := Rect2(x, 0, ICON, ICON)
		draw_rect(box, Color(0.03, 0.06, 0.09, 0.9))
		var icon := _tex(String(entry.get("icon", "")))
		if icon != null:
			draw_texture_rect(icon, box.grow(-3.0), false)

		var active := float(entry.get("active", 0.0))
		var cd := float(entry.get("cd", 0.0))
		var cd_total := maxf(0.001, float(entry.get("cd_total", 0.0)))

		if cd > 0.0:
			# 冷却:自下而上的暗色遮罩 + 居中白色秒数(与假死一致)
			var h := ICON * clampf(cd / cd_total, 0.0, 1.0)
			draw_rect(Rect2(x, ICON - h, ICON, h), Color(0.02, 0.04, 0.06, 0.78))
			draw_rect(box, Color(0.35, 0.62, 0.72, 0.55), false, 1.0)
			_draw_center_text(x, "%d" % int(ceil(cd)), Color(0.95, 0.96, 1.0, 0.95))
		elif active > 0.0:
			# 持续时间:同样的居中数字,改成金色 + 金边
			draw_rect(box.grow(-1.0), C_GOLD, false, 2.0)
			_draw_center_text(x, "%d" % int(ceil(active)), C_GOLD)
		else:
			draw_rect(box, Color(0.35, 0.62, 0.72, 0.55), false, 1.0)

		# 快捷键提示
		var hint := String(entry.get("hint", ""))
		if not hint.is_empty():
			var hw := _font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			draw_rect(Rect2(x + ICON - hw - 6.0, ICON - 12.0, hw + 4.0, 11.0), Color(0.02, 0.04, 0.06, 0.8))
			draw_string(_font, Vector2(x + ICON - hw - 4.0, ICON - 3.0), hint,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.88, 0.95, 0.9))
		x += ICON + GAP


## 居中大字(冷却 / 持续时长共用)
func _draw_center_text(x: float, text: String, col: Color) -> void:
	var tw := _font_bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var pos := Vector2(x + (ICON - tw) * 0.5, ICON * 0.5 + 7.0)
	draw_string(_font_bold, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 0, 0, 0.7))
	draw_string(_font_bold, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
