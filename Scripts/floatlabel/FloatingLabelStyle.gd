class_name FloatingLabelStyle extends RefCounted

## 未知 / 没指定材料：不上色，保持 RichTextLabel 自己的颜色
const DEFAULT_COLOR : Color = Color.WHITE

## 材料枚举 -> 颜色。要调配色只改这一处。
static func material_color(material : int) -> Color:
	match material:
		MaterialManager.MATERIAL.GOLD:       return Color("#FFD447")  # 金黄
		MaterialManager.MATERIAL.FOOD:       return Color("#7ED957")  # 草绿
		MaterialManager.MATERIAL.WOOD:       return Color("#C08A4E")  # 木棕
		MaterialManager.MATERIAL.MINE:       return Color("#9FB3C8")  # 石灰蓝
		MaterialManager.MATERIAL.POPULATION: return Color("#6EC1E4")  # 青蓝
	return DEFAULT_COLOR

## 用材料色把文本包成 BBCode。material < 0 = 不上色，原样返回。
static func material_bbcode(material : int, text : String) -> String:
	if material < 0:
		return text
	return "[color=#%s][b]%s[/b][/color]" % [material_color(material).to_html(false), text]
