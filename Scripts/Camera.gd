extends Camera2D
## 相机脚本：鼠标滚轮缩放地图

# 缩放限制和速度
const MIN_ZOOM := 0.2    # 最小放大到 0.1 倍（缩小地图，128 地图要看全得缩到这个程度）
const MAX_ZOOM := 10.0    # 最大放大到 3 倍
const ZOOM_STEP := 1.1   # 每滚一格缩放 1.1 倍

# 是否正在按住鼠标中键拖拽视角
var _dragging := false

func _unhandled_input(event: InputEvent) -> void:
	# 处理鼠标按键：中键控制拖拽开关，滚轮负责缩放
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# 中键按下/松开，切换拖拽状态
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			return
		# 滚轮：向上放大，向下缩小（滚轮会连发两事件，只处理按下那次）
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed:
				var factor := ZOOM_STEP if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP
				var new_zoom: Vector2 = clamp(zoom * factor, Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
				zoom = new_zoom
		return
	
	# 处理鼠标移动：按住中键时拖动视角
	if event is InputEventMouseMotion and _dragging:
		# relative 是鼠标这次移动的相对位移
		# 相机离地图越远（zoom 越小），同样的屏幕移动对应的地图距离越大，
		# 所以要把屏幕位移除以 zoom，地图才会跟手。
		position -= event.relative / zoom
