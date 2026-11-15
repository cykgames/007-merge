extends Node2D
## 背景、玻璃罐和死亡線。全部用 draw 指令畫出來。

## 0..1，越接近 1 說明越危險，死亡線會變紅並加速閃爍
var danger: float = 0.0:
	set(value):
		var was := danger
		danger = clampf(value, 0.0, 1.0)
		if absf(was - danger) > 0.001:
			queue_redraw()

var _bg: GradientTexture2D
var _jar: StyleBoxFlat
var _inner: StyleBoxFlat
var _time := 0.0


func _ready() -> void:
	var g := Gradient.new()
	g.set_color(0, Color("241a33"))
	g.set_color(1, Color("54294c"))
	_bg = GradientTexture2D.new()
	_bg.gradient = g
	_bg.width = 4
	_bg.height = 256
	_bg.fill_from = Vector2(0, 0)
	_bg.fill_to = Vector2(0, 1)

	_jar = StyleBoxFlat.new()
	_jar.bg_color = Color(1, 1, 1, 0.07)
	_jar.set_corner_radius_all(38)
	_jar.set_border_width_all(4)
	_jar.border_color = Color(1, 1, 1, 0.16)

	_inner = StyleBoxFlat.new()
	_inner.bg_color = Color(0.09, 0.05, 0.14, 0.35)
	_inner.corner_radius_top_left = 18
	_inner.corner_radius_top_right = 18
	_inner.corner_radius_bottom_left = 28
	_inner.corner_radius_bottom_right = 28


func _process(delta: float) -> void:
	_time += delta
	if danger > 0.01:
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(_bg, Rect2(Vector2.ZERO, GameLayout.SCREEN), false)

	# 背景光暈
	draw_circle(Vector2(GameLayout.center_x(), 300.0), 420.0, Color(1, 0.7, 0.4, 0.045))

	var l := GameLayout.WALL_L
	var r := GameLayout.WALL_R
	var top := 150.0
	var bot := GameLayout.FLOOR_Y

	_jar.draw(get_canvas_item(), Rect2(l - 16, top - 16, r - l + 32, bot - top + 32))
	_inner.draw(get_canvas_item(), Rect2(l, top, r - l, bot - top))

	# 玻璃反光（很淡，只是讓罐壁不那麼平）
	draw_line(Vector2(l + 22, top + 70), Vector2(l + 22, bot - 220), Color(1, 1, 1, 0.028), 16.0, true)
	draw_line(Vector2(r - 30, top + 130), Vector2(r - 30, bot - 320), Color(1, 1, 1, 0.02), 9.0, true)

	_draw_death_line(l, r)


func _draw_death_line(l: float, r: float) -> void:
	var y := GameLayout.DEATH_Y
	var calm := Color(1, 1, 1, 0.22)
	var alarm := Color(1.0, 0.30, 0.32, 0.95)
	var speed: float = lerpf(2.0, 11.0, danger)
	var pulse: float = 0.6 + 0.4 * sin(_time * speed)
	var col: Color = calm.lerp(alarm, danger)
	col.a *= lerpf(1.0, pulse, danger)

	# 虛線
	var x := l + 6.0
	var dash := 22.0
	var gap := 16.0
	while x < r - 6.0:
		var x2 := minf(x + dash, r - 6.0)
		draw_line(Vector2(x, y), Vector2(x2, y), col, 4.0, true)
		x = x2 + gap

	if danger > 0.02:
		# 頂部危險漸隱帶
		var band := Color(alarm.r, alarm.g, alarm.b, 0.16 * danger * pulse)
		draw_rect(Rect2(l, 150.0, r - l, y - 150.0), band)
