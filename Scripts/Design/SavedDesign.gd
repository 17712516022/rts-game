class_name SavedDesign extends PanelContainer

## 保存的每条设计：{"底盘": BOTTOM枚举, "部署数组": [槽位→TOP枚举, -1=空槽]}
var designs: Array = []

@onready var saved_list: ItemList = %SavedList
@onready var tabs: TabContainer = %Tabs
@onready var selectbutton: Button = $VBoxContainer/selectbutton

var selected_design: Dictionary = {}
var spawn_pos: Vector2

func SetUp(context_pos: Vector2) -> void:
	spawn_pos = context_pos
	# 打开面板就刷一次，避免停在「保存的设计」页签时列表空白
	refresh_saved_list()

func _ready() -> void:
	tabs.tab_changed.connect(_on_tab_changed)
	EventBus.save_the_design.connect(_on_save_the_design)
	selectbutton.pressed.connect(_on_selected_the_design)
	saved_list.item_selected.connect(_on_saved_item_selected)

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

func _on_tab_changed(index: int) -> void:
	if index == 1:
		refresh_saved_list()

func _on_selected_the_design() -> void:
	if not selected_design.has("底盘") or selected_design["底盘"] < 0:
		return
	
	# 参数顺序与 EventBus.spawn_soider 声明一致：(炮枚举数组, 底盘枚举, 坐标)
	EventBus.spawn_soider.emit(selected_design["部署数组"], selected_design["底盘"], spawn_pos)
	hide()

func _on_saved_item_selected(index: int) -> void:
	if index < 0 or index >= designs.size():
		return
	selected_design = designs[index]
