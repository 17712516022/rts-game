class_name HighLighter extends Polygon2D
## 点击高亮指示器：地图上被选中的格子会盖上一层半透明高亮。
## 监听 EventBus 的选中信号，收到后把六边形挪到对应格子并显示。
## 颜色、层级、初始隐藏都配在场景节点属性里。

func _ready() -> void:
	z_index = 0
	# 生成六边形形状（本地坐标，节点位置就是格子中心）
	polygon = _build_cell_polygon()
	# 订阅"选中格子"信号：每次点击，高亮跟着移动
	EventBus.select_one_cell.connect(_on_selected_one_cell)

# 按 hex_size 生成一个六边形的六个顶点
func _build_cell_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i)
		points.append(Vector2(cos(angle), sin(angle)) * MapData.hex_size)
	return points

# 信号回调：把高亮移到选中格子中心并显示
func _on_selected_one_cell(cell_pos: Vector2i) -> void:
	global_position = PositionCaculater.calculate_position(cell_pos.x, cell_pos.y)
	visible = true
