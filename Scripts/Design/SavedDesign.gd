class_name SavedDesign extends PanelContainer

## 保存的每条设计：{"底盘": BOTTOM枚举, "部署数组": [槽位→TOP枚举, -1=空槽]}
var designs: Array = []

@onready var saved_list: ItemList = %SavedList
@onready var tabs: TabContainer = %Tabs
@onready var selectbutton: Button = $VBoxContainer/selectbutton

var selected_design: Dictionary = {}

var spawn_building : Construction = null

func SetUp(context_building : Construction) -> void:
	spawn_building = context_building
	# 打开面板就刷一次，避免停在「保存的设计」页签时列表空白
	refresh_saved_list()

func _ready() -> void:
	tabs.tab_changed.connect(_on_tab_changed)
	EventBus.save_the_design.connect(_on_save_the_design)
	selectbutton.pressed.connect(_on_selected_the_design)
	saved_list.item_selected.connect(_on_saved_item_selected)
	# 资源变动就刷新征召按钮：钱够了按钮自动亮起来
	EventBus.material_changed.connect(_on_material_changed)

func _on_save_the_design(design: SoiderDesign) -> void:
	if design == null or design.bottom_enum < 0:
		return
	var new_saved_design: Dictionary = {
		"底盘": design.bottom_enum,               # BOTTOM 枚举
		"部署数组": design.turret_choices.duplicate(),  # 与槽位等长的枚举数组，-1=空槽
	}
	designs.append(new_saved_design)

## 把已保存设计条目刷新到「保存的设计」页
func refresh_saved_list() -> void:
	saved_list.clear()

	if designs.is_empty():
		saved_list.add_item("还没有保存的设计，先去「设计」页装配并保存吧")
		_refresh_select_button()
		return

	for entry in designs:
		var bottom_enum: int = entry.get("底盘", -1)
		var bottom: SoiderBottomResource = SoiderComponentData.BOTTOM_RES.get(bottom_enum)
		var text: String = "（未选底盘）" if bottom == null else bottom.display_name

		var choices: Array = entry.get("部署数组", [])
		var names := PackedStringArray()
		for choice in choices:
			if choice < 0:
				continue
			var top: SoiderTopResource = SoiderComponentData.TOP_RES.get(choice)
			if top != null:
				names.append(top.display_name)
		if not names.is_empty():
			text += " ｜ 主炮：" + "、".join(names)
		saved_list.add_item(text)
	
	_refresh_select_button()

## 当前选中设计的征召消耗（{MATERIAL: value}）；没选中 / 没底盘时返回空字典
func _selected_cost() -> Dictionary:
	if not selected_design.has("底盘") or selected_design["底盘"] < 0:
		return {}
	var bottom: SoiderBottomResource = SoiderComponentData.BOTTOM_RES.get(selected_design["底盘"])
	var tops: Array = []
	for choice in selected_design.get("部署数组", []):
		if choice >= 0:
			tops.append(SoiderComponentData.TOP_RES.get(choice))
	return SoiderDesign.merge_cost(bottom, tops)

## 刷新征召按钮：按钮上直接显示要花多少，买不起就置灰并写明缺什么。
## （不能等玩家点了才在后台静默失败——那样玩家只会觉得"点了没反应"）
func _refresh_select_button() -> void:
	var has_selection : bool = selected_design.has("底盘") and selected_design["底盘"] >= 0
	if not has_selection:
		selectbutton.text = "征召"
		selectbutton.disabled = true
		return
	var cost := _selected_cost()
	var lack := _lack_text(cost)
	if lack.is_empty():
		selectbutton.text = "征召（%s）" % MaterialManager.costs_to_text(cost)
	else:
		# 买不起也把缺口顶在按钮上：玩家一眼知道差多少，而不是"点不动"
		selectbutton.text = "征召（缺 %s）" % lack
	selectbutton.disabled = not lack.is_empty()

## 列出玩家付不起的材料及缺口（"矿石 60"）；全都付得起返回空串
func _lack_text(cost : Dictionary) -> String:
	var parts : Array = []
	for i in cost:
		var need : float = cost[i]
		if need <= 0.0:
			continue
		var have : float = MaterialManager.get_material_number(i, TeamData.Team.PLAYER)
		if have < need:
			parts.append("%s %.0f" % [MaterialManager.material_name(i), ceilf(need - have)])
	return "  ".join(parts)

## 出生兵营还能不能用（节点还在、没被拆、还是玩家自己的）
func _spawn_building_valid() -> bool:
	if spawn_building == null or not is_instance_valid(spawn_building):
		return false
	return spawn_building.get_squad_id() == TeamData.Team.PLAYER

## 资源变动 → 重算买不买得起（只关心玩家自己的账户）
func _on_material_changed(_material: MaterialManager.MATERIAL, _value: float, squad: TeamData.Team) -> void:
	if squad != TeamData.Team.PLAYER:
		return
	_refresh_select_button()

func _on_tab_changed(index: int) -> void:
	if index == 1:
		refresh_saved_list()

func _on_selected_the_design() -> void:
	if not selected_design.has("底盘") or selected_design["底盘"] < 0:
		return
	# 出生点 = 打开本面板的那个兵营。兵营没了就说清楚，不要静默吞掉这次点击。
	if not _spawn_building_valid():
		return
	var cost := _selected_cost()
	if not MaterialManager.can_afford(cost, TeamData.Team.PLAYER):
		return
	
	EventBus.spawn_soider.emit(selected_design["部署数组"], selected_design["底盘"], spawn_building.global_position)
	hide()

func _on_saved_item_selected(index: int) -> void:
	if index < 0 or index >= designs.size():
		return
	selected_design = designs[index]
	_refresh_select_button()
