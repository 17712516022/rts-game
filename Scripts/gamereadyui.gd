class_name GameReadyUi extends Control

const HINT_DEFAULT : String = "请选择出生点"

@onready var ready_button: Button = %ReadyButton
@onready var hint_label: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel

##建造管理器：由 ui.gd 注入，和建造面板共用同一份（建筑容器已由它注入好）
var construction_manager : ConstructionManager

var select_cell : Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	show()
	_set_hint(HINT_DEFAULT)
	Engine.time_scale = 0.0
	ready_button.pressed.connect(_on_ready_button_pressed)
	EventBus.select_one_cell.connect(_on_select_one_cell)

##外部注入：和 ConstructUI 共用同一个 ConstructionManager
func SetUp(context_construction_manager : ConstructionManager) -> void:
	construction_manager = context_construction_manager

func _on_ready_button_pressed() -> void:
	if construction_manager == null:
		_set_hint("建造管理器未初始化")
		return
	if select_cell.x < 0 or select_cell.y < 0:
		_set_hint("请先选择格子")
		return
	# 建造是同步的：try_build 返回 true 就说明建筑已经放好，这时才关界面。
	# 顺序不能反——先关界面的情况下，一旦建造被拒（地形 / 已有建筑 / 资源不足），
	# 玩家会既看不见准备界面、时间又在流动，整局卡死在准备阶段。
	var err : Array = []
	if not construction_manager.try_build(select_cell, ConstructionData.Constructions.CENTER, err, TeamData.Team.PLAYER):
		_set_hint(err[0] if not err.is_empty() else "这里无法建造，请换个位置")
		return
	# 断开订阅：界面已隐藏，之后玩家点格子不该再改这里的状态
	EventBus.select_one_cell.disconnect(_on_select_one_cell)
	EventBus.player_has_ready.emit()
	hide()
	Engine.time_scale = 1.0

func _on_select_one_cell(cell_pos : Vector2i) -> void:
	select_cell = cell_pos

func _set_hint(text : String) -> void:
	hint_label.text = text
