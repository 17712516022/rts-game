extends Node

# 开局先在固定格放行政中心
func build_first_center(construction_manager : ConstructionManager , start_cell : Vector2i ,squad : TeamData.Team) -> void:
	construction_manager.try_build(start_cell, ConstructionData.Constructions.CENTER, [], squad)

# 中心周围半径 3 的空格（可建区）
func find_empty_cells(centres : Array) -> Array:
	if centres.is_empty():
		return []
	var cells : Array = []
	for i in centres:
		cells.append_array(PositionCaculater.search_closest_cell(i, 3))
	return cells.filter(
		func(a : Vector2i) -> bool:
			return ConstructionData.building_grid[a.x][a.y] == null
	)

func refresh_centres(building_type : ConstructionResource, cell_pos : Vector2i , centres : Array, squad : TeamData.Team) -> void:
	if building_type != null and building_type.is_center_kind():
		var c : Construction = ConstructionData.building_grid[cell_pos.x][cell_pos.y]
		if c != null and c.get_squad_id() == squad:
			centres.append(cell_pos)

func on_center_changed(centres : Array ,squad : TeamData.Team) -> void:
	centres.clear()
	for c in ConstructionData.buildings_by_squad.get(squad, []):
		if c.is_center():
			centres.append(c.cell)
