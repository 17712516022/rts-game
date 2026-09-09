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

## 征召消耗的资源（和建筑 resource_cost 格式一致：{"gold": 50, "food": 20}）
@export var top_resource_cost: Dictionary = {}

## 士兵贴图
@export var top_texture: Texture2D
@export var bullet_texture: Texture2D
