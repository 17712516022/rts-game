class_name AIAttack extends BTLeaf

var target_team : TeamData.Team
var possible_targets : Array


func _init(p_target_team : TeamData.Team = TeamData.Team.PLAYER) -> void:
	target_team = p_target_team

func execute(ctx : Dictionary) -> int:
	possible_targets.clear()
	for build in ConstructionData.buildings_by_squad.get(target_team, []):
		possible_targets.append(build)
	
	if possible_targets.is_empty():
		return Status.FALIURE
	
	possible_targets.sort_custom(
		func(a : Construction, b : Construction) -> bool:
			return PositionCaculater.calculate_position(ctx["start_cell"].x ,ctx["start_cell"].y).distance_to(a.global_position) < PositionCaculater.calculate_position(ctx["start_cell"].x ,ctx["start_cell"].y).distance_to(b.global_position))
	var true_target : Construction = possible_targets.front()
	
	for i in ctx["armys"] :
		var soider : SoiderBottom = i
		soider.mover.set_target(true_target.global_position)
	
	return Status.SUCCESS
