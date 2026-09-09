class_name BTLeaf extends BTNode
## 行为树"动作"叶子基类，两种用法：
##  1. 正式动作：子类存好参数、override execute() 写真实逻辑（推荐，见 AIBuild/AIAttack/AIDesign）。
##  2. 临时动作：构造时不带逻辑，后续 set_func() 注入 lambda（一次性/调试用）。
## 执行顺序：有 lambda 先走 lambda，否则走子类 execute()。

var _func : Callable

func set_func(c_func : Callable) -> BTLeaf:
	_func = c_func
	return self

func tick(ctx : Dictionary) -> int:
	if _func.is_valid():
		return _func.call(ctx)
	return execute(ctx)

## 子类 override 的动作入口：干完活返回 BTNode.Status
func execute(_ctx : Dictionary) -> int:
	return Status.FALIURE
