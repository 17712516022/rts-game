extends Node
## 预加载所有建筑 .tres 配置，供各处通过 ConstructionData.XXX_RES 引用。
## 按钮和资源的映射属于 UI 层视图绑定，放在 ConstructUI 里，不进数据单例。

## 建筑占用表：building_grid[行][列] = Construction 节点实例或 null，由 ConstructionManager 放置时写入
## （值实际是节点，旧注释写 "ConstructionResource" 是历史遗留，已纠正）
var building_grid: Array = []

## 行政中心归属表：owner_grid[行][列] = 行政中心 Construction 节点实例，无归属 = null
## 存节点而非坐标：中心易手换阵营时节点不变，势力格子自动跟随；高亮渲染能直接取中心阵营上色。
## 注意引用生命周期：中心被移除(死亡)必须先清空 owner_grid 里指向它的格子再释放节点，
## 见 CenterOwnershipManager.remove_center 与 Construction._die 的联动。
## 格式、尺寸和 building_grid / MapData.grid 完全对齐。由 CenterOwnershipManager 负责维护。
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
