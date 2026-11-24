extends Node

## 维度地图数据:训练舱 + 4 张地图 + 最终地图(Boss 战)。
##
## 目前只有训练舱和地图 01 做出来了,02-04 与最终地图先占位;
## 最终地图的解锁规则已经写好:4 张地图全部探索完才开放。

signal changed

const ENTRY_TUTORIAL := "freshman"
const ENTRY_MAIN := "world_01"
const ENTRY_FINAL := "final"

const MAPS := [
	{
		"id": "freshman",
		"kind": "tutorial",
		"name": "教程",
		"sub": "TUTORIAL // 基础操作",
		"scene": "res://levels/freshman_world.tscn",
		"desc": "熟悉移动、跳跃、近战、闪避与技能。第一次进主城建议先来这里。",
	},
	{
		"id": "world_01",
		"kind": "world",
		"name": "边缘接入 · 外层节点",
		"sub": "LAYER 1 // EDGE ACCESS",
		"scene": "res://levels/world_edge.tscn",
		"desc": "被侵蚀成一片幽暗古森：巨树、藤蔓、腐木栈桥、树屋遗迹与毒沼。一路向右穿过森林，在尽头的传送门撤离。",
	},
	{
		"id": "world_02",
		"kind": "world",
		"name": "网关防护 · 防火墙",
		"sub": "LAYER 2 // GATEWAY",
		"scene": "",
		"desc": "流量与规则的关卡。防火墙的规则已被改写，正在放行不该放行的人。",
	},
	{
		"id": "world_03",
		"kind": "world",
		"name": "数据舱 · 存储层",
		"sub": "LAYER 3 // DATA VAULT",
		"scene": "",
		"desc": "核心数据的存放处。数据舱被占据，被感染的进程还在里面翻找。",
	},
	{
		"id": "world_04",
		"kind": "world",
		"name": "内核外围 · 指令层",
		"sub": "LAYER 4 // KERNEL RING",
		"scene": "",
		"desc": "离内核只差最后一层。指令在这里被篡改，守卫已经不听命令。",
	},
	{
		"id": "final",
		"kind": "final",
		"name": "内核核心 · 主控室",
		"sub": "CORE // 最终层",
		"scene": "",
		"desc": "四层全部打通后开启。入侵者的本体，就在主控室里。",
	},
]

## 已探索(通关)的地图 id
var cleared: Array[String] = []


func maps() -> Array:
	return MAPS


func entries() -> Array:
	return MAPS


func get_entry(id: String) -> Dictionary:
	for m in MAPS:
		if String(m["id"]) == id:
			return m
	return {}


func world_count() -> int:
	var n := 0
	for m in MAPS:
		if String(m["kind"]) == "world":
			n += 1
	return n


func is_built(id: String) -> bool:
	var m := get_entry(id)
	return not m.is_empty() and not String(m["scene"]).is_empty()


func is_cleared(id: String) -> bool:
	return cleared.has(id)


func mark_cleared(id: String) -> void:
	if cleared.has(id):
		return
	cleared.append(id)
	changed.emit()


func cleared_worlds() -> int:
	var n := 0
	for m in MAPS:
		if String(m["kind"]) == "world" and is_cleared(String(m["id"])):
			n += 1
	return n


## 能否进入:最终地图要先探索完所有世界;其余要已经做好。
func is_unlocked(id: String) -> bool:
	if id == ENTRY_FINAL:
		return cleared_worlds() >= world_count()
	return is_built(id)


func status_text(id: String) -> String:
	var m := get_entry(id)
	if m.is_empty():
		return "未知"
	if id == ENTRY_FINAL:
		if is_cleared(id):
			return "已完成"
		if is_unlocked(id):
			return "已解锁 · 可进入"
		return "需探索全部 %d 张地图（%d / %d）" % [world_count(), cleared_worlds(), world_count()]
	if not is_built(id):
		return "尚未开放"
	if is_cleared(id):
		return "已探索"
	return "可进入"


func reset() -> void:
	cleared.clear()
	changed.emit()
