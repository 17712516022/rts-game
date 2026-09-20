class_name VFXManager extends Node2D

@onready var path_line: PathLineVFX = %PathLine

func _ready() -> void:
	# 特效请求走信号总线（EventBus）进来：调用方只发信号，不直接碰这个节点
	EventBus.show_path_vfx.connect(show_path_vfx)
	EventBus.hide_path_vfx.connect(hide_path_vfx)
	# PathLine 只是"样式模板"（.tscn 里 visible = false）：真正画的线由 PathLineVFX 复制出来、
	# 挂在 VFXManager 下（见 _acquire_line）。这里 hide() 的是模板本身，不影响预览线。
	path_line.hide()

func show_path_vfx(mover: Node2D, points: Array) -> void:
	path_line.show_path_vfx(mover, points)
	# 轨迹推进在 _process 里，而 _process 在"没轨迹"时会把自己关掉，
	# 所以每次画新线都得重新打开一次（set_process 要调在带 _process 的本节点上）
	set_process(true)

func hide_path_vfx() -> void:
	path_line.hide_path_vfx()

func _process(_delta: float) -> void:
	if path_line._tracks.is_empty():
		set_process(false)
		return
	# keys() 每次返回新数组，所以循环里 erase 是安全的
	for mover in path_line._tracks.keys():
		if not is_instance_valid(mover):
			path_line._drop_track(mover)  # 士兵没了（被移除/死亡）也别留着线
			continue
	
		var track : Dictionary = path_line._tracks[mover]
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
			path_line._drop_track(mover)  # 走完全程：收线，别让空轨一直挂在字典里
			continue
		path_line._refresh_line(mover, track)
