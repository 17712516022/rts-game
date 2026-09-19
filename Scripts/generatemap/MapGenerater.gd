class_name MapGenerater extends Node
## 地图网格生成器：等海拔、气候、河流都生成完，把 MapData.grid 和
## river_grid 拼成一个六边形大网格，画到场景里的 MapMesh 上。
## 挂在 MapMesh 节点上运行，自己通过 %MapMesh 引用自己。

func _ready() -> void:
	# 地形生成完画一版（含气候变体，此时还没有河道）
	EventBus.map_has_generated.connect(_on_map_has_generated)
	# 河流生成完再重建一次，把河道颜色画上去
	EventBus.rivers_generated.connect(_on_rivers_generated)

func _on_map_has_generated() -> void:
	_build_mesh()

# 河流生成完毕，重建一次网格，把河道颜色画上去
func _on_rivers_generated() -> void:
	_build_mesh()

# 算出一个六边形的六个顶点
func hex_corners(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i)
		points.append(center + Vector2(cos(angle), sin(angle)) * MapData.hex_size)
	return points

# ============ 把整张地图合并成一个网格 ============
func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for row in range(MapData.map_height):
		for col in range(MapData.map_width):
			var center : Vector2 = PositionCaculater.calculate_position(row, col)
			var points : Array = hex_corners(center)
			# 先按地形拿颜色
			var color : Color = MapData.TERRAIN_COLORS[MapData.terrain_grid[row][col]]
			
			# 一个六边形拆成 6 个三角形：中心连相邻两个顶点
			for i in range(6):
				var next : int = (i + 1) % 6
				st.set_color(color)
				st.add_vertex(Vector3(center.x, center.y, 0))
				st.set_color(color)
				st.add_vertex(Vector3(points[i].x, points[i].y, 0))
				st.set_color(color)
				st.add_vertex(Vector3(points[next].x, points[next].y, 0))
	
	# 把拼好的成品放进场景里的 MeshInstance2D
	self.mesh = st.commit()
