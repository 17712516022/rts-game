class_name SoiderFactory extends Node
## 士兵工厂：按玩家设计的组合（槽位→主炮的映射 + 一个底盘 Bottom 的枚举）取配置副本。
## 部件数据集中在 SoiderComponentData 全局单例（TOP_RES / BOTTOM_RES），这里只负责组合与拷贝。

## 按玩家设计的组合取一份 {turrets, bottom} 配置。
## turret_choices 与底盘 turret_slot_offsets 等长：turret_choices[i] = 槽位 i 的主炮枚举，-1 = 空槽。
## 返回 turrets 逐槽对应：长度 = 槽位数，装炮的槽是 SoiderTopResource 副本，空槽是 null。
## 全部 duplicate 副本而非原件，防止多个士兵实例共享同一份配置互相改数值。
func get_designed_soider_res(turret_choices: Array, bottom: SoiderComponentData.BOTTOM) -> Dictionary:
	var turret_copies: Array = []
	for choice in turret_choices:
		if choice < 0:
			turret_copies.append(null)
			continue
		turret_copies.append((SoiderComponentData.TOP_RES[choice] as Resource).duplicate())
	return {
		"turrets": turret_copies,
		"bottom": (SoiderComponentData.BOTTOM_RES[bottom] as Resource).duplicate(),
	}
