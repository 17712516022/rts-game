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
		# 追击建筑（而不是 set_target 到建筑坐标）：终点被敌方建筑占格，只靠 navigate 会得到空路径
		soider.mover.set_chase_target(true_target)
	
	return Status.SUCCESS
