class_name WaterVFX extends Node2D

## 描边宽度（像素）
const LINE_WIDTH : float = 6.0
## 河流描边色：固定绿，不跟阵营走（所有中心的河流长得一样）
const RIVER_COLOR : Color = Color(0.15, 0.85, 0.35, 0.95)

## 已注册的行政中心清单就在它里面（字典当 HashSet 用），直接读，不再自己维护一份
@onready var _ownership: CenterOwnerManager = %CenterOwnershipManager

## 本地缓存的六边形 6 顶点（相对中心 (0,0)），和 MapGenerater.hex_corners / PolicyHighLighter 同一套
var _hex_local: PackedVector2Array = []

func _ready() -> void:
	_hex_local = _build_hex_local()
	EventBus.construct_building.connect(_request_redraw)
	EventBus.construction_destroyed.connect(_request_redraw)
	EventBus.team_refresh_requested.connect(_request_redraw)

func _request_redraw(_a = null, _b = null) -> void:
	queue_redraw()

func _draw() -> void:
	if _ownership == null or _hex_local.is_empty():
		return
	# 地图/归属表还没生成（编辑器预览、开局早期）时画不了
	if ConstructionData.owner_grid.is_empty() or MapData.terrain_grid.is_empty():
		return

	for c in _ownership.centers.keys():
		var center: Construction = c
		if not is_instance_valid(center):
			continue
		# 这个中心辖下没有港口 → 它的水路不通，不画
		if not WaterData.has_port(center):
			continue
	
		# 中心管辖的格子必然落在它的势力半径内（CenterOwnershipManager 就是这么划的），
		# 所以只扫这一小片（半径 3，约 37 格），不扫全图
		for cell in PositionCaculater.search_closest_cell(center.cell, CenterOwnerManager.OWNER_RADIUS):
			# 判定统一走 WaterData.is_navigable_river（= 河流 + 归属中心已有建成港口），
			# 和 Mover / PathFinder 的加速条件完全同源，不会出现"画了边却没加速"
			if not WaterData.is_navigable_river(cell):
				continue
			_draw_hex_outline(cell, RIVER_COLOR)

## 给一个格子描一圈六边形边框：6 个顶点 + 首点补到末尾闭合成环。
## 相邻河流格会共用一条边（画两遍，颜色一样，看不出接缝）。
func _draw_hex_outline(cell: Vector2i, color: Color) -> void:
	var world_center: Vector2 = PositionCaculater.calculate_position(cell.x, cell.y)
	var points := PackedVector2Array()
	points.resize(7)
	for i in range(6):
		points[i] = world_center + _hex_local[i]
	points[6] = points[0]   # 闭合：polyline 不会自己连回起点
	draw_polyline(points, color, LINE_WIDTH, true)

## 和 MapGenerater.hex_corners 完全一致（平顶 0° 起算，60° 一步）
func _build_hex_local() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i)
		points.append(Vector2(cos(angle), sin(angle)) * MapData.hex_size)
	return points
