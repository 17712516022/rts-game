class_name GameOver extends Node

@onready var center_ownership_manager: CenterOwnerManager = %CenterOwnershipManager

func _ready() -> void:
	EventBus.team_refresh_requested.connect(_on_team_refresh_requested)
	
func _on_team_refresh_requested() -> void:
	var teams : Array = TeamData.ALL_TEAMS
	for team in teams:
		if ConstructionData.buildings_by_squad.get(team,[]).is_empty():
			EventBus.squad_lost.emit(team)
	
