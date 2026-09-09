class_name ConstructionResource extends Resource

@export var name : String
## 种类标识：每类建筑的唯一稳定标识（如"行政中心""农场"）。
## 判断建筑类型一律比对它，不要用资源引用 == 模板常量——
## 建造时 ConstructionFactory 会给每栋建筑 duplicate() 一份配置，副本引用永远不比中模板。
@export var display_name : String = ""

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

## 静态：算实际建造时间 = base × (1/ConstructModifier) × policy_modifier
## ConstructModifier 是"建造速度"（越高越快），取倒数转成"时间修正"（越高越慢）
## 任何地方都能调：Construction.gd 实例化时、ConstructionDiscription 面板显示时
static func calculate_build_time(base_time: float, terrain: MapData.TERRAIN, policy_modifier: float = 1.0) -> float:
	var construct_mod: float = ModifierData.Modifiers[terrain]["ConstructModifier"]
	# 防御：construct_mod <= 0 表示不能建（海洋等），理论上游上层已挡，兜底返回 base
	if construct_mod <= 0.0:
		return base_time
	var terrain_modifier := 1.0 / construct_mod
	return base_time * terrain_modifier * policy_modifier

## 静态：算实际产出 = base_value × 地形修正 × 政策修正
## 地形修正按材料类型从 ModifierData 取（金→GoldModifier, 食→FoodModifier, 矿→ProductionModifier, 木→1.0）
static func calculate_output(base_value: float, material: MaterialManager.MATERIAL, terrain: MapData.TERRAIN, police_modifier: float = 1.0) -> float:
	var terrain_mod := _terrain_output_modifier(material, terrain)
	return base_value * terrain_mod * police_modifier

## 静态私有：按材料类型 + 地形查产出系数（从 OutputProductor 搬来的 match 逻辑）
static func _terrain_output_modifier(material: MaterialManager.MATERIAL, terrain: MapData.TERRAIN) -> float:
	match material:
		MaterialManager.MATERIAL.GOLD:
			return ModifierData.Modifiers[terrain]["GoldModifier"]
		MaterialManager.MATERIAL.FOOD:
			return ModifierData.Modifiers[terrain]["FoodModifier"]
		MaterialManager.MATERIAL.MINE:
			return ModifierData.Modifiers[terrain]["ProductionModifier"]
		MaterialManager.MATERIAL.WOOD:
			return 1.0
	return 1.0
