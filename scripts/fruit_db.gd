class_name FruitDB
extends RefCounted
## 水果數據表：等級 -> 半徑 / 顏色 / 名稱 / 外觀樣式。
## 等級 0 是櫻桃，等級 10 是大西瓜。WILD(-1) 是特色玩法裏的彩虹果。

enum Style { PLAIN, SEEDS, CLUSTER, CREASE, SCALE, NET, STRIPE }

const WILD := -1              ## 彩虹果（萬能果）
const NO_MERGE := -99         ## 兩者不能合成
const ANNIHILATE := -2        ## 雙雙消失（兩個大西瓜 / 彩虹果碰大西瓜）

const MAX_TIER := 10          ## 大西瓜
const SPAWN_MAX_TIER := 4     ## 只會掉落前 5 種
const WILD_RADIUS := 44.0
const WILD_MERGE_TIER := 4    ## 彩虹果 + 彩虹果 的產物

const FRUITS: Array[Dictionary] = [
	{"name": "櫻桃",   "radius": 24.0,  "color": Color("e0304a"), "style": Style.PLAIN,   "leaf": true},
	{"name": "草莓",   "radius": 31.0,  "color": Color("ff566f"), "style": Style.SEEDS,   "leaf": true},
	{"name": "葡萄",   "radius": 40.0,  "color": Color("9b5de5"), "style": Style.CLUSTER, "leaf": true},
	{"name": "橘子",   "radius": 49.0,  "color": Color("ff9f1c"), "style": Style.PLAIN,   "leaf": true},
	{"name": "柿子",   "radius": 59.0,  "color": Color("f4731c"), "style": Style.PLAIN,   "leaf": true},
	{"name": "蘋果",   "radius": 71.0,  "color": Color("e03b3b"), "style": Style.PLAIN,   "leaf": true},
	{"name": "梨子",   "radius": 83.0,  "color": Color("d3dd52"), "style": Style.PLAIN,   "leaf": true},
	{"name": "水蜜桃", "radius": 97.0,  "color": Color("ffa1b5"), "style": Style.CREASE,  "leaf": true},
	{"name": "鳳梨",   "radius": 113.0, "color": Color("f5c445"), "style": Style.SCALE,   "leaf": true},
	{"name": "哈密瓜", "radius": 132.0, "color": Color("a9d69b"), "style": Style.NET,     "leaf": false},
	{"name": "大西瓜", "radius": 154.0, "color": Color("3aa35f"), "style": Style.STRIPE,  "leaf": false},
]

## 掉落權重：越小的水果越常出現
const SPAWN_WEIGHTS: Array[int] = [30, 26, 20, 14, 10]


static func radius_of(tier: int) -> float:
	if tier == WILD:
		return WILD_RADIUS
	return FRUITS[tier]["radius"]


static func color_of(tier: int) -> Color:
	if tier == WILD:
		return Color("ff7fd0")
	return FRUITS[tier]["color"]


static func name_of(tier: int) -> String:
	if tier == WILD:
		return "彩虹果"
	return FRUITS[tier]["name"]


## 合成出該等級時得到的基礎分（1, 3, 6, 10, ... 三角數）
static func value_of(tier: int) -> int:
	if tier == WILD:
		return 20
	return int((tier + 1) * (tier + 2) / 2.0)


static func random_spawn_tier() -> int:
	var total := 0
	for w in SPAWN_WEIGHTS:
		total += w
	var r := randi() % total
	for i in SPAWN_WEIGHTS.size():
		r -= SPAWN_WEIGHTS[i]
		if r < 0:
			return i
	return 0


## 返回 a、b 相撞後應該產生的等級；NO_MERGE 表示不合成，ANNIHILATE 表示同歸於盡
static func merge_result(a: int, b: int) -> int:
	if a == WILD and b == WILD:
		return WILD_MERGE_TIER
	if a == WILD or b == WILD:
		var other: int = b if a == WILD else a
		if other == MAX_TIER:
			return ANNIHILATE
		return other + 1
	if a != b:
		return NO_MERGE
	if a == MAX_TIER:
		return ANNIHILATE
	return a + 1


static func can_merge(a: int, b: int) -> bool:
	return merge_result(a, b) != NO_MERGE
