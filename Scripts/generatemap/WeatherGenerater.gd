class_name WeatherGenerater extends Node

# 气候噪声
var weather_noise := FastNoiseLite.new()
var weather_frequency : float = 0.00015  # 数字越小气候带越大块，越大越碎
var weather_seed : int = 1234        # 换一个数字，就生成一种新气候分布

# 气候分带阈值（weather 噪声范围 -1 到 1）：
#   高于 SNOW_THRESHOLD   -> 雪地 / 寒冷海
#   高于 FOREST_THRESHOLD -> 森林
#   低于 SAND_THRESHOLD   -> 沙漠 / 温暖海
#   中间                  -> 普通地形
const SNOW_THRESHOLD : float = 0.3
const FOREST_THRESHOLD : float = 0.0
const SAND_THRESHOLD : float = -0.3

func _ready() -> void:
	EventBus.map_has_generated.connect(_on_map_has_generated)

func _on_map_has_generated() -> void:
	_setup_noise()
	_generate_weather()

func _generate_weather() -> void:
	MapData.weather_grid.clear()
	var terrain_rows: Array = []
	for row in range(MapData.map_height):
		var terrain_row: Array = []
		var weather_row: Array = []
		for line in range(MapData.map_width):
			var pos: Vector2 = PositionCaculater.calculate_position(row, line)
			var weather : float = weather_noise.get_noise_2d(pos.x, pos.y)
			var elevation : float = MapData.elevation_grid[row][line]
			terrain_row.append(_get_terrain(elevation, weather))
			weather_row.append(weather)
		terrain_rows.append(terrain_row)
		MapData.weather_grid.append(weather_row)
	# 覆盖海拔生成的基础地形，加入气候变体
	MapData.terrain_grid = terrain_rows

# 根据海拔定地形层次，再按气候值挑变体（森林/沙漠/普通/雪地）。
# 海洋不叠加气候变体，按海拔原样分成深海 -> 海洋 -> 近海（阈值与 ElevationGenerater 一致），
# 否则整片海都会被刷成同一档「近海」色。
func _get_terrain(elevation : float, weather : float) -> MapData.TERRAIN:
	if elevation < MapData.DEEPSEE_LEVEL:
		return MapData.TERRAIN.DEEPSEE
	elif elevation < MapData.NORMALSEE_LEVEL:
		return MapData.TERRAIN.NORMALSEE
	elif elevation < MapData.CLOSESEE_LEVEL:
		return MapData.TERRAIN.CLOSESEE
	elif elevation < MapData.PLAIN_LEVEL:
		return _land_variant(MapData.TERRAIN.FOREST_PLAIN, MapData.TERRAIN.SAND_PLAIN, MapData.TERRAIN.PLAIN, MapData.TERRAIN.SNOW_PLAIN, weather)
	elif elevation < MapData.MOUNT_LEVEL:
		return _land_variant(MapData.TERRAIN.FOREST_MOUNT, MapData.TERRAIN.MOUNT , MapData.TERRAIN.MOUNT, MapData.TERRAIN.SNOW_MOUNT, weather)
	else :
		return _land_variant( MapData.TERRAIN.HIGHERMOUNT, MapData.TERRAIN.HIGHERMOUNT, MapData.TERRAIN.HIGHERMOUNT, MapData.TERRAIN.SNOW_HIGHERMOUNT, weather)

# 陆地：正雪负沙中间森林，靠近 0 是普通
func _land_variant(forest : int, sand : int, normal : int, snow : int, weather : float) -> int:
	if weather > SNOW_THRESHOLD:
		return snow
	elif weather > FOREST_THRESHOLD:
		return forest
	elif weather < SAND_THRESHOLD:
		return sand
	return normal

# ============ 噪声配置 ============
func _setup_noise() -> void:
	weather_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	weather_noise.frequency = weather_frequency
	weather_noise.seed = weather_seed
