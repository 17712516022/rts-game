extends Node
##时间管理器：每隔固定时长推进一个月，发射 month_passed 信号。
##用帧间隔（delta）累加计时，不再用引擎时间戳——这样暂停 / 时间缩放 / 切场景都连续。

##每隔多久（秒）过一个月
const MONTH_TIME : float = 10.0

##本月已累积的时长（秒）
var month_timer : float = 0.0

func _ready() -> void:
	month_timer = 0.0

func _process(delta: float) -> void:
	month_timer += delta
	
	# 一帧可能跨过多个月（掉帧 / 时间缩放），用 while 把欠的月份补齐，不丢月
	while month_timer >= MONTH_TIME:
		month_timer -= MONTH_TIME
		# 每月为每个已注册阵营各广播一轮，各系统按 squad 过滤（建筑产出、人口税收等）
		for squad in TeamData.ALL_TEAMS:
			EventBus.month_passed.emit(squad)
