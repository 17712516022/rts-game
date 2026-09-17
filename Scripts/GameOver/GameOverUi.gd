class_name GameOverUi extends Control

@onready var game_over_rich_text_label: RichTextLabel = %GameOverRichTextLabel

var squad_str : Dictionary = {
	TeamData.Team.PLAYER : "玩家",
	TeamData.Team.ENEMY : "敌人",
}

func _ready() -> void:
	hide()
	modulate = Color(1,1,1,0)
	EventBus.squad_lost.connect(_on_squad_lost)

func _update_game_over_rich_text_label(squad : TeamData.Team) -> void:
	game_over_rich_text_label.text = squad_str.get(squad,"未知势力") + "已经战败"
	
	show()
	var tween : Tween = create_tween()
	tween.tween_property(self , "modulate" ,Color(1,1,1,1) ,1.0)
	await tween.finished
	var new_tween : Tween = create_tween()
	new_tween.tween_property(self , "modulate" ,Color(1,1,1,0) ,1.0)
	await new_tween.finished
	hide()

func _on_squad_lost(squad : TeamData.Team) -> void:
	_update_game_over_rich_text_label(squad)
