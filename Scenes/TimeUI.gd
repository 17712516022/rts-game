class_name TimeUi extends Control

@onready var time_progress_bar: ProgressBar = %TimeProgressBar

func _ready() -> void:
	time_progress_bar.value = 0

func _process(_delta: float) -> void:
	time_progress_bar.value = TimeManager.month_timer / TimeManager.MONTH_TIME * 100.0
