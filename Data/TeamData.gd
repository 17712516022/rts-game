extends Node
## 阵营常量：士兵/建筑的 Squad 节点存的就是 Team 里的值。
## 0 = 玩家；1+ = AI/其他势力。以后开多人直接在 Team 里加项即可，判定代码不用改。

enum Team {
	PLAYER = 0,
	ENEMY = 1,
	# 预留扩展：2、3……
}

## 当前已注册的阵营清单：TimeManager 按月结算的广播按这份清单逐阵营发。
## 以后新增 Team 时，同步这里 + MaterialManager.squads_material 的初始账户即可。
const ALL_TEAMS: Array = [Team.PLAYER, Team.ENEMY]

var team_color : Dictionary = {
	Team.PLAYER : Color(0.2,0.9,0.5 ,0.2),
	Team.ENEMY : Color(0.9 , 0.2,0.1 , 0.2)
}
