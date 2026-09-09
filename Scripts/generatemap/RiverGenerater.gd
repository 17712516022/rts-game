extends Node
## 河流生成器（反算版）：先算出"每个格子到海要累计爬升多少海拔"，
## 再从高山源头沿代价递减的方向一路走回海，标记出河道。
## 好处：
##   1. 河到海就停，永远不会在海里流。
##   2. 路径逐格连续，不会隔空、不会断在内陆盆地（洼地格也会指向它的出水口）。
##   3. 没有蓄水逻辑，不会铺出超大的湖。
##   4. 蜿蜒：每步从到海代价最低的几个邻居里随机挑一个，保留自然弯曲。

const GENERATE_RIVER_POSSIBILITY : float = 0.3  # 高地格子作为河源头的概率
const MEANDER_CANDIDATES : int = 6                    # 从代价最低的多少个邻居里随机选，数字越大河越蜿蜒

var cost_grid : Array = []   # cost_grid[行][列] = 到海的累计爬坡量，INF 表示到不了海（内陆死水）
var dist_grid : Array = []   # dist_grid[行][列] = 到海的最少步数，源头过滤用

func _ready() -> void:
	EventBus.map_has_generated.connect(_on_map_has_generated)

func _on_map_has_generated() -> void:
	_generate_river()

func _generate_river() -> void:
	# 1. 先清空并重建河流标记表（全地图默认没有河）
	MapData.river_grid.clear()
	for row in range(MapData.map_height):
		var row_arr: Array = []
		for line in range(MapData.map_width):
			row_arr.append(false)
		MapData.river_grid.append(row_arr)

	# 2. 反算：从所有海洋格出发向内地扩散，算出每格到海的累计爬坡量。
	#    这个表里暗含了方向：往代价更低的邻居走，就是往海走。
	_compute_cost_to_sea()

	# 3. 遍历高地格子，按概率挑一些当河源头，沿方向表一路走回海
	for row in range(MapData.map_height):
		for line in range(MapData.map_width):
			var elev : float = MapData.elevation_grid[row][line]
			if not _is_local_peak(Vector2i(row, line)):
				continue   # 不是山顶的格子不发源，保证源头在山脊深处
			if randf() > GENERATE_RIVER_POSSIBILITY:
				continue
			_follow_to_sea(Vector2i(row, line))

	# 4. 全部河道标记完成，通知地图重绘，把河道画出来
	EventBus.rivers_generated.emit()

# 多源 Dijkstra：源 = 所有海洋格（代价 0）。
# 走一步到邻居的代价 = 上升的海拔（下坡和平路免费，上坡才算钱），
# 所以每个格子的代价就是"从这里爬到海要累计上升多少"。
# 同时记录每个格子到海的步数（dist_grid），步数不限代价，供源头过滤用。
# 用二叉堆做优先队列，保证每个格子记录到的是全局最小的爬坡代价。
func _compute_cost_to_sea() -> void:
	cost_grid.clear()
	dist_grid.clear()
	for row in range(MapData.map_height):
		var row_arr: Array = []
		var dist_arr: Array = []
		for line in range(MapData.map_width):
			row_arr.append(INF)
			dist_arr.append(-1)
		cost_grid.append(row_arr)
		dist_grid.append(dist_arr)

	var heap := MiniHeap.new()
	for row in range(MapData.map_height):
		for line in range(MapData.map_width):
			if MapData.elevation_grid[row][line] <= MapData.CLOSESEE_LEVEL:
				cost_grid[row][line] = 0.0
				dist_grid[row][line] = 0
				heap.push(0.0, Vector2i(row, line))

	while not heap.is_empty():
		var item := heap.pop()
		var cur_cost : float = item[0]
		var cur : Vector2i = item[1]
		if cur_cost > cost_grid[cur.x][cur.y]:
			continue   # 队列里过期的旧记录，跳过
		var cur_elev : float = MapData.elevation_grid[cur.x][cur.y]
		for nb in PositionCaculater.get_neighbors(cur):
			var climb := maxf(0.0, MapData.elevation_grid[nb.x][nb.y] - cur_elev)
			var new_cost := cur_cost + climb
			if new_cost < cost_grid[nb.x][nb.y]:
				cost_grid[nb.x][nb.y] = new_cost
				dist_grid[nb.x][nb.y] = dist_grid[cur.x][cur.y] + 1
				heap.push(new_cost, nb)

# 判断一格是不是"局部山顶"：周围 6 个邻居里没有一个比它高。
# 只从山顶发源，源头一定是内陆制高点，河才有足够的落差和长度。
func _is_local_peak(cell: Vector2i) -> bool:
	var elev : float = MapData.elevation_grid[cell.x][cell.y]
	for nb in PositionCaculater.get_neighbors(cell):
		if MapData.elevation_grid[nb.x][nb.y] > elev:
			return false
	return true

# 从源头出发，沿着"到海代价"单调递减的方向一路走回海。
# 每步从代价最低的几个邻居里随机挑一个，制造蜿蜒。
# 走到海（或走投无路、超长）就停；海格不标记为河。
func _follow_to_sea(start: Vector2i) -> void:
	var current : Vector2i = start
	var steps := 0
	while true:
		# 到海就停，海格不是河道
		if MapData.elevation_grid[current.x][current.y] <= MapData.CLOSESEE_LEVEL:
			return

		# 标记当前格子为河道
		MapData.river_grid[current.x][current.y] = true
		steps += 1
	
		# 收集"到海代价更低"的邻居，当作候选方向（这些都是往海走的路）
		var cur_cost : float = cost_grid[current.x][current.y]
		var candidates : Array = []   # 每项是 [到海代价, 格子]
		for nb in PositionCaculater.get_neighbors(current):
			var nb_cost : float = cost_grid[nb.x][nb.y]
			if nb_cost < cur_cost:
				candidates.append([nb_cost, nb])

		if candidates.is_empty():
			return   # 走投无路（源头已被过滤，正常不会到这里）

		# 按"到海代价"从高到低排序，优先选离海最远、最不急着入海的方向。
		# 河会沿着自己高度的缓坡绕行，先在低地平原流一大段，最后才入海，
		# 河道因此大幅变长，也更贴近真实大河在平原上蜿蜒的姿态。
		candidates.sort_custom(func(a, b): return a[0] > b[0])
		var top_n := mini(candidates.size(), MEANDER_CANDIDATES)
		current = candidates[randi() % top_n][1]

# 简单的小顶堆（二叉堆），给 Dijkstra 当优先队列用
class MiniHeap:
	var items : Array[Array] = []   # 每项是 [代价, 格子]

	func push(cost: float, cell: Vector2i) -> void:
		items.append([cost, cell])
		var i := items.size() - 1
		while i > 0:
			var p := (i - 1) >> 1
			if items[p][0] <= items[i][0]:
				break
			var t := items[p]
			items[p] = items[i]
			items[i] = t
			i = p

	func pop() -> Array:
		var top : Array = items[0]
		var last : Array = items.pop_back()
		if items.is_empty():
			return top
		items[0] = last
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var smallest := i
			if l < items.size() and items[l][0] < items[smallest][0]:
				smallest = l
			if r < items.size() and items[r][0] < items[smallest][0]:
				smallest = r
			if smallest == i:
				break
			var t := items[i]
			items[i] = items[smallest]
			items[smallest] = t
			i = smallest
		return top

	func is_empty() -> bool:
		return items.is_empty()
