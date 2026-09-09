class_name Mover extends Node

const MIN_MOVE : float = 1.0

## 移动速度（像素/秒）
var speed: float 

@onready var path_finder: PathFinder = %PathFinder

var soider: SoiderBottom
var dirction : Vector2 
var target : Vector2 
## 是否已下达移动目标（Vector2 是值类型，不能用 != null 判断）
var has_target := false

var sample_points : Array
var current : Vector2

func _ready() -> void:
	soider = get_parent() as SoiderBottom

func SetUP(context_speed : float) -> void:
	speed = context_speed

func get_speed() -> float:
	var pos : Vector2 = soider.global_position
	var cell_pos : Vector2i = PositionCaculater.calculate_cell(pos)
	var terr : MapData.TERRAIN = MapData.terrain_grid[cell_pos.x][cell_pos.y]
	var modifers : Dictionary = ModifierData.Modifiers[terr]
	var speed_modifer = modifers["MoveSpeedModifier"]
	
	return speed * speed_modifer

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
