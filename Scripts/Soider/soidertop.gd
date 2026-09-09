class_name SoiderTop extends Node2D

var top_res : SoiderTopResource

@onready var soidertoptexture: Sprite2D = $Soidertoptexture
@onready var hitbox: Area2D = $Hitbox
@onready var bullet_spawner: BulletSpawner = $BulletSpawner

## 进入射程的敌对目标（敌方士兵 SoiderBottom 或敌方建筑 Construction，都可打）
var targets : Array
var soider : SoiderBottom
## 当前要打的最近目标：士兵或建筑统一当 PhysicsBody2D 处理（打点都取 global_position）
var true_target : PhysicsBody2D : 
	get :
		if not targets.is_empty():
			return targets.front()
		return null
var coolingdown_timer : float
var max_coolingdown : float

func _ready() -> void:
	soider = get_parent() as SoiderBottom
	hitbox.area_entered.connect(_add_to_possible_target.bind())
	hitbox.area_exited.connect(_remove_from_possible_target.bind())
	_apply_slot()

## 装配本槽：context_top_res 为 null = 空槽（隐藏炮台、禁用攻击范围）
func SetupSlot(context_top_res : SoiderTopResource) -> void:
	top_res = context_top_res
	if is_inside_tree():
		_apply_slot()

## 把当前 top_res 配置应用到节点（贴图/攻击范围/显隐）
func _apply_slot() -> void:
	var active : bool = top_res != null
	visible = active
	if not active:
		return
	# 设贴图
	if top_res.top_texture != null and soidertoptexture != null:
		soidertoptexture.texture = top_res.top_texture
	
	var hit_box_shape : CollisionShape2D = hitbox.get_child(0) as CollisionShape2D
	var circle := hit_box_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = top_res.attack_range
	
	max_coolingdown = top_res.attack_coolingdown
	coolingdown_timer = max_coolingdown

## 从触发圈(Area2D)向上找"带阵营的可攻击对象"（士兵/建筑都带 get_squad_id）。
func _find_target_owner(area: Area2D) -> PhysicsBody2D:
	var n : Node = area
	while n != null:
		if n is PhysicsBody2D and n.has_method("get_squad_id"):
			return n
		n = n.get_parent()
	return null

func _add_to_possible_target(area: Area2D) -> void:
	var enemy : PhysicsBody2D = _find_target_owner(area)
	if enemy == null:
		return
	# 只打两类：敌对士兵 / 敌对建筑（未来有别的可打对象在这里加）
	if not (enemy is SoiderBottom or enemy is Construction):
		return
	if enemy.get_squad_id() == soider.get_squad_id():
		return
	targets.append(enemy)

func _remove_from_possible_target(area: Area2D) -> void:
	var enemy : PhysicsBody2D = _find_target_owner(area)
	if enemy != null:
		targets.erase(enemy)

## 每帧过滤：死掉的、离队的（比如中心刚易手变成友军）都不再是目标，然后按距离排最近在前
func find_attack_target() -> void:
	targets = targets.filter(
		func(t: PhysicsBody2D) -> bool:
			return is_instance_valid(t) and t.is_inside_tree() \
				and t.get_squad_id() != soider.get_squad_id()
	)
	targets.sort_custom(
		func (a : PhysicsBody2D,b : PhysicsBody2D) :
			a.global_position.distance_to(soider.global_position) < b.global_position.distance_to(soider.global_position) 
	)

## 攻击目标（对方是士兵或建筑，掉血/易手由它自己处理）
func attack_target(delta : float) -> void:
	find_attack_target()      # 先滤死单位/离队单位 + 按距离升序 → true_target 才有意义
	
	coolingdown_timer -= delta
	if coolingdown_timer > 0.0 :
		return
	if true_target == null or top_res == null:
		return
		
	coolingdown_timer = max_coolingdown
	create_bullet()

func create_bullet() -> void:
	var dirction : Vector2 = bullet_spawner.global_position.direction_to(true_target.global_position)
	bullet_spawner.create_bullet(dirction,self)
