class_name ConstructionResource extends Resource

@export var name : String
## 种类标识：每类建筑的唯一稳定标识（如"行政中心""农场"）。
## 判断建筑类型一律比对它，不要用资源引用 == 模板常量——
## 建造时 ConstructionFactory 会给每栋建筑 duplicate() 一份配置，副本引用永远不比中模板。
@export var display_name : String = ""

## 建筑简介：面板里展示给玩家的一句话说明
@export_multiline var description : String = ""

## 是不是行政中心类建筑（行政中心 / 次级行政中心都会划领地、可易手）
func is_center_kind() -> bool:
	return display_name == "行政中心" or display_name == "次级行政中心"
## 建造所需时间（秒）
@export var time: float
## 建筑生命值
@export var health: float

# ————— 建造消耗（检查器里直接看到名字，可读性比字典好）—————
@export var cost_gold: float = 0.0
@export var cost_food: float = 0.0
@export var cost_wood: float = 0.0
@export var cost_mine: float = 0.0

# ————— 每回合产出（同上）—————
@export var output_gold: float = 0.0
@export var output_food: float = 0.0
@export var output_wood: float = 0.0
@export var output_mine: float = 0.0

##建筑的纹理
@export var texture : Texture2D

## 运行时使用：拿到 MaterialManager.MATERIAL 枚举做 key 的消耗字典。
## 不传 value = 0 的条目，方便上层 for 循环只遍历实际有值的材料。
func resource_cost_enum() -> Dictionary:
	var result := {}
	if cost_gold > 0.0:
		result[MaterialManager.MATERIAL.GOLD] = cost_gold
	if cost_food > 0.0:
		result[MaterialManager.MATERIAL.FOOD] = cost_food
	if cost_wood > 0.0:
		result[MaterialManager.MATERIAL.WOOD] = cost_wood
	if cost_mine > 0.0:
		result[MaterialManager.MATERIAL.MINE] = cost_mine
	return result

## 运行时使用：拿到 MaterialManager.MATERIAL 枚举做 key 的产出字典
func output_enum() -> Dictionary:
	var result := {}
	if output_gold > 0.0:
		result[MaterialManager.MATERIAL.GOLD] = output_gold
	if output_food > 0.0:
		result[MaterialManager.MATERIAL.FOOD] = output_food
	if output_wood > 0.0:
		result[MaterialManager.MATERIAL.WOOD] = output_wood
	if output_mine > 0.0:
		result[MaterialManager.MATERIAL.MINE] = output_mine
	return result

## 静态：算实际建造时间 = base × 建造时间修正 × policy_modifier
## 地形基值 + 政策/事件等各层修正统一由 FinalModifierCalculator 合成。
## ConstructModifier 是"建造速度"（越高越快），所以取 1/速度 转成"时间修正"（越高越慢）。
## 任何地方都能调：Construction.gd 实例化时、ConstructionDiscription 面板显示时
static func calculate_build_time(base_time: float, terrain: MapData.TERRAIN, policy_modifier: float = 1.0) -> float:
	var time_modifier := FinalModifierCalculator.build_time_multiplier(terrain)
	# 防御：不能建的地形（海洋/河流等）返回 INF，上游本该已挡，这里退回 base 免得算出 Inf
	if not is_finite(time_modifier):
		return base_time
	return base_time * time_modifier * policy_modifier

## 静态：算实际产出 = base_value × 最终产出修正 × policy_modifier
## 产出修正按材料类型查（金→GoldModifier, 食→FoodModifier, 矿→ProductionModifier, 木→WoodModifier），
## 地形基值 × 政策/事件等各层修正都由 FinalModifierCalculator 合成，调用方不再自己乘
static func calculate_output(base_value: float, material: MaterialManager.MATERIAL, terrain: MapData.TERRAIN, police_modifier: float = 1.0) -> float:
	var output_modifier := FinalModifierCalculator.output_factor(material, terrain)
	return base_value * output_modifier * police_modifier
