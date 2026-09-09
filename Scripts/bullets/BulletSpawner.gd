class_name BulletSpawner extends Marker2D

@onready var bullets_pool: BulletsPool = %BulletsPool

func create_bullet(dirction : Vector2 ,shooter : SoiderTop) -> void:
	bullets_pool.create_bullet(self.global_position,dirction,shooter)
