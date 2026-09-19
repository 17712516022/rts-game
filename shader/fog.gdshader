shader_type canvas_item;

// ====================================================================
// 战争迷雾：玩家单位 / 玩家建筑附近 -> 迷雾 alpha 抹成 0（照亮）
// 位置由 Fog.gd 每帧按"世界坐标"塞进下面两组 uniform 数组。
// 数组长度必须固定（这里各 64 个槽位），用不到的槽位 Fog.gd 会填一个很远的点。
//
// ⚠️ 想改上限：必须同时改这里和 Fog.gd 里的 C_UNITS / C_BUILDINGS，两处数字要对上。
//    注意开销 = 屏幕像素数 x 传入点数，槽位开越大越卡，所以推荐靠"视野剔除"
//    （Fog.gd 只传镜头内的单位）来保证够用，而不是无脑加大这个长度。
// ====================================================================

// ---------- 玩家单位（士兵）----------
uniform vec2 reveal_points[64];
uniform int reveal_count = 0;
uniform float unit_inner = 140.0;      // 内圈：完全照亮
uniform float unit_outer = 220.0;      // 外圈：平滑渐隐结束

// ---------- 玩家建筑 ----------
uniform vec2 building_points[640];
uniform int building_count = 0;
uniform float building_inner = 260.0;  // 建筑照亮范围更大
uniform float building_outer = 380.0;

// ---------- 迷雾浓度（淡入用）----------
// 整体浓度：0 = 迷雾完全透明（看得见地图），1 = 正常迷雾。
// 由 Fog.gd 的 _fade_in 从 0 补间到 1，做出"迷雾渐渐浮上来"的效果。
// 注意：不要试图用节点 modulate 做淡入 —— 本 shader 最后一行是 COLOR = col 整体覆盖，
// 会把 modulate（顶点色）丢掉，所以淡入必须走这个 uniform。
uniform float fog_alpha : hint_range(0.0, 1.0) = 1.0;

// ---------- 迷雾覆盖的世界矩形 ----------
// fog_origin = 左上角世界坐标，fog_size = 覆盖的世界宽高
uniform vec2 fog_origin = vec2(0.0);
uniform vec2 fog_size = vec2(1.0);

// ---------- 迷雾漂移 ----------
// 整张噪声贴图沿水平方向平移的速度，单位 = 每秒走过多少个"贴图宽度"。
//   0    = 静止
//   正值 = 图案向右飘，负值 = 向左飘
// 贴图本身是 seamless（可无缝平铺）的，配合下面的 fract() 绕回时画面连续、看不出接缝。
uniform float flow_speed : hint_range(-0.05, 0.05, 0.001) = 0.004;

// 把一个"照亮源"并进总可见度：
// 距离 <= inner 时为 0（全透明），inner~outer 之间平滑过渡，>= outer 时为 1（保留迷雾）
float apply_source(float reveal, vec2 world, vec2 src, float inner, float outer) {
	float d = distance(world, src);
	return min(reveal, smoothstep(inner, outer, d));
}

void fragment() {
	// 把 UV(0~1) 还原成世界坐标
	vec2 world = fog_origin + UV * fog_size;

	// reveal = 0 表示"被照亮"（迷雾透明），1 表示"保留迷雾"
	float reveal = 1.0;

	// 玩家士兵
	for (int i = 0; i < 64; i++) {
		if (i >= reveal_count) {
			break;
		}
		reveal = apply_source(reveal, world, reveal_points[i], unit_inner, unit_outer);
	}

	// 玩家建筑
	for (int i = 0; i < 64; i++) {
		if (i >= building_count) {
			break;
		}
		reveal = apply_source(reveal, world, building_points[i], building_inner, building_outer);
	}

	// 迷雾整体漂移：只平移"贴图采样坐标"，world 依旧用几何 UV 算，
	// 于是云在飘，照亮圈始终钉在士兵/建筑身上。
	// fract() 把坐标夹回 0~1：长时间运行不会因为浮点精度累积而抖动。
	vec2 flow_uv = vec2(fract(UV.x - TIME * flow_speed), UV.y);
	vec4 col = texture(TEXTURE, flow_uv);
	col.a *= reveal;      // 被照亮的地方 alpha 变 0，露出下面的地图
	col.a *= fog_alpha;   // 再乘整体浓度，淡入时整张迷雾一起变淡
	COLOR = col;
}
