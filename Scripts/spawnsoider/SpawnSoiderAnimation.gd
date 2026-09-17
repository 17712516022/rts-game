class_name SpawnSoiderAnimation extends Node

@onready var spawn_soider_progress_bar: TextureProgressBar = %SpawnSoiderProgressBar

var max_time : float
var remaining_time : float

var bottom : SoiderBottom

func _ready() -> void:
	set_process(false)

func start(tops : Array,bottom_node : SoiderBottom ,) -> void:
	bottom = bottom_node
	var tops_time : float = 0.0
	for i in tops:
		var top : SoiderTopResource = i
		tops_time += top.spawn_time
	max_time = bottom.bott_res.spawn_time + tops_time
	
	remaining_time = max_time
	spawn_soider_progress_bar.show()
	set_process(true)

func _process(delta: float) -> void:
	remaining_time -= delta
	spawn_soider_progress_bar.value = float(1 - remaining_time / max_time) * 100
	if remaining_time <= 0.0 :
		spawn_soider_progress_bar.hide()
		set_process(false)
		# 广播（玩家/敌人的兵都会发，接收方按 squad 过滤自己阵营的）
		EventBus.soider_spawned.emit(bottom,bottom.get_squad_id())
	
