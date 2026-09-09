class_name DesignPreviewer extends VBoxContainer

@onready var texture_bottom: TextureRect = %TextureBottom
@onready var attribute_label: RichTextLabel = %AttributeLabel
@onready var design_preview_animation_player: AnimationPlayer = $DesignPreviewAnimationPlayer
## 槽位按钮所在容器：场景里每个槽位放一个 TextureButton（子节点顺序 = 槽位顺序）
@onready var slots_container: Control = $SoiderTextureMarginContainer/Slots

## 未选底盘时的占位文案
const EMPTY_HINT := "选择炮台和底盘，预览组合属性"

## 点击某个槽位按钮时发出：参数 = 槽位序号（Slots 下第几个 TextureButton）
signal start_select_top(slot: int)

## 槽位按钮列表（顺序 = 槽位序号，0 起）
var _slot_buttons: Array[TextureButton] = []
## 各槽位的空槽默认贴图（快照场景初始值，换底盘/复位时恢复）
var _slot_empty_textures: Array[Texture2D] = []
## 各槽位按钮的基础调色（做高亮对比用，快照场景初始值）
var _slot_base_modulate: Array[Color] = []

func _ready() -> void:
	_collect_slots()

## 收集 Slots 容器下所有 TextureButton 作为槽位按钮
## 场景里摆几个按钮，就支持几个槽；顺序即槽位序号
func _collect_slots() -> void:
	_slot_buttons.clear()
	_slot_empty_textures.clear()
	_slot_base_modulate.clear()
	for child in slots_container.get_children():
		var btn := child as TextureButton
		if btn == null:
			continue
		_slot_buttons.append(btn)
		_slot_empty_textures.append(btn.texture_normal)
		_slot_base_modulate.append(btn.modulate)
		btn.pressed.connect(_on_slot_pressed.bind(_slot_buttons.size() - 1))

func _on_slot_pressed(slot: int) -> void:
	set_active_slot(slot)
	start_select_top.emit(slot)

## 高亮正在装配的槽位（-1 = 取消高亮；点击槽位按钮后由脚本自动调用）
func set_active_slot(slot: int) -> void:
	for i in _slot_buttons.size():
		var base := _slot_base_modulate[i]
		_slot_buttons[i].modulate = Color(
			minf(base.r * 1.35, 1.0),
			minf(base.g * 1.35, 1.0),
			minf(base.b * 1.35, 1.0),
			1.0
		) if i == slot else base

## 槽位 slot 装上炮台：把该槽按钮的贴图换成炮台贴图
## top_res 为 null = 卸下，恢复该槽的空槽默认贴图
func set_slot_turret(slot: int, top_res: SoiderTopResource) -> void:
	if slot < 0 or slot >= _slot_buttons.size():
		return
	_slot_buttons[slot].texture_normal = null if top_res == null else top_res.top_texture

## 换底盘 / 全部卸下：所有槽位恢复空槽贴图并取消高亮
func clear_all_slots() -> void:
	for i in _slot_buttons.size():
		_slot_buttons[i].texture_normal = _slot_empty_textures[i]
	set_active_slot(-1)

## 刷新底盘贴图（bottom_res 为 null 时清空）
func refresh_bottom(bottom_res: SoiderBottomResource) -> void:
	texture_bottom.texture = null if bottom_res == null else bottom_res.bottom_texture

## 刷新组合属性文本；design 为 null（未选底盘）时显示占位提示
func refresh_summary(design: SoiderDesign) -> void:
	attribute_label.text = EMPTY_HINT if design == null else design.summary_text()
