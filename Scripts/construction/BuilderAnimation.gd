class_name BuilderAnimation extends Node
## 建造倒计时+渐显组件：给 Construction 实例挂的子组件。
## 一个时钟一个职责：
##   - _process 负责倒计时：每帧 remaining_time -= delta，到 0 emit build_finished
##   - Tween 只负责视觉：modulate 从透明渐变到不透明（和倒计时同时开始、同样时长）
##   - 进度条在 _process 里同步刷新（和 Tween 同一个 idle 时钟，不抖动）
## 不存 ConstructionResource 引用——Builder 只知道"让某节点渐显 N 秒"。

signal build_finished

## 是否在建造中
var is_building: bool = false
## 剩余秒数（0 = 已完工或还没 start）
var remaining_time: float = 0.0
## 总时长（画进度条：进度 = 1 - remaining_time / total_time）
var total_time: float = 0.0

var _tween: Tween

@onready var construction_progress_bar: TextureProgressBar = %ConstructionProgressBar

func _ready() -> void:
	set_process(false)
	construction_progress_bar.visible = false

## 启动建造动画。必须 start 时已经在节点树里（否则 create_tween 无效）。
## target：要渐显的贴图节点（一般就是父 Construction 的 %ConstructionTexture）
## build_seconds：建造时间 = 动画时长（ConstructionResource.time）
func start(target: CanvasItem, build_seconds: float) -> void:
	# 已经在建造中就停掉旧 Tween，避免两个动画叠
	if _tween and _tween.is_valid():
		_tween.kill()
	if build_seconds <= 0.0 :
		# 0 秒建造：立刻就位 + 发完成信号，不进倒计时
		is_building = false
		remaining_time = 0.0
		total_time = 0.0
		target.modulate = Color(1, 1, 1, 1)
		construction_progress_bar.visible = false
		build_finished.emit()
		return
	# 正常建造
	is_building = true
	total_time = build_seconds
	remaining_time = build_seconds
	target.modulate = Color(1, 1, 1, 0)
	# 进度条归零 + 显示
	construction_progress_bar.value = 0.0
	construction_progress_bar.visible = true
	# Tween 只管视觉渐显，不管倒计时（倒计时由 _process 负责）
	_tween = create_tween()
	_tween.tween_property(target, "modulate", Color(1, 1, 1, 1), build_seconds)
	# 开始每帧扣时间 + 刷进度条（和 Tween 同一个 idle 时钟）
	set_process(true)

func _process(delta: float) -> void :
	if not is_building:
		set_process(false)
		return
	remaining_time -= delta
	if remaining_time <= 0.0:
		_finish_build()
		return
	_update_progress_bar()

# 倒计时归零：收尾 + 发完成信号
func _finish_build() -> void :
	remaining_time = 0.0
	is_building = false
	set_process(false)
	construction_progress_bar.visible = false
	build_finished.emit()

# 进度条同步：进度 = 1 - remaining / total
func _update_progress_bar() -> void :
	if total_time <= 0.0:
		return
	construction_progress_bar.value = construction_progress_bar.max_value * (1.0 - remaining_time / total_time)
