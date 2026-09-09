class_name Map extends Node2D
## 地图交互脚本：接收鼠标左键点击，反算出点中了哪个格子。
## 坐标换算公式都在全局单例 PositionCaculater 里，这里只管点击逻辑。

func _unhandled_input(event: InputEvent) -> void:
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
