class_name Bullet extends CharacterBody2D

## 脱靶兜底:飞行超过该时间仍未命中就销毁,防子弹永远飞下去
const MAX_LIFETIME := 3.0

var speed : float = 200.0
var dir : Vector2 = Vector2.ZERO
var attack_value : float = 0.0
var shooter : SoiderTop
var pool : BulletsPool

var _start : Vector2 = Vector2.ZERO   # 发射瞬间的世界坐标
var _t : float = 0.0                  # 已飞行时间

@onready var bullet_sprite_2d: Sprite2D = $BulletSprite2D

func _physics_process(delta: float) -> void:
	_t += delta
	# 绝对定位:位置 = 出生点 + 方向×已飞路程(世界坐标数学直线)。
	# 池挂在移动的兵身上,若用"当前位置 += 增量"会被父节点拖动 → 这里每帧覆盖成绝对坐标,弹道恒定
	global_position = _start + dir * speed * _t
	if _t > MAX_LIFETIME:
		pool.return_to_pool(self)

func SetUp(c_pool : BulletsPool) -> void:
	pool = c_pool

func be_shoot(start : Vector2,c_dir : Vector2 , c_shooter : SoiderTop,)  -> void:
	dir = c_dir
	shooter = c_shooter
	_start = start
	
	_t = 0.0
	global_position = start
	
	bullet_sprite_2d.texture = shooter.top_res.bullet_texture
	show()
	
	set_physics_process(true)
	if is_instance_valid(shooter) and shooter.top_res != null:
		attack_value = shooter.top_res.attack   # 开火瞬间定死伤害

func get_attack_value() -> float:
	return attack_value

func return_to_pool() -> void:
	if pool == null :
		return
	pool.return_to_pool(self)
