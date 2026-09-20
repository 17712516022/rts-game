extends Node

## 算作"水体"的地形：河流 + 浅海（近海）。
## 以后要把海洋、深海也算进水体，往这个数组里加一项即可，判定逻辑一处都不用改。
const WATER_TERRAINS : Array = [MapData.TERRAIN.RIVER, MapData.TERRAIN.CLOSESEE]

## 港口的 display_name。建筑类型一律按 display_name 比对，不要拿资源引用 == 模板常量：
## 建造时 ConstructionFactory 会 duplicate() 一份配置，副本引用永远比不中模板。
const PORT_NAME := "港口"

## 通航水道的移动速度系数：河流原本只有 0.1（见 ModifierData），港口通航后按正常速度走 → 1.0
const NAVIGABLE_MOVE_SPEED := 1.0

## center -> 是否已有港口 的缓存。
## has_port 每次调用都要重建一张全图 visited 表（search_closest_cell 按 map_height×map_width
## 分配），而 Mover 每帧每单位都要问一次移动速度，所以必须缓存。
## 下面四个事件任一发生都可能改变"谁有港口/谁归谁"，届时整体清空重算。
var _has_port_cache: Dictionary = {}

func _ready() -> void:
	EventBus.construct_building.connect(_clear_has_port_cache)
	EventBus.construction_destroyed.connect(_clear_has_port_cache)
	EventBus.center_destroyed.connect(_clear_has_port_cache)
	EventBus.team_refresh_requested.connect(_clear_has_port_cache)

## 各信号带的参数个数/类型都不一样，一律忽略
func _clear_has_port_cache(_a = null, _b = null) -> void:
	_has_port_cache.clear()

## 这个地形算不算水体
func is_water_terrain(terrain: int) -> bool:
	return WATER_TERRAINS.has(terrain)

## 这格本身是不是水体
func is_water(cell: Vector2i) -> bool:
	return is_water_terrain(MapData.terrain_grid[cell.x][cell.y])

## 这格的六个邻居里有没有水体（河流 / 浅海）
## 邻居由 PositionCaculater 给出，出界方向的邻居已经被它过滤掉了
func has_water_neighbor(cell: Vector2i) -> bool:
	for nb in PositionCaculater.get_neighbors(cell):
		if is_water(nb):
			return true
	return false

## 某个行政中心辖区里有没有港口
func has_port(center: Construction) -> bool:
	if center == null or not is_instance_valid(center):
		return false
	# 地图/归属表还没初始化（编辑器预览、开局早期）时直接返回 false
	if ConstructionData.owner_grid.is_empty() or ConstructionData.building_grid.is_empty():
		return false
	if _has_port_cache.has(center):
		return _has_port_cache[center]
	var found := _scan_port(center)
	_has_port_cache[center] = found
	return found

## 真扫一遍：只扫中心势力半径内的格子（约 37 格），不扫全图
func _scan_port(center: Construction) -> bool:
	for cell in PositionCaculater.search_closest_cell(center.cell, CenterOwnerManager.OWNER_RADIUS):
		# 不归这个中心的格子（含被别的中心抢走的）直接跳过
		if ConstructionData.owner_grid[cell.x][cell.y] != center:
			continue
		var building = ConstructionData.building_grid[cell.x][cell.y]
		if building is Construction and building.res != null \
				and building.res.display_name == PORT_NAME:
			return true
	return false

# ============ 通航水道（描边格）的速度查询 ============
## 这格的归属行政中心（owner_grid 存的就是中心节点实例；越界/表未建好返回 null）
func get_owner_center(cell: Vector2i):
	var grid: Array = ConstructionData.owner_grid
	if cell.x < 0 or cell.y < 0 or cell.x >= grid.size():
		return null
	var line_arr: Array = grid[cell.x]
	if cell.y >= line_arr.size():
		return null
	return line_arr[cell.y]

## 这格是不是"被描边的通航水道"：河流 + 归属中心已有建成港口。
## WaterVFX 的描边和移动加速共用这一个判定，改规则只改这里。
func is_navigable_river(cell: Vector2i) -> bool:
	if _terrain_at(cell) != MapData.TERRAIN.RIVER:
		return false
	return has_port(get_owner_center(cell))

## 这格的移动速度系数：通航水道 = 1.0（不减速），其余地形交给 FinalModifierCalculator
## （地形基值 × 政策/事件/建筑等登记的修正）。
## Mover（实际速度）和 PathFinder（通行代价）都走这里，保证"走得快"和"算得近"一致。
func get_move_speed_modifier(cell: Vector2i) -> float:
	var terrain: int = _terrain_at(cell)
	if not ModifierData.Modifiers.has(terrain):
		return 0.0   # 越界/未知地形 = 不可通行（不抛越界错）
	if is_navigable_river(cell):
		return NAVIGABLE_MOVE_SPEED
	return FinalModifierCalculator.move_speed(terrain)

## 安全取地形：越界返回 -1
func _terrain_at(cell: Vector2i) -> int:
	var grid: Array = MapData.terrain_grid
	if cell.x < 0 or cell.y < 0 or cell.x >= grid.size() or cell.y >= grid[cell.x].size():
		return -1
	return grid[cell.x][cell.y]
