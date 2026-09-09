class_name BTSelector extends BTNode
 # 遇到 SUCCESS 或 RUNNING 都短路
var children : Array[BTNode] = []

func add(new_node : BTNode) -> BTSelector:
	children.append(new_node)
	return self

func tick(ctx : Dictionary ) -> int:
	for i in children:
		var result : int = i.tick(ctx)
		if result != Status.FALIURE : # 遇到 SUCCESS 或 RUNNING 都短路
			return Status.SUCCESS
	
	return Status.FALIURE
