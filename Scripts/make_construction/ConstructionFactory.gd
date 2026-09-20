class_name ConstructionFactory extends Node

## 建筑工厂：负责把"建筑类型枚举"（ConstructionData.Constructions）
## 转换成对应的建筑配置资源（.tres）。

## 建筑类型 -> 对应的 .tres 资源配置文件
var construction_resources := {}

func _init() -> void:
	construction_resources = {
		ConstructionData.Constructions.FARM: preload("res://Resource/house/farm.tres"),
		ConstructionData.Constructions.CENTER: preload("res://Resource/house/Center.tres"),
		ConstructionData.Constructions.LOWERCENTER: preload("res://Resource/house/LowerCenter.tres"),
		ConstructionData.Constructions.MINE: preload("res://Resource/house/Mine.tres"),
		ConstructionData.Constructions.RESIDENT: preload("res://Resource/house/Resident.tres"),
		ConstructionData.Constructions.ARMY: preload("res://Resource/house/Army.tres"),
		ConstructionData.Constructions.PORT: preload("res://Resource/house/Port.tres"),
		ConstructionData.Constructions.TREE : preload("uid://b6wckgmtg7lob"),
	}

# 根据建筑类型创建一份新的建筑配置
func create_new_construction(construction : ConstructionData.Constructions) -> ConstructionResource:
	if not construction_resources.has(construction):
		push_error("ConstructionFactory：未知的建筑类型 %s" % construction)
		return null
	# duplicate 一份副本，让每个建筑实例独立，改属性不会污染模板
	return construction_resources[construction].duplicate() as ConstructionResource
