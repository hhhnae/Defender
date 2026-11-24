extends CanvasLayer

## 整备终端:左侧技能插槽(终极 1 / 技能 3 / 战斗风格 2),右侧已获得技能。
## 打开时暂停游戏;ESC 或右上角按钮关闭。

const UI_FONT := preload("res://levels/ui/ui_font.gd")

const C_CYAN := Color("#5fe4ff")
const C_CYAN_DIM := Color("#2d7f9e")
const C_VIOLET := Color("#9d6bff")
const C_AMBER := Color("#ffb648")
const C_TEXT := Color(0.78, 0.98, 1.0, 1.0)
const C_MUTED := Color(0.42, 0.6, 0.7, 0.9)

var _opened := false
var _paused_by_us := false
var _font: Font
var _font_bold: Font

var _root: Control
var _slots_box: VBoxContainer
var _owned_box: VBoxContainer
var _owned_title: Label
var _toast: Label
var _slot_buttons := {}      # "kind:index" -> Button
var _selected_kind := ""
var _selected_index := -1
var _toast_timer := 0.0
var _icon_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 55
	visible = false
	_font = UI_FONT.make(false)
	_font_bold = UI_FONT.make(true)
	_build()
	if Loadout != null:
		Loadout.changed.connect(_refresh)


func is_open() -> bool:
	return _opened


func open() -> void:
	if _opened:
		return
	_opened = true
	visible = true
	_selected_kind = ""
	_selected_index = -1
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_us = true
	_refresh()


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


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer = maxf(0.0, _toast_timer - delta)
		_toast.modulate.a = minf(1.0, _toast_timer * 2.0)


func _input(event: InputEvent) -> void:
	if not _opened:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


# ---------------------------------------------------------------- 交互

func _on_slot_pressed(kind: String, index: int) -> void:
	_selected_kind = kind
	_selected_index = index
	var item: Dictionary = Loadout.get_slot(kind, index)
	if not item.is_empty():
		Loadout.unequip(kind, index)
		_show_toast("已卸下：%s" % String(item.get("name", "?")))
	_refresh()


func _on_item_pressed(item: Dictionary) -> void:
	var kind := String(item.get("kind", ""))
	var prefer := _selected_index if _selected_kind == kind else -1
	var target := Loadout.equip(item, kind, prefer)
	if target < 0:
		_show_toast("没有空的%s插槽" % _kind_name(kind))
		return
	_selected_kind = kind
	_selected_index = target
	_show_toast("已装备：%s → %s" % [String(item.get("name", "?")), _slot_name(kind, target)])
	_refresh()


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_timer = 2.0


# ---------------------------------------------------------------- 刷新

func _refresh() -> void:
	if _slots_box == null or not _opened:
		return
	for child in _slots_box.get_children():
		_slots_box.remove_child(child)
		child.queue_free()
	_slot_buttons.clear()

	_slots_box.add_child(_section_label("技能插槽 / SLOTS"))
	var ultimate_item: Dictionary = Loadout.get_slot(Loadout.KIND_ULTIMATE, 0)
	_slots_box.add_child(_make_slot(Loadout.KIND_ULTIMATE, 0, "终极技能", ultimate_item, 92, C_VIOLET))
	for i in Loadout.SKILL_COUNT:
		var item: Dictionary = Loadout.get_slot(Loadout.KIND_SKILL, i)
		_slots_box.add_child(_make_slot(Loadout.KIND_SKILL, i, "技能槽 %d" % (i + 1), item, 64, C_CYAN))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	_slots_box.add_child(gap)
	_slots_box.add_child(_section_label("战斗风格 / STYLES"))
	for i in Loadout.STYLE_COUNT:
		var item: Dictionary = Loadout.get_slot(Loadout.KIND_STYLE, i)
		_slots_box.add_child(_make_slot(Loadout.KIND_STYLE, i, "风格槽 %d" % (i + 1), item, 64, C_AMBER))

	_refresh_owned()


func _refresh_owned() -> void:
	for child in _owned_box.get_children():
		_owned_box.remove_child(child)
		child.queue_free()
	var count := Loadout.owned.size()
	_owned_title.text = "已有物品  (%d)" % count
	if count == 0:
		var wrap := CenterContainer.new()
		wrap.custom_minimum_size = Vector2(0, 260)
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_owned_box.add_child(wrap)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		wrap.add_child(v)
		var empty := Label.new()
		empty.text = "尚未获得任何物品"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_override("font", _font_bold)
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", C_MUTED)
		v.add_child(empty)
		var tip := Label.new()
		tip.text = "通关关卡、击败 Boss 后可获得新技能"
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.add_theme_font_override("font", _font)
		tip.add_theme_font_size_override("font_size", 13)
		tip.add_theme_color_override("font_color", Color(0.32, 0.46, 0.56, 0.9))
		v.add_child(tip)
		return

	for item in Loadout.owned:
		_owned_box.add_child(_make_item_card(item))


# ---------------------------------------------------------------- 图标

## 先走导入资源;还没被编辑器导入时直接读 PNG。
func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _icon_cache.has(path):
		return _icon_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var img := Image.new()
		if img.load(path) == OK:
			tex = ImageTexture.create_from_image(img)
	_icon_cache[path] = tex
	return tex


func _icon_rect(item: Dictionary, size: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _load_icon(String(item.get("icon", "")))
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


# ---------------------------------------------------------------- 控件

func _make_slot(kind: String, index: int, slot_name: String, item: Dictionary,
		height: float, accent: Color) -> Control:
	var selected := _selected_kind == kind and _selected_index == index
	var filled := not item.is_empty()
	var border := accent
	var bg := Color(0.02, 0.05, 0.09, 0.9)
	if filled:
		bg = Color(0.04, 0.11, 0.17, 0.95)
	else:
		border = Color(accent.r, accent.g, accent.b, 0.4)
	if selected:
		border = Color(1.0, 0.82, 0.45, 1.0)
		bg = Color(0.07, 0.14, 0.2, 0.95)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(470, height)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _box(bg, border))
	btn.add_theme_stylebox_override("hover", _box(bg.lightened(0.06), border))
	btn.add_theme_stylebox_override("pressed", _box(bg, border))
	btn.add_theme_stylebox_override("focus", _box(bg, border))
	btn.pressed.connect(_on_slot_pressed.bind(kind, index))
	if filled:
		btn.tooltip_text = "%s\n%s" % [String(item.get("name", "")), String(item.get("desc", ""))]

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var tag := Label.new()
	tag.text = slot_name
	tag.custom_minimum_size = Vector2(92, 0)
	tag.add_theme_font_override("font", _font)
	tag.add_theme_font_size_override("font_size", 12)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85))
	row.add_child(tag)

	if filled and not String(item.get("icon", "")).is_empty():
		row.add_child(_icon_rect(item, 40.0))

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)

	var name_label := Label.new()
	name_label.text = String(item.get("name", "—— 空 ——")) if filled else "—— 空 ——"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font", _font_bold if filled else _font)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", C_TEXT if filled else Color(0.3, 0.42, 0.5, 0.9))
	texts.add_child(name_label)

	if filled:
		var desc := Label.new()
		desc.text = String(item.get("desc", ""))
		desc.add_theme_font_override("font", _font)
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", C_MUTED)
		desc.clip_text = true
		desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(desc)
	elif selected:
		var hint := Label.new()
		hint.text = "已选中,点击右侧技能装备"
		hint.add_theme_font_override("font", _font)
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45, 0.9))
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(hint)

	_slot_buttons["%s:%d" % [kind, index]] = btn
	return btn


func _make_item_card(item: Dictionary) -> Control:
	var equipped := Loadout.is_equipped(item)
	var border := C_CYAN if not equipped else Color(0.35, 0.5, 0.58, 0.55)
	var bg := Color(0.03, 0.07, 0.11, 0.92) if not equipped else Color(0.02, 0.04, 0.07, 0.85)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(430, 84)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _box(bg, border))
	btn.add_theme_stylebox_override("hover", _box(Color(0.05, 0.14, 0.2, 0.95), Color(0.45, 0.97, 1.0, 0.95)))
	btn.add_theme_stylebox_override("pressed", _box(bg, border))
	btn.add_theme_stylebox_override("focus", _box(bg, border))
	btn.pressed.connect(_on_item_pressed.bind(item))
	btn.tooltip_text = "%s\n%s" % [String(item.get("name", "")), String(item.get("desc", ""))]

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
	if not String(item.get("icon", "")).is_empty():
		row.add_child(_icon_rect(item, 36.0))

	row.add_child(texts)

	var name_label := Label.new()
	name_label.text = String(item.get("name", "?"))
	name_label.add_theme_font_override("font", _font_bold)
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", C_TEXT if not equipped else C_MUTED)
	texts.add_child(name_label)

	var desc := Label.new()
	desc.text = String(item.get("desc", ""))
	desc.add_theme_font_override("font", _font)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", C_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(desc)

	var tag := Label.new()
	tag.text = "已装备" if equipped else _kind_short(String(item.get("kind", "")))
	tag.custom_minimum_size = Vector2(58, 0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_theme_font_override("font", _font_bold)
	tag.add_theme_font_size_override("font_size", 12)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_color_override("font_color", C_AMBER if equipped else C_CYAN_DIM)
	row.add_child(tag)
	return btn


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _font_bold)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.5, 0.78, 0.9, 0.95))
	return label


# ---------------------------------------------------------------- 构建

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.68)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.02, 0.04, 0.08, 0.97), Color(0.35, 0.9, 1.0, 0.8)))
	panel.custom_minimum_size = Vector2(1100, 640)
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

	# 左:插槽
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(470, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	_slots_box = VBoxContainer.new()
	_slots_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slots_box.add_theme_constant_override("separation", 8)
	left.add_child(_slots_box)

	# 右:已有技能
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(470, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)

	_owned_title = _section_label("已有物品  (0)")
	right.add_child(_owned_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)

	_owned_box = VBoxContainer.new()
	_owned_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_owned_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_owned_box)


	# 底部提示
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	root_box.add_child(footer)

	_toast = Label.new()
	_toast.text = ""
	_toast.add_theme_font_override("font", _font_bold)
	_toast.add_theme_font_size_override("font_size", 13)
	_toast.add_theme_color_override("font_color", C_AMBER)
	_toast.modulate.a = 0.0
	_toast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_toast)

	var hint := Label.new()
	hint.text = "点击左侧插槽选中 → 点击右侧技能装备 · 点击已装备插槽卸下 · ESC 关闭"
	hint.add_theme_font_override("font", _font)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.56, 0.66, 0.9))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(hint)


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)

	var title := Label.new()
	title.text = "整备终端"
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", C_TEXT)
	titles.add_child(title)

	var sub := Label.new()
	sub.text = "LOADOUT TERMINAL // SAFE_NODE_07"
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


func _kind_name(kind: String) -> String:
	match kind:
		Loadout.KIND_ULTIMATE:
			return "终极技能"
		Loadout.KIND_SKILL:
			return "技能"
		Loadout.KIND_STYLE:
			return "战斗风格"
	return ""


func _kind_short(kind: String) -> String:
	match kind:
		Loadout.KIND_ULTIMATE:
			return "终极"
		Loadout.KIND_SKILL:
			return "技能"
		Loadout.KIND_STYLE:
			return "风格"
	return ""


func _slot_name(kind: String, index: int) -> String:
	match kind:
		Loadout.KIND_ULTIMATE:
			return "终极技能"
		Loadout.KIND_SKILL:
			return "技能槽 %d" % (index + 1)
		Loadout.KIND_STYLE:
			return "风格槽 %d" % (index + 1)
	return ""
