class_name OutputProductor extends Node
## 建筑产出器：每过一个月，把建筑配置里的 output 转成实际资源收入。
## 产出修正计算统一用 ConstructionResource.calculate_output 静态方法（和建造时间对称）。
## 这里只负责：收 month_passed 信号 → 判断这轮广播是不是自己建筑阵营 → 遍历产出 → 发给 MaterialManager。
## 阵营不缓存快照，每次产出现读 construction.get_squad_id()：中心易手后产出自动归新主。

var construction_res : ConstructionResource
var terrain : MapData.TERRAIN
var floating_label_pool : FloatingLabelPool
var construction : Construction

## 政策产出修正（将来接政策系统，>1 = 产出更多，<1 = 产出更少），占位 1.0
var police_modifier: float = 1.0

func SetUp(context_cons_res : ConstructionResource, context_terrain : MapData.TERRAIN,context_floating_label_pool : FloatingLabelPool ,context_construction : Construction) -> void:
	construction_res = context_cons_res
	terrain = context_terrain
	floating_label_pool = context_floating_label_pool
	construction = context_construction

func _ready() -> void:
	EventBus.month_passed.connect(_on_month_passed)

## 结算一轮产出（squad = 这轮广播对应的阵营，直接用它入账）
func _product(squad : TeamData.Team) -> void:
	if construction_res == null:
		return
	var out := construction_res.output_enum()
	for material in out.keys():
		var base: float = out[material]
		var result := ConstructionResource.calculate_output(base, material, terrain, police_modifier)
		MaterialManager.receive_material(material, result ,squad)
		
		# 浮字要显示材料中文名：直接 str(枚举) 出来的是 "0/1/2"，玩家看不懂
		floating_label_pool.show_label(construction.global_position, "+%.0f %s" % [result, MaterialManager.material_name(material)])

## month_passed 会为每个阵营各广播一轮：建筑只在自己阵营那一轮产出，
## 否则每轮都触发一次，产出会翻倍/错账。
func _on_month_passed(squad : TeamData.Team) -> void:
	if construction == null or construction_res == null:
		return
	if squad != construction.get_squad_id():
		return
	_product(squad)
