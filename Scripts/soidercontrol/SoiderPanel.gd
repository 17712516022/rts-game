class_name SoiderPanel extends Control

@onready var discord_soider_button: Button = %DiscordSoiderButton

func _ready() -> void:
	hide()
	EventBus.select_the_soider.connect(_on_select_the_soider)
	discord_soider_button.pressed.connect(_on_discord_soider_button_pressed)
	
func _on_select_the_soider() -> void:
	show()

func _on_discord_soider_button_pressed() -> void:
	for i in SoiderManager.get_current_soiders():
		SoiderManager.delete_from_selecting_soider(i)
