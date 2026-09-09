class_name BTPass extends BTNode
## 永远 SUCCESS 的占位叶子：表示"这一步无需求 / 故意放行"，
## 让外层 Sequence 不因 FALIURE 中断，继续推下一阶段。

func tick(_ctx : Dictionary) -> int:
	return Status.SUCCESS
