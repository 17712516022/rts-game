extends Node
## 士兵组件数据仓库（全局单例）：预加载所有士兵组件 .tres。
## 士兵 = 炮台（Top：攻击/攻击范围）+ 底盘（Bottom：生命/速度/防御）自由组合，没有预设兵种。
## 组件用枚举命名（TOP/BOTTOM），通过 *_RES 字典取对应 .tres，工厂按枚举取配置副本。
## 加新组件：.tres 放到 Resource/Soider/，枚举加一项 + *_RES 字典加一行
##（字典插入顺序 = 设计面板 ItemList 条目顺序，务必一致）。

## ============ 炮台（Top） ============
enum TOP {
	普通炮台,   # 普通炮台.tres
	火炮,       # 火炮.tres
	钻头,       # 钻头.tres
	机枪,
	激光
}

const TOP_RES := {
	TOP.普通炮台 : preload("uid://dict00emaaats"),
	TOP.火炮 : preload("uid://2grnsyram06f"),
	TOP.钻头 : preload("uid://hpfgkp4yxpp3"),
	TOP.机枪 : preload("uid://q6spwt2vn4hm"),
	TOP.激光 : preload("uid://ucgswwyt4hxn"),
}

## ============ 底盘（Bottom） ============
enum BOTTOM {
	普通底盘, 高级底盘  # 普通底盘.tres
}

const BOTTOM_RES := {
	BOTTOM.普通底盘: preload("uid://d0ac47jmo7qqr"),
	BOTTOM.高级底盘: preload("uid://bqqpr2ir4cxt1")
}

## 面板展示用的炮台枚举列表（顺序 = 设计面板 TopItemList 条目顺序，即字典插入顺序）
func get_top_list() -> Array:
	return TOP_RES.keys()

## 面板展示用的底盘枚举列表（顺序 = 设计面板 BottomItemList 条目顺序，即字典插入顺序）
func get_bottom_list() -> Array:
	return BOTTOM_RES.keys()
