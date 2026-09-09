class_name ConstructionManager extends Node

## 建筑显示用的场景（挂在格子上的建筑节点）
const CONSTRUCTION_SCENE := preload("res://Scenes/construction.tscn")

## 建筑节点挂载的容器（一般传地图根节点下的一个 Node2D），由 SetUp 注入
var construction_container : Node2D
var construction_factory : ConstructionFactory = ConstructionFactory.new()

func SetUp(context_construction_container : Node2D) -> void:
	construction_container = context_construction_container

func try_build(cell: Vector2i, building_type: ConstructionData.Constructions, out_err: Array,squad : TeamData.Team) -> bool:
	# 检查地形能否建造（ConstructModifier <= 0 表示海洋等不能建）
	var terrain: MapData.TERRAIN = MapData.terrain_grid[cell.x][cell.y]
	var modifier: float = ModifierData.Modifiers[terrain]["ConstructModifier"]
	
	if modifier <= 0.0:
		out_err.append("该地形无法建造")
		return false
	
	# 行政中心自己不要求有归属（它就是开疆拓土建立归属的起点）
	var is_center: bool = (building_type == ConstructionData.Constructions.CENTER
		or building_type == ConstructionData.Constructions.LOWERCENTER)
	if not is_center and ConstructionData.owner_grid[cell.x][cell.y] == null:
		out_err.append("附近没有行政中心，无法建造")
		return false
	if ConstructionData.building_grid[cell.x][cell.y] != null:
		out_err.append("该格已有建筑")
		return false
	
	var res : ConstructionResource = construction_factory.create_new_construction(building_type)
	# 检查资源是否足够（can_spend 全过才能建）
	if not _check_cost(res, out_err,squad):
		return false
	# 扣资源
	_pay_cost(res,squad)
	# 放置建筑
	_spawn_building(cell, res, squad)
	return true

# 检查建造消耗：resource_cost_enum() 已经把 0 值过滤了，直接枚举 key
func _check_cost(resource: ConstructionResource, out_err: Array, squad : TeamData.Team) -> bool:
	var cost := resource.resource_cost_enum()
	for material in cost:
		if not MaterialManager.can_spend(material, cost[material],squad):
			out_err.append("资源不足")
			return false
	return true

# 实际扣资源
func _pay_cost(resource: ConstructionResource , squad : TeamData.Team) -> void:
	var cost := resource.resource_cost_enum()
	for material in cost:
		MaterialManager.spend_material(material, cost[material],squad)

# 在指定格子中心实例化一个建筑节点，把图标显示到地图上
# team：这栋建筑归哪个阵营（玩家 0，敌人 1...），默认玩家
func _spawn_building(cell: Vector2i, resource: ConstructionResource, team: int = TeamData.Team.PLAYER) -> void:
	var building: Construction = CONSTRUCTION_SCENE.instantiate()
	building.set_resource(resource)
	building.cell = cell
	# 放到格子中心（六边形的几何中心）
	building.position = PositionCaculater.calculate_position(cell.x, cell.y)
	# 挂到容器节点下，让建筑跟着地图一起被相机缩放平移
	construction_container.add_child(building)
	
	building.squad.set_team_id(team)
	
	ConstructionData.building_grid[cell.x][cell.y] = building
	
