class_name UseablePeople extends Node
## 可用人口：每 100 人口换 1 点可用人口，每个兵按底盘 cost_population 长期占用。
## 造兵闸口统一走 can_spawn：玩家（SavedDesign）和敌人（AIDesign）最后都汇到 SoiderSpawner，
## 由它在真正创建士兵之前来问这里，两边共用同一道限制。

## 多少人口 = 1 点可用人口
const PEOPLE_PER_USABLE : float = 100.0

@onready var soider_container: Node2D = %SoiderContainer

var costs : Dictionary = {
	TeamData.Team.PLAYER : 0.0,
	TeamData.Team.ENEMY : 0.0,
}

## 本帧是否已排过刷新：同一帧里批量出兵 / 团灭只在帧末统一算一次
var _refresh_queued : bool = false

func _ready() -> void:
	EventBus.month_passed.connect(_on_month_passed)
	# 士兵是 add_child 直接挂进容器的，不走 month_passed：
	# 进出容器那一刻就重算（进 = 出兵，出 = 阵亡），UI 不用等造兵动画播完、也不用等下一次过月
	soider_container.child_entered_tree.connect(_on_soider_tree_changed)
	soider_container.child_exiting_tree.connect(_on_soider_tree_changed)
	# 出兵成功（动画播完）再兜一次底：万一有别的路径挪动士兵没走容器信号
	EventBus.soider_spawned.connect(_on_soider_spawned)
	# 开局先按初始人口算一次，别让第一帧显示旧值
	_request_refresh()

## 士兵进出容器：这里只当脏标记，具体数值到帧末现算
func _on_soider_tree_changed(_node : Node) -> void:
	_request_refresh()

## 出兵成功（动画播完）后兜底重算一次
func _on_soider_spawned(_soider : SoiderBottom, _squad : TeamData.Team) -> void:
	_request_refresh()

## 合并同一帧内的多次请求，帧末统一重算（批量出兵 / 团灭不做重复扫描）
func _request_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh_all.call_deferred()

func _refresh_all() -> void:
	_refresh_queued = false
	for squad in TeamData.ALL_TEAMS:
		_refresh(squad)

## 重算占用 + 上限推给 UI。UI 只显示玩家那一份，敌营那轮不必再推一次；
## 推出去的两个数都是这里当场算的，UI 不会显示过期数字
func _refresh(squad : TeamData.Team) -> void:
	_refresh_usable(squad)
	_refresh_costs(squad)
	
	if squad == TeamData.Team.PLAYER:
		EventBus.refresh_useable_people.emit(
			costs[squad],
			MaterialManager.get_material_number(MaterialManager.MATERIAL.USABLE_POPULATION, squad)
		)

## 按当前人口重算上限。人口随时会变（过月增长 / 饿死、征召时扣人口），
## 所以每次刷新都跟着重算，不再只在过月时算一次
func _refresh_usable(squad : TeamData.Team) -> void:
	var current_people : float = MaterialManager.get_material_number(MaterialManager.MATERIAL.POPULATION, squad)
	var useable_people : float = current_people / PEOPLE_PER_USABLE
	# 没变就不写：set_material_number 会广播 material_changed，白刷一遍订阅方（阵亡时上限通常没变）
	if is_equal_approx(MaterialManager.get_material_number(MaterialManager.MATERIAL.USABLE_POPULATION, squad), useable_people):
		return
	MaterialManager.set_material_number(MaterialManager.MATERIAL.USABLE_POPULATION, squad ,useable_people)

## 统计某阵营当前兵力占用（重扫容器，不依赖缓存）
func _refresh_costs(squad : TeamData.Team) -> void:
	var soiders : Array = SoiderManager.get_soiders(soider_container,squad)
	costs[squad] = 0.0
	
	for i in soiders:
		var soider : SoiderBottom = i
		# 已经 queue_free 的兵（child_exiting_tree 时还没真正离树）不能算进去，否则占用多算一个
		if soider.is_queued_for_deletion():
			continue
		costs[squad] += soider.bott_res.cost_population

## 过月：延后到帧末再算。MonthlyMaterialCalculator 的吃饭 / 饿死也是 deferred 且比这里先入队，
## 等它跑完再算上限，分母才不会拿"饿死之前"的人口
func _on_month_passed(squad : TeamData.Team) -> void:
	_refresh.call_deferred(squad)

## 已占用是否超上限；extra_cost 用于「再塞这一个兵会不会超」的预检（刚好用满不算超）
func over_limit(squad : TeamData.Team, extra_cost : float = 0.0) -> bool:
	return costs[squad] + extra_cost > MaterialManager.get_material_number(MaterialManager.MATERIAL.USABLE_POPULATION, squad)

## 征召预检：把这一个兵也算进去后会不会超编。每次都现扫容器，不吃 costs 的旧缓存，
## 所以刚造完兵 / 刚死兵都不会按过期数字放行。
func can_spawn(cost_population : float, squad : TeamData.Team) -> bool:
	_refresh_costs(squad)
	return not over_limit(squad, cost_population)
