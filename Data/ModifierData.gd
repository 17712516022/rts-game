extends Node

## ConstructModifier = 建造难度系数，1.0 最好建，越低越难，0.0 不能建。
## MoveSpeedModifier = 移动速度系数，1.0 正常速度，越低越慢，0.0 无法通行。
## FoodModifier   = 食物产出系数，平原农田高、沙漠雪地低。
## ProductionModifier = 产能系数，丘陵山地高（矿产）、平原低。
## GoldModifier   = 金币产出系数，沿海/沙漠高（贸易/集市），其他一般。

const Modifiers : Dictionary={
	# ===== 海洋（不能建造，不能通行；产出靠渔业） =====
	MapData.TERRAIN.DEEPSEE : {
		"ConstructModifier" : 0.0,
		"MoveSpeedModifier" : 0.0,
		"FoodModifier" : 0.0,
		"ProductionModifier" : 0.0,
		"GoldModifier" : 0.0,
	},
	MapData.TERRAIN.NORMALSEE : {
		"ConstructModifier" : 0.0,
		"MoveSpeedModifier" : 0.0,
		"FoodModifier" : 0.0,
		"ProductionModifier" : 0.0,
		"GoldModifier" : 0.1,
	},
	MapData.TERRAIN.CLOSESEE : {
		"ConstructModifier" : 0.0,
		"MoveSpeedModifier" : 0.0,
		"FoodModifier" : 0.0,
		"ProductionModifier" : 0.0,
		"GoldModifier" : 1.5,
	},
	# ===== 平原（食物高，好建好走） =====
	MapData.TERRAIN.FOREST_PLAIN : {
		"ConstructModifier" : 0.8,
		"MoveSpeedModifier" : 0.8,
		"FoodModifier" : 1.0,
		"ProductionModifier" : 0.6,
		"GoldModifier" : 0.8,
	},
	MapData.TERRAIN.SAND_PLAIN : {
		"ConstructModifier" : 0.6,
		"MoveSpeedModifier" : 0.7,
		"FoodModifier" : 0.2,
		"ProductionModifier" : 0.5,
		"GoldModifier" : 0.5,
	},
	MapData.TERRAIN.PLAIN : {
		"ConstructModifier" : 1.0,
		"MoveSpeedModifier" : 1.0,
		"FoodModifier" : 1.0,
		"ProductionModifier" : 1.0,
		"GoldModifier" : 1.0,
	},
	MapData.TERRAIN.SNOW_PLAIN : {
		"ConstructModifier" : 0.5,
		"MoveSpeedModifier" : 0.5,
		"FoodModifier" : 0.2,
		"ProductionModifier" : 0.2,
		"GoldModifier" : 0.5,
	},
	# ===== 山地（高产能，低食物） =====
	MapData.TERRAIN.FOREST_MOUNT : {
		"ConstructModifier" : 0.5,
		"MoveSpeedModifier" : 0.3,
		"FoodModifier" : 0.5,
		"ProductionModifier" : 1.2,
		"GoldModifier" : 0.5,
	},
	MapData.TERRAIN.MOUNT : {
		"ConstructModifier" : 0.6,
		"MoveSpeedModifier" : 0.45,
		"FoodModifier" : 0.6,
		"ProductionModifier" : 1.1,
		"GoldModifier" : 0.6,
	},
	MapData.TERRAIN.SNOW_MOUNT : {
		"ConstructModifier" : 0.3,
		"MoveSpeedModifier" : 0.25,
		"FoodModifier" : 0.3,
		"ProductionModifier" : 0.8,
		"GoldModifier" : 0.3,
	},
	MapData.TERRAIN.HIGHERMOUNT : {
		"ConstructModifier" : 0.3,
		"MoveSpeedModifier" : 0.3,
		"FoodModifier" : 0.2,
		"ProductionModifier" : 1.2,
		"GoldModifier" : 0.3,
	},
	MapData.TERRAIN.SNOW_HIGHERMOUNT : {
		"ConstructModifier" : 0.1,
		"MoveSpeedModifier" : 0.15,
		"FoodModifier" : 0.1,
		"ProductionModifier" : 0.9,
		"GoldModifier" : 0.2,
	},
}
