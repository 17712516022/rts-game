extends Node

enum MATERIAL {
	GOLD, FOOD, WOOD, MINE,POPULATION
}

## 材料 → 中文显示名（UI / 浮动文字 / 面板描述统一用这里，不要再各写一份 match）
const MATERIAL_NAMES : Dictionary = {
	MATERIAL.GOLD : "金币",
	MATERIAL.FOOD : "食物",
	MATERIAL.WOOD : "木材",
	MATERIAL.MINE : "矿石",
	MATERIAL.POPULATION : "人口",
}

var START_MATERIAL : Dictionary = {
	TeamData.Team.PLAYER : {
		MATERIAL.GOLD : 15000.0,
		MATERIAL.FOOD : 100.0,
		MATERIAL.WOOD : 100.0,
		MATERIAL.MINE : 50.0,
		MATERIAL.POPULATION : 100.0,
	},
	TeamData.Team.ENEMY : {
		MATERIAL.GOLD : 300.0,
		MATERIAL.FOOD : 300.0,
		MATERIAL.WOOD : 300.0,
		MATERIAL.MINE : 300.0,
		MATERIAL.POPULATION : 1000.0,
	},
}

var squads_material : Dictionary = {}

func _ready() -> void:
	# 深拷贝一份初始账户：直接赋值会让所有实例共享同一份字典引用
	for squad in START_MATERIAL:
		squads_material[squad] = START_MATERIAL[squad].duplicate()

# 读取某种资源的当前数量
func get_material_number(material : MATERIAL , squad : TeamData.Team) -> float:
	assert(squads_material[squad].has(material) , "出错了")
	return squads_material[squad][material]

# 花费资源：从现有数量里扣掉 value，数量最低扣到 0
func spend_material(material : MATERIAL , value : float,squad : TeamData.Team) -> void :
	assert(squads_material[squad].has(material) , "出错了")
	squads_material[squad][material] = maxf(0.0, squads_material[squad][material] - value)
	EventBus.material_changed.emit(material, squads_material[squad][material], squad)

# 获得资源：在现有数量上加 value
func receive_material(material : MATERIAL ,value : float , squad : TeamData.Team) -> void :
	assert(squads_material[squad].has(material) , "出错了")
	squads_material[squad][material] += value
	EventBus.material_changed.emit(material, squads_material[squad][material], squad)

func can_spend(material : MATERIAL ,value : float,squad : TeamData.Team) -> bool:
	assert(squads_material[squad].has(material) , "出错了")
	# 余额刚好等于花费也允许（花完正好变 0，和 spend_material 的 maxf 行为一致）
	return squads_material[squad][material] - value >= 0


## 能不能付得起这份账单（不扣钱，用于按钮置灰 / 预览）
func can_afford(costs : Dictionary, squad : TeamData.Team) -> bool:
	for material in costs:
		if costs[material] <= 0.0:
			continue
		if not can_spend(material, costs[material], squad):
			return false
	return true

## 尝试支付：付得起才扣，返回是否成功。失败时账户不变。
func try_spend(costs : Dictionary, squad : TeamData.Team) -> bool:
	if not can_afford(costs, squad):
		return false
	for material in costs:
		if costs[material] <= 0.0:
			continue
		spend_material(material, costs[material], squad)
	return true

## 材料枚举 -> 中文名（越界/未知返回 "未知"）
func material_name(material : MATERIAL) -> String:
	return MATERIAL_NAMES.get(material, "未知")

## 把 {MATERIAL: value} 拼成 "金币 100  木材 50"；空字典返回 fallback
func costs_to_text(costs : Dictionary, fallback : String = "无") -> String:
	if costs.is_empty():
		return fallback
	var parts : Array = []
	for material in costs:
		if costs[material] <= 0.0:
			continue
		parts.append("%s %.0f" % [material_name(material), costs[material]])
	return "无" if parts.is_empty() else "  ".join(parts)
