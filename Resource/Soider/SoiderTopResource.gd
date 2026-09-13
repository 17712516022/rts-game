class_name SoiderTopResource extends Resource
## 炮台资源配置：定义一种士兵的攻击属性、征召消耗和炮台贴图。
## .tres 文件放在 Resource/Soider/ 下，每种兵一个文件。
## 用法：兵营征召士兵时读取对应 .tres，配合 SoiderBottomResource（底盘配置）一起生成士兵。

## 显示名称
@export var display_name: String 

## 攻击力（每次攻击造成的伤害）
@export var attack: float
@export var attack_range: float 
@export var attack_coolingdown : float

# ————— 征召消耗（和 ConstructionResource 完全对称：逐项 export，检查器里直接看到名字）—————
@export var cost_gold: float = 0.0
@export var cost_food: float = 0.0
@export var cost_wood: float = 0.0
@export var cost_mine: float = 0.0
## 征召占用的人口（造兵会真的从人口池里扣，形成"军队 vs 经济"的取舍）
@export var cost_population: float = 0.0

@export var spawn_time : float = 0.0 

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
@export var top_texture: Texture2D
@export var bullet_texture: Texture2D
