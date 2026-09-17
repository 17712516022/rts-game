class_name CenterOwnerManager extends Node

const OWNER_RADIUS: int = 3   # 行政中心势力范围半径

## 已建的行政中心节点集合（Dictionary 当 HashSet 用，顺序无意义）
var centers: Dictionary = {}

@onready var _construction_container: Node2D = %ConstrutionContainer

func _ready() -> void:
	EventBus.construct_building.connect(_on_construct_build)
	EventBus.center_destroyed.connect(_on_center_destroyed)
	EventBus.team_refresh_requested.connect(refresh_all_teams)

func _on_construct_build(resource: ConstructionResource, cell_pos: Vector2i) -> void:
	if resource == null or not resource.is_center_kind():
		return
	# 事件只带 res+格子坐标；中心节点早就登记进 building_grid 了（建造放置时就写入，早于完工广播）
	var center: Construction = ConstructionData.building_grid[cell_pos.x][cell_pos.y] as Construction
	if center == null:
		return
	if centers.has(center):
		return
	centers[center] = true
	_fill_owner_for_new_center(center)

## 中心被移除(死亡)：Construction._die 在 queue_free 之前同步广播到这里，把势力格子清空重填，
## 保证 owner_grid 不残留指向已释放节点的 freed 引用。
func _on_center_destroyed(center: Construction) -> void:
	remove_center(center)

## 新中心建成：只对「半径 OWNER_RADIUS 范围内 + 原来 owner_grid 为空(null)」的格子
## 写进 owner_grid 的值 = 中心节点实例
func _fill_owner_for_new_center(new_center: Construction) -> void:
	ConstructionData.ensure_owner_grid()
	var center_cell: Vector2i = new_center.cell
	# 只扫新中心势力半径内的格子（约 37 格），不再全图遍历
	for cell in PositionCaculater.search_closest_cell(center_cell, OWNER_RADIUS):
		# 原来已经有归属 → 不动（先建优先，已经被老中心占了）
		if ConstructionData.owner_grid[cell.x][cell.y] != null:
			continue
		# 空着的：在所有中心里找最佳（最近赢；相同距离取遍历遇到的第一个）
		var best = _find_best_owner(cell)
		if best != null:
			ConstructionData.owner_grid[cell.x][cell.y] = best
	_sync_all_construction_owners()

## 拆中心：清掉这个中心的势力 → 用剩下的中心把空地重新「填空」（填最近的那个中心）
func remove_center(p_center: Construction) -> void:
	if p_center == null or not centers.has(p_center):
		return
	centers.erase(p_center)
	ConstructionData.ensure_owner_grid()
	# 被拆中心管辖的格子必然在它势力半径内，只扫这一小片，不再全图遍历
	var freed_cells: Array = []
	for cell in PositionCaculater.search_closest_cell(p_center.cell, OWNER_RADIUS):
		if ConstructionData.owner_grid[cell.x][cell.y] == p_center:
			ConstructionData.owner_grid[cell.x][cell.y] = null
			freed_cells.append(cell)
	# 把刚清出来的空格用剩下的中心重新填空（最近赢）
	for cell in freed_cells:
		var best = _find_best_owner(cell)
		if best != null:
			ConstructionData.owner_grid[cell.x][cell.y] = best
	_sync_all_construction_owners()

## 同步所有已实例化的 Construction 实例 owner_center（A+B 双写）
## owner_grid 值：中心 Construction 节点（有归属）或 null（无归属）。
## Construction.owner_center 也是同一套：中心节点 / null。类型一致，强判不用防御。
func _sync_all_construction_owners() -> void:
	if _construction_container == null:
		return
	var h: int = MapData.map_height
	var w: int = MapData.map_width
	for child in _construction_container.get_children():
		if child is Construction:
			var c: Construction = child
			if c.cell.x >= 0 and c.cell.y >= 0 and c.cell.x < h and c.cell.y < w:
				c.owner_center = ConstructionData.owner_grid[c.cell.x][c.cell.y]

## 全图阵营刷新（中心易手后广播触发）：每栋建筑的 squad 跟随它的归属中心。
## 规则 = 用户设计：建筑继承行政中心的阵营；中心换主 → 整片势力一起换旗。
## owner_grid 直接给中心节点，拿 center.get_squad_id() 就是唯一真相源，不用再坐标反查 building_grid。
func refresh_all_teams() -> void:
	if _construction_container == null:
		return
	var h: int = MapData.map_height
	var w: int = MapData.map_width
	var all_buildings: Array = []
	for child in _construction_container.get_children():
		if not (child is Construction):
			continue
		var c: Construction = child
		if c.cell.x < 0 or c.cell.y < 0 or c.cell.x >= h or c.cell.y >= w:
			continue
		all_buildings.append(c)
		var center = ConstructionData.owner_grid[c.cell.x][c.cell.y]
		if center == null or center == c:
			continue
		if center.get_squad_id() != c.get_squad_id():
			c.squad.set_team_id(center.get_squad_id())
	# 易手后阵营全变了：按容器里的建筑重扫一次索引（O(建筑数)），不扫地图
	ConstructionData.rebuild_index(all_buildings)

## 给单个格子找最佳归属行政中心：最近赢；相同距离取字典遍历遇到的第一个（都没先后意义）
## 返回中心 Construction 节点（找到）或 null（没中心在半径内）
func _find_best_owner(cell: Vector2i):
	var best_owner = null
	var best_dist: int = OWNER_RADIUS + 1
	for center in centers.keys():
		var c: Construction = center as Construction
		if not is_instance_valid(c):
			continue
		var d: int = _hex_distance(cell, c.cell)
		if d > OWNER_RADIUS:
			continue
		if d < best_dist:
			best_dist = d
			best_owner = c
	return best_owner

## odd-q (row, col) → cube (x, y, z) 距离
func _cube(cell: Vector2i) -> Vector3i:
	var col: int = cell.y
	var row: int = cell.x
	var x: int = col
	var z: int = row - (col - (col & 1)) / 2
	var y: int = -x - z
	return Vector3i(x, y, z)

func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var ac: Vector3i = _cube(a)
	var bc: Vector3i = _cube(b)
	return (abs(ac.x - bc.x) + abs(ac.y - bc.y) + abs(ac.z - bc.z)) / 2
