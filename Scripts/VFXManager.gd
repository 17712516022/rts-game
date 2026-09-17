class_name VFXManager extends Node2D

## PathLine 只当样式模板用：宽度/宽度曲线/颜色都从它复制，它自己不参与绘制
@onready var path_line: Line2D = %PathLine

## 每条被选中的士兵各占一轨：mover(Node2D) -> { "pts": Array, "next": int, "line": Line2D }
## 多选时每个兵各发一次 show_path_vfx，这里必须按 mover 分开存，否则后发的会冲掉先发的
var _tracks : Dictionary = {}
## 收起来的线放这里复用，避免每次右键都新建节点
var _line_pool : Array = []

func _ready() -> void:
	# 特效请求走信号总线（EventBus）进来：调用方只发信号，不直接碰这个节点
	EventBus.show_path_vfx.connect(show_path_vfx)
	EventBus.hide_path_vfx.connect(hide_path_vfx)
	path_line.hide()

## 开始画一条会跟着 mover 缩短的路径线。points 为空（无路）时不画。
func show_path_vfx(mover: Node2D, points: Array) -> void:
	if mover == null or not is_instance_valid(mover):
		return
	# 没路：只收掉这一个 mover 的线，不能动别人的
	# （多选时只要有一个兵寻不到路，清全场的写法会把其他兵刚画好的线一起抹掉）
	if points.is_empty():
		_drop_track(mover)
		return

	var track : Dictionary = _tracks.get(mover, {})
	if track.is_empty():
		track = { "pts": [], "next": 1, "line": _acquire_line() }
		_tracks[mover] = track

	var pts : Array = track["pts"]
	pts.clear()
	pts.append(mover.global_position)  # 起点 = 出发时士兵所在，之后士兵沿这些点走
	for p in points:
		if p is Vector2:
			pts.append(p)
	track["next"] = 1
	_refresh_line(mover, track)
	set_process(true)

## 收起所有路径线（无参 = 全清，保留原来的语义）
func hide_path_vfx() -> void:
	for mover in _tracks.keys():
		_release_line(_tracks[mover]["line"])
	_tracks.clear()
	set_process(false)

func _process(_delta: float) -> void:
	if _tracks.is_empty():
		set_process(false)
		return
	# keys() 每次返回新数组，所以循环里 erase 是安全的
	for mover in _tracks.keys():
		if not is_instance_valid(mover):
			_drop_track(mover)  # 士兵没了（被移除/死亡）也别留着线
			continue

		var track : Dictionary = _tracks[mover]
		var path_pts : Array = track["pts"]
		var pos: Vector2 = mover.global_position
		var next : int = track["next"]
		# 向前吞点：士兵沿折线单向移动，只可能越过“下一个待走点”。
		# 用“pos 在本段的投影比例 t”：t >= 1 表示 pos 已经走过该段终点，删掉继续看下一段。
		# 不依赖格子尺寸或帧率，即使卡顿一下跨过多个点也能一次吞干净。
		while next < path_pts.size():
			var from_pt: Vector2 = path_pts[next - 1]
			var to_pt: Vector2 = path_pts[next]
			var seg: Vector2 = to_pt - from_pt
			var seg_len2: float = seg.length_squared()
			if seg_len2 <= 0.0:
				next += 1  # 原地段（几乎不可能）直接跳过
				continue
			var t: float = (pos - from_pt).dot(seg) / seg_len2
			if t < 1.0:
				break  # 还没走到这个点，保留它
			next += 1
		track["next"] = next

		if next >= path_pts.size():
			_drop_track(mover)  # 走完全程：收线，别让空轨一直挂在字典里
			continue
		_refresh_line(mover, track)

## 按当前进度重画：线 = [士兵当前位置] + [所有还没走过的路径点]
func _refresh_line(mover: Node2D, track : Dictionary) -> void:
	var path_pts : Array = track["pts"]
	var pts := PackedVector2Array([mover.global_position])
	for i in range(track["next"], path_pts.size()):
		pts.append(path_pts[i])
	var line : Line2D = track["line"]
	line.points = pts
	line.visible = pts.size() > 1  # 只剩一个点画不出东西

## 借一根线：优先从回收池拿，池空则按 PathLine 的样式复制一根
func _acquire_line() -> Line2D:
	var line : Line2D
	if _line_pool.is_empty():
		line = path_line.duplicate() as Line2D
		# 这三行别省：duplicate 会连 %PathLine 的唯一名和 owner 一起抄过来
		line.name = "PathLine_%d" % get_child_count()
		line.unique_name_in_owner = false
		line.owner = null
		add_child(line)
	else:
		line = _line_pool.pop_back()
	line.points = PackedVector2Array()
	line.show()
	return line

func _release_line(line : Line2D) -> void:
	if line == null or not is_instance_valid(line):
		return
	line.points = PackedVector2Array()
	line.hide()
	_line_pool.append(line)

## 收掉某个 mover 的轨迹（线回池复用）
## mover 故意不加类型标注：_process 里清理"已被释放的士兵"时也要走这里，
## 而把 previously freed 的对象传进 Node2D 形参会直接报
## "Invalid type in function '_drop_track' ... is not a subclass of the expected argument class"。
## 字典本身不受影响：键 Variant 仍持有该对象的 ObjData，实例 id 有效，has/erase 照常命中。
func _drop_track(mover) -> void:
	if not _tracks.has(mover):
		return
	_release_line(_tracks[mover]["line"])
	_tracks.erase(mover)
