class_name BuildPanel extends Control

@onready var barracks_button: Button = %BarracksButton
@onready var block: Button = %block
@onready var build_text_label: RichTextLabel = %BuildTextLabel
@onready var build_texture: TextureRect = %BuildTexture
@onready var buildhealth_progress_bar: TextureProgressBar = %BuildhealthProgressBar
## 面板本体（锚定在右下角），显隐和滑入/滑出动画都作用在它身上
@onready var buildspanel: PanelContainer = $buildspanel

var build : Construction
var build_res : ConstructionResource

## 隐藏时向屏幕右侧滑出的位移，只要大于面板宽度就能完全移出屏幕
const SLIDE_OFFSET : Vector2 = Vector2(360, 0)

## 面板“显示状态”的位置（右下角贴角），_ready 里布局完成后记录一次
var _shown_position : Vector2
var _shown_position_ready : bool = false

## 当前滑入/滑出的补间；重新切面板前先杀掉旧的，避免多段动画互相打架
var _tween : Tween

func _ready() -> void:
	buildspanel.hide()
	EventBus.select_one_cell.connect(_on_select_one_cell.bind())

	barracks_button.pressed.connect(_on_barracks_button_pressed)
	block.pressed.connect(_on_block_pressed)

	# 等一帧让容器布局完成，拿到右下角锚定的真实坐标，并先把面板停到屏幕外
	await get_tree().process_frame
	_shown_position = buildspanel.position
	_shown_position_ready = true
	buildspanel.position = _shown_position + SLIDE_OFFSET

func _on_select_one_cell(cell : Vector2i) -> void:
	hide_panel()

	build  = ConstructionData.building_grid[cell.x][cell.y]
	if build == null:
		return
	if build.get_squad_id() != TeamData.Team.PLAYER:
		return

	build_res = build.res
	build_texture.texture = build_res.texture
	buildhealth_progress_bar.value = build.health / build_res.health * 100

	barracks_button.visible = build_res.display_name == "兵营"

	_updata_text()

	show_panel()

## 刷新面板文字：把当前建筑的名称 / 生命 / 产出拼成 BBCode 塞进标签
func _updata_text() -> void:
	build_text_label.text = ""
	if build == null or build_res == null:
		return
	var txt := "[b][color=yellow]%s[/color][/b]\n" % build_res.display_name
	if build_res.description != "":
		txt += "[i][color=gray]%s[/color][/i]\n" % build_res.description
	txt += "[b]生命值 : [/b] %.0f / %.0f\n" % [build.health, build.max_health]
	txt += "[b]产出 : [/b] " + _actual_output_to_str()
	build_text_label.text = txt

## 产出带地形修正：遍历产出字典，每项算实际值；弱于基础值红色，否则绿色
func _actual_output_to_str() -> String:
	var out := build_res.output_enum()
	if out.is_empty():
		return "无"
	var parts : Array = []
	for the_material in out:
		var base : float = out[the_material]
		var actual := ConstructionResource.calculate_output(base, the_material, build.terrain)
		var mat_name := MaterialManager.material_name(the_material)
		if actual < base - 0.01:
			parts.append("%s [color=red]%.1f[/color]" % [mat_name, actual])
		else:
			parts.append("%s [color=green]%.1f[/color]" % [mat_name, actual])
	return "  ".join(parts)

func _on_barracks_button_pressed() -> void:
	hide_panel()
	if build_res == null or build_res.display_name != "兵营":
		return
	EventBus.start_design.emit(build)

func _on_block_pressed() -> void:
	hide_panel()
	build._die()

## 面板滑入：从屏幕右侧滑回右下角并显示（仿 ConstructUI._show_panel）
## 先瞬移回屏外再补间到目标位，保证每次弹出都是同一个“滑进来”的动画
func show_panel() -> void:
	if not _shown_position_ready:
		_shown_position = buildspanel.position
		_shown_position_ready = true
	
	if _tween != null and _tween.is_valid():
		_tween.kill()
	
	buildspanel.visible = true
	buildspanel.position = _shown_position + SLIDE_OFFSET
	_tween = create_tween()
	_tween.tween_property(buildspanel, "position", _shown_position, 0.2)

## 面板滑出：滑到屏幕右侧外，滑完再隐藏（仿 ConstructUI._hide_panel）
## 用 tween_callback 收尾而不是 await，避免滑出中途被打断时协程永远挂起
func hide_panel() -> void:
	if not buildspanel.visible:
		return
	
	if _tween != null and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(buildspanel, "position", _shown_position + SLIDE_OFFSET, 0.2)
	_tween.tween_callback(func(): buildspanel.visible = false)
