class_name SoiderSpawner extends Node

const SOIDER_SCENE := preload("res://Scenes/soiderbottom.tscn")

var soider_fac : SoiderFactory = SoiderFactory.new()
## 士兵节点挂载的容器（场景预设 %SoiderContainer）
@onready var soider_container : Node2D = %SoiderContainer

func _ready() -> void:
	EventBus.spawn_soider.connect(_on_spawn_soider)

func _on_spawn_soider(turret_choices : Array, bottom : SoiderComponentData.BOTTOM, pos : Vector2) -> void:
	var src_building : Construction = _building_at(pos)
	if src_building == null or src_building.res == null or src_building.res.display_name != "兵营":
		return
	var squad : TeamData.Team = src_building.get_squad_id()
	
	var ress : Dictionary = soider_fac.get_designed_soider_res(turret_choices, bottom)
	if ress.is_empty():
		return
	
	var costs : Dictionary = SoiderDesign.merge_cost(ress["bottom"], ress["turrets"])
	if not MaterialManager.try_spend(costs, squad):
		return
	
	var bottom_node : SoiderBottom = SOIDER_SCENE.instantiate()
	bottom_node.SetUp(ress.bottom)
	# 逐槽装配：槽位 i 有炮就装进 Turret_i，空槽自动隐藏
	bottom_node.AssembleTurrets(ress.turrets)
	# 放到指定世界坐标
	bottom_node.position = pos
	# 继承出生格上建筑的 squad：兵从哪个建筑出来就归哪个阵营（寻路用它判断自家建筑不挡路）
	_inherit_spawn_squad(bottom_node, src_building)
	# 反算所在格子，写入 bottom_node.cell（寻路/移动后更新都靠它）
	bottom_node.cell = PositionCaculater.calculate_cell(pos)
	# 挂到容器下
	soider_container.add_child(bottom_node)
	
	src_building.spawn_soider_animation.start(ress.turrets,bottom_node)

## 世界坐标所在格上的建筑（没有 / 越界返回 null）
func _building_at(spawn_pos: Vector2) -> Construction:
	var cell := PositionCaculater.calculate_cell(spawn_pos)
	var grid: Array = ConstructionData.building_grid
	return grid[cell.x][cell.y] as Construction

## 出生点格子上有建筑 → 把它的 squad 写进士兵的 Squad 节点。
## 没 Squad 节点就保持场景默认值（不会报错）。
func _inherit_spawn_squad(bottom_node: SoiderBottom, src_building: Construction) -> void:
	var squad_node: Squad = bottom_node.get_node_or_null("Squad")
	if squad_node == null or src_building == null:
		return
	squad_node.squad = src_building.get_squad_id()
