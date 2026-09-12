class_name UI extends CanvasLayer

@onready var constrution_container: Node2D = %ConstrutionContainer
@onready var constructui: ConstructUI = %Constructui
@onready var design_panel: DesignPanelUi = $DesignPanel


## 建造业务管理器（UI 层不自己造，由这里统一创建并注入）
var construction_manager := ConstructionManager.new()

func _ready() -> void:
	add_child(construction_manager)
	constructui.SetUp(construction_manager, constrution_container)
	
	EventBus.start_design.connect(_show_design_panel)

func _show_design_panel(building : Construction) -> void:
	design_panel.show_design_panel()
	design_panel.SetUp(building)
