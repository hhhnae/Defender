extends CanvasLayer

## 维度通道:在传送门交互后弹出,选择要前往的地图。
## 左侧是地图列表,右侧是选中地图的详情与「进入」按钮。

signal entered(id: String)

const UI_FONT := preload("res://levels/ui/ui_font.gd")

const C_CYAN := Color("#5fe4ff")
const C_VIOLET := Color("#9d6bff")
const C_AMBER := Color("#ffb648")
const C_GREEN := Color("#5dffb0")
const C_TEXT := Color(0.78, 0.98, 1.0, 1.0)
const C_MUTED := Color(0.42, 0.6, 0.7, 0.9)

var _opened := false
var _paused_by_us := false
var _font: Font
var _font_bold: Font

var _root: Control
var _list: VBoxContainer
var _preview_name: Label
var _preview_sub: Label
var _preview_desc: Label
var _preview_status: Label
var _enter_button: Button
var _selected_id := ""

var _buttons := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 56
	visible = false
	_font = UI_FONT.make(false)
	_font_bold = UI_FONT.make(true)
	_build()


func is_open() -> bool:
	return _opened


func open(prefer_id := "") -> void:
	if _opened:
		return
	_opened = true
	visible = true
	if WorldMap != null:
		WorldMap.changed.connect(_refresh_list, CONNECT_REFERENCE_COUNTED)
	var ids := _ids()
	if prefer_id != "" and ids.has(prefer_id):
		_selected_id = prefer_id
	elif not ids.has(_selected_id):
		_selected_id = ids[0] if not ids.is_empty() else ""
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_us = true
	_refresh_list()
	_refresh_preview()


func close() -> void:
	if not _opened:
		return
	_opened = false
	visible = false
	if _paused_by_us:
		_paused_by_us = false
		get_tree().paused = false


func _exit_tree() -> void:
	if _paused_by_us:
		_paused_by_us = false
		get_tree().paused = false


func _ids() -> Array:
	var out := []
	for m in WorldMap.maps():
		out.append(String(m["id"]))
	return out


func _input(event: InputEvent) -> void:
	if not _opened:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


# ---------------------------------------------------------------- 交互

func _on_entry_pressed(id: String) -> void:
	_selected_id = id
	_refresh_list()
	_refresh_preview()


func _on_enter_pressed() -> void:
	if _selected_id == "" or not WorldMap.is_unlocked(_selected_id):
		return
	var id := _selected_id
	close()
	entered.emit(id)


# ---------------------------------------------------------------- 刷新

func _refresh_list() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for m in WorldMap.maps():
		var id := String(m["id"])
		var locked := not WorldMap.is_unlocked(id)
		var selected := id == _selected_id
		var btn := _make_entry(m, locked, selected)
		btn.pressed.connect(_on_entry_pressed.bind(id))
		_list.add_child(btn)
		_buttons[id] = btn


func _refresh_preview() -> void:
	if _preview_name == null:
		return
	var m := WorldMap.get_entry(_selected_id)
	if m.is_empty():
		_preview_name.text = "—"
		_preview_sub.text = ""
		_preview_desc.text = ""
		_preview_status.text = ""
		_enter_button.disabled = true
		return
	var locked := not WorldMap.is_unlocked(_selected_id)
	_preview_name.text = String(m["name"])
	_preview_sub.text = String(m["sub"])
	_preview_desc.text = String(m["desc"])
	_preview_status.text = WorldMap.status_text(_selected_id)
	var status_color := C_GREEN
	if locked:
		status_color = C_AMBER
	_preview_status.add_theme_color_override("font_color", status_color)
	_enter_button.disabled = locked
	_enter_button.text = "进入地图" if not locked else "尚未解锁"


# ---------------------------------------------------------------- 控件

func _make_entry(m: Dictionary, locked: bool, selected: bool) -> Button:
	var id := String(m["id"])
	var kind := String(m["kind"])
	var accent := C_CYAN
	if kind == "tutorial":
		accent = C_GREEN
	elif kind == "final":
		accent = C_VIOLET

	var bg := Color(0.02, 0.05, 0.09, 0.9)
	var border := Color(accent.r, accent.g, accent.b, 0.45)
	if selected:
		border = C_AMBER
		bg = Color(0.07, 0.14, 0.2, 0.95)
	elif WorldMap.is_cleared(id):
		bg = Color(0.03, 0.09, 0.12, 0.92)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(430, 64)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _box(bg, border))
	btn.add_theme_stylebox_override("hover", _box(bg.lightened(0.06), border))
	btn.add_theme_stylebox_override("pressed", _box(bg, border))
	btn.add_theme_stylebox_override("focus", _box(bg, border))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)

	var name_label := Label.new()
	name_label.text = String(m["name"])
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font", _font_bold)
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", C_TEXT if not locked else C_MUTED)
	texts.add_child(name_label)

	var sub := Label.new()
	sub.text = String(m["sub"])
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_font_override("font", _font)
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.75))
	texts.add_child(sub)

	var tag := Label.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.custom_minimum_size = Vector2(96, 0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_theme_font_override("font", _font_bold)
	tag.add_theme_font_size_override("font_size", 11)
	if WorldMap.is_cleared(id):
		tag.text = "已探索"
		tag.add_theme_color_override("font_color", C_GREEN)
	elif locked:
		tag.text = "锁定"
		tag.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45, 0.9))
	else:
		tag.text = "可进入"
		tag.add_theme_color_override("font_color", accent)
	row.add_child(tag)
	return btn


# ---------------------------------------------------------------- 构建

func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.02, 0.04, 0.08, 0.97), Color(0.35, 0.9, 1.0, 0.8)))
	panel.custom_minimum_size = Vector2(1060, 604)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 12)
	margin.add_child(root_box)

	root_box.add_child(_build_header())

	var rule := ColorRect.new()
	rule.color = Color(0.35, 0.9, 1.0, 0.35)
	rule.custom_minimum_size = Vector2(0, 2)
	root_box.add_child(rule)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 26)
	root_box.add_child(body)

	# 左:地图列表
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(430, 0)
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)

	var list_title := Label.new()
	list_title.text = "地图列表 / MAPS · 由外到内"
	list_title.add_theme_font_override("font", _font_bold)
	list_title.add_theme_font_size_override("font_size", 13)
	list_title.add_theme_color_override("font_color", Color(0.5, 0.78, 0.9, 0.95))
	left.add_child(list_title)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	left.add_child(_list)

	# 右:详情
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(520, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)

	var detail_title := Label.new()
	detail_title.text = "目标详情 / DETAILS"
	detail_title.add_theme_font_override("font", _font_bold)
	detail_title.add_theme_font_size_override("font_size", 13)
	detail_title.add_theme_color_override("font_color", Color(0.5, 0.78, 0.9, 0.95))
	right.add_child(detail_title)

	var detail_panel := PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel",
		_box(Color(0.03, 0.06, 0.10, 0.92), Color(0.3, 0.7, 0.85, 0.45)))
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		detail_margin.add_theme_constant_override("margin_" + side, 20)
	detail_panel.add_child(detail_margin)

	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 10)
	detail_margin.add_child(detail)

	_preview_name = Label.new()
	_preview_name.text = "—"
	_preview_name.add_theme_font_override("font", _font_bold)
	_preview_name.add_theme_font_size_override("font_size", 26)
	_preview_name.add_theme_color_override("font_color", C_TEXT)
	detail.add_child(_preview_name)

	_preview_sub = Label.new()
	_preview_sub.text = ""
	_preview_sub.add_theme_font_override("font", _font)
	_preview_sub.add_theme_font_size_override("font_size", 12)
	_preview_sub.add_theme_color_override("font_color", C_MUTED)
	detail.add_child(_preview_sub)

	var detail_rule := ColorRect.new()
	detail_rule.color = Color(0.35, 0.9, 1.0, 0.25)
	detail_rule.custom_minimum_size = Vector2(0, 1)
	detail.add_child(detail_rule)

	_preview_desc = Label.new()
	_preview_desc.text = ""
	_preview_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_desc.custom_minimum_size = Vector2(0, 120)
	_preview_desc.add_theme_font_override("font", _font)
	_preview_desc.add_theme_font_size_override("font_size", 14)
	_preview_desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.88, 0.95))
	detail.add_child(_preview_desc)

	_preview_status = Label.new()
	_preview_status.text = ""
	_preview_status.add_theme_font_override("font", _font_bold)
	_preview_status.add_theme_font_size_override("font_size", 14)
	_preview_status.add_theme_color_override("font_color", C_GREEN)
	detail.add_child(_preview_status)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(spacer)

	_enter_button = Button.new()
	_enter_button.text = "进入地图"
	_enter_button.custom_minimum_size = Vector2(0, 54)
	_enter_button.focus_mode = Control.FOCUS_NONE
	_enter_button.add_theme_font_override("font", _font_bold)
	_enter_button.add_theme_font_size_override("font_size", 20)
	_enter_button.add_theme_color_override("font_color", C_TEXT)
	_enter_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	_enter_button.add_theme_stylebox_override("normal",
		_box(Color(0.03, 0.10, 0.16, 0.95), Color(0.35, 0.85, 1.0, 0.8)))
	_enter_button.add_theme_stylebox_override("hover",
		_box(Color(0.06, 0.18, 0.26, 1.0), Color(0.5, 1.0, 1.0, 1.0)))
	_enter_button.add_theme_stylebox_override("pressed",
		_box(Color(0.02, 0.08, 0.12, 1.0), Color(0.6, 1.0, 1.0, 1.0)))
	_enter_button.add_theme_stylebox_override("disabled",
		_box(Color(0.02, 0.04, 0.07, 0.9), Color(0.3, 0.4, 0.5, 0.5)))
	_enter_button.pressed.connect(_on_enter_pressed)
	detail.add_child(_enter_button)

	var hint := Label.new()
	hint.text = "点击左侧地图查看详情 · 选中后点「进入地图」 · ESC 关闭"
	hint.add_theme_font_override("font", _font)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.56, 0.66, 0.9))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root_box.add_child(hint)


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)

	var title := Label.new()
	title.text = "维度通道"
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", C_TEXT)
	titles.add_child(title)

	var sub := Label.new()
	sub.text = "WORLD SELECT // DIMENSION GATE 04"
	sub.add_theme_font_override("font", _font)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", C_MUTED)
	titles.add_child(sub)

	var close_btn := Button.new()
	close_btn.text = "关闭  ESC"
	close_btn.custom_minimum_size = Vector2(130, 40)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_override("font", _font_bold)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", C_TEXT)
	close_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	close_btn.add_theme_stylebox_override("normal", _box(Color(0.02, 0.05, 0.09, 0.85), Color(0.25, 0.7, 0.85, 0.55)))
	close_btn.add_theme_stylebox_override("hover", _box(Color(0.05, 0.16, 0.24, 0.9), Color(0.45, 0.97, 1.0, 0.95)))
	close_btn.add_theme_stylebox_override("pressed", _box(Color(0.02, 0.09, 0.14, 0.95), Color(0.6, 1.0, 1.0, 1.0)))
	close_btn.pressed.connect(close)
	header.add_child(close_btn)
	return header


func _box(bg: Color, border: Color) -> CyberBox:
	var b := CyberBox.new()
	b.bg_color = bg
	b.border_color = border
	b.border_width = 2.0
	b.corner = 10.0
	return b
