class_name BTCheckDistance extends BTNode
## 资源门槛装饰器：ctx[key_a] < ctx[key_b]（资源低于门槛）→ 执行 child；否则 FALIURE。
## 用在哪：把"缺什么补什么"的每个分支做成一个这样的检查。
## 用法：
##   var checker := BTCheckDistance.new("gold", "gold_threshold")   # 检查金够不够
##   checker.add(盖民居的叶子)                                       # 不够才盖民居
## ctx 里的 key 由上层每次 tick 填好，比如：
##   ctx = { "gold": 当前金, "gold_threshold": 300, "mine": ..., ... }

var child : BTNode
var key_a : String   # ctx 里"现有资源量"的 key
var key_b : String   # ctx 里"门槛"的 key

func _init(check_key_a : String, check_key_b : String) -> void:
	key_a = check_key_a
	key_b = check_key_b

func add(new_node : BTNode) -> BTCheckDistance:
	child = new_node
	return self

func tick(ctx : Dictionary) -> int:
	if child == null:
		return BTNode.Status.FALIURE
	if ctx[key_a] < ctx[key_b]:
		return child.tick(ctx)        # 低于门槛 → 真缺，去执行 child 补它
	return BTNode.Status.FALIURE      # 资源充足 → 不归这个分支管，让树试下一个
