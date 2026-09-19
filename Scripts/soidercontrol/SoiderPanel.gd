class_name SoiderPanel extends Control

@onready var discord_soider_button: Button = %DiscordSoiderButton
@onready var soider_ui_rich_text: RichTextLabel = %SoiderUiRichText

## 逐条明细最多列几个兵：再多只报数量，免得选中一大片时面板被撑成长条
const MAX_DETAIL_ROWS : int = 5

func _ready() -> void:
	hide()
	# 唯一刷新入口：选中集合的任何变化（选兵 / 框选为空 / 选中部队阵亡）都广播它
	EventBus.soider_selection_changed.connect(_on_selection_changed)
	discord_soider_button.pressed.connect(_on_discord_soider_button_pressed)

func _on_selection_changed() -> void:
	if SoiderManager.get_current_soiders().is_empty():
		hide()
		return
	update_soider_ui_rich_text()
	show()

func _on_discord_soider_button_pressed() -> void:
	# 清空列表会广播 soider_selection_changed，面板由 _on_selection_changed 统一收起
	SoiderManager.set_selecting_soiders([])
	EventBus.hide_path_vfx.emit()

func update_soider_ui_rich_text() -> void:
	var soiders : Array = get_valid_soiders()
	var txt : String = "[b]当前共指挥[/b] [color=yellow]%d[/color]" % soiders.size()
	
	for i in mini(soiders.size(), MAX_DETAIL_ROWS):
		var soider : SoiderBottom = soiders[i]
		txt += "\n%s  炮%d" % [get_soider_name(soider), soider.tops.size()]
	if soiders.size() > MAX_DETAIL_ROWS:
		txt += "\n[color=gray]…还有其他 %d 个[/color]" % (soiders.size() - MAX_DETAIL_ROWS)
	
	soider_ui_rich_text.text = txt

func get_soider_name(soider : SoiderBottom) -> String:
	return soider.bott_res.display_name if soider.bott_res != null else "未知底盘"

## 选中列表里可能残留已被 queue_free、当帧还没真正释放的兵，显示前先滤掉
func get_valid_soiders() -> Array:
	var result : Array = []
	for i in SoiderManager.get_current_soiders():
		var soider : SoiderBottom = i
		if not is_instance_valid(soider) or soider == null or soider.is_queued_for_deletion():
			continue
		result.append(soider)
	return result
