class_name SoiderBottom extends CharacterBody2D

var bott_res : SoiderBottomResource
var current_health : float
## 当前所在格子（移动后更新）
var cell : Vector2i = Vector2i(-1, -1)
## 转向速度（弧度/秒），3.0 ≈ 每秒转一圈
@export var turn_speed : float = 2.0
@export var top_turn_speed : float = 4.0
## 已装炮的炮台列表（只含非空槽，由 AssembleTurrets 填充；攻击由各炮台自己负责）
var tops: Array = []

## 平滑移动组件（场景预设）
@onready var mover: Mover = %Mover
## 是否已完成初始化（防止 SetUp/_ready 时序导致重复初始化）
var _initialized : bool = false

@onready var soiderbottontexture: Sprite2D = %Soiderbottontexture
@onready var gpu_particles_2d: GPUParticles2D = $Soiderbottontexture/GPUParticles2D
@onready var hurtbox: Area2D = %hurtbox
@onready var health_progress_bar: TextureProgressBar = %healthProgressBar
@onready var squad: Squad = $Squad

## 对外暴露阵营：寻路时用，同 squad 的建筑不挡路
func get_squad_id() -> int:
	return squad.get_squad() if squad != null else -1

func _ready() -> void:
	health_progress_bar.value = health_progress_bar.max_value
	hurtbox.body_entered.connect(_on_body_entered)
	_init_soider()

# 外部注入：传进来士兵配置资源
func SetUp(context_bott_res : SoiderBottomResource) -> void:
	bott_res = context_bott_res
	# 如果已经在场景树里（_ready 已跑过），立即初始化
	# 否则 _ready 会调 _init_soider
	if is_inside_tree():
		_init_soider()

## 装配预摆炮台槽：turrets[i] = 槽位 i 的 SoiderTopResource，null = 空槽。
## 场景里按 Turret_0、Turret_1… 顺序与槽位一一对应。
func AssembleTurrets(turrets: Array) -> void:
	tops.clear()
	var i := 0
	while has_node("Turret_%d" % i):
		var slot: SoiderTop = get_node("Turret_%d" % i)
		var slot_res: SoiderTopResource = null
		if i < turrets.size():
			slot_res = turrets[i] as SoiderTopResource
		slot.SetupSlot(slot_res)
		if slot_res != null:
			tops.append(slot)
		i += 1

# 初始化士兵属性：血量、贴图、移动速度
func _init_soider() -> void:
	if bott_res == null or _initialized:
		return
	_initialized = true
	
	current_health = bott_res.max_health
	if bott_res.bottom_texture != null and soiderbottontexture != null:
		soiderbottontexture.texture = bott_res.bottom_texture
	
	mover.SetUP(bott_res.speed)

func _physics_process(delta: float) -> void:
	velocity = mover.get_speed() * mover.get_dirction() 
	gpu_particles_2d.emitting = mover.is_moving()
	
	updata_rotation(delta)
	attack(delta)
	
	move_and_slide()

# 受伤：交给伤害计算器算最终伤害，再扣血
func take_damage(amount: float) -> void:
	var actual: float = DamageCalculator.calculate(amount, bott_res.defense)
	current_health -= actual
	if current_health <= 0.0:
		_die()

func attack(delta : float) -> void:
	for i in tops:
		i.attack_target(delta)

# 死亡：从场景树移除
func _die() -> void:
	SoiderManager.delete_from_selecting_soider(self)
	queue_free()

# 移动到达/停下后：按当前位置刷新所在格缓存（寻路已在内部按实时位置现算，这里供占领判定等逻辑参考）
func _on_move_finished() -> void:
	cell = PositionCaculater.calculate_cell(global_position)

func updata_rotation(delta: float) -> void:
	var target_rot : float = soiderbottontexture.global_position.angle_to_point(mover.get_next_point())
	soiderbottontexture.rotation = rotate_toward(soiderbottontexture.rotation, target_rot, turn_speed * delta)
	
	for i in tops:
		var t: PhysicsBody2D = i.true_target
		if t == null:
			i.rotation = rotate_toward(i.rotation, target_rot, top_turn_speed * delta)          # 没目标 → 炮台保持当前朝向
			continue
			
		var top_target_rot : float = i.global_position.angle_to_point(t.global_position)
		i.rotation = rotate_toward(i.rotation, top_target_rot, turn_speed * delta)

func _on_body_entered(body : Node2D) -> void:
	if not (body is Bullet):
		return
	
	var bullet : Bullet = body
	if not bullet.is_physics_processing() :
		return
	
	# 射手可能已经死了（子弹还在飞）：失效的 shooter 引用读出来是 Nil，先防御
	var shooter := bullet.shooter
	if shooter == null or not is_instance_valid(shooter):
		return
	
	if tops.has(shooter):
		return
	# 自己阵营的子弹不掉血
	if shooter.soider.get_squad_id() == get_squad_id():
		return
	
	var value : float = bullet.get_attack_value()
	bullet.return_to_pool()
	take_damage(value)
	updata_health_bar()

func updata_health_bar() -> void:
	health_progress_bar.value = float(current_health / bott_res.max_health) * 100
