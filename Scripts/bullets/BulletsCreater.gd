class_name BulletsPool extends Node

const MAX_BULLETS_COUNT : int = 8
const BULLET = preload("uid://qw4t8tq0aitv")

#对象池
var _pool : Array[Bullet] = []

func _ready() -> void:
	for i in range(MAX_BULLETS_COUNT):
		InitBullet()

func InitBullet() -> void:
	var bullet : Bullet = BULLET.instantiate()
	bullet.set_physics_process(false)
	bullet.hide()
	bullet.SetUp(self)
	
	add_child(bullet)
	
	_pool.append(bullet)

func create_bullet(start : Vector2,dirction : Vector2 ,shooter : SoiderTop) -> void:
	if _pool.is_empty():
		InitBullet()
		
	var bullet : Bullet = _pool.pop_back()
	bullet.be_shoot(start,dirction,shooter)

func return_to_pool(bullet : Bullet) -> void:
	bullet.set_physics_process(false)
	bullet.velocity = Vector2.ZERO
	bullet.hide()
	_pool.append(bullet)
