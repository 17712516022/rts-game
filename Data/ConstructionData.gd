extends Node
var building_grid: Array = []

var owner_grid: Array = []

## 建筑索引：阵营 -> 该阵营所有建筑实例（Array[Construction]）。
## 事件驱动增量维护：建造放置时 index_building 登记、死亡时 unindex_building 移除、
## 易手后 rebuild_index 重扫建筑列表（O(建筑数)，不扫地图）。
## 用途：AI 找己方中心/兵营/敌方建筑，全部 O(建筑数)，替代全图遍历。
var buildings_by_squad: Dictionary = {}

const CENTER_RES : = preload("res://Resource/house/Center.tres")
const LOWERCENTER_RES : = preload("res://Resource/house/LowerCenter.tres")
const RESIDENT_RES : = preload("res://Resource/house/Resident.tres")
const FARM_RES : = preload("res://Resource/house/farm.tres")
const MINE_RES : = preload("res://Resource/house/Mine.tres")
const ARMY_RES : = preload("res://Resource/house/Army.tres")
const TREE_RES = preload("uid://b6wckgmtg7lob")

enum Constructions {
	CENTER,LOWERCENTER,FARM,MINE,RESIDENT,ARMY,TREE
}

## 保证 owner_grid 已经和地图同尺寸初始化（未归属格=null）
func ensure_owner_grid() -> void:
	if not owner_grid.is_empty():
		return
	for row in range(MapData.map_height):
		var line_arr: Array = []
		for col in range(MapData.map_width):
			line_arr.append(null)
		owner_grid.append(line_arr)

func ensure_building_grid() -> void:
	if not building_grid.is_empty():
		return
	for row in range(MapData.map_height):
		var line_arr: Array = []
		for col in range(MapData.map_width):
			line_arr.append(null)
		building_grid.append(line_arr)

## 登记一栋建筑进它当前阵营的桶（建造放置、易手迁移时调用）
func index_building(c: Construction) -> void:
	var s: int = c.get_squad_id()
	if not buildings_by_squad.has(s):
		buildings_by_squad[s] = []
	var arr: Array = buildings_by_squad[s]
	if not arr.has(c):
		arr.append(c)

## 从它当前阵营的桶移除（死亡前调用；必须先于 set_team_id 改阵营）
func unindex_building(c: Construction) -> void:
	var s: int = c.get_squad_id()
	if buildings_by_squad.has(s):
		buildings_by_squad[s].erase(c)

## 按给定建筑数组重建索引（易手后阵营全变时用，O(建筑数)，不扫地图）
func rebuild_index(buildings: Array) -> void:
	buildings_by_squad.clear()
	for b in buildings:
		index_building(b)
