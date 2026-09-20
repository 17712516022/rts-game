class_name Mover extends Node

const MIN_MOVE : float = 1.0
const SAFE_DITANCE : float = 5.0

## 移动速度（像素/秒）
var speed: float 

@onready var path_finder: PathFinder = %PathFinder

var soider: SoiderBottom
var dirction : Vector2 
var target : Vector2 
var chase_target : Node2D
var max_attack_range : float = 0.0
## 是否已下达移动目标（Vector2 是值类型，不能用 != null 判断）
var has_target := false

var sample_points : Array
var current : Vector2

func _ready() -> void:
	soider = get_parent() as SoiderBottom
	

## 由 SoiderBottom._ready 调用（父 _ready 在所有子节点之后，hitbox 必已就绪）：
## 挑射程最远的炮台连停步判定。空手兵（tops 为空）直接跳过，max_attack_range 保持 0。
func SetupChaseHitbox() -> void:
	var max_range_top : SoiderTop = null
	for i in soider.tops:
		var top : SoiderTop = i
		if max_range_top == null or top.top_res.attack_range > max_range_top.top_res.attack_range:
			max_range_top = top
	if max_range_top == null:
		return   # 空手兵：没有可连的 hitbox（顺带修掉 tops 为空时的崩溃）
	max_range_top.hitbox.area_entered.connect(_on_area_enter)
	max_range_top.hitbox.area_exited.connect(_on_area_exited)
	max_attack_range = max_range_top.top_res.attack_range

func SetUP(context_speed : float) -> void:
	speed = context_speed

## 当前格的速度：统一走 WaterData 查询——通航水道（被描边的河流格）系数是 1.0，
## 其余地形照旧按 ModifierData（河流原本只有 0.1，通了港口才不减速）
func get_speed() -> float:
	var pos : Vector2 = soider.global_position
	var cell_pos : Vector2i = PositionCaculater.calculate_cell(pos)
	return speed * WaterData.get_move_speed_modifier(cell_pos)

func get_dirction() -> Vector2:
	return dirction

func _physics_process(_delta: float) -> void:
	# 队首点删空 = 到达终点：复位状态、关闭处理
	if sample_points.is_empty():
		stop()
		return
	
	current = sample_points.front()
	# 距下一点只剩「一帧能走完 + 余量」时视为已到达：删点，并立即改指后续点
	if soider.global_position.distance_to(current) <= max(MIN_MOVE, get_speed() * _delta * 1.2):
		sample_points.remove_at(0)
		if sample_points.is_empty():
			stop()
			return
		current = sample_points.front()
	
	dirction = (current - soider.global_position).normalized()

func get_next_point() -> Vector2:
	return current

func set_target(context_target : Vector2) -> void:
	target = context_target
	has_target = true
	
	sample_points = path_finder.navigate(soider.global_position , target, soider.get_squad_id())
	
	set_physics_process(true)

## 停下（到达/被打断）：不再朝旧目标转向
func stop() -> void:
	has_target = false
	dirction = Vector2.ZERO
	sample_points.clear()
	set_physics_process(false)

func is_moving() -> bool:
	return has_target

func set_chase_target(entity : Node) -> void:
	has_target = true
	chase_target = entity
	
	sample_points = path_finder.navigate(soider.global_position , chase_target.global_position, -1)
	
	set_physics_process(true)

func _on_area_enter(area : Area2D) -> void:
	if not is_instance_valid(chase_target):
		return
	if _find_target_owner(area) == chase_target :
		stop()

func _on_area_exited(area : Area2D) -> void:
	if not is_instance_valid(chase_target):
		return
	if _find_target_owner(area) == chase_target:
		set_physics_process(true)
		sample_points = path_finder.navigate(soider.global_position , chase_target.global_position, -1)

func _find_target_owner(area: Area2D) -> PhysicsBody2D:
	var n : Node = area
	while n != null:
		if n is PhysicsBody2D and n.has_method("get_squad_id"):
			return n
		n = n.get_parent()
	return null
