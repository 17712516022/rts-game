extends Node

# ————— 修正种类（key）：和 ModifierData 的列名同名，产出按材料分开 —————
## 移动速度系数（1.0 正常，0 = 不能走）
const MOVE_SPEED := "MoveSpeedModifier"
## 建造速度系数（1.0 正常，越高建得越快，0 = 不能建）
const CONSTRUCT_SPEED := "ConstructModifier"
## 产出系数：食物 / 产能（矿）/ 金币 / 木材（木材没有地形列，基值恒 1.0）
const OUTPUT_FOOD := "FoodModifier"
const OUTPUT_PRODUCTION := "ProductionModifier"
const OUTPUT_GOLD := "GoldModifier"
const OUTPUT_WOOD := "WoodModifier"
## 伤害修正：攻方加成 / 防御方减免（1.0 无影响）
const DAMAGE_ATTACK := "DamageAttackModifier"
const DAMAGE_DEFENSE := "DamageDefenseModifier"
## 人口增长系数 / 税率系数（月结算用，MonthlyMaterialCalculator 的占位修正将来并到这里）
const POP_GROWTH := "PopGrowthModifier"
const TAX := "TaxModifier"

## 没有地形基值（伤害、木材、人口…）的修正的基值：1.0 = 中性
const NEUTRAL : float = 1.0
## 地形没给出这类修正时的基值，同上
const NO_TERRAIN_DATA : float = 1.0
## 地形查不到 / 越界：0 = 该地形上这类修正彻底不可用（不能建、不能走）
const BLOCKED : float = 0.0

## 登记表：key -> Array[Dictionary]，每项 {value, source, team, entity}
var _entries: Dictionary = {}
## 结果缓存：String -> float。任何登记/撤销都整体清空（登记很少发生，重算很便宜）
var _cache: Dictionary = {}

# ============ 登记 / 撤销 ============

## 登记一条修正。同一个 (key, source, team, entity) 重复登记 = 覆盖旧值，不会越乘越多。
## team / entity 不传 = 全局生效。
func set_modifier(key: String, value: float, source: String, team = null, entity = null) -> void:
	_remove(key, source, team, entity)
	if not _entries.has(key):
		_entries[key] = []
	_entries[key].append({"value": value, "source": source, "team": team, "entity": entity})
	_cache.clear()

## 一次性撤掉某个来源登记的所有修正（政策到期、buff 消失时调这个，比逐条 key 撤干净）
func clear_source(source: String) -> void:
	for key in _entries.keys():
		var kept: Array = []
		for e in _entries[key]:
			if e["source"] != source:
				kept.append(e)
		if kept.is_empty():
			_entries.erase(key)
		else:
			_entries[key] = kept
	_cache.clear()

## 全部清空（回主菜单 / 重开一局时调）：所有修正回到"只有地形基值"
func clear_all() -> void:
	_entries.clear()
	_cache.clear()


## 取最终修正值 = 地形基值 × Π(匹配的登记值)。
## terrain 传 MapData.TERRAIN；team 传 TeamData.Team；entity 传建筑 / 部队节点。
## 返回 0 = 不可用（不能建 / 不能走），调用方自己判。
func final(key: String, terrain = null, team = null, entity = null) -> float:
	var base: float = _terrain_base(key, terrain)
	if _entries.is_empty():
		return base   # 开局默认：一条修正都没登记，连缓存都不用走
	var cache_key := "%s|%s|%s|%s" % [key, terrain, team, _entity_id(entity)]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var result: float = base
	for e in _entries.get(key, []):
		if _matches(e, team, entity):
			result *= e["value"]
	_cache[cache_key] = result
	return result

## 这格能不能走 / 能不能建：最终值 > 0 才算可用
func is_usable(key: String, terrain = null, team = null, entity = null) -> bool:
	return final(key, terrain, team, entity) > 0.0

## 移动速度系数（Mover 取实际速度、PathFinder 算通行代价都用它 → 走得快和算得近同源）
func move_speed(terrain, team = null, entity = null) -> float:
	return final(MOVE_SPEED, terrain, team, entity)

## 建造速度系数（越高建得越快，0 = 不能建）
func build_speed(terrain, team = null, entity = null) -> float:
	return final(CONSTRUCT_SPEED, terrain, team, entity)

## 建造时间修正 = 1 / 建造速度（>1 = 建得更久）。
## 不能建的地形返回 INF——调用方一眼看得出是"建不了"，不要去乘出个 0 当瞬时完工。
func build_time_multiplier(terrain, team = null, entity = null) -> float:
	var speed: float = build_speed(terrain, team, entity)
	if speed <= 0.0:
		return INF
	return 1.0 / speed

## 某材料在某地形上的最终产出系数（产出 = base × 它）
func output_factor(material: MaterialManager.MATERIAL, terrain, team = null, entity = null) -> float:
	return final(output_key(material), terrain, team, entity)

## 最终伤害：攻击力 × 攻击加成 - 防御力，再乘防御方减免，最低 1 点。
## 和 DamageCalculator.calculate 同一套公式，只是加成改成按 阵营/个体 查。
func damage(attack: float, defense: float, attacker_team = null, defender_team = null,
		attacker = null, defender = null) -> float:
	var boosted: float = attack * final(DAMAGE_ATTACK, null, attacker_team, attacker)
	var after_defense: float = boosted - defense
	var final_damage: float = after_defense * final(DAMAGE_DEFENSE, null, defender_team, defender)
	# 最低 1 点伤害（避免完全免疫导致打不死）
	return maxf(1.0, final_damage)

## 材料枚举 -> 产出修正 key（木材没有地形列，基值 1.0，但可以登记加成）
func output_key(material: MaterialManager.MATERIAL) -> String:
	match material:
		MaterialManager.MATERIAL.GOLD:
			return OUTPUT_GOLD
		MaterialManager.MATERIAL.FOOD:
			return OUTPUT_FOOD
		MaterialManager.MATERIAL.MINE:
			return OUTPUT_PRODUCTION
		MaterialManager.MATERIAL.WOOD:
			return OUTPUT_WOOD
	return OUTPUT_WOOD

## 地形基值：查 ModifierData 里这一列。没传地形 = 没有基值可取，按中性 1.0；
## 地形越界 / 查不到 = 0（不能建、不能走）；这个地形没给这类修正（如木材）= 中性 1.0
func _terrain_base(key: String, terrain) -> float:
	if terrain == null:
		return NEUTRAL
	if not ModifierData.Modifiers.has(terrain):
		return BLOCKED
	var row: Dictionary = ModifierData.Modifiers[terrain]
	if not row.has(key):
		return NO_TERRAIN_DATA
	return row[key]

## 这条登记对本次查询生效吗：登记时带了的维度，查询时也必须带同样的值
func _matches(e: Dictionary, team, entity) -> bool:
	if e["team"] != null and e["team"] != team:
		return false
	if e["entity"] != null:
		# 登记的对象已经被 free（buff 挂在已死单位上）→ 不再生效
		if not is_instance_valid(e["entity"]) or e["entity"] != entity:
			return false
	return true

## 同 (key, source, team, entity) 去重：同来源重复登记是覆盖，不是叠加
func _remove(key: String, source: String, team, entity) -> void:
	if not _entries.has(key):
		return
	var kept: Array = []
	for e in _entries[key]:
		var same: bool = e["source"] == source and e["team"] == team and e["entity"] == entity
		if not same:
			kept.append(e)
	_entries[key] = kept

## 缓存 key 用实体 id：对象不能直接当字典 key 拼进字符串
func _entity_id(entity) -> String:
	if entity == null or not is_instance_valid(entity):
		return "-"
	return str(entity.get_instance_id())
