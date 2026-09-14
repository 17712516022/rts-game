class_name AIBuild extends BTLeaf

var building_type : ConstructionData.Constructions

func _init(type : ConstructionData.Constructions) -> void:
	building_type = type

func execute(ctx : Dictionary) -> int:
	var construction_manager := ctx.get("construction_manager") as ConstructionManager
	if construction_manager == null:
		return Status.FALIURE
	
	var squad : TeamData.Team = ctx.get("squad", TeamData.Team.ENEMY)
	var centres := ctx.get("centres", []) as Array
	
	var cells : Array = AiTools.find_empty_cells(centres)
	if cells.is_empty():
		return Status.FALIURE
	
	var cell : Vector2i = cells.pick_random()
	if construction_manager.try_build(cell, building_type, [], squad):
		return Status.SUCCESS
	return Status.FALIURE
