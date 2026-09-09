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

## 征召消耗的资源（和建筑 resource_cost 格式一致：{"gold": 50, "food": 20}）
@export var bottom_resource_cost: Dictionary = {}

## 士兵贴图
@export var bottom_texture: Texture2D
