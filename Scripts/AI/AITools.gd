extends Node

const BUILD_CENTRES_RANGE : int = 6
const BUILD_CONSTRUCTION_RANGE : int = 3

func build_first_center(construction_manager : ConstructionManager , start_cell : Vector2i ,squad : TeamData.Team) -> void:
	var cell : Vector2i = start_cell
	# 传进来的格子不可建就自己重抽一个，别拿着它硬建
	if not can_build_on(cell):
		cell = find_start_cell()
		
	construction_manager.try_build(cell, ConstructionData.Constructions.CENTER, [], squad)
	
# 中心周围半径 3 的空格（可建区）
func find_empty_cells(centres : Array) -> Array:
	if centres.is_empty():
		return []
	var cells : Array = []
	var seen : Dictionary = {}
	for i in centres:
		for cell in PositionCaculater.search_closest_cell(i, BUILD_CONSTRUCTION_RANGE):
			if seen.has(cell):
				continue
			seen[cell] = true
			cells.append(cell)
	return cells.filter(
		func(a : Vector2i) -> bool:
			return ConstructionData.building_grid[a.x][a.y] == null
	)

func find_center_usable_cells(centres : Array) -> Array:
	if centres.is_empty():
		return []
	
	# 每个中心周围半径 3 的已建区，新中心的中心格不能落在这里。
	# 原来这句写在 filter 闭包里，每个候选格都重算一遍整表（O(n²)），提到外面只算一次。
	var blocked : Dictionary = {}
	for cell in find_empty_cells(centres):
		blocked[cell] = true
	
	var cells : Array = []
	var seen : Dictionary = {}
	for i in centres :
		for cell in PositionCaculater.search_closest_cell(i, BUILD_CENTRES_RANGE):
			# 多个中心的半径会重叠，去重，别让同一个格子出现好几次
			if seen.has(cell) or blocked.has(cell):
				continue
			seen[cell] = true
			cells.append(cell)
	
	return cells.filter(
		func(a : Vector2i) -> bool:
			return ConstructionData.building_grid[a.x][a.y] == null and ConstructionData.owner_grid[a.x][a.y] == null
	)

func refresh_centres(building_type : ConstructionResource, cell_pos : Vector2i , centres : Array, squad : TeamData.Team) -> void:
	if building_type != null and building_type.is_center_kind():
		var c : Construction = ConstructionData.building_grid[cell_pos.x][cell_pos.y]
		if c != null and c.get_squad_id() == squad and not centres.has(cell_pos):
			centres.append(cell_pos)

func on_center_changed(centres : Array ,squad : TeamData.Team) -> void:
	centres.clear()
	for c in ConstructionData.buildings_by_squad.get(squad, []):
		if c.is_center():
			centres.append(c.cell)

func can_build_on(cell : Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= MapData.map_height or cell.y >= MapData.map_width:
		return false
	var terrain : MapData.TERRAIN = MapData.terrain_grid[cell.x][cell.y]
	return ModifierData.Modifiers[terrain]["ConstructModifier"] > 0.0

func find_start_cell() -> Vector2i:
	var cell := Vector2i(randi_range(0, MapData.map_height - 1), randi_range(0, MapData.map_width - 1))
	if can_build_on(cell):
		return cell
	return find_start_cell()
