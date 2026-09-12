class_name BTRamdonSequnce extends BTNode

var children : Array = []

func add(new_node : BTNode) -> BTRamdonSequnce:
	children.append(new_node)
	return self

func tick(_ctx : Dictionary ) -> int:
	children.shuffle()
	for i in children:
		var result : int = i.tick(_ctx)
		if result != Status.SUCCESS :
			return result
			
	return Status.SUCCESS
