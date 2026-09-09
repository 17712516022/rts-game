extends Node
## 伤害计算器：集中处理所有伤害公式，方便以后加 buff/减伤/暴击等修饰。
## 用法：take_damage 时调 calculate(actual_attack, defender) 拿到最终伤害值。

## 攻击方 buff 修正（乘算，1.0=无加成）。外部设置，比如狂暴 buff 设 1.5
var attacker_modifier: float = 1.0
## 防御方 buff 修正（乘算，1.0=无减免）。外部设置，比如护盾 buff 设 0.5
var defender_modifier: float = 1.0

# 计算最终伤害：攻击力 × 攻击buff - 防御力，再乘防御buff减免，最低 1 点
func calculate(attack: float, defense: float) -> float:
	# 第一步：基础伤害 = 攻击力 × 攻击方加成 - 防御力
	var base: float = attack * attacker_modifier - defense
	# 第二步：乘防御方减免（比如护盾减半伤害）
	var final: float = base * defender_modifier
	# 最低 1 点伤害（避免完全免疫导致打不死）
	return maxf(1.0, final)

# 重置所有 buff 修正（回合结束时调）
func reset_modifiers() -> void:
	attacker_modifier = 1.0
	defender_modifier = 1.0
