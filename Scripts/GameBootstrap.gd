extends Node
## 游戏启动初始化链路（唯一入口）。
## 职责：只排顺序、调一次
## 启动顺序（整个项目就这一份，别在其他模块 _ready 里再做"初始化 grid"）：

func _ready() -> void:
	# 只等一次信号，游戏启动不会重复触发
	EventBus.map_has_generated.connect(_on_map_ready, CONNECT_ONE_SHOT)

func _on_map_ready() -> void:
	# 初始化所有和地图同尺寸的 
	ConstructionData.ensure_building_grid()
	ConstructionData.ensure_owner_grid()
	# 以后新增 ResourceDepositGrid ,UnitGrid ,FogGrid 
	# 广播"游戏准备好了"
	EventBus.game_ready.emit()
