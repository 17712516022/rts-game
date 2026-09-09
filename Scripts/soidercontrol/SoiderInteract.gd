class_name SoiderInteract extends Node2D

@onready var hurtbox: Area2D = %hurtbox
var soider : SoiderBottom
@onready var mover: Mover = %Mover
@onready var path_finder: PathFinder = %PathFinder

func _ready() -> void:
	soider = get_parent() as SoiderBottom
	hurtbox.input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 只处理鼠标按键事件，其他输入直接忽略
	if not (event is InputEventMouseButton):
		return
	# 只处理左键，忽略右键、中键等
	if not (event.button_index == MOUSE_BUTTON_LEFT):
		return
	# 只在按下瞬间响应，松手不处理（否则一次点击会触发两次）
	if not event.pressed:
		return
	
	# 点中了士兵就把事件标记为已处理，
	# 这样 Map._unhandled_input 就不会再收到这次点击，避免同时点到地块
	get_viewport().set_input_as_handled()
	
	SoiderManager.add_to_selecting_soider(soider)
	EventBus.select_the_soider.emit()

func _unhandled_input(event: InputEvent) -> void:
	# 不在选中列表里的士兵不响应移动命令（选中状态以 SoiderManager 列表为唯一来源）
	if soider == null or not SoiderManager.soider_selecting.has(soider):
		return
	# 只处理鼠标按键事件，其他输入直接忽略
	if not (event is InputEventMouseButton):
		return
	# 右键下达移动命令
	if not (event.button_index == MOUSE_BUTTON_RIGHT):
		return
	# 只在按下瞬间响应，松手不处理（否则一次点击会触发两次）
	if not event.pressed:
		return
	
	# 故意不 set_input_as_handled：多只士兵被选中时要让每只都能收到这次右键
	_move_to_mouse()

func _move_to_mouse() -> void:
	if soider == null:
		return
	var target: Vector2 = get_global_mouse_position()
	# 寻路结果发给特效层去画线，这里不关心“怎么画”（无路时 points 为空，特效层会自己收起）
	var points: Array = path_finder.navigate(soider.global_position, target, soider.get_squad_id())
	EventBus.show_path_vfx.emit(soider, points)
	
	mover.set_target(target)
