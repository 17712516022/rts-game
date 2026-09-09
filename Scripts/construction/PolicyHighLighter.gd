class_name PolicyHighLighter extends Node2D

## 边界色（统一深灰）
const BORDER_COLOR := Color(0.2, 0.2, 0.2, 0.9)
const BORDER_WIDTH := 2.5
## 兜底色：中心 squad 不在 TeamData.team_color 表里时（如 -1 无主）用中性灰，避免取色崩/空白
const NEUTRAL_COLOR := Color(0.45, 0.45, 0.45, 0.9)

## 六边形 6 条边 = 两个相邻顶点索引（顺序和 _hex_local 一致：0°/60°/120°/180°/240°/300°）
const EDGES: Array = [
	[1, 2],   # 边 0：顶上水平（60°↔120°）
	[2, 3],   # 边 1：左上斜边
	[3, 4],   # 边 2：左下斜边
	[4, 5],   # 边 3：底下水平（240°↔300°）
	[5, 0],   # 边 4：右下斜边
	[0, 1],   # 边 5：右上斜边
]

const TOLERANCE_SQ := 4.0

## 本地缓存的六边形 6 顶点（相对中心(0,0)），和 MapGenerater / HighLighter 同一套
var _hex_local: PackedVector2Array

func _ready() -> void:
	_hex_local = _build_hex_local()
	z_index = 1   # 贴在地形上面，建筑/单位下面
	# 三件事都会让势力图变：新中心建成(填新格子)、中心被拆/打死(清格子重填)、中心易手(阵营变颜色变)
	EventBus.construct_building.connect(_request_redraw)
	EventBus.center_destroyed.connect(_request_redraw)
	EventBus.team_refresh_requested.connect(_request_redraw)

func _request_redraw(_a = null, _b = null) -> void:
	queue_redraw()

# 和 MapGenerater.hex_corners 完全一致（平顶 0°起算）
func _build_hex_local() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i)
		points.append(Vector2(cos(angle), sin(angle)) * MapData.hex_size)
	return points

## 读 owner_grid：有归属的填充色 + 归属不同的交界画深灰边线
func _draw() -> void:
	if ConstructionData.owner_grid.is_empty():
		return
	var h: int = ConstructionData.owner_grid.size()
	# 第一遍：所有有主格按所属中心阵营填色（填色和边线分两遍，逻辑清楚）
	for row in range(h):
		var line_arr: Array = ConstructionData.owner_grid[row]
		var w: int = line_arr.size()
		
		for col in range(w):
			var theowner = line_arr[col]
			if theowner == null:
				continue
				
			var world_center: Vector2 = PositionCaculater.calculate_position(row, col)
			var world_points := PackedVector2Array()
			world_points.resize(6)
			for i in range(6):
				world_points[i] = world_center + _hex_local[i]
			draw_colored_polygon(world_points, _owner_color(theowner))
	# 第二遍：逐个有归属的势力格，检查 6 条边对面的邻居归属。
	# 邻居归属≠自己（或越界出地图）→ 这条边画一条深灰线。
	for row in range(h):
		var line_arr: Array = ConstructionData.owner_grid[row]
		var w: int = line_arr.size()
		for col in range(w):
			var theowner = line_arr[col]
			if theowner == null:
				continue
			_draw_edges_for_cell(row, col, theowner, Vector2i(row, col))

## owner_grid 存的是中心 Construction 节点（StaticBody2D 实例）：按中心的阵营(squad)上色。
## 中心易手换主后 squad 已变，同批格子颜色自动跟随（team_refresh_requested 触发重绘）。
func _owner_color(theowner : Construction) -> Color:
	if theowner != null and theowner.has_method("get_squad_id") and TeamData.team_color.has(theowner.get_squad_id()):
		return TeamData.team_color[theowner.get_squad_id()]
	return NEUTRAL_COLOR

func _draw_edges_for_cell(row: int, col: int, theowner : Construction , cell: Vector2i) -> void:
	var self_center: Vector2 = PositionCaculater.calculate_position(row, col)
	# 对 6 个合法邻居（PositionCaculater 自带 even/odd 偏移和越界检查）
	for nb in PositionCaculater.get_neighbors(cell):
		var nb_owner = null
		if nb.x < 0 or nb.y < 0 or nb.x >= ConstructionData.owner_grid.size():
			nb_owner = null
		else:
			var line_arr: Array = ConstructionData.owner_grid[nb.x]
			if nb.y >= line_arr.size():
				nb_owner = null
			else:
				nb_owner = line_arr[nb.y]
		# 邻居归属和自己相同 → 同势力，不画边界
		if nb_owner == theowner:
			continue
		# 归属不同：找公共边（6 条边里谁的中点正好是两格中心点）
		var nb_center: Vector2 = PositionCaculater.calculate_position(nb.x, nb.y)
		var edge_idx: int = _find_shared_edge_index(self_center, nb_center)
		if edge_idx < 0:
			continue
		var va: int = EDGES[edge_idx][0]
		var vb: int = EDGES[edge_idx][1]
		var pa: Vector2 = self_center + _hex_local[va]
		var pb: Vector2 = self_center + _hex_local[vb]
		draw_line(pa, pb, BORDER_COLOR, BORDER_WIDTH, true)

## 对 self 和 nb 的中心，找哪条边的中点正好落在两格中心连线的中点上。
## 返回边索引 EDGES[i]，找不到返回 -1（容错，理论上不会发生）
func _find_shared_edge_index(self_center: Vector2, nb_center: Vector2) -> int:
	var mid_centers: Vector2 = (self_center + nb_center) * 0.5
	var best_idx: int = -1
	var best_dist_sq: float = INF
	# 容忍度：边长一半 1px 以内就算匹配（浮点误差防护）
	for i in range(6):
		var va: int = EDGES[i][0]
		var vb: int = EDGES[i][1]
		var edge_mid := (_hex_local[va] + _hex_local[vb]) * 0.5 + self_center
		var d_sq := mid_centers.distance_squared_to(edge_mid)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best_idx = i
	if best_dist_sq <= TOLERANCE_SQ:
		return best_idx
	return -1
