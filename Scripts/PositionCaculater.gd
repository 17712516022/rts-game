extends Node
## 六边形坐标计算工具（全局单例）
## 所有"格子坐标 <-> 屏幕坐标"的换算都放在这里，全项目共用这一份公式。
## 布局：平顶式 odd-q（左右尖角，水平密排，奇数列垂直半格错位）。

# ============ 正向换算 ============
# 格子坐标 (row, line) -> 屏幕中心点
func calculate_position(row: int, line: int) -> Vector2:
	return Vector2(1.5 * MapData.hex_size * line, sqrt(3.0) * MapData.hex_size * (row + 0.5 * float(line & 1)))

# ============ 反向换算 ============
# 屏幕坐标 -> 格子坐标。返回 x=行 row, y=列 line。
func calculate_cell(mouse_pos: Vector2) -> Vector2i:
	# 第一步：粗定位
	var line := roundi(mouse_pos.x / (1.5 * MapData.hex_size))
	var row := roundi(mouse_pos.y / (sqrt(3.0) * MapData.hex_size) - 0.5 * float(line & 1))
	# 第二步：在 3×3 邻域内选最近的中心（修正边界错位）
	var best := Vector2i(row, line)
	var best_dist := INF
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			var r := row + dr
			var l := line + dc
			if r < 0 or l < 0 or r >= MapData.map_height or l >= MapData.map_width:
				continue
			var d := mouse_pos.distance_squared_to(calculate_position(r, l))
			if d < best_dist:
				best_dist = d
				best = Vector2i(r, l)
	return best

## 找出中心格周围 hex_distance <= closest_distance 的所有格子（含中心）。
## radius=0: 1, radius=1: 7, radius=2: 19, radius=3: 37（1+6+12+18）。
## 用 BFS + 二维访问表，稳定扩散。
func search_closest_cell(center: Vector2i, closest_distance: int = 3) -> Array:
	var w := MapData.map_width
	var h := MapData.map_height
	# 先验证中心在地图内（否则直接返回空）
	if center.x < 0 or center.y < 0 or center.x >= h or center.y >= w:
		return []
	# 用二维 PackedByteArray 存 visited（0 未访问，1 已访问）
	var visited: Array = []
	for r in range(h):
		var row_arr := PackedByteArray()
		row_arr.resize(w)
		row_arr.fill(0)
		visited.append(row_arr)
	var result: Array = []
	# 队列 BFS：[cell, remaining_steps]。remaining 代表"从这格出发还能走几步"
	var queue: Array = [[center, closest_distance]]
	visited[center.x][center.y] = 1     # 入队时就 mark，防止重复入队
	result.append(center)
	while queue.size() > 0:
		var frame: Array = queue.pop_front()
		var cell: Vector2i = frame[0]
		var remaining: int = frame[1]
		if remaining <= 0:
			continue
		for nb in get_neighbors(cell):
			if visited[nb.x][nb.y] == 0:
				visited[nb.x][nb.y] = 1
				result.append(nb)
				queue.append([nb, remaining - 1])
	return result

## 平顶式 odd-q 六个邻居（和 calculate_position、MapGenerater、RiverGenerater、PathFinder 配套的项目原始约定）
# 偶数列 line & 1 == 0：上左(-1,-1) 上(-1,0) 上右(-1,1) 左(0,-1) 右(0,1) 下(1,0)
# 奇数列 line & 1 == 1：上(-1,0) 左(0,-1) 右(0,1) 下左(1,-1) 下(1,0) 下右(1,1)
func get_neighbors(cell: Vector2i) -> Array:
	var offsets: Array
	if cell.y & 1 == 0:
		offsets = [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0)]
	else:
		offsets = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)]
	var h := MapData.map_height
	var w := MapData.map_width
	var neighbors: Array = []
	for offset in offsets:
		var nb: Vector2i = cell + offset
		if nb.x < 0 or nb.y < 0 or nb.x >= h or nb.y >= w:
			continue
		neighbors.append(nb)
	return neighbors
