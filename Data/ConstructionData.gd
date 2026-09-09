extends Node
var building_grid: Array = []

var owner_grid: Array = []

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
