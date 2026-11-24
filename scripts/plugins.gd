extends Node

## 插件仓库:记录主角获得的插件(时域强化等)。
## 目前只做持有与查询,后续可以在这里挂具体效果。

signal changed

const TIME_BOOST := "plugin_time_boost"

const PLUGIN_DATA := {
	"plugin_time_boost": {
		"name": "时域强化",
		"sub": "TIME DOMAIN BOOST",
		"desc": "空格触发:60 秒内攻速 ×3、闪避无冷却,并且移动方式改为连续闪避。冷却 25 秒。",
		"icon": "res://levels/ui/icons/icon_time_boost.png",
	},
}

var owned: Array[String] = []


func has(id: String) -> bool:
	return owned.has(id)


func grant(id: String) -> bool:
	if owned.has(id):
		return false
	owned.append(id)
	changed.emit()
	return true


## 转成整备终端的物品结构(终极技能槽)。
func to_item(id: String) -> Dictionary:
	var data := get_data(id)
	if data.is_empty():
		return {}
	return {
		"id": id,
		"name": String(data.get("name", id)),
		"kind": "ultimate",
		"tag": "终极",
		"desc": String(data.get("desc", "")),
		"icon": String(data.get("icon", "")),
	}


## 是否正装在终极槽里(卸下后效果就没了)。
func is_equipped(id: String) -> bool:
	var lo := get_node_or_null("/root/Loadout")
	return lo != null and bool(lo.call("has_ultimate", id))


func get_data(id: String) -> Dictionary:
	return PLUGIN_DATA.get(id, {})


func all_owned() -> Array[String]:
	return owned


func reset() -> void:
	owned.clear()
	changed.emit()
