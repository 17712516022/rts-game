class_name ConstuctionDiscription extends PanelContainer
## 建筑描述面板：接收 ConstructionResource，用 BBCode 拼一段富文本显示。
## 由 ConstructUI 在按钮 hover 时调 show_panel(res)，离开时调 hide_panel()。

@onready var rich_text_label: RichTextLabel = %RichTextLabel

## 当前正在显示的建筑资源
var _res: ConstructionResource

## pos_y 可选：传了就把面板 global_position.y 挪到指定位置（对齐按钮用）
## 没传就保持面板在编辑器里放好的位置（最稳妥的默认行为）
func show_panel(res: ConstructionResource, pos_y: float = -INF) -> void:
	if pos_y != -INF:
		self.global_position.y = pos_y
	_res = res
	_update_content()
	visible = true

func hide_panel() -> void:
	visible = false

# 把资源字段拼成 BBCode 富文本一次性塞进 RichTextLabel
func _update_content() -> void:
	if _res == null:
		rich_text_label.text = ""
		return
	var txt := "[b][color=yellow]建筑信息[/color][/b]\n"
	
	# 从选中格子读地形（必定存在），建造时间和产出都要用，只读一次
	var cell := MapData.selected_cell
	var terrain: MapData.TERRAIN = MapData.terrain_grid[cell.x][cell.y]
	
	# 建造时间：弱于基础值（更慢）红色，好于或等于基础值（更快/相同）绿色
	var actual_time := ConstructionResource.calculate_build_time(_res.time, terrain)
	if actual_time > _res.time + 0.01:
		txt += "[b]建造时间 : [/b] [color=red]%.1f 秒[/color] (基础 %.1f)\n" % [actual_time, _res.time]
	else:
		txt += "[b]建造时间 : [/b] [color=green]%.1f 秒[/color] (基础 %.1f)\n" % [actual_time, _res.time]
	
	txt += "[b]生命值 : [/b] %.0f\n" % _res.health
	# 消耗
	txt += "[b]消耗 : [/b] " + _mat_dict_to_str(_res.resource_cost_enum()) + "\n"
	# 产出：地形必有，直接算实际值（含修正）
	txt += "[b]产出 : [/b] " + _actual_output_to_str(terrain)
	rich_text_label.text = txt

# 产出带地形修正：遍历产出字典，每项算实际值。
# 弱于基础值是红色，好于或等于基础值是绿色，差异大时附基础值对比
func _actual_output_to_str(terrain: MapData.TERRAIN) -> String:
	var out := _res.output_enum()
	if out.is_empty():
		return "无"
	var parts: Array = []
	for the_material in out:
		var base: float = out[the_material]
		var actual := ConstructionResource.calculate_output(base, the_material, terrain)
		if actual < base - 0.01:
			parts.append("%s [color=red]%.1f[/color] (基础 %.0f)" % [_material_name(the_material), actual, base])
		else:
			parts.append("%s [color=green]%.1f[/color] (基础 %.0f)" % [_material_name(the_material), actual, base])
	return "  ".join(parts)

# 把 {MaterialManager.MATERIAL.GOLD: 100, ...} 拼成 "金币 100  木材 50"
func _mat_dict_to_str(d: Dictionary) -> String:
	if d.is_empty():
		return "无"
	var parts: Array = []
	for key in d:
		parts.append("%s %.0f" % [_material_name(key), d[key]])
	return "  ".join(parts)

# MaterialManager.MATERIAL 枚举 -> 中文显示名
func _material_name(mat: MaterialManager.MATERIAL) -> String:
	match mat:
		MaterialManager.MATERIAL.GOLD:
			return "金币"
		MaterialManager.MATERIAL.FOOD:
			return "食物"
		MaterialManager.MATERIAL.WOOD:
			return "木材"
		MaterialManager.MATERIAL.MINE:
			return "矿石"
	return "未知"
