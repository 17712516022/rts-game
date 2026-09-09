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

## 征召消耗（底盘 + 各已装主炮合并）
func total_cost() -> Dictionary:
	var cost: Dictionary = {}
	var bottom := bottom_res()
	if bottom != null:
		cost.merge(bottom.bottom_resource_cost)
	for res in installed_top_res_list():
		cost.merge((res as SoiderTopResource).top_resource_cost)
	return cost

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
		for res_name in cost:
			text += "\n%s：%s" % [res_name, str(cost[res_name])]
	return text
