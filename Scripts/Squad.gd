class_name Squad extends Node
## 外部不要直接改 squad 字段，统一走 set_team_id。

var squad : int = TeamData.Team.PLAYER

func get_squad() -> int:
	return squad

## 阵营写入统一入口：由建造方/中心刷新逻辑调用
func set_team_id(team: int) -> void:
	squad = team
