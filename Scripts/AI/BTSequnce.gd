class_name BTSequnce extends BTNode
#全成功才成功
var children : Array[BTNode] = []

func add(n : BTNode) -> BTSequnce:
	children.append(n)
	return self#返回自己是为了可以链式调用

func tick(ctx : Dictionary ) -> int:
	for i in children:  #看看自己是不是每一个孩子都成功
		var result : int = i.tick(ctx)
		if result != Status.SUCCESS:
			return result
	
	return Status.SUCCESS
