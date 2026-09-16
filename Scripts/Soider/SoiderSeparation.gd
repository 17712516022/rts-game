extends Node
## 同阵营士兵之间的分离力：防止多个兵叠在同一个点上。
## 名单按阵营缓存（squad_id -> 士兵数组），只在出生/死亡时刷新，不在每帧重扫容器。

@export var outer_separate_radius : float = 64.0   # 出圈不产生推力
@export var inner_separate_radius : float = 32.0   # 进圈推力拉满
@export var max_separate_speed : float = 50.0      # 分离力上限（像素/秒）

## squad_id -> 该阵营当前在场士兵。敌我各占一个 key，互相不覆盖
var _squads : Dictionary = {}

## 出生时刷新：由 SoiderBottom._ready 调用，只重扫「自己这一个阵营」
func update_squad_soiders(soider_container : Node2D, soider : SoiderBottom) -> void:
	var squad_id : int = soider.get_squad_id()
	_squads[squad_id] = SoiderManager.get_soiders(soider_container, squad_id)

## 死亡时摘除：由 SoiderBottom._die 调用
func remove_soider(soider : SoiderBottom) -> void:
	var mates : Array = _squads.get(soider.get_squad_id(), [])
	mates.erase(soider)

## 单个邻居的推力：以「权重」为单位（0~1），量级由 steering_force 统一缩放
## mate_pos 是「邻居」的位置（不是移动目标），方向从邻居指向自己 = 推开
func apply_separate_force(soider : SoiderBottom, mate_pos : Vector2) -> Vector2:
	var mate_distance : float = soider.global_position.distance_to(mate_pos)
	if mate_distance >= outer_separate_radius:
		return Vector2.ZERO      # 出圈：直接返回零向量，后面不会再被覆盖
	if mate_distance < 0.001:
		# 完全重合：direction_to 返回零向量，随机给个方向
		return Vector2.RIGHT.rotated(randf() * TAU)

	var weight : float
	if mate_distance <= inner_separate_radius:
		weight = 1.0
	else:
		# 只有进到 else 的分支才可能落在这段，t 必然在 0~1 之间，不会外推出负数
		var inner_to_outer : float = outer_separate_radius - inner_separate_radius
		weight = lerpf(1.0, 0.0, (mate_distance - inner_separate_radius) / inner_to_outer)

	return weight * mate_pos.direction_to(soider.global_position)   # 去掉负号


## 汇总本阵营所有邻居的推力，返回可直接加进 velocity 的速度向量
func steering_force(soider : SoiderBottom) -> Vector2:
	var total : Vector2 = Vector2.ZERO
	var mates : Array = _squads.get(soider.get_squad_id(), [])   # 没刷过 → 空数组，不报错
	for i in mates:
		var unit : SoiderBottom = i
		if unit == soider:
			continue                       # 名单含自己，自己到自己是 0 距离
		if not is_instance_valid(unit):
			continue                       # 兜底：漏摘的已释放对象
		total += apply_separate_force(soider, unit.global_position)
	return total.limit_length(1.0) * max_separate_speed
