class_name BuildPanel extends Control

@onready var upgrade: Button = %Upgrade
@onready var block: Button = %block
@onready var build_text_label: RichTextLabel = %BuildTextLabel
@onready var build_texture: TextureRect = %BuildTexture
@onready var buildhealth_progress_bar: TextureProgressBar = %BuildhealthProgressBar

var build : Construction
var build_res : ConstructionResource

func _ready() -> void:
	hide()
	EventBus.select_one_cell.connect(_on_select_one_cell.bind())
	
	upgrade.pressed.connect(_on_upgrade_pressed)
	block.pressed.connect(_on_block_pressed)

func _on_select_one_cell(cell : Vector2i) -> void:
	hide()
	
	build  = ConstructionData.building_grid[cell.x][cell.y]
	if build == null:
		return
	
	build_res = build.res
	build_texture.texture = build_res.texture
	buildhealth_progress_bar.value = build.health / build_res.health * 100
	
	if build_res.display_name == "兵营" :
		upgrade.text = "打开设计面板"
	
	show()

func _updata_text() -> void:
	build_text_label

func _on_upgrade_pressed() -> void:
	if build_res.display_name == "兵营" :
		EventBus.start_design.emit(build)
	
	pass

func _on_block_pressed() -> void:
	pass
