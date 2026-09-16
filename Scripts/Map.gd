class_name Map extends Node2D
## 地图交互脚本：接收鼠标左键点击，反算出点中了哪个格子。
## 坐标换算公式都在全局单例 PositionCaculater 里，这里只管点击逻辑。

const MIN_LENGTH : int = 3

var _dragging : bool 
var box_start_point : Vector2
var box_rect : Rect2

@onready var soider_container: Node2D = %SoiderContainer

func _finish_box() -> void:
	SoiderManager.set_box_rect(Rect2())#把框收起来
	var picked : Array = []
	for i in soider_container.get_children():
		var unit : SoiderBottom = i
		if not is_instance_valid(unit) or unit == null or unit.is_queued_for_deletion():
			continue
		if unit.get_squad_id() != TeamData.Team.PLAYER:
			continue
		if box_rect.has_point(unit.global_position):
			picked.append(unit)
	
	SoiderManager.set_selecting_soiders(picked)
	if not picked.is_empty():
		EventBus.select_the_soider.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			box_rect = Rect2()
			box_start_point = get_global_mouse_position()
			_dragging = true
		# 左键松开：结算
		elif _dragging:
			_dragging = false
			if box_start_point.distance_to(get_global_mouse_position()) < MIN_LENGTH:
				SoiderManager.set_box_rect(Rect2())
				return
			_finish_box()
	# 拖动中：只更新矩形并重画，不查兵
	if event is InputEventMouseMotion and _dragging:
		box_rect = Rect2(box_start_point, get_global_mouse_position() - box_start_point).abs()
		SoiderManager.set_box_rect(box_rect)   
		return
	
	# 只处理鼠标按键事件，其他输入直接忽略
	if not (event is InputEventMouseButton):
		return
	# 只处理左键，忽略右键、中键等
	if not (event.button_index == MOUSE_BUTTON_LEFT):
		return
	# 只在按下瞬间响应，松手不处理（否则一次点击会触发两次）
	if not event.pressed:
		return
	
	# get_global_mouse_position() 直接拿到地图世界坐标，相机缩放平移都自动算好了
	var mouse_pos : Vector2 = get_global_mouse_position()
	# 反算点中的格子，返回 x=行、y=列
	var cell_pos : Vector2 = PositionCaculater.calculate_cell(mouse_pos)
	# 存进全局数据仓库，以后建城、放单位、显示信息都能从这里读
	MapData.selected_cell = cell_pos
	EventBus.select_one_cell.emit(cell_pos)
