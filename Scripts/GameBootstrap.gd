class_name GameBootstrap extends Node

@onready var camera_2d: Camera = %Camera2D

# 广播 game_ready 需要同时满足的两件事（都订阅的是 map_has_generated，
# 谁先跑取决于节点顺序，所以两边都判一次，别假设先后）
var _grids_ready : bool = false
var _rivers_ready : bool = false

func _ready() -> void:
	# 只等一次信号，游戏启动不会重复触发
	EventBus.map_has_generated.connect(_on_map_ready, CONNECT_ONE_SHOT)
	# 河道生成会把 terrain_grid 的格子改写成 RIVER，玩家和 AI 选点都必须等它刷完
	EventBus.rivers_generated.connect(_on_rivers_generated, CONNECT_ONE_SHOT)

func _on_map_ready() -> void:
	# 初始化所有和地图同尺寸的 
	ConstructionData.ensure_building_grid()
	ConstructionData.ensure_owner_grid()
	# 以后新增 ResourceDepositGrid ,UnitGrid ,FogGrid 
	_grids_ready = true
	_try_emit_game_ready()

func _on_rivers_generated() -> void:
	_rivers_ready = true
	_try_emit_game_ready()

# 网格初始化完 + 河道刷完，才广播"游戏准备好了"。
# 以前这里 map_has_generated 一到就发 game_ready，而河道可能还没生成完，
# 于是 AI 挑出生点看到的是"没画河"的地形，中心有可能落在之后的河道上。
func _try_emit_game_ready() -> void:
	if _grids_ready and _rivers_ready:
		EventBus.game_ready.emit()
