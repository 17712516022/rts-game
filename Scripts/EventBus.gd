extends Node

@warning_ignore("unused_signal")
signal map_has_generated

@warning_ignore("unused_signal")
signal game_ready   # GameBootstrap 在所有 grid 初始化完成后广播，玩家操作才允许开始

@warning_ignore("unused_signal")
signal rivers_generated

@warning_ignore("unused_signal")
signal select_one_cell(cell_pos : Vector2i)

@warning_ignore("unused_signal")
signal construct_building(building_type : ConstructionResource, cell_pos : Vector2i)

## 行政中心被移除/打死（走 Construction._die 的非易手路径）时广播，参数是中心实例。
## 必须在中心节点 queue_free 之前同步 emit——owner_grid 存的是中心节点引用，
## 要先让 CenterOwnershipManager 清掉它辖下的格子归属，否则会残留 freed 引用。
@warning_ignore("unused_signal")
signal center_destroyed(center : Construction)

signal construction_destroyed(build : Construction)

## 账户变动广播（带阵营）：squad 指明哪个阵营的账户变了，UI 只认自己阵营的变动
@warning_ignore("unused_signal")
signal material_changed( material : MaterialManager.MATERIAL , value : float, squad : TeamData.Team)

## 过月广播（带阵营）：TimeManager 每月为每个已注册阵营各广播一轮，订阅方按 squad 过滤
@warning_ignore("unused_signal")
signal month_passed(squad : TeamData.Team)

## turret_choices：与底盘槽位等长的数组，第 i 项 = 槽位 i 的主炮枚举，-1 = 空槽
@warning_ignore("unused_signal")
signal spawn_soider(turret_choices : Array , bottom : SoiderComponentData.BOTTOM , pos : Vector2 )

## 请求打开设计面板。带的是"发起打开的兵营节点"而不是坐标快照：
## 士兵要从这个兵营的位置出生，存节点才能在兵营被拆/易手时立刻发现，不会拿着过期坐标硬出兵。
@warning_ignore("unused_signal")
signal start_design(building : Construction)

@warning_ignore("unused_signal")
signal save_the_design(design : SoiderDesign)

## 特效层：请求绘制一条移动路径预览线。mover 为移动者（线会跟着它边走边缩短），
## points 为寻路点（PathFinder.navigate 的结果，不含起点，空=无路）。
@warning_ignore("unused_signal")
signal show_path_vfx(mover : Node2D, points : Array)

## 特效层：请求收起路径预览线（如移动完成）
@warning_ignore("unused_signal")
signal hide_path_vfx

@warning_ignore("unused_signal")
signal select_the_soider

## 选中士兵集合发生变化（选兵 / 框选为空 / 选中部队阵亡）时广播，不带参数：
## 由 SoiderManager 的三个写入口统一发出，UI 订阅后去 SoiderManager 现读列表，不存快照。
@warning_ignore("unused_signal")
signal soider_selection_changed

## 士兵被成功创建并挂到容器后广播（玩家/敌人都发），参数是实例，供 AI 之类收集自己阵营的兵
@warning_ignore("unused_signal")
signal soider_spawned(soider : SoiderBottom,squad : TeamData.Team)

## 有中心易手/需要全图建筑按归属中心刷新阵营时广播（CenterOwnershipManager 负责执行刷新）
@warning_ignore("unused_signal")
signal team_refresh_requested

@warning_ignore("unused_signal")
signal soider_right_clicked(soider : SoiderBottom)

## 敌人建筑被右键：与 soider_right_clicked 对称，供锁定标识之类的订阅方使用。
## 由 SoiderInteract._move_to_mouse 在下达攻击令的同一处广播，保证"标识"和"命令"同源不会打架。
@warning_ignore("unused_signal")
signal building_right_clicked(building : Construction)

@warning_ignore("unused_signal")
signal squad_lost(squad : TeamData.Team)

## 可用人口刷新（给 UI）：occupied = 当前兵力占用，usable = 当前上限。
## 两个数都是发信号那一刻现算的，收方直接显示，不要再去读缓存（避免显示过期数字）
@warning_ignore("unused_signal")
signal refresh_useable_people(occupied : float, usable : float)

@warning_ignore("unused_signal")
signal player_has_ready
