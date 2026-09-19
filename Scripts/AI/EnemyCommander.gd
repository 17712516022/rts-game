class_name EnemyCommander extends Node

const TIME_WAIT_TIME : float = 5.0

# —— 各资源"低于这个数就去补对应建筑"的门槛（想调策略改这里）——
const GOLD_LOW : float = 300.0   # 敌人初始金 1000
const MINE_LOW : float = 300.0   # 敌人初始矿 1000
const WOOD_LOW : float = 300.0   # 敌人初始木 1000 
const GOLD_HIGH : float = 600.0

var squad : TeamData.Team = TeamData.Team.ENEMY
var construction_manager : ConstructionManager
var start_cell : Vector2i
var centres : Array = []            # 已完工的自己的行政中心格子

var root : BTSequnce                # 决策树的根：补建 → 攻击 → 设计，尽力全部推完

@onready var constrution_container : Node2D = %ConstrutionContainer
@onready var soider_container: Node2D = %SoiderContainer

func _ready() -> void:
	EventBus.game_ready.connect(_on_game_ready, CONNECT_ONE_SHOT)
	EventBus.construct_building.connect(_on_building_down)
	EventBus.team_refresh_requested.connect(_on_center_changed)

func _on_game_ready() -> void:
	start_cell = AiTools.find_start_cell()
	# 建造管理器：必须挂到场景树 + 注入容器，否则内部 add_child 崩
	construction_manager = ConstructionManager.new()
	add_child(construction_manager)
	construction_manager.SetUp(constrution_container)
	
	_build_tree()
	AiTools.build_first_center(construction_manager , start_cell  ,squad )
	
	var timer := Timer.new()
	timer.wait_time = TIME_WAIT_TIME
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_tick)

# 每 2 秒：往 ctx 小黑板填三种资源 + 兵力 + 叶子依赖 → 跑整棵树
func _on_tick() -> void:
	var ctx := {
		"gold": MaterialManager.get_material_number(MaterialManager.MATERIAL.GOLD, squad),
		"gold_threshold": GOLD_LOW,
		"build_new_center_gold" : GOLD_HIGH * centres.size(),
		"mine": MaterialManager.get_material_number(MaterialManager.MATERIAL.MINE, squad),
		"mine_threshold": MINE_LOW,
		"wood": MaterialManager.get_material_number(MaterialManager.MATERIAL.WOOD, squad),
		"wood_threshold": WOOD_LOW,
		"food": MaterialManager.get_material_number(MaterialManager.MATERIAL.FOOD, squad),
		"food_threshold": MaterialManager.get_material_number(MaterialManager.MATERIAL.POPULATION , squad),
		"my_army_count" : SoiderManager.get_soider_count(soider_container,squad),
		"others_army_count" : SoiderManager.get_soider_count(soider_container,TeamData.Team.PLAYER),
		# —— 给动作叶子提供的依赖 ——
		"construction_manager" : construction_manager,
		"centres" : centres,
		"squad" : squad,
		"start_cell" : start_cell,
		"armys" : SoiderManager.get_soiders(soider_container,squad)
	}
	root.tick(ctx)

func _build_tree() -> void:
	root = BTSequnce.new()

	# —— 阶段① 补建：随机挑一种缺的资源补上；全都不缺 → 末尾 BTPass 放行 ——
	var build_stage := BTRandomSelector.new()
	build_stage.add(_build_branch("gold", ConstructionData.Constructions.RESIDENT)) # 缺金 → 民居(产金)
	build_stage.add(_build_branch("mine", ConstructionData.Constructions.MINE))     # 缺矿 → 矿井(产矿)
	build_stage.add(_build_branch("wood", ConstructionData.Constructions.TREE))     # 缺木 → 林场(产木)
	build_stage.add(_build_branch("food", ConstructionData.Constructions.FARM))     # 缺食物 → 农场(产食物)
	build_stage.add(BTCheckDistance.new("build_new_center_gold","gold" ).add(AIBuild.new(ConstructionData.Constructions.LOWERCENTER)))
	build_stage.add(BTPass.new())
	root.add(build_stage)
	# —— 阶段② 攻击：敌方 < 我方 → 出兵；我方不占优 → 放行给设计 ——
	root.add(_attack_stage())
	# —— 阶段③ 设计：顺序设计底盘 → 炮台 ——
	root.add(_design_stage())

## 攻击检查：敌方数量 < 我方数量（我方占优）→ 出兵；否则 BTPass 放行。
func _attack_stage() -> BTSelector:
	var stage := BTSelector.new()
	var checker : BTCheckDistance = BTCheckDistance.new("others_army_count", "my_army_count")
	checker.add(AIAttack.new())                       # 默认打玩家
	stage.add(checker)
	stage.add(BTPass.new())
	return stage

## 设计阶段：先设计底盘，成功后才继续设计炮台。
func _design_stage() -> BTSequnce:
	var design_sequnce : BTSequnce = BTSequnce.new()
	design_sequnce.add(AIDesign.new())
	return design_sequnce

## 资源门槛装饰：ctx 里该资源 < 门槛 → 交给 AIBuild 去补这栋建筑
func _build_branch(res_key : String, building_type : ConstructionData.Constructions) -> BTCheckDistance:
	var checker : BTCheckDistance = BTCheckDistance.new(res_key, res_key + "_threshold")
	checker.add(AIBuild.new(building_type))
	return checker

func _on_building_down(building_type : ConstructionResource, cell_pos : Vector2i ,) -> void:
	AiTools.refresh_centres(building_type , cell_pos , centres , squad)

func _on_center_changed() -> void:
	AiTools.on_center_changed(centres,squad)
