class_name SoiderInteract extends Node2D

@onready var hurtbox: Area2D = %hurtbox
var soider : SoiderBottom
@onready var mover: Mover = %Mover
@onready var path_finder: PathFinder = %PathFinder

func _ready() -> void:
	soider = get_parent() as SoiderBottom
	hurtbox.input_event.connect(_on_input_event)
	EventBus.soider_right_clicked.connect(_on_soider_right_clicked)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 只处理鼠标按键事件，其他输入直接忽略
	if not (event is InputEventMouseButton):
		return
	# 只处理左键，忽略右键、中键等
	if not (event.button_index == MOUSE_BUTTON_LEFT):
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				EventBus.soider_right_clicked.emit(soider)
		return
	# 只在按下瞬间响应，松手不处理（否则一次点击会触发两次）
	if not event.pressed:
		return
	
	# 点中了士兵就把事件标记为已处理，
	# 这样 Map._unhandled_input 就不会再收到这次点击，避免同时点到地块
	get_viewport().set_input_as_handled()
	
	if soider.get_squad_id() == TeamData.Team.PLAYER:
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
	
	var cell : Vector2i = PositionCaculater.calculate_cell(target)
	var building = ConstructionData.building_grid[cell.x][cell.y]
	if building != null and building.get_squad_id() != soider.get_squad_id():
		attack_entity(ConstructionData.building_grid[cell.x][cell.y])
		return
	
	
	mover.set_target(target)

func attack_entity(c_entity: Node2D) -> void:
	mover.set_chase_target(c_entity)

func _on_soider_right_clicked(c_entity : SoiderBottom) -> void:
	if c_entity == null or not is_instance_valid(c_entity):
		return
	if soider == null:
		return
	if c_entity.get_squad_id() == soider.get_squad_id():
		return
	# 只有被选中的兵才执行命令（和 _unhandled_input 的准入条件保持一致）
	if not SoiderManager.soider_selecting.has(soider):
		return
	attack_entity(c_entity)
	
	# 追人时不要留移动预览线：picking 排在 _unhandled_input 之后，这一帧 _move_to_mouse
	# 已经先发过一条指向鼠标点的 show_path_vfx，只能在这里紧接着收回。
	# 用无参 hide 清全部轨道是安全的：被点中敌人时，所有选中的兵都会走到这里改成追击，
	# 没有谁还需要保留移动预览线。
	EventBus.hide_path_vfx.emit()
