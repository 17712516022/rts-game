extends Node
## 伤害计算器：伤害公式的门面。各层伤害加成（全局 / 阵营 / 个体 buff）统一在
## FinalModifierCalculator 里登记，这里不再自己存修正变量，避免"两个账本各加各的"。
## 用法：take_damage 时调 calculate(actual_attack, defense) 拿到最终伤害值。

## 伤害加成的登记来源名：谁登记伤害修正就把 source 传它，reset_modifiers 才能一并撤掉
const SOURCE := "DamageCalculator"

# 计算最终伤害：攻击力 × 攻击加成 - 防御力，再乘防御方减免，最低 1 点
# attacker_team / defender_team 不传 = 只吃全局加成
func calculate(attack: float, defense: float, attacker_team = null, defender_team = null) -> float:
	return FinalModifierCalculator.damage(attack, defense, attacker_team, defender_team)

# 重置伤害加成（回合/战斗结束时调）：只撤本来源登记的，不动政策、事件等别人的修正
func reset_modifiers() -> void:
	FinalModifierCalculator.clear_source(SOURCE)
