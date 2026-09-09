class_name EnemyCommander extends Node

const SOIDERBOTTOM = preload("uid://cf1hhxii2pui0")

var squad : TeamData.Team

var _ctx := {}                     # 行为树黑板，每 tick 重填
var construction_manager : ConstructionManager


func _ready() -> void:
	EventBus.game_ready.connect(_on_game_ready)
	
func _on_game_ready() -> void:
	construction_manager = ConstructionManager.new()
