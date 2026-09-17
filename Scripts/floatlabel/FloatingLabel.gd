class_name FloatingLabel extends Control

@onready var floating_label_text: RichTextLabel = %FloatingLabelText

const FLOATING_RELATIVE : Vector2 = Vector2(0,60)

signal float_aniamtion_finished(label : FloatingLabel)

#伤害飘字
func play(global_pos : Vector2 , text : String) -> void:
	self.global_position = global_pos
	floating_label_text.text = text
	self.modulate = Color(1,1,1,1)
	
	show()
	
	var tween : Tween = create_tween()
	tween.set_parallel(true) #如果 parallel 为 true，则后续追加的 Tweener 默认就是同时运行的，否则默认依次运行
	tween.tween_property(self,"global_position",global_position - FLOATING_RELATIVE, 0.8)
	tween.tween_property(self,"modulate",Color(1,1,1,0),0.8)
	#向上飘并且变淡
	
	await tween.finished
	float_aniamtion_finished.emit(self)
