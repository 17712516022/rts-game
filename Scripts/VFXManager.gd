class_name VFXManager extends Node2D

@onready var path_line: Line2D = %PathLine

## 当前跟踪的移动者（它走到哪，线就缩到哪）；为空 = 当前没有活动的路径预览
var _mover: Node2D
## 该移动者本次移动的完整路径点（世界坐标）：索引 0 = 出发起点，之后 = 寻路途经点 + 精确终点
var _path_pts: Array = []
## 下一个还没被“吃掉”的路径点下标。士兵越过了 _path_pts[_next_idx] 后它就 +1
var _next_idx: int = 1

func _ready() -> void:
	# 特效请求走信号总线（EventBus）进来：调用方只发信号，不直接碰这个节点
	EventBus.show_path_vfx.connect(show_path_vfx)
	EventBus.hide_path_vfx.connect(hide_path_vfx)
	path_line.hide()

## 开始画一条会跟着 mover 缩短的路径线。points 为空（无路）时不画。
func show_path_vfx(mover: Node2D, points: Array) -> void:
	if mover == null or not is_instance_valid(mover) or points.is_empty():
		hide_path_vfx()
		return
	_mover = mover
	_path_pts.clear()
	_path_pts.append(mover.global_position)  # 起点 = 出发时士兵所在，之后士兵沿这些点走
	for p in points:
		if p is Vector2:
			_path_pts.append(p)
	_next_idx = 1
	_refresh_line()
	set_process(true)

## 收起路径线并停止跟踪
func hide_path_vfx() -> void:
	set_process(false)
	_mover = null
	_path_pts.clear()
	_next_idx = 1
	path_line.hide()

func _process(_delta: float) -> void:
	if _mover == null or not is_instance_valid(_mover):
		hide_path_vfx()  # 移动者没了（被移除/死亡）也别留着线
		return
	var pos: Vector2 = _mover.global_position
	# 向前吞点：士兵沿折线单向移动，只可能越过“下一个待走点”。
	# 用“pos 在本段的投影比例 t”：t >= 1 表示 pos 已经走过该段终点，删掉继续看下一段。
	# 不依赖格子尺寸或帧率，即使卡顿一下跨过多个点也能一次吞干净。
	while _next_idx < _path_pts.size():
		var from_pt: Vector2 = _path_pts[_next_idx - 1]
		var to_pt: Vector2 = _path_pts[_next_idx]
		var seg: Vector2 = to_pt - from_pt
		var seg_len2: float = seg.length_squared()
		if seg_len2 <= 0.0:
			_next_idx += 1  # 原地段（几乎不可能）直接跳过
			continue
		var t: float = (pos - from_pt).dot(seg) / seg_len2
		if t < 1.0:
			break  # 还没走到这个点，保留它
		_next_idx += 1
	_refresh_line()

## 按当前进度重画：线 = [士兵当前位置] + [所有还没走过的路径点]
func _refresh_line() -> void:
	var pts := PackedVector2Array([_mover.global_position])
	for i in range(_next_idx, _path_pts.size()):
		pts.append(_path_pts[i])
	path_line.points = pts
	path_line.show()
