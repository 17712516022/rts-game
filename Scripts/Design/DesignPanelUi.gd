class_name DesignPanelUi extends Control

@onready var top_item_list: ItemList = %TopItemList
@onready var bottom_item_list: ItemList = %BottomItemList
@onready var design_preview: DesignPreviewer = %DesignPreview
@onready var save_design: Button = %SaveDesign
@onready var quit_design: Button = %quitDesign
## 「已保存设计」页节点自己挂了 SavedDesign.gd，它就是保存仓库
@onready var saved_design_panel: SavedDesign = %SavedDesign

## ItemList 行号 ↔ 枚举的对照缓存（行号不能直接当枚举值用）
var usable_top_lists: Array = []
var usable_bottom_list: Array = []

## 当前底盘枚举（-1 = 未选）
var _bottom_enum: int = -1
## 槽位 i → 主炮枚举；-1 = 空槽；长度 = 底盘槽位数，随换底盘重建
var _turret_choices: Array[int] = []
## 正在装配的槽序号（-1 = 无）
var _editing_slot: int = -1

func _ready() -> void:
	top_item_list.item_selected.connect(_on_top_item_selected)
	bottom_item_list.item_selected.connect(_on_bottom_item_selected)
	design_preview.start_select_top.connect(_on_start_select_top)
	save_design.pressed.connect(_on_save_design_pressed)
	quit_design.pressed.connect(_on_quit_design_pressed)
	
	show_design_panel()
	
	# 未选底盘：主炮列表不可选
	_set_top_list_enabled(false)

func SetUp(context_pos : Vector2) -> void:
	saved_design_panel.SetUp(context_pos)

func show_design_panel() -> void:
	refresh_bottom_list()
	refresh_top_list()
	show()

## ============ 列表构建 ============
func refresh_top_list() -> void:
	top_item_list.clear()
	usable_top_lists = SoiderComponentData.get_top_list()
	for enum_val in usable_top_lists:
		var res := SoiderComponentData.TOP_RES[enum_val] as SoiderTopResource
		top_item_list.add_item(res.display_name, res.top_texture, true)

func refresh_bottom_list() -> void:
	bottom_item_list.clear()
	usable_bottom_list = SoiderComponentData.get_bottom_list()
	for enum_val in usable_bottom_list:
		var res := SoiderComponentData.BOTTOM_RES[enum_val] as SoiderBottomResource
		bottom_item_list.add_item(res.display_name, res.bottom_texture, true)

## ============ 交互 ============
## 换了底盘：槽位布局全变，旧装配作废，重建全空槽
func _on_bottom_item_selected(index: int) -> void:
	if index < 0 or index >= usable_bottom_list.size():
		return
	_bottom_enum = usable_bottom_list[index]
	_reset_turret_choices()
	_refresh_preview()

## 点了预览上的槽位钮：进入该槽的装配
func _on_start_select_top(slot: int) -> void:
	if _bottom_enum < 0:
		return
	_editing_slot = slot
	if slot < 0 or slot >= _turret_choices.size():
		# 摆的按钮数多于数据槽位数：忽略
		_editing_slot = -1
		_set_top_list_enabled(false)
		return
	top_item_list.deselect_all()
	_set_top_list_enabled(true)

## 主炮列表选中一项：装到当前编辑中的槽位
func _on_top_item_selected(index: int) -> void:
	if _editing_slot < 0 or index < 0 or index >= usable_top_lists.size():
		top_item_list.deselect_all()
		return
	var top_enum: int = usable_top_lists[index]
	var res := SoiderComponentData.TOP_RES[top_enum] as SoiderTopResource
	_turret_choices[_editing_slot] = top_enum
	design_preview.set_slot_turret(_editing_slot, res)
	_refresh_preview()


## ============ 状态 / 产出 ============
func _current_bottom_res() -> SoiderBottomResource:
	if _bottom_enum < 0:
		return null
	return SoiderComponentData.BOTTOM_RES[_bottom_enum] as SoiderBottomResource

## 让预览组件整体同步：底盘贴图 + 组合属性文本（换底盘 / 装配后调用）
func _refresh_preview() -> void:
	design_preview.refresh_bottom(_current_bottom_res())
	design_preview.refresh_summary(current_design())

## 按当前底盘重建槽位数组（全空槽）并复位预览
func _reset_turret_choices() -> void:
	_turret_choices.clear()
	var bottom_res := _current_bottom_res()
	if bottom_res != null:
		for i in bottom_res.slot_count():
			_turret_choices.append(-1)
	_editing_slot = -1
	top_item_list.deselect_all()
	_set_top_list_enabled(false)
	design_preview.clear_all_slots()

## 当前组合快照（未选底盘返回 null）；生成士兵 / 征召时使用
func current_design() -> SoiderDesign:
	if _bottom_enum < 0:
		return null
	return SoiderDesign.new(_bottom_enum, _turret_choices)

## ItemList 没有 disabled 属性：用「忽略鼠标 + 置灰」模拟禁用
func _set_top_list_enabled(enabled: bool) -> void:
	top_item_list.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	top_item_list.modulate = Color.WHITE if enabled else Color(0.65, 0.65, 0.65, 1.0)

func _on_save_design_pressed() -> void:
	EventBus.save_the_design.emit(current_design())
	
func _on_quit_design_pressed() -> void:
	hide()
