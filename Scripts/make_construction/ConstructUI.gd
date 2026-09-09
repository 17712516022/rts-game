class_name ConstructUI extends Control
## 建造面板 UI：点击格子时弹出，显示选中格子的信息；点建筑按钮触发建造。
## 只负责界面：按钮绑定、信息显示。建造业务逻辑在 ConstructionManager 里。
## 建筑 .tres 配置由全局单例 ConstructionData 提供。

@onready var terrain_label: Label = %TerrainLabel
@onready var position_label: Label = %PositionLabel
@onready var close_button: Button = %CloseButton
@onready var center_button: Button = %CenterButton
@onready var sub_center_button: Button = %SubCenterButton
@onready var house_button: Button = %HouseButton
@onready var farm_button: Button = %FarmButton
@onready var mine_button: Button = %MineButton
@onready var barracks_button: Button = %BarracksButton
@onready var port_button: Button = %PortButton
@onready var tree_button: Button = %TreeButton
@onready var panel: PanelContainer = %Panel

@onready var construction_discription: ConstuctionDiscription = %ConstructionDiscription

## 建造业务（UI 层只管调用它，不关心具体怎么建）
var construction_manager : ConstructionManager

var squad : TeamData.Team = TeamData.Team.PLAYER

@onready var _button_res_map: Dictionary = {
	center_button: {"res": ConstructionData.CENTER_RES, "type": ConstructionData.Constructions.CENTER},
	sub_center_button: {"res": ConstructionData.LOWERCENTER_RES, "type": ConstructionData.Constructions.LOWERCENTER},
	house_button: {"res": ConstructionData.RESIDENT_RES, "type": ConstructionData.Constructions.RESIDENT},
	farm_button: {"res": ConstructionData.FARM_RES, "type": ConstructionData.Constructions.FARM},
	mine_button: {"res": ConstructionData.MINE_RES, "type": ConstructionData.Constructions.MINE},
	barracks_button: {"res": ConstructionData.ARMY_RES, "type": ConstructionData.Constructions.ARMY},
	tree_button : {"res" : ConstructionData.TREE_RES, "type" : ConstructionData.Constructions.TREE},
}

func _ready() -> void:
	# 初始隐藏，等玩家点击格子再弹出来
	panel.hide()
	EventBus.select_one_cell.connect(_on_select_one_cell)
	
	close_button.pressed.connect(_on_close_pressed)
	# 一行循环搞定所有按钮的 pressed + hover 绑定
	# 注意：lambda 里要用局部变量暂存，否则所有 lambda 都会拿到循环最后一轮的值
	for btn in _button_res_map:
		var entry: Dictionary = _button_res_map[btn]
		var res: ConstructionResource = entry.res
		var type: int = entry.type
		btn.pressed.connect(func(): _try_build(res, type))
		btn.mouse_entered.connect(func(): construction_discription.show_panel(res, btn.global_position.y))
		btn.mouse_exited.connect(construction_discription.hide_panel)
	# 港口还没有对应的 .tres 资源，先禁用
	port_button.disabled = true

# 外部注入：传进来建造管理器和建筑容器节点
func SetUp(manager: ConstructionManager, context_construction_container : Node2D) -> void:
	construction_manager = manager
	construction_manager.SetUp(context_construction_container)

# 信号回调：玩家点了一个格子，刷新面板内容并显示
func _on_select_one_cell(cell: Vector2i) -> void:
	if ConstructionData.building_grid[cell.x][cell.y] != null:
		_hide_panel()
		return
	
	var terrain: MapData.TERRAIN = MapData.terrain_grid[cell.x][cell.y]
	terrain_label.text = MapData.TERRAIN_NAMES[terrain]
	position_label.text = "第 %d 行 第 %d 列" % [cell.x, cell.y]
	_show_panel()

# 点击建筑按钮：交给建造管理器执行，结果显示在标签上
func _try_build(resource: ConstructionResource, building_type: ConstructionData.Constructions) -> void:
	if construction_manager == null:
		terrain_label.text = "建造管理器未初始化"
		return
	var cell := MapData.selected_cell
	# 还没选格子就提示
	if cell.x < 0 or cell.y < 0:
		terrain_label.text = "先点击选择一个格子"
		return
	var err: Array = []
	if construction_manager.try_build(cell, building_type, resource, err , squad):
		_hide_panel()
	else:
		terrain_label.text = err[0] if not err.is_empty() else "建造失败"

func _on_close_pressed() -> void:
	_hide_panel()

func _show_panel() -> void:
	panel.visible = true
	var tween : Tween = create_tween()
	tween.tween_property(panel,"position",Vector2(0,290),0.2)

func _hide_panel() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(panel,"position",Vector2(-230,290),0.2)
	await tween.finished
	panel.visible = false
