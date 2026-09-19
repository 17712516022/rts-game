class_name UseablePeopleUI extends Node

@onready var use_able_population_label: Label = %UseAblePopulationLabel

func _ready() -> void:
	# 初值不在这里猜：UseablePeople 启动时会推一次现算值过来（同一帧帧末，看不到闪）
	EventBus.refresh_useable_people.connect(_on_refresh)

## occupied = 当前兵力占用，usable = 当前上限，两个都是发信号那一刻现算的
func _on_refresh(occupied : float, usable : float) -> void:
	use_able_population_label.text = "%s / %s" % [_format(occupied), _format(usable)]
	# 超编时标红，比"看起来满了其实还能造"好读
	use_able_population_label.modulate = Color(1.0, 0.35, 0.35) if occupied > usable else Color.WHITE

## 整数不带小数点（1 / 2），有小数才显示（2.5 / 3）
static func _format(value : float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)
