extends Node
## 地图数据仓库（全局单例）
## 比如 MapData.TERRAIN.GRASS、MapData.TERRAIN_COLORS、MapData.grid。

# 地形分界阈值（海拔值范围 -1 到 1）：
const DEEPSEE_LEVEL : float = -0.4 #深海
const NORMALSEE_LEVEL : float= -0.20  # 海洋
const CLOSESEE_LEVEL :float = 0.0 #近海
const PLAIN_LEVEL : float= 0.3     # 平原
const MOUNT_LEVEL : float= 0.5   # 山地
const HIGHERMOUNT_LEVEL : float = 1.0 # 高山

# ============ 地形类型 ============
enum TERRAIN {
	RIVER, #河流
	
	DEEPSEE , #深海
	NORMALSEE ,  # 海洋
	CLOSESEE, #近海
	
	FOREST_PLAIN,   #森林平原
	SAND_PLAIN,    # 沙漠平原
	PLAIN,      # 平原
	SNOW_PLAIN,      # 雪地平原
	
	FOREST_LOWLAND,   #森林丘陵
	SAND_LOWLAND,    # 沙漠丘陵
	LOWLAND,    # 丘陵
	SNOW_LOWLAND,      # 雪地丘陵
	
	FOREST_MOUNT,   #森林山地
	MOUNT,    # 丘陵
	SNOW_MOUNT,      # 雪地山地
	
	HIGHERMOUNT , # 高山
	SNOW_HIGHERMOUNT,      # 雪地山地
}

# ============ 每种地形显示用的颜色 ============
# 以后换成贴图时，这里改成纹理路径即可
const TERRAIN_COLORS := {
	TERRAIN.RIVER : Color(0.35, 0.62, 0.95),
	
	# 海洋（海拔越低越深，颜色越暗）：深海最暗 -> 海洋 -> 近海最亮
	TERRAIN.DEEPSEE: Color(0.0, 0.2, 0.4),
	TERRAIN.NORMALSEE: Color(0.1, 0.3, 0.5),
	TERRAIN.CLOSESEE: Color(0.3, 0.6, 0.7),
	# 陆地（海拔越高颜色越深）：平原最亮 -> 丘陵 -> 山地 -> 高山最暗
	# 暂不考虑气候变体，同一海拔档的 4 种变体用同一个高度色
	# 平原（最亮）
	TERRAIN.FOREST_PLAIN: Color(0.2, 1, 0.2),
	TERRAIN.SAND_PLAIN: Color(1, 1, 0.5),
	TERRAIN.PLAIN: Color(0.7, 1, 0.6),
	TERRAIN.SNOW_PLAIN: Color(0.9, 0.9, 0.9),
	# 山地
	TERRAIN.FOREST_MOUNT: Color(0.05, 0.5, 0.05),
	TERRAIN.MOUNT: Color(0.25, 0.25, 0.25),
	TERRAIN.SNOW_MOUNT: Color(0.7, 0.7, 0.7),
	# 高山（最暗）
	TERRAIN.HIGHERMOUNT: Color(0.05, 0.05, 0.05),
	TERRAIN.SNOW_HIGHERMOUNT: Color(0.6, 0.6, 0.6),
}

# ============ 地图参数（改地图大小就在这里改，全局共用） ============
var map_width: int = 128    # 地图有多少列
var map_height: int = 128   # 地图有多少行
var hex_size: float = 36.0  # 六边形的大小（中心到顶点的距离，像素）

# ============ 地图数据（由 MapGenerater 生成时写入） ============
var terrain_grid : Array = []   # 地形表，grid[行][列] = 地形类型，谁要读地形都从这里取
var elevation_grid : Array = [] #海拔表
var weather_grid : Array = [] #气候表
var river_grid : Array = []   # 河流标记表，river_grid[行][列] = true 表示这格是河道，由 RiverGenerater 写入
# ============ 玩家当前选中的格子（点击时由 Map 脚本写入） ============
var selected_cell: Vector2i = Vector2i(-1, -1)   # x 是行、y 是列，(-1,-1) 表示还没选过

# ============ 每种地形对应的名字（方便打印和以后做界面） ============
const TERRAIN_NAMES := {
	TERRAIN.RIVER : "河流",
	TERRAIN.DEEPSEE: "深海",
	TERRAIN.NORMALSEE: "海洋",
	TERRAIN.CLOSESEE: "近海",
	TERRAIN.FOREST_PLAIN: "森林平原",
	TERRAIN.SAND_PLAIN: "沙漠平原",
	TERRAIN.PLAIN: "平原",
	TERRAIN.SNOW_PLAIN: "雪地平原",
	TERRAIN.FOREST_MOUNT: "森林山地",
	TERRAIN.MOUNT: "山地",
	TERRAIN.SNOW_MOUNT: "雪地山地",
	TERRAIN.HIGHERMOUNT: "高山",
	TERRAIN.SNOW_HIGHERMOUNT: "雪地高山",
}
