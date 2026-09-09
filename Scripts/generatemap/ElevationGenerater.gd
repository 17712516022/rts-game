class_name ElevationGenerater extends Node

# ============ 地形生成参数（想换地图长相，只改这里） ============
# 海拔噪声：决定大陆和海洋的形状
var elevation_noise := FastNoiseLite.new()
var elevation_frequency : float = 0.0002  # 数字越小大陆越大块，越大越碎
var elevation_seed : int = 12345        # 换一个数字，就生成一张新地图

func _ready() -> void:
	_setup_noise()
	_generate_terrain()
	# 等所有节点的 _ready 都执行完（下一帧）再发开工信号，
	# 避免其他生成器还没来得及订阅就错过信号
	await get_tree().process_frame
	EventBus.map_has_generated.emit()

# ============ 噪声配置 ============
func _setup_noise() -> void:
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elevation_noise.frequency = elevation_frequency
	elevation_noise.seed = elevation_seed

# ============ 生成地形 ============
func _generate_terrain() -> void:
	MapData.terrain_grid.clear()
	MapData.elevation_grid.clear()
	for row in range(MapData.map_height):
		var rows: Array = []
		var elevation_rows :Array = []
		for line in range(MapData.map_width):
			var pos: Vector2 = PositionCaculater.calculate_position(row, line)
			var elevation : float = elevation_noise.get_noise_2d(pos.x, pos.y)
			
			rows.append(_get_terrain(elevation))
			elevation_rows.append(elevation)
		
		MapData.terrain_grid.append(rows)
		MapData.elevation_grid.append(elevation_rows)

# 根据一格的位置查噪声，决定它是什么地形（只定海拔层次，气候变体由 WeatherGenerater 叠加）
func _get_terrain(elevation : float) -> MapData.TERRAIN:
	if elevation < MapData.DEEPSEE_LEVEL:
		return MapData.TERRAIN.DEEPSEE
	elif elevation < MapData.NORMALSEE_LEVEL:
		return MapData.TERRAIN.NORMALSEE
	elif elevation < MapData.CLOSESEE_LEVEL:
		return MapData.TERRAIN.CLOSESEE
	elif elevation < MapData.PLAIN_LEVEL:
		return MapData.TERRAIN.PLAIN
	elif elevation < MapData.MOUNT_LEVEL:
		return MapData.TERRAIN.MOUNT
	elif elevation < MapData.HIGHERMOUNT_LEVEL:
		return MapData.TERRAIN.MOUNT
	else:
		return MapData.TERRAIN.HIGHERMOUNT
