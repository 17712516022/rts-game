class_name SoiderBottomResource extends Resource
## 底盘资源配置：定义士兵的生存/移动属性（生命、速度、防御、贴图）。

## 显示名称
@export var display_name: String

## 最大生命值
@export var max_health : float
## 移动速度（像素/秒）
@export var speed : float
## 防御力（减伤：最终伤害 = 攻击力 - 防御力，最低 1 点）
@export var defense : float = 0.0

## 主炮槽位：每个元素 = 一个槽位相对底盘原点 (0,0) 的偏移（世界单位）。
## 槽位数量 = 数组长度（不同底盘布局不同：单中置 / 左右双肩 / 品字三炮…都由它决定）。
## 装配时炮台节点落在 offsets[i] 处；顺序 = 面板槽位按钮顺序。
@export var turret_slot_offsets: Array[Vector2] = []

## 槽位数（= 可同时搭载的炮台数量）
func slot_count() -> int:
	return turret_slot_offsets.size()

# ————— 征召消耗（和 ConstructionResource 完全对称：逐项 export，检查器里直接看到名字）—————
@export var cost_gold: float = 0.0
@export var cost_food: float = 0.0
@export var cost_wood: float = 0.0
@export var cost_mine: float = 0.0
## 征召占用的人口（造兵会真的从人口池里扣，形成"军队 vs 经济"的取舍）
@export var cost_population: float = 0.0

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
	if cost_population > 0.0:
		result[MaterialManager.MATERIAL.POPULATION] = cost_population
	return result

## 士兵贴图
@export var bottom_texture: Texture2D
