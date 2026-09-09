class_name BTRandomSelector extends BTNode
# 随机顺序的 Selector：每次 tick 打乱顺序，从上往下试，
# 命中第一个非 FALIURE（SUCCESS/RUNNING）就收工，本轮结束。

var children : Array[BTNode] = []

func add(new_node : BTNode) -> BTRandomSelector:
	children.append(new_node)
	return self

func tick(ctx : Dictionary) -> int:
	children.shuffle()
	for i in children:
		if i.tick(ctx) != Status.FALIURE:
			return Status.SUCCESS

	return Status.FALIURE
