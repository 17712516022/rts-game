class_name AIDesign extends BTLeaf

func execute(ctx : Dictionary) -> int:
	return design(ctx)

func design(ctx : Dictionary) -> int:
	var squad : TeamData.Team = ctx["squad"]
	var bottom : int = -1
	var tops : Array = []
	
	# 挑底盘：必须「底盘 + 至少一门炮」整单买得起才算数（光底盘没炮 = 白送，不出）。
	# 和原逻辑一样偏爱字典里靠后（更贵）的底盘，只是预算线抬高了一门保底炮。
	for key in SoiderComponentData.BOTTOM_RES :
		var bottom_res : SoiderBottomResource = SoiderComponentData.BOTTOM_RES[key]
		for top_key in SoiderComponentData.TOP_RES :
			var base_cost : Dictionary = SoiderDesign.merge_cost(bottom_res, [SoiderComponentData.TOP_RES[top_key]])
			if MaterialManager.can_afford(base_cost, squad):
				bottom = key
				tops = [top_key]     # 先锁一门保底炮，保证 tops 永不为空
				break
	
	if bottom < 0:                    # 连「底盘 + 最便宜的一门炮」都造不起：攒钱下轮再说
		return Status.FALIURE
	
	# 贪心补炮：上限 = 底盘槽位数（多买的炮钱照扣却装不上，纯浪费）
	var slot_count : int = SoiderComponentData.BOTTOM_RES[bottom].slot_count()
	for key in SoiderComponentData.TOP_RES :
		if tops.size() >= slot_count:
			break
		if tops.has(key):            # 保底炮已经算过，不重复买
			continue
		var next_tops : Array = tops.duplicate()
		next_tops.append(key)
		var next_res : Array = []
		
		for i in next_tops:
			next_res.append(SoiderComponentData.TOP_RES[i])
		var next_total_cost : Dictionary = SoiderDesign.merge_cost(
			SoiderComponentData.BOTTOM_RES[bottom], next_res
		)
		if MaterialManager.can_afford(next_total_cost, squad):
			tops.append(key)
	
	var pos : Vector2 = select_spawn_pos(ctx)
	if pos == Vector2(-1,-1):
		construct_barracks(ctx)
		return Status.FALIURE
	
	spawn_soider(bottom, tops, pos)
	return Status.SUCCESS

func select_spawn_pos(ctx : Dictionary) -> Vector2:
	var barracks : Array = []
	for b in ConstructionData.buildings_by_squad.get(ctx["squad"], []):
		var build : Construction = b
		if build is Construction and build.res != null and build.res.display_name == "兵营":
			if not build.is_under_construction and not build.is_spawn_army:
				barracks.append(build)
	
	if barracks.is_empty():
		return Vector2(-1, -1)
	return barracks.pick_random().global_position

func construct_barracks(ctx : Dictionary) -> void:
	var construction_manager : ConstructionManager = ctx["construction_manager"]
	var cells : Array = AiTools.find_empty_cells(ctx["centres"])
	if not cells.is_empty():
		var pos : Vector2i = cells.pick_random()
		construction_manager.try_build(pos, ConstructionData.Constructions.ARMY,[],ctx["squad"])

func spawn_soider(bottom : int , tops : Array ,pos : Vector2) -> void:
	EventBus.spawn_soider.emit(tops , bottom , pos)
