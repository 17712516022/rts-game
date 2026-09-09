extends Node

enum MATERIAL {
	GOLD, FOOD, WOOD, MINE,POPULATION
}

var squads_material : Dictionary = {
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
