extends Node

signal map_has_generated

signal game_ready   # GameBootstrap 在所有 grid 初始化完成后广播，玩家操作才允许开始

signal rivers_generated

signal select_one_cell(cell_pos : Vector2i)

signal construct_building(building_type : ConstructionResource, cell_pos : Vector2i)

## 行政中心被移除/打死（走 Construction._die 的非易手路径）时广播，参数是中心实例。
## 必须在中心节点 queue_free 之前同步 emit——owner_grid 存的是中心节点引用，
## 要先让 CenterOwnershipManager 清掉它辖下的格子归属，否则会残留 freed 引用。
signal center_destroyed(center : Construction)

## 账户变动广播（带阵营）：squad 指明哪个阵营的账户变了，UI 只认自己阵营的变动
signal material_changed( material : MaterialManager.MATERIAL , value : float, squad : TeamData.Team)

## 过月广播（带阵营）：TimeManager 每月为每个已注册阵营各广播一轮，订阅方按 squad 过滤
signal month_passed(squad : TeamData.Team)

## turret_choices：与底盘槽位等长的数组，第 i 项 = 槽位 i 的主炮枚举，-1 = 空槽
signal spawn_soider(turret_choices : Array , bottom : SoiderComponentData.BOTTOM , pos : Vector2)

signal start_design(pos : Vector2)

signal save_the_design(design : SoiderDesign)

## 特效层：请求绘制一条移动路径预览线。mover 为移动者（线会跟着它边走边缩短），
## points 为寻路点（PathFinder.navigate 的结果，不含起点，空=无路）。
signal show_path_vfx(mover : Node2D, points : Array)

## 特效层：请求收起路径预览线（如移动完成）
signal hide_path_vfx

signal select_the_soider

## 士兵被成功创建并挂到容器后广播（玩家/敌人都发），参数是实例，供 AI 之类收集自己阵营的兵
signal soider_spawned(soider : SoiderBottom)

## 有中心易手/需要全图建筑按归属中心刷新阵营时广播（CenterOwnershipManager 负责执行刷新）
signal team_refresh_requested
