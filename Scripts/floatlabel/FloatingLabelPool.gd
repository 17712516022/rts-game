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

func show_label(global_pos : Vector2 , text : String) -> void:
	var label : FloatingLabel
	
	if _pool.is_empty() : #对象池空了，跳过
		return
	else :
		label = _pool.pop_back() #不空就弹出来一个
	
	var offset : Vector2 = Vector2(randf_range(-OFFSET_X,OFFSET_X) , randf_range(-OFFSET_Y,OFFSET_Y))
	#加上随机偏移好看点
	label.play(global_pos + offset , text)
	
func return_to_pool(label : FloatingLabel) -> void:
	label.hide()
	_pool.append(label)#加到池子末尾
