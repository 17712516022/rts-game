class_name AIAttack extends BTLeaf

var target_team : TeamData.Team

func _init(p_target_team : TeamData.Team = TeamData.Team.PLAYER) -> void:
	target_team = p_target_team

func execute(ctx : Dictionary) -> int:
	# TODO(出兵/攻击)：把目标 team（target_team）换成真实指令。
	# ctx["my_army_count"] / ctx["others_army_count"] 已能判断要不要继续打。
	return Status.SUCCESS
