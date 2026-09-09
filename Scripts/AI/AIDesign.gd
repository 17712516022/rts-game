class_name AIDesign extends BTLeaf
## 敌人"设计士兵"动作叶子：把一整套士兵（底盘 + 各槽主炮）按预算攒出来。
## 原 EnemyCommander 用两个 AIDesign 占位（try_design_bottom / try_design_top），
## 现在用 Step 参数区分这两小步，外层 Sequence 里按 BOTTOM → TOP 顺序放两个实例。
## ctx 现成可用：gold / mine / wood 及对应 *_threshold（预算）、squad（自己阵营）。
## 执行体是旧占位的迁移（原实现是 TODO 恒 SUCCESS）；真实"设计"待接入
## （参考玩家侧 SoiderDesign：填 bottom_enum 和 turret_choices，再 EventBus.spawn_soider 出兵）。

enum Step {
	BOTTOM,  # 第一步：选底盘
	TOP,     # 第二步：给各槽位装主炮
}

var step : Step

func _init(p_step : Step) -> void:
	step = p_step

func execute(ctx : Dictionary) -> int:
	match step:
		Step.BOTTOM:
			return design_bottom(ctx)
		Step.TOP:
			return design_top(ctx)
	return Status.SUCCESS

## 选底盘（参考 SoiderComponentData.BOTTOM_RES，按当前资源挑可负担的）
func design_bottom(_ctx : Dictionary) -> int:
	# TODO(设计)：把选中底盘记到队伍设计里（如 SoiderDesign.bottom_enum）。
	return Status.SUCCESS

## 按底盘槽位逐个配主炮（参考 SoiderComponentData.TOP_RES 与底盘 slot_count）
func design_top(_ctx : Dictionary) -> int:
	# TODO(设计)：把各槽主炮记到队伍设计里（如 SoiderDesign.turret_choices）。
	return Status.SUCCESS
