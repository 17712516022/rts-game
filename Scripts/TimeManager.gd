class_name TimeManager extends Control
##时间管理器：每隔固定时长（毫秒）推进一个月，发射 month_passed 信号。
##用引擎启动以来的毫秒时间戳计时。

##每隔多久（毫秒）过一个月
const MONTH_TIME : int = 10000

##上次过月时刻的引擎时间戳（毫秒）
var time_since_month : int

@onready var time_progress_bar: ProgressBar = %TimeProgressBar

func _ready() -> void:
	time_progress_bar.value = 0
	time_since_month = Time.get_ticks_msec()

func _process(_delta: float) -> void:
	var now : int = Time.get_ticks_msec()
	time_progress_bar.value = (now - time_since_month) * 100 / MONTH_TIME 
	
	if now - time_since_month >= MONTH_TIME:
		# 每月为每个已注册阵营各广播一轮，各系统按 squad 过滤（建筑产出、人口税收等）
		for squad in TeamData.ALL_TEAMS:
			EventBus.month_passed.emit(squad)
		time_since_month = now
