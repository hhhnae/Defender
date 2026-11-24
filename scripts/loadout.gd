extends Node

## 整备数据:技能插槽(终极 1 / 技能 3 / 战斗风格 2)与已获得的技能。
##
## 初始状态:身上只有自带的「标准近战」战斗风格(平A),其余全空,已有技能为空。
## 其它系统(玩家、HUD)之后可从 here 读取装备结果。

signal changed

const KIND_ULTIMATE := "ultimate"
const KIND_SKILL := "skill"
const KIND_STYLE := "style"

const ULTIMATE_COUNT := 1
const SKILL_COUNT := 3
const STYLE_COUNT := 2

## 主角自带的平A战斗风格:开局装在第一个风格槽,也可以卸下再换回来。
const DEFAULT_STYLE := {
	"id": "style_basic_melee",
	"name": "标准近战",
	"kind": "style",
	"tag": "平A",
	"desc": "J 轻斩(两段变化),K 重斩,L 突进斩。不消耗资源,是最稳的输出手段。",
	"icon": "res://levels/ui/icons/style_basic_melee.png",
}

## 初始技能:假死(Q),开在第一个技能槽。
## 技能描述统一格式:功能 + 冷却时间。
const DEFAULT_SKILL := {
	"id": "skill_feign",
	"name": "假死",
	"kind": "skill",
	"tag": "Q",
	"desc": "Q 触发:原地倒地装死,期间免疫伤害,按任意攻击键起身。持续到下次攻击,冷却 10 秒。",
	"icon": "res://levels/ui/icons/skill_feign.png",
}

var ultimate: Array[Dictionary] = [{}]
var skills: Array[Dictionary] = [{}, {}, {}]
var styles: Array[Dictionary] = [{}, {}]

## 已获得的技能(未装备的也会留在这里,右侧列表展示)
var owned: Array[Dictionary] = []


func _ready() -> void:
	ultimate.resize(ULTIMATE_COUNT)
	skills.resize(SKILL_COUNT)
	styles.resize(STYLE_COUNT)
	_seed_default_style()


## 自带战斗风格既占第一个风格槽,也放进「已有技能」,卸下后还能装回来。
func _seed_default_style() -> void:
	var has_owned := false
	for it in owned:
		if String((it as Dictionary).get("id", "")) == String(DEFAULT_STYLE["id"]):
			has_owned = true
			break
	if not has_owned:
		owned.push_front(DEFAULT_STYLE.duplicate(true))
	var has_slot := false
	for cur in styles:
		var d: Dictionary = cur
		if not d.is_empty() and String(d.get("id", "")) == String(DEFAULT_STYLE["id"]):
			has_slot = true
			break
	if not has_slot:
		styles[0] = DEFAULT_STYLE.duplicate(true)
	# 假死技能同样:已拥有 + 默认装在第一个技能槽
	var has_skill := false
	for it in owned:
		if String((it as Dictionary).get("id", "")) == String(DEFAULT_SKILL["id"]):
			has_skill = true
			break
	if not has_skill:
		owned.push_back(DEFAULT_SKILL.duplicate(true))
	var skill_slotted := false
	for cur in skills:
		var d2: Dictionary = cur
		if not d2.is_empty() and String(d2.get("id", "")) == String(DEFAULT_SKILL["id"]):
			skill_slotted = true
			break
	if not skill_slotted:
		skills[0] = DEFAULT_SKILL.duplicate(true)


func slot_count(kind: String) -> int:
	match kind:
		KIND_ULTIMATE:
			return ULTIMATE_COUNT
		KIND_SKILL:
			return SKILL_COUNT
		KIND_STYLE:
			return STYLE_COUNT
	return 0


func slot_array(kind: String) -> Array:
	match kind:
		KIND_ULTIMATE:
			return ultimate
		KIND_SKILL:
			return skills
		KIND_STYLE:
			return styles
	return []


func get_slot(kind: String, index: int) -> Dictionary:
	var arr := slot_array(kind)
	if index < 0 or index >= arr.size():
		return {}
	return arr[index]


func set_slot(kind: String, index: int, item: Dictionary) -> void:
	var arr := slot_array(kind)
	if index < 0 or index >= arr.size():
		return
	arr[index] = item.duplicate(true) if not item.is_empty() else {}
	changed.emit()


## 找一个空槽;满则返回 -1。
func first_empty(kind: String) -> int:
	var arr := slot_array(kind)
	for i in arr.size():
		if (arr[i] as Dictionary).is_empty():
			return i
	return -1


## 装备某个已拥有技能:优先指定槽,其次第一个空槽。成功返回槽位下标。
func equip(item: Dictionary, kind: String, prefer_index := -1) -> int:
	if item.is_empty():
		return -1
	var target := prefer_index
	if target < 0 or target >= slot_count(kind) or not get_slot(kind, target).is_empty():
		target = first_empty(kind)
	if target < 0:
		return -1
	# 同一个技能不允许同时占两个槽
	_remove_from_slots(item)
	set_slot(kind, target, item)
	changed.emit()
	return target


func unequip(kind: String, index: int) -> void:
	if get_slot(kind, index).is_empty():
		return
	set_slot(kind, index, {})


func _remove_from_slots(item: Dictionary) -> void:
	var item_id := String(item.get("id", ""))
	for kind in [KIND_ULTIMATE, KIND_SKILL, KIND_STYLE]:
		var arr := slot_array(kind)
		for i in arr.size():
			var cur: Dictionary = arr[i]
			if not cur.is_empty() and String(cur.get("id", "")) == item_id:
				arr[i] = {}
				return


## 指定 id 的技能是否正装在某个技能槽里。
func has_skill(id: String) -> bool:
	for cur in skills:
		var d: Dictionary = cur
		if not d.is_empty() and String(d.get("id", "")) == id:
			return true
	return false


## 指定 id 的终极技能/插件是否装在终极槽里。
func has_ultimate(id: String) -> bool:
	for cur in ultimate:
		var d: Dictionary = cur
		if not d.is_empty() and String(d.get("id", "")) == id:
			return true
	return false


## 指定 id 的战斗风格是否正装在某个风格槽里。
func has_style(id: String) -> bool:
	for cur in styles:
		var d: Dictionary = cur
		if not d.is_empty() and String(d.get("id", "")) == id:
			return true
	return false


func is_equipped(item: Dictionary) -> bool:
	var item_id := String(item.get("id", ""))
	for kind in [KIND_ULTIMATE, KIND_SKILL, KIND_STYLE]:
		for cur in slot_array(kind):
			var d: Dictionary = cur
			if not d.is_empty() and String(d.get("id", "")) == item_id:
				return true
	return false


func grant(item: Dictionary) -> void:
	if item.is_empty():
		return
	for cur in owned:
		if String((cur as Dictionary).get("id", "")) == String(item.get("id", "")):
			return
	owned.append(item.duplicate(true))
	changed.emit()


## 调试/测试用:清空已获得技能与所有非自带槽位。
func reset() -> void:
	owned.clear()
	skills = [{}, {}, {}]
	styles = [{}, {}]
	ultimate = [{}]
	_seed_default_style()
	changed.emit()
