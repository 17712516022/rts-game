class_name BTLeaf extends BTNode

var _func : Callable

func _init(c_func : Callable) -> void:
	_func = c_func

func tick(ctx : Dictionary ) -> int:
	return _func.call(ctx)
