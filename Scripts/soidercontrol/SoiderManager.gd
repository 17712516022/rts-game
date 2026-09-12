extends Node2D

var soider_selecting : Array

# 选中圈样式：画在自身 _draw 里，0 子节点、0 额外脚本
const RING_RADIUS : float = 24.0
const RING_COLOR : Color = Color(0.9, 0.2, 0.2)
const RING_WIDTH : float = 3.0

func _ready() -> void:
	# autoload 比主场景先挂到树、默认会被场景内容盖住，抬高层级保证圈在最上层
	z_index = 1

func add_to_selecting_soider(soider : SoiderBottom) -> void:
	# 去重：同一只士兵已在选中列表里就不重复加入
	if soider_selecting.has(soider):
		return
	soider_selecting.append(soider)

func delete_from_selecting_soider(soider : SoiderBottom) -> void:
	soider_selecting.erase(soider)

func get_current_soiders() -> Array:
	return soider_selecting

func _process(_delta: float) -> void:
	# 士兵移动时圈要跟着走，每帧重画（顺便覆盖“列表清空后清掉旧圈”）
	queue_redraw()

func _draw() -> void:
	# autoload 挂在 root 下没有父变换：本地坐标 == 世界坐标，直接用 global_position 画
	for soider in soider_selecting:
		draw_arc(soider.global_position, RING_RADIUS, 0.0, TAU, 64, RING_COLOR, RING_WIDTH, true)
		
		for i in soider.tops:
			var top : SoiderTop = i
			draw_circle(top.global_position, top.top_res.attack_range, Color(1,1,1), false, 1, true)

func get_soider_count(container : Node2D,squad : int) -> int:
	var count : int = 0
	var children : Array = container.get_children()
	for i in children:
		var child : SoiderBottom = i
		if child.get_squad_id() == squad:
			count += 1
	return count

func get_soiders(container : Node2D,squad : int) -> Array:
	var result : Array = []
	for  i in container.get_children():
		var child : SoiderBottom = i
		if child.get_squad_id() == squad : 
			result.append(child)
	
	return result
