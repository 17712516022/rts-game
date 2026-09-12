class_name MonthlyMaterialCalculator extends Node
## 每月经济结算：收税 → 吃饭 → 人口增减。
## TimeManager 每月为每个阵营各广播一轮，本节点每轮只结算被广播的那个阵营
## （收入/扣费全部落在 squad 自己的账户上，玩家和 AI 走同一套规则）。
## 挂 main.tscn，_ready 自动连 month_passed。
##
## 结算顺序：先收税、再吃饭。收税在前，避免"账上明明有钱却饿死"的观感。
## 注意本节点是延后（call_deferred）结算的，见 _on_month_passed。

# ————— 可调平衡常数（调经济就改这一段）—————
## 每人每月口粮消耗。人口 100 → 每月吃 10 食物
const FOOD_PER_POP : float = 0.1
## 每人每月税收（金币）
const BASE_TAX : float = 0.1
## 人口自然增长率（有粮、且未到人口上限时才生效）
const BASE_PERCENT : float = 0.01
## 每缺 1 食物饿死多少人
const STARVE_PER_FOOD : float = 2.0
## 单月饿死人数上限（占总人口比例）：防止一次饥荒直接灭族
const MAX_STARVE_RATIO : float = 0.05
## 基础人口上限（一栋民居都不造也能养活的人口）
const BASE_POP_CAP : float = 100.0
## 每栋民居额外提供的人口上限：想涨人口就得造民居
const POP_PER_RESIDENT : float = 15.0
## 民居的 display_name（和 Resident.tres 保持一致）
const RESIDENT_NAME : String = "民居"

## 政策修正（>1 = 增长更快 / 收得更多，<1 = 更慢 / 更少）
var popu_policy_modifier: float = 1.0
var tax_policy_modifier: float = 1.0
## 其他修正（事件 / 建筑 buff 等）
var popu_other_modifier: float = 1.0
var tax_other_modifier: float = 1.0

func _ready() -> void:
	EventBus.month_passed.connect(_on_month_passed)

func _on_month_passed(squad : TeamData.Team) -> void:
	# 延后到本帧末尾再结算：month_passed 是同步广播，各建筑的产出（OutputProductor）
	# 会在同一轮信号里先后入账。如果本节点抢在前面结算，本月刚收的粮就来不及吃，
	# 农场等于白建。call_deferred 保证"所有产出都入账之后"才吃饭/收税。
	_settle.call_deferred(squad)

func _settle(squad : TeamData.Team) -> void:
	_settle_tax(squad)
	_settle_food(squad)

## 收税：人口是钱袋子（也是嘴），所以人口既是收入来源也是粮食负担
func _settle_tax(squad : TeamData.Team) -> void:
	var population := MaterialManager.get_material_number(MaterialManager.MATERIAL.POPULATION, squad)
	if population <= 0.0:
		return
	var income : int = roundi(population * BASE_TAX * tax_policy_modifier * tax_other_modifier)
	if income != 0:
		MaterialManager.receive_material(MaterialManager.MATERIAL.GOLD, float(income), squad)

## 吃饭：吃得起就吃 + 人口增长；吃不起就吃光 + 饿死一部分（不再是"1 人吃 1 食"把粮食吃穿）
func _settle_food(squad : TeamData.Team) -> void:
	var population := MaterialManager.get_material_number(MaterialManager.MATERIAL.POPULATION, squad)
	if population <= 0.0:
		return
	var need : float = population * FOOD_PER_POP
	var have := MaterialManager.get_material_number(MaterialManager.MATERIAL.FOOD, squad)
	if have >= need:
		MaterialManager.spend_material(MaterialManager.MATERIAL.FOOD, need, squad)
		_grow_population(squad, population)
		return
	# 缺粮：有多少吃多少，差额折算成饿死人数
	MaterialManager.spend_material(MaterialManager.MATERIAL.FOOD, have, squad)
	_starve(squad, population, need - have)

## 人口增长：有粮才长，且不超过"民居撑起来的上限"（只压增长，不强制下降）
func _grow_population(squad : TeamData.Team, population : float) -> void:
	var cap := _population_cap(squad)
	if population >= cap:
		return
	var grow : float = population * BASE_PERCENT * popu_policy_modifier * popu_other_modifier
	grow = minf(grow, cap - population)
	var growth : int = roundi(grow)
	if growth > 0:
		MaterialManager.receive_material(MaterialManager.MATERIAL.POPULATION, float(growth), squad)

## 饥荒：按缺口饿死人，单月不超过总人口的 MAX_STARVE_RATIO
func _starve(squad : TeamData.Team, population : float, shortage : float) -> void:
	var starved : float = minf(shortage * STARVE_PER_FOOD, maxf(1.0, population * MAX_STARVE_RATIO))
	var deaths : int = roundi(starved)
	if deaths > 0:
		MaterialManager.spend_material(MaterialManager.MATERIAL.POPULATION, float(deaths), squad)

## 人口上限 = 基础上限 + 本方民居数量 × 每栋容纳
func _population_cap(squad : TeamData.Team) -> float:
	return BASE_POP_CAP + float(_count_own_buildings(squad, RESIDENT_NAME)) * POP_PER_RESIDENT

## 数一数全图属于 squad 且 display_name 匹配的建筑。
## 用 display_name 比对而不是资源引用 ==：建造时工厂 duplicate 过配置，副本引用永远比不中模板。
func _count_own_buildings(squad : TeamData.Team, building_name : String) -> int:
	var count : int = 0
	var grid : Array = ConstructionData.building_grid
	for row in grid:
		for building in row:
			if building == null or not is_instance_valid(building):
				continue
			if building.get_squad_id() != squad:
				continue
			var res = building.res
			if res != null and res.display_name == building_name:
				count += 1
	return count
