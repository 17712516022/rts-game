class_name Construction extends StaticBody2D

@onready var construction_texture: Sprite2D = %ConstructionTexture
@onready var builder_animation: BuilderAnimation = %BuilderAnimation
@onready var spawn_soider_animation: SpawnSoiderAnimation = %SpawnSoiderAnimation
@onready var output_productor: OutputProductor = %OutputProductor
@onready var floating_label_pool: FloatingLabelPool = %FloatingLabelPool
@onready var squad: Squad = $Squad
@onready var construction_hurt_box: Area2D = %ConstructionHurtBox
@onready var construction_progress_bar: TextureProgressBar = %ConstructionProgressBar
@onready var spawn_soider_progress_bar: TextureProgressBar = %SpawnSoiderProgressBar

## 对外暴露阵营：与部队同 squad 时，这栋建筑对那支部队不挡路
## 注意：读取可以在此转发，写入阵营统一走 $Squad.set_team_id（Squad 组件管自己的阵营）
func get_squad_id() -> int:
	return squad.get_squad() if squad != null else -1
	
## 是不是行政中心（中心是"势力心脏"：被打到 0 不消失，而是易手换主）
func is_center() -> bool:
	return res != null and res.is_center_kind()

## 中心易手后的免伤时长（毫秒）：防止刚易手立刻被旧主力反复夺回（演示期保护，后续做正式占领玩法可删）
const CAPTURE_INVULN_MS := 3000
var _capture_until_ms := 0

var health : float
var max_health : float

## 本建筑的配置（由 set_resource 注入）
var res : ConstructionResource
## 本建筑所在格子的地形
var terrain : MapData.TERRAIN
## 建筑所在格子，由建造管理器实例化时设置（用于反查地形）
var cell : Vector2i = Vector2i(-1, -1)

var owner_center = null
## 政策建造时间修正（将来接政策系统，>1 = 建造更慢，<1 = 更快），占位 1.0
var policy_modifier: float = 1.0

## 对外暴露：是否在建造中（查 Builder）
var is_under_construction: bool:
	get:
		return builder_animation != null and builder_animation.is_building
## 对外暴露：剩余建造时间（秒），查 Builder
var remaining_build_time: float:
	get:
		return builder_animation.remaining_time if builder_animation != null else 0.0
var is_spawn_army : bool :
	get :
		return spawn_soider_animation.visible == true

func _ready() -> void:
	construction_hurt_box.body_entered.connect(_on_bullet_entered)
	
	# 配置或格子没就绪就跳过（编辑器预览等场景下不会正常建造）
	if res == null or cell.x < 0 or cell.y < 0 or MapData.terrain_grid.is_empty():
		return
	
	terrain = MapData.terrain_grid[cell.x][cell.y]
	construction_texture.texture = res.texture
	construction_texture.visible = true
	max_health = res.health
	health = res.health
	
	# 实际建造时间 = base × (1/ConstructModifier) × policy_modifier
	# 计算逻辑统一放在 ConstructionResource.calculate_build_time 静态方法
	builder_animation.build_finished.connect(_complete_building)
	builder_animation.start(construction_texture, ConstructionResource.calculate_build_time(res.time, terrain, policy_modifier))

# 建造结束：给产出器注入配置 + 地形，从这一刻起 month_passed 触发才会真正产出资源
# （建造中 SetUp 没调，construction_res 还是 null，_product 首行 null 守卫直接 return，不会乱产出）
func _complete_building() -> void:
	EventBus.construct_building.emit(res, cell)
	output_productor.SetUp(res, terrain,floating_label_pool,self)

# 唯一入口：外部传入已准备好的 ConstructionResource（.tres 或工厂造好的副本）
func set_resource(construction_res : ConstructionResource) -> void:
	res = construction_res

func updata_health_bar() -> void:
	construction_progress_bar.value = float(health / max_health) * 100

func _on_bullet_entered(body : Node2D ) -> void :
	if not (body is Bullet):
		return
	
	var bullet : Bullet = body as Bullet
	if not bullet.is_physics_processing() :
		return
	
	# 射手可能已死（子弹还在飞）：失效引用读出来是 Nil，先防御再取阵营
	var shooter := bullet.shooter
	if shooter == null or not is_instance_valid(shooter) \
			or not is_instance_valid(shooter.soider):
		return
	# 友军子弹不掉血（同阵营的兵打自己的建筑会白忙）
	var attacker_squad: int = shooter.soider.get_squad_id()
	if attacker_squad == get_squad_id():
		return
	
	var value : float = bullet.get_attack_value()
	bullet.return_to_pool()
	take_damage(value, attacker_squad)
	updata_health_bar()

# 受伤：交给伤害计算器算最终伤害，再扣血。
# attacker_squad：谁打的（-1 = 无主伤害，如陷阱；中心易手靠它决定换给谁）
func take_damage(amount: float, attacker_squad: int = -1) -> void:
	# 中心刚易手有短暂免伤，避免立刻被旧主力反复夺回
	if is_center() and Time.get_ticks_msec() < _capture_until_ms:
		return
	
	var actual : float = DamageCalculator.calculate(amount, 0)
	health -= actual
	if health > 0.0:
		return
	
	# 中心被打到 0：不消失，而是易手给攻击方，整片势力随它换主
	if is_center() and attacker_squad >= 0 and attacker_squad != get_squad_id():
		_capture_by(attacker_squad)
		return
	_die()

## 中心易手：换阵营、回满血、广播全图刷新
func _capture_by(new_squad: int) -> void:
	# 先按旧阵营从索引移除，换阵营后再按新阵营登记（易手是"迁移"，不是新增）
	ConstructionData.unindex_building(self)
	squad.set_team_id(new_squad)
	health = res.health if res != null else health
	_capture_until_ms = Time.get_ticks_msec() + CAPTURE_INVULN_MS
	updata_health_bar()
	ConstructionData.index_building(self)
	EventBus.team_refresh_requested.emit()

# 死亡：从场景树移除
func _die() -> void:
	var self_pos : Vector2i = PositionCaculater.calculate_cell(global_position)
	ConstructionData.building_grid[self_pos.x][self_pos.y] = null
	# 中心被打死（无主伤害等不走易手的路径）：必须先广播让 CenterOwnershipManager 清掉
	# 它辖下所有格子的归属并重填，再 queue_free。owner_grid 存的是中心节点引用，
	# 顺序反了会残留 freed 引用（节点先释放，grid 里还指向它）。
	if is_center():
		EventBus.center_destroyed.emit(self)
	ConstructionData.unindex_building(self)
	queue_free()
