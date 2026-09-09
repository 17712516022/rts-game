class_name MaterialUI extends Control
## 资源栏 UI：显示四种资源数量，监听 MaterialManager 的 material_changed 信号实时刷新。

@onready var gold_label: Label = %GoldLabel
@onready var wood_label: Label = %WoodLabel
@onready var mine_label: Label = %MineLabel
@onready var food_label: Label = %FoodLabel
@onready var population_label: Label = %PopulationLabel

func _ready() -> void:
	EventBus.material_changed.connect(_on_material_changed)
	# 进场先刷一遍，避免显示默认数字
	refresh_all()

# 信号回调：资源变动时只更新对应的那个标签（只认玩家阵营，敌人入账不刷玩家 UI）
func _on_material_changed(materials: MaterialManager.MATERIAL, value: float, squad: TeamData.Team) -> void:
	if squad != TeamData.Team.PLAYER:
		return
	var label := _label_of(materials)
	if label != null:
		label.text = str(int(value))

# 把四种资源全刷一遍
func refresh_all() -> void:
	for materials in MaterialManager.MATERIAL.values():
		var label := _label_of(materials)
		if label != null:
			label.text = str(int(MaterialManager.get_material_number(materials,TeamData.Team.PLAYER)))

# 资源枚举 -> 对应标签
func _label_of(materials: MaterialManager.MATERIAL) -> Label:
	match materials:
		MaterialManager.MATERIAL.GOLD:
			return gold_label
		MaterialManager.MATERIAL.FOOD:
			return food_label
		MaterialManager.MATERIAL.WOOD:
			return wood_label
		MaterialManager.MATERIAL.MINE:
			return mine_label
		MaterialManager.MATERIAL.POPULATION:
			return population_label
	return null
