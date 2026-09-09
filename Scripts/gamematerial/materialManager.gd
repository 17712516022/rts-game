extends Node
## 资源管理器（全局单例）：按阵营分账管理五种资源（金币、食物、木材、矿产、人口）。
## squads_material 字典是唯一数据源，所有改动都从这里读，
## 通过 spend_material / receive_material 写（必须带 squad），写完后发射 material_changed
## 信号（带 squad）通知 UI，UI 只认自己阵营的变动。
## 人口/税收的月度自然增长单独在 MonthlyMaterialCalculator 脚本里（职责单一）。
## 注意：以后新增 Team 时，记得同步 TeamData.ALL_TEAMS 和下方的初始账户。

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
	# 敌人账户先全 0 起步：避免空字典导致 has() 断言崩；初始资金等 AI 势力实现时由外部注入
	TeamData.Team.ENEMY : {
		MATERIAL.GOLD : 0.0,
		MATERIAL.FOOD : 0.0,
		MATERIAL.WOOD : 0.0,
		MATERIAL.MINE : 0.0,
		MATERIAL.POPULATION : 0.0,
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
