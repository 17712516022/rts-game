class_name TargetMarker extends Sprite2D

## 当前锁定的目标：士兵和建筑都行，两者都提供 get_squad_id()
var target : Node2D

var _tween : Tween

func _ready() -> void:
	freeze()
	
	EventBus.soider_right_clicked.connect(_try_lock)
	EventBus.building_right_clicked.connect(_try_lock)

## 统一入口：兵/建筑右键都走这里，只在"选中了兵 + 目标是敌方"时才标
func _try_lock(p_entity : Node2D) -> void:
	if p_entity == null or not is_instance_valid(p_entity):
		return
	# 右键的本质是给选中的兵下令，没选兵就不存在锁定
	if SoiderManager.soider_selecting.is_empty():
		return
	if p_entity.get_squad_id() == TeamData.Team.PLAYER:
		return
	
	play(p_entity)

func fresh() -> void:
	scale = Vector2(2,2)

func play(p_entity : Node2D) -> void:
	# 多只兵一起开会各发一次同样的信号：同一目标已在标就不重播，省掉一堆抢 scale 的 tween
	if target == p_entity and visible:
		return
	fresh()
	set_process(true)
	target = p_entity
	show()
	global_position = target.global_position
	# 换目标时收掉上一根还没跑完的缩放 tween，避免两根同时写 scale
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self , "scale" , Vector2(1,1),0.6)

func _process(delta: float) -> void:
	# 目标没了（被打死 queue_free）或中心易手归了自己，锁定就不再成立
	if not is_instance_valid(target) or target.get_squad_id() == TeamData.Team.PLAYER:
		freeze()
		return
	rotation += delta * PI / 3
	global_position = target.global_position

func freeze() -> void:
	hide()
	set_process(false)
