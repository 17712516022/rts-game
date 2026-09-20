class_name Fog extends Sprite2D

## 迷雾着色器：把玩家士兵和玩家建筑附近"照亮"（迷雾 alpha 抹成 0）。
const FOG_SHADER := preload("res://shader/fog.gdshader")

const C_UNITS : int = 64
const C_BUILDINGS : int = 640

## 填给"空槽位"的假坐标：离地图远到不可能被算进照亮范围
const FAR_AWAY := Vector2(1.0e7, 1.0e7)

## 照亮半径（世界像素）。内圈全亮、外圈开始渐隐，做出柔和边缘。
@export_group("士兵照亮半径")
@export var unit_inner : float = 200.0
@export var unit_outer : float = 300.0
@export_group("建筑照亮半径")
@export var building_inner : float = 260.0
@export var building_outer : float = 400.0
@export_group("迷雾漂移")
## 迷雾整体平移速度，单位 = 每秒走过多少个"贴图宽度"。
## 0 = 静止，正值 = 图案向右飘。贴图是 seamless 的，绕回时看不出接缝。
@export var flow_speed : float = 0.01
@export_group("性能")
## 视野外扩多少像素内的单位也照样计入（防止边缘单位一进一出造成闪烁）
@export var cull_margin : float = 200.0

var _mat : ShaderMaterial
var _camera : Camera2D

## 复用同一份缓冲区，避免每帧 new 出垃圾
var _unit_buf := PackedVector2Array()
var _bld_buf := PackedVector2Array()

@onready var constrution_container: Node2D = %ConstrutionContainer
@onready var soider_container: Node2D = %SoiderContainer

func _ready() -> void:
	hide()
	_mat = material
	_mat.set_shader_parameter("flow_speed", flow_speed)
	# 起始浓度 0：等 _fade_in 再补间到 1，做出迷雾渐渐浮上来的效果
	_mat.set_shader_parameter("fog_alpha", 0.0)
	
	_unit_buf.resize(C_UNITS)
	_bld_buf.resize(C_BUILDINGS)
	
	EventBus.game_ready.connect(_on_game_ready)
	EventBus.player_has_ready.connect(_fade_in)
	
func _on_game_ready() -> void:
	_mat.set_shader_parameter("unit_inner", unit_inner)
	_mat.set_shader_parameter("unit_outer", unit_outer)
	_mat.set_shader_parameter("building_inner", building_inner)
	_mat.set_shader_parameter("building_outer", building_outer)

	_camera = get_viewport().get_camera_2d()

func _process(_delta: float) -> void:
	if _mat == null:
		return
	
	# 每帧只取"当前镜头里"的玩家单位/建筑 —— 屏幕外的不需要照亮
	var view := _visible_world_rect()
	
	# 玩家士兵
	var unit_n := _fill_player_points(soider_container, _unit_buf, view, unit_outer)
	_mat.set_shader_parameter("reveal_count", unit_n)
	_mat.set_shader_parameter("reveal_points", _unit_buf)
	
	# 玩家建筑
	var bld_n := _fill_player_points(constrution_container, _bld_buf, view, building_outer)
	_mat.set_shader_parameter("building_count", bld_n)
	_mat.set_shader_parameter("building_points", _bld_buf)
	
	var fog_size : Vector2 = texture.get_size() * scale
	var fog_origin : Vector2 = global_position
	if centered:
		fog_origin -= fog_size * 0.5
	_mat.set_shader_parameter("fog_origin", fog_origin)
	_mat.set_shader_parameter("fog_size", fog_size)

## 当前镜头能看到的世界矩形（再外扩 pad，保证边缘的照亮不会被切掉）。
func _visible_world_rect() -> Rect2:
	if _camera == null:
		return Rect2(-1.0e7, -1.0e7, 2.0e7, 2.0e7)   # 没相机就当全图可见

	var half := get_viewport_rect().size * 0.5 / _camera.zoom
	var center := _camera.get_screen_center_position()
	return Rect2(center - half, half * 2.0)

## 把容器里"玩家阵营"且"在视野附近"的节点位置填进 pts（定长），返回有效个数。
## 用不到的位置保持 FAR_AWAY，避免残留上一帧坐标。
func _fill_player_points(container : Node2D, pts : PackedVector2Array,
		view : Rect2, pad : float) -> int:
	for i in range(pts.size()):
		pts[i] = FAR_AWAY

	var n : int = 0
	if container == null:
		return 0

	var area := view.grow(pad + cull_margin)   # 视野外扩出照亮半径的余量

	for child in container.get_children():
		if n >= pts.size():
			break
		if not (child is Node2D) or child.is_queued_for_deletion():
			continue
		# 士兵(SoiderBottom)和建筑(Construction)都能 get_squad_id()
		if not child.has_method("get_squad_id"):
			continue
		if child.get_squad_id() != TeamData.Team.PLAYER:
			continue
		var pos : Vector2 = child.global_position
		if not area.has_point(pos):   # 屏幕外的照亮看不见，直接跳过
			continue
		pts[n] = pos
		n += 1
	
	return n

## 淡入：把迷雾浓度 0 -> 1 补间一秒。
## 注意不能补间节点的 modulate：shader 结尾是 COLOR = col 整体覆盖，
## modulate（顶点色）会被丢掉，只有 shader 里的 fog_alpha 才真的能控制迷雾浓淡。
func _fade_in() -> void:
	show()
	var tween : Tween = create_tween()
	tween.tween_method(_set_fog_alpha, 0.0, 1.0, 2.0)

func _set_fog_alpha(v : float) -> void:
	_mat.set_shader_parameter("fog_alpha", v)
