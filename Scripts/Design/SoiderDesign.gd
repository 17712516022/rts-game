class_name SoiderDesign
extends RefCounted

## 底盘枚举（SoiderComponentData.BOTTOM，-1 = 未选底盘）
var bottom_enum: int = -1
## 槽位 → 主炮枚举：turret_choices[i] = 槽位 i 装的主炮（SoiderComponentData.TOP），-1 = 空槽。
## 长度应 = bottom_res().slot_count()，由 UI 层保证。
var turret_choices: Array[int] = []

func _init(p_bottom_enum: int = -1, p_turret_choices: Array[int] = []) -> void:
	bottom_enum = p_bottom_enum
	turret_choices = p_turret_choices.duplicate()

## 底盘配置资源（没选底盘返回 null）
func bottom_res() -> SoiderBottomResource:
	if bottom_enum < 0:
		return null
	return SoiderComponentData.BOTTOM_RES[bottom_enum] as SoiderBottomResource

## 槽位总数（没选底盘返回 0）
func slot_count() -> int:
	var bottom := bottom_res()
	if bottom == null:
		return 0
	return bottom.slot_count()

## 已装炮数量（空槽不算）
func installed_count() -> int:
	var n: int = 0
	for choice in turret_choices:
		if choice >= 0:
			n += 1
	return n

## 槽位 i 装的主炮枚举（越界/空槽返回 -1）
func choice_at(slot: int) -> int:
	if slot < 0 or slot >= turret_choices.size():
		return -1
	return turret_choices[slot]

## 逐槽解析：返回与 turret_choices 等长的配置数组，空槽为 null
func slot_res_list() -> Array:
	var result: Array = []
	for choice in turret_choices:
		if choice < 0:
			result.append(null)
			continue
		result.append(SoiderComponentData.TOP_RES[choice] as SoiderTopResource)
	return result

## 已装主炮的配置列表（不含空槽，顺序 = 槽位顺序）
func installed_top_res_list() -> Array:
	var result: Array = []
	for choice in turret_choices:
		if choice >= 0:
			result.append(SoiderComponentData.TOP_RES[choice] as SoiderTopResource)
	return result

## 主炮攻击力合计（只算已装槽）
func total_attack() -> float:
	var sum: float = 0.0
	for res in installed_top_res_list():
		sum += (res as SoiderTopResource).attack
	return sum

## 征召消耗（底盘 + 各已装主炮合并），key = MaterialManager.MATERIAL 枚举。
## 这个字典可以直接喂给 MaterialManager.try_spend / can_afford。
func total_cost() -> Dictionary:
	return merge_cost(bottom_res(), installed_top_res_list())

## 静态：把一份底盘 + 一组主炮的消耗合并成 {MATERIAL: value}，同名材料累加。
## 面板展示、出兵结算、AI 决策都走这里，保证"看到的花费 = 实际扣的花费"。
static func merge_cost(bottom: SoiderBottomResource, top_res_list: Array) -> Dictionary:
	var cost : Dictionary = {}
	if bottom != null:
		_merge_into(cost, bottom.resource_cost_enum())
	for res in top_res_list:
		var top_res := res as SoiderTopResource
		if top_res != null:
			_merge_into(cost, top_res.resource_cost_enum())
	return cost

## 静态私有：把 src 的每项累加进 dst（同名材料相加，不是覆盖）
static func _merge_into(dst : Dictionary, src : Dictionary) -> void:
	for material in src:
		dst[material] = dst.get(material, 0.0) + src[material]

## 征召消耗的中文文本（"金币 90  木材 20  人口 1"）；没消耗返回 "无"
func cost_text() -> String:
	return MaterialManager.costs_to_text(total_cost())

## 拼成面板展示用的 bbcode 文本；没选底盘返回空串
func summary_text() -> String:
	var bottom := bottom_res()
	if bottom == null:
		return ""
	var text := "[b]%s[/b]" % bottom.display_name
	text += "\n主炮槽：%d（已装 %d）" % [slot_count(), installed_count()]
	text += "\n生命：%s\n速度：%s\n防御：%s" % [
		str(bottom.max_health), str(bottom.speed), str(bottom.defense),
	]
	if installed_count() > 0:
		text += "\n攻击合计：%s" % str(total_attack())
		for i in turret_choices.size():
			var choice: int = turret_choices[i]
			if choice < 0:
				continue
			var top_res := SoiderComponentData.TOP_RES[choice] as SoiderTopResource
			text += "\n槽位%d %s：攻击%s 范围%s" % [
				i + 1, top_res.display_name, str(top_res.attack), str(top_res.attack_range),
			]
	var cost := total_cost()
	if not cost.is_empty():
		text += "\n[b]【征召消耗】[/b]"
		for material in cost:
			text += "\n%s：%.0f" % [MaterialManager.material_name(material), cost[material]]
	return text
