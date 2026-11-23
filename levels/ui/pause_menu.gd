extends CanvasLayer
## 暂停菜单:关卡里按 ESC 呼出,可选择 继续 / 重来 / 回到主城 / 退出。
## 打开时暂停整棵树,键盘(↑↓ + Enter)和鼠标都能操作。

signal closed

const UI_FONT := preload("res://levels/ui/ui_font.gd")
const MAIN_MENU := "res://main.tscn"
const SAFE_WORLD := "res://levels/safe_world.tscn"

var _opened := false
var _paused_by_us := false
var _buttons: Array[Button] = []
var _root: Control
var _font: Font
var _font_bold: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	visible = false
	_font = UI_FONT.make(false)
	_font_bold = UI_FONT.make(true)
	_build()


func is_open() -> bool:
	return _opened


func open() -> void:
	if _opened:
		return
	_opened = true
	visible = true
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_us = true
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func close() -> void:
	if not _opened:
		return
	_opened = false
	visible = false
	_release_pause()
	closed.emit()


func _release_pause() -> void:
	if _paused_by_us:
		_paused_by_us = false
		get_tree().paused = false


func _exit_tree() -> void:
	_release_pause()


# ---------------------------------------------------------------- 选项

func _on_resume() -> void:
	close()


func _on_restart() -> void:
	_release_pause()
	get_tree().reload_current_scene()


func _on_safe_world() -> void:
	_release_pause()
	get_tree().change_scene_to_file(SAFE_WORLD)


func _on_quit() -> void:
	_release_pause()
	get_tree().change_scene_to_file(MAIN_MENU)


# ---------------------------------------------------------------- 输入

func _input(event: InputEvent) -> void:
	if not _opened:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


# ---------------------------------------------------------------- 构建 UI

func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.02, 0.04, 0.08, 0.94), Color(0.35, 0.9, 1.0, 0.75)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "暂停"
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.75, 0.97, 1.0, 1.0))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "PAUSED // SYSTEM HOLD"
	sub.add_theme_font_override("font", _font)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.45, 0.66, 0.78, 0.95))
	vbox.add_child(sub)

	var rule := ColorRect.new()
	rule.color = Color(0.35, 0.9, 1.0, 0.45)
	rule.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(rule)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)

	_add_button(vbox, "继续游戏", _on_resume)
	_add_button(vbox, "重来", _on_restart)
	_add_button(vbox, "回到主城", _on_safe_world)
	_add_button(vbox, "退出", _on_quit)

	var hint := Label.new()
	hint.text = "↑ ↓ 选择    Enter 确认    ESC 继续游戏"
	hint.add_theme_font_override("font", _font)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.42, 0.6, 0.7, 0.85))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func _add_button(parent: Node, text: String, action: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 52)
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.78, 0.98, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 1, 1, 1))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	btn.add_theme_constant_override("outline_size", 4)
	btn.add_theme_stylebox_override("normal", _box(Color(0.02, 0.05, 0.09, 0.85), Color(0.25, 0.7, 0.85, 0.55)))
	btn.add_theme_stylebox_override("hover", _box(Color(0.05, 0.16, 0.24, 0.9), Color(0.45, 0.97, 1.0, 0.95)))
	btn.add_theme_stylebox_override("pressed", _box(Color(0.02, 0.09, 0.14, 0.95), Color(0.6, 1.0, 1.0, 1.0)))
	btn.add_theme_stylebox_override("focus", _box(Color(0.05, 0.16, 0.24, 0.9), Color(0.45, 0.97, 1.0, 0.95)))
	btn.pressed.connect(action)
	parent.add_child(btn)
	_buttons.append(btn)


func _box(bg: Color, border: Color) -> CyberBox:
	var b := CyberBox.new()
	b.bg_color = bg
	b.border_color = border
	b.border_width = 2.0
	b.corner = 10.0
	return b
