class_name FruitArt
extends RefCounted
## 純程式化繪製水果——不依賴任何圖片素材。
## 所有函數都以 (0,0) 爲水果圓心，調用方負責 transform。

static func draw_fruit(ci: CanvasItem, tier: int) -> void:
	var r: float = FruitDB.radius_of(tier)
	if tier == FruitDB.WILD:
		_draw_wild(ci, r)
		_draw_face(ci, r, Color(0.22, 0.18, 0.32))
		return

	var info: Dictionary = FruitDB.FRUITS[tier]
	var base: Color = info["color"]

	# 描邊 + 主體 + 假光照
	ci.draw_circle(Vector2.ZERO, r, base.darkened(0.45))
	ci.draw_circle(Vector2.ZERO, r * 0.93, base)
	ci.draw_circle(Vector2(-r * 0.10, -r * 0.14), r * 0.74, base.lightened(0.10))

	match int(info["style"]):
		FruitDB.Style.SEEDS:
			_draw_seeds(ci, r)
		FruitDB.Style.CLUSTER:
			_draw_cluster(ci, r, base)
		FruitDB.Style.CREASE:
			_draw_crease(ci, r, base)
		FruitDB.Style.SCALE:
			_draw_scale(ci, r, base)
		FruitDB.Style.NET:
			_draw_net(ci, r, base)
		FruitDB.Style.STRIPE:
			_draw_stripe(ci, r)

	# 高光
	ci.draw_circle(Vector2(-r * 0.36, -r * 0.44), r * 0.19, Color(1, 1, 1, 0.5))
	ci.draw_circle(Vector2(-r * 0.18, -r * 0.58), r * 0.085, Color(1, 1, 1, 0.32))

	if bool(info["leaf"]):
		_draw_leaf(ci, r)

	_draw_face(ci, r, base.darkened(0.7))


# ---------------------------------------------------------------- 表情

static func _draw_face(ci: CanvasItem, r: float, ink: Color) -> void:
	var eye_r := maxf(1.6, r * 0.095)
	for s in [-1.0, 1.0]:
		var p := Vector2(r * 0.30 * s, -r * 0.03)
		ci.draw_circle(p, eye_r, ink)
		ci.draw_circle(p + Vector2(-eye_r * 0.32, -eye_r * 0.36), eye_r * 0.38, Color(1, 1, 1, 0.9))
	for s in [-1.0, 1.0]:
		ci.draw_circle(Vector2(r * 0.52 * s, r * 0.24), r * 0.115, Color(1.0, 0.42, 0.48, 0.30))
	ci.draw_arc(Vector2(0, r * 0.08), r * 0.24, deg_to_rad(28), deg_to_rad(152),
			14, ink, maxf(1.2, r * 0.05), true)


# ---------------------------------------------------------------- 葉柄

static func _draw_leaf(ci: CanvasItem, r: float) -> void:
	var stem := PackedVector2Array([
		Vector2(-r * 0.055, -r * 0.88),
		Vector2(r * 0.055, -r * 0.88),
		Vector2(r * 0.10, -r * 1.14),
		Vector2(-r * 0.02, -r * 1.12),
	])
	ci.draw_colored_polygon(stem, Color("6b4226"))

	var leaf := PackedVector2Array()
	var pivot := Vector2(r * 0.30, -r * 1.02)
	for i in 18:
		var a := TAU * i / 18.0
		leaf.append(Vector2(cos(a) * r * 0.34, sin(a) * r * 0.13).rotated(-0.5) + pivot)
	ci.draw_colored_polygon(leaf, Color("3f9e4d"))
	ci.draw_line(pivot - Vector2(r * 0.28, -r * 0.14), pivot + Vector2(r * 0.28, -r * 0.14),
			Color("2c7a38"), maxf(1.0, r * 0.022), true)


# ---------------------------------------------------------------- 各種花紋

static func _draw_seeds(ci: CanvasItem, r: float) -> void:
	var seed := Color(1.0, 0.96, 0.80, 0.9)
	for i in 14:
		var a := TAU * i / 14.0 + 0.35
		var rad: float = r * (0.44 if i % 2 == 0 else 0.74)
		ci.draw_circle(Vector2(cos(a), sin(a)) * rad, maxf(1.0, r * 0.042), seed)


static func _draw_cluster(ci: CanvasItem, r: float, base: Color) -> void:
	var dark := base.darkened(0.22)
	var offs := [
		Vector2(0.0, -0.44), Vector2(-0.40, -0.12), Vector2(0.40, -0.12),
		Vector2(-0.22, 0.32), Vector2(0.22, 0.32), Vector2(0.0, 0.06),
	]
	for o in offs:
		var c: Vector2 = o * r
		ci.draw_circle(c, r * 0.30, dark)
		ci.draw_circle(c + Vector2(-r * 0.09, -r * 0.09), r * 0.09, Color(1, 1, 1, 0.22))


static func _draw_crease(ci: CanvasItem, r: float, base: Color) -> void:
	ci.draw_arc(Vector2(-r * 0.52, 0), r * 0.60, deg_to_rad(-50), deg_to_rad(50),
			16, base.darkened(0.16), maxf(1.2, r * 0.045), true)


static func _draw_scale(ci: CanvasItem, r: float, base: Color) -> void:
	var line := base.darkened(0.30)
	var w := maxf(1.0, r * 0.032)
	var d1 := Vector2(1, 1).normalized()
	var d2 := Vector2(1, -1).normalized()
	for i in range(-4, 5):
		var off := i * r * 0.30
		_chord(ci, d1, off, r * 0.9, line, w)
		_chord(ci, d2, off, r * 0.9, line, w)


static func _draw_net(ci: CanvasItem, r: float, base: Color) -> void:
	var net := base.lightened(0.45)
	var w := maxf(1.0, r * 0.03)
	var rr := r * 0.90
	for i in 5:
		var y := lerpf(-0.66, 0.66, i / 4.0) * r
		var h := sqrt(maxf(0.0, rr * rr - y * y))
		ci.draw_line(Vector2(-h, y), Vector2(h, y), net, w, true)
	for i in 5:
		var x := lerpf(-0.66, 0.66, i / 4.0) * r
		var v := sqrt(maxf(0.0, rr * rr - x * x))
		ci.draw_line(Vector2(x, -v), Vector2(x, v), net, w, true)


static func _draw_stripe(ci: CanvasItem, r: float) -> void:
	var dark := Color("1d6b3a")
	for k in 5:
		var u := lerpf(-0.86, 0.86, k / 4.0)
		var pts := PackedVector2Array()
		for j in 13:
			var t := lerpf(-PI * 0.5, PI * 0.5, j / 12.0)
			pts.append(Vector2(u * cos(t) * r * 0.93, sin(t) * r * 0.93))
		ci.draw_polyline(pts, dark, maxf(1.6, r * 0.06), true)


# ---------------------------------------------------------------- 彩虹果

static func _draw_wild(ci: CanvasItem, r: float) -> void:
	ci.draw_circle(Vector2.ZERO, r, Color(0.24, 0.20, 0.34))
	var n := 7
	for i in n:
		var col := Color.from_hsv(float(i) / n, 0.72, 1.0)
		var pts := PackedVector2Array([Vector2.ZERO])
		var a0 := TAU * i / n - PI * 0.5
		var a1 := TAU * (i + 1) / n - PI * 0.5
		for j in 7:
			var a := lerpf(a0, a1, j / 6.0)
			pts.append(Vector2(cos(a), sin(a)) * r * 0.92)
		ci.draw_colored_polygon(pts, col)
	ci.draw_circle(Vector2.ZERO, r * 0.30, Color(1, 1, 1, 0.55))
	ci.draw_circle(Vector2(-r * 0.34, -r * 0.40), r * 0.16, Color(1, 1, 1, 0.6))


# ---------------------------------------------------------------- 工具

## 畫一條被半徑 rad 的圓裁剪過的弦，dir 是方向，off 是到圓心的垂距
static func _chord(ci: CanvasItem, dir: Vector2, off: float, rad: float, col: Color, w: float) -> void:
	var d2 := rad * rad - off * off
	if d2 <= 0.0:
		return
	var h := sqrt(d2)
	var c := Vector2(-dir.y, dir.x) * off
	ci.draw_line(c - dir * h, c + dir * h, col, w, true)
