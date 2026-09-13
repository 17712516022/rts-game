class_name AIDesign extends BTLeaf

func execute(ctx : Dictionary) -> int:
	return design(ctx)

func design(ctx : Dictionary) -> int:
	var bottom : int = -1
	var tops : Array = []
	
	for key in SoiderComponentData.BOTTOM_RES :
		if MaterialManager.can_afford(SoiderComponentData.BOTTOM_RES[key].resource_cost_enum(), ctx["squad"]):
			bottom = key
	
	if bottom < 0:                    # 连最便宜的底盘都造不起
		return Status.FALIURE
	
	for key in SoiderComponentData.TOP_RES :
		var next_tops : Array = tops.duplicate()
		next_tops.append(key)
		var next_res : Array = []
		
		for i in next_tops:
			next_res.append(SoiderComponentData.TOP_RES[i])
		var next_total_cost : Dictionary = SoiderDesign.merge_cost(
			SoiderComponentData.BOTTOM_RES[bottom], next_res
		)
		if MaterialManager.can_afford(next_total_cost, ctx["squad"]):
			tops.append(key)
	
	var pos : Vector2 = select_spawn_pos(ctx)
	if pos == Vector2(-1,-1):
		return Status.FALIURE
	
	spawn_soider(bottom, tops, pos)
	return Status.SUCCESS

func select_spawn_pos(ctx : Dictionary) -> Vector2:
	var barracks : Array = []
	for b in ConstructionData.buildings_by_squad.get(ctx["squad"], []):
		if b is Construction and b.res != null and b.res.display_name == "兵营":
			barracks.append(b)
	if barracks.is_empty():
		return Vector2(-1, -1)
	return barracks.pick_random().global_position

func spawn_soider(bottom : int , tops : Array ,pos : Vector2) -> void:
	EventBus.spawn_soider.emit(tops , bottom , pos)
