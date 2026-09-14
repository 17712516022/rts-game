class_name PathFinder extends Node

## 海洋是否可通行（默认不可：还没有海军/运输船）
@export var allow_ocean: bool = false
## 有建筑的格子是否可通行（默认不可：建筑挡路）
@export var allow_buildings: bool = false

## squad_id：谁在寻路。>=0 时同 squad 的建筑对它不挡路；-1（默认）保持旧行为——建筑一律不挡路
## 世界坐标寻路：中间点取各格中心，末点精确落在 to_world（不吸附格中心），
## 不含起点格中心（移动方从当前位置直接开走，不闪回/抖动）。
## 同格返回 [to_world]；目标不可走（海洋/建筑）或无路返回空数组。
func navigate(from_world: Vector2, to_world: Vector2, squad_id: int = -1) -> Array:
	var start_cell: Vector2i = PositionCaculater.calculate_cell(from_world)
	var end_cell: Vector2i = PositionCaculater.calculate_cell(to_world)
	if start_cell == end_cell:
		return [to_world]
	var path : Array = find_path(start_cell, end_cell, squad_id)
	if path.size() < 2:
		return []
	var points: Array = []
	for i in range(1, path.size() - 1):
		var c: Vector2i = path[i]
		points.append(PositionCaculater.calculate_position(c.x, c.y))
	points.append(to_world)
	return points

## 找路径：返回从 start 到 end 的格子数组（含首尾），找不到返回空数组
func find_path(start: Vector2i, end: Vector2i, squad_id: int = -1) -> Array:
	# 地图没生成 / 起点或终点本身走不了
	if MapData.terrain_grid.is_empty() or not _passable(start, squad_id) or not _passable(end, squad_id):
		return []
	if start == end:
		return [start]
	
	var open: Array = []            # 待探索格（存 Vector2i）
	var closed: Dictionary = {}     # 已处理格
	var g_score: Dictionary = {}    # 起点到该格的实际代价
	var f_score: Dictionary = {}    # g + h，越小越优先
	var came_from: Dictionary = {}  # 每格从哪来，用于回溯
	g_score[start] = 0.0
	f_score[start] = float(_hex_distance(start, end))
	open.append(start)
	
	while not open.is_empty():
		# 挑 f 最小的格展开（线性扫描，256×256 地图够用）
		var best_idx := 0
		for i in range(1, open.size()):
			if f_score[open[i]] < f_score[open[best_idx]]:
				best_idx = i
		var current: Vector2i = open[best_idx]
		if current == end:
			return _reconstruct_path(came_from, current)
	
		open.remove_at(best_idx)
		closed[current] = true
		for nb in PositionCaculater.get_neighbors(current):
			# 只收容没走过、且更便宜的走法
			if closed.has(nb) or not _passable(nb, squad_id):
				continue
			var tentative_g: float = g_score[current] + _cell_cost(nb)
			var is_new: bool = not g_score.has(nb)
			if is_new or tentative_g < g_score[nb]:
				came_from[nb] = current
				g_score[nb] = tentative_g
				f_score[nb] = tentative_g + float(_hex_distance(nb, end))
				if is_new:
					open.append(nb)
	
	return []  # 开放表耗尽仍无路

## 单格通行代价：1.0 / 移动速度系数（速度 0 = 不可通行）
func _cell_cost(cell: Vector2i) -> float:
	var ms: float = ModifierData.Modifiers[MapData.terrain_grid[cell.x][cell.y]]["MoveSpeedModifier"]
	if ms <= 0.0:
		return INF
	return 1.0 / ms

## 这格能不能走：代价有限，且（按开关）不是海洋、没有会挡路的建筑
func _passable(cell: Vector2i, squad_id: int) -> bool:
	if _cell_cost(cell) == INF:
		return false
	if not allow_ocean and _is_ocean(cell):
		return false
	if not allow_buildings and _building_blocks(cell, squad_id):
		return false
	return true

# 5 种海洋地形
func _is_ocean(cell: Vector2i) -> bool:
	var t: MapData.TERRAIN = MapData.terrain_grid[cell.x][cell.y]
	return t in [MapData.TERRAIN.DEEPSEE,
			MapData.TERRAIN.NORMALSEE,
			MapData.TERRAIN.CLOSESEE]

## 格上的建筑节点（grid 未初始化/越界返回 null）
func _building_at(cell: Vector2i):
	if ConstructionData.building_grid.is_empty():
		return null
	if ConstructionData.building_grid.size() <= cell.x \
			or ConstructionData.building_grid[cell.x].size() <= cell.y:
		return null
	return ConstructionData.building_grid[cell.x][cell.y]

## 这个格子的建筑会不会挡 squad_id 的部队：
## 无建筑 → 不挡；建筑 squad 和部队相同 → 自己人，不挡；不同/未知 → 挡
func _building_blocks(cell: Vector2i, squad_id: int) -> bool:
	var building = _building_at(cell)
	if building == null:
		return false
	# 无阵营部队（-1）走老逻辑：建筑一律不挡路（返回 false = 不挡）
	if squad_id < 0:
		return false
	return building.get_squad_id() != squad_id

## odd-q 平顶坐标转 cube 后求最短距离（作为 h 永不高估，保证 A* 最优解）
func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var ax: int = a.y
	var az: int = a.x - (a.y - (a.y & 1)) / 2
	var ay: int = -ax - az
	var bx: int = b.y
	var bz: int = b.x - (b.y - (b.y & 1)) / 2
	var by: int = -bx - bz
	return (absi(ax - bx) + absi(ay - by) + absi(az - bz)) / 2

## 从终点沿 came_from 退回起点并反转
func _reconstruct_path(came_from: Dictionary, end: Vector2i) -> Array:
	var path: Array = [end]
	var current: Vector2i = end
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path
