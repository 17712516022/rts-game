class_name FloatingLabelPool extends Node

const MAX_FLOATING_LABEL_COUNT : int = 30
const FLOATING_LABEL = preload("uid://d3yi3lhsxj1ao")
const OFFSET_X : int = 20
const OFFSET_Y : int = 10

#对象池
var _pool : Array[FloatingLabel] = []

func _ready() -> void:
	for i in range(MAX_FLOATING_LABEL_COUNT):
		var label : FloatingLabel = FLOATING_LABEL.instantiate()
		add_child(label)
		label.hide() #先影藏
		
		_pool.append(label)
		label.float_aniamtion_finished.connect(_on_float_aniamtion_finished.bind())

func _on_float_aniamtion_finished(label : FloatingLabel) -> void:
	return_to_pool(label)

## 飘一条字。material 是 MaterialManager.MATERIAL，< 0 = 不上色（普通飘字，比如以后的伤害数字）。
## 调用方只给"内容 + 材料"，具体什么颜色、要不要包 BBCode 由 FloatingLabelStyle 决定。
func show_label(global_pos : Vector2 , text : String , material : int = -1) -> void:
	var label : FloatingLabel
	
	if _pool.is_empty() : #对象池空了，跳过
		return
	else :
		label = _pool.pop_back() #不空就弹出来一个
	
	var offset : Vector2 = Vector2(randf_range(-OFFSET_X,OFFSET_X) , randf_range(-OFFSET_Y,OFFSET_Y))
	#加上随机偏移好看点
	label.play(global_pos + offset , FloatingLabelStyle.material_bbcode(material , text))
	
func return_to_pool(label : FloatingLabel) -> void:
	label.hide()
	_pool.append(label)#加到池子末尾
