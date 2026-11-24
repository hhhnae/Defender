extends Node

## 技能/终极技能的通用运行时:谁都能注册定义,显示层只读这里的数据。
## 与具体技能解耦:这里只管「图标 / 冷却 / 持续时间 / 何时可再次触发」,
## 真正的效果由技能自己监听 activated 信号去做。

signal changed
signal activated(id: String, seconds: float)

const KIND_ULTIMATE := "ultimate"
const KIND_SKILL := "skill"

## 技能定义表:要加新技能,在这里加一条即可(图标 + 计时),显示与冷却自动生效。
const DEFS := {
	"plugin_time_boost": {
		"name": "时域强化",
		"kind": KIND_ULTIMATE,
		"icon": "res://levels/ui/icons/icon_time_boost.png",
		"duration": 60.0,
		"cooldown": 25.0,
		"hint": "空格",
	},
	"skill_feign": {
		"name": "假死",
		"kind": KIND_SKILL,
		"icon": "res://levels/ui/icons/skill_feign.png",
		"duration": 0.0,
		"cooldown": 10.0,
		"hint": "Q",
	},
}

## 每项:{kind, index, id, name, icon, hint, cd, cd_total, active, active_total, ready}
var entries: Array[Dictionary] = []

var _tick := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lo := get_node_or_null("/root/Loadout")
	if lo != null and not lo.is_connected("changed", refresh):
		lo.changed.connect(refresh)
	refresh()


func get_def(id: String) -> Dictionary:
	return DEFS.get(id, {})


## 根据整备槽重新生成条目(保留已有冷却进度)。
func refresh() -> void:
	var old := {}
	for e in entries:
		old[String(e["id"])] = e

	entries.clear()
	var lo := get_node_or_null("/root/Loadout")
	if lo == null:
		changed.emit()
		return
	_push(KIND_ULTIMATE, 0, lo.call("get_slot", KIND_ULTIMATE, 0), old)
	for i in 3:
		_push(KIND_SKILL, i, lo.call("get_slot", KIND_SKILL, i), old)
	changed.emit()


func _push(kind: String, index: int, item: Dictionary, old: Dictionary) -> void:
	if item.is_empty():
		return
	var id := String(item.get("id", ""))
	if id.is_empty():
		return
	var def := get_def(id)
	var prev: Dictionary = old.get(id, {})
	var cd_total := float(def.get("cooldown", 0.0))
	entries.append({
		"kind": kind,
		"index": index,
		"id": id,
		"name": String(def.get("name", item.get("name", id))),
		"icon": String(def.get("icon", item.get("icon", ""))),
		"hint": String(def.get("hint", "")),
		"duration": float(def.get("duration", 0.0)),
		"cd_total": cd_total,
		"cd": float(prev.get("cd", 0.0)),
		"active": float(prev.get("active", 0.0)),
		"active_total": float(prev.get("active_total", 0.0)),
	})


func find(kind: String, index: int) -> Dictionary:
	for e in entries:
		if String(e["kind"]) == kind and int(e["index"]) == index:
			return e
	return {}


func find_by_id(id: String) -> Dictionary:
	for e in entries:
		if String(e["id"]) == id:
			return e
	return {}


## 尝试触发某个槽。冷却中/已激活时返回 false。
func trigger(kind: String, index: int) -> bool:
	var e := find(kind, index)
	if e.is_empty():
		return false
	if float(e["cd"]) > 0.0 or float(e["active"]) > 0.0:
		return false
	var duration := float(e["duration"])
	e["active"] = duration
	e["active_total"] = duration
	if duration <= 0.0:
		e["cd"] = float(e["cd_total"])
	activated.emit(String(e["id"]), duration)
	changed.emit()
	return true


## 让不走触发流程的技能(例如玩家脚本自己处理冷却的)也能把冷却显示到技能条。
func set_cooldown(id: String, seconds: float) -> void:
	var e := find_by_id(id)
	if e.is_empty():
		return
	e["cd"] = maxf(float(e["cd"]), seconds)
	changed.emit()


## 某个技能当前是否处于持续效果中。
func is_active(id: String) -> bool:
	var e := find_by_id(id)
	return not e.is_empty() and float(e["active"]) > 0.0


func remaining_cd(id: String) -> float:
	var e := find_by_id(id)
	return 0.0 if e.is_empty() else float(e["cd"])


func _process(delta: float) -> void:
	var dirty := false
	for e in entries:
		if float(e["active"]) > 0.0:
			e["active"] = maxf(0.0, float(e["active"]) - delta)
			if float(e["active"]) <= 0.0:
				e["cd"] = float(e["cd_total"])
				dirty = true
		elif float(e["cd"]) > 0.0:
			e["cd"] = maxf(0.0, float(e["cd"]) - delta)
			dirty = true
	_tick += delta
	if dirty and _tick >= 0.1:
		_tick = 0.0
		changed.emit()
