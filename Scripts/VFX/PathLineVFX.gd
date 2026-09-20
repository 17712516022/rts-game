class_name PathLineVFX extends Line2D

## 每条被选中的士兵各占一轨：mover(Node2D) -> { "pts": Array, "next": int, "line": Line2D }
## 多选时每个兵各发一次 show_path_vfx，这里必须按 mover 分开存，否则后发的会冲掉先发的
var _tracks : Dictionary = {}
## 收起来的线放这里复用，避免每次右键都新建节点
var _line_pool : Array = []
## 复制出来的线编号（不能拿 get_child_count() 当编号：线挂到父节点下了，self 的子节点数恒为 0）
var _line_seq : int = 0

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
	# 这里不 set_process：逐帧推进轨迹的 _process 在 VFXManager 上（本类没有 _process，
	# 对着自己 set_process 是空转），由 VFXManager.show_path_vfx 负责把它的 process 打开。

## 收起所有路径线（无参 = 全清，保留原来的语义）
## process 状态只由 VFXManager 管：它下一帧看到 _tracks 空了会自己 set_process(false)
func hide_path_vfx() -> void:
	for mover in _tracks.keys():
		_release_line(_tracks[mover]["line"])
	_tracks.clear()


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
## 关键：复制出来的线要挂在 self 的父节点（VFXManager）下，绝不能 add_child(self)。
## self 是模板（场景里 visible = false，_ready 里也 hide()），而 Godot 的可见性是层级的
## ——父节点不可见，子节点自己 visible = true 也不画。挂在模板下面 = 全部隐身，
## 这正是"路径预览线看不见"的原因。
func _acquire_line() -> Line2D:
	var line : Line2D
	if _line_pool.is_empty():
		line = self.duplicate() as Line2D
		# 这三行别省：duplicate 会连 %PathLine 的唯一名和 owner 一起抄过来
		line.unique_name_in_owner = false
		line.owner = null
		_line_seq += 1
		line.name = "PathLine_%d" % _line_seq
		var host : Node = get_parent() if get_parent() != null else self
		host.add_child(line)
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
