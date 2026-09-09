class_name MonthlyMaterialCalculator extends Node
## 人口自然增长：每月过月触发，给 MaterialManager.POPULATION 增加一部分。
## 职责单一：只管"每月涨多少人口"——算值 + 调用资源系统入账。
## 通过 main.tscn 挂节点进场景树，_ready 自动连 month_passed 信号。

const BASE_PERCENT : float = 0.01
const BASE_TAX : float = 0.1

## 政策修正（>1 = 增长更快，<1 = 增长更慢）
var popu_policy_modifier: float = 1.0
var tax_policy_modifier: float = 1.0
## 其他修正（事件/建筑buff等）
var popu_other_modifier: float = 1.0
var tax_other_modifier: float = 1.0

func _ready() -> void:
	EventBus.month_passed.connect(_on_month_passed)

func _on_month_passed(squad : TeamData.Team) -> void:
	var population: float = MaterialManager.get_material_number(MaterialManager.MATERIAL.POPULATION , squad)
	spend_food(population,squad)
	get_gold(population,squad)
	boost_population(population,squad)
	
func boost_population(population : int,squad : TeamData.Team) -> void:
	var percent: float = BASE_PERCENT * popu_policy_modifier * popu_other_modifier
	var growth : int = roundi(population * percent)
	MaterialManager.receive_material(MaterialManager.MATERIAL.POPULATION, float(growth),squad)
	
func spend_food(population : int,squad : TeamData.Team) -> void:
	var cost : int = min(population,MaterialManager.get_material_number(MaterialManager.MATERIAL.FOOD,squad))
	MaterialManager.spend_material(MaterialManager.MATERIAL.FOOD,cost,squad)
	
func get_gold(population : int,squad : TeamData.Team) -> void:
	var percent : float = BASE_TAX * tax_policy_modifier * tax_other_modifier
	var income : int = roundi(population * percent)
	MaterialManager.receive_material(MaterialManager.MATERIAL.GOLD, float(income),squad)
