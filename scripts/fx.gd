class_name Fx
extends RefCounted
## 一次性特效：粒子迸發 + 飄字。全部運行時生成，用完自動釋放。

static var _dot: ImageTexture


static func dot_texture() -> ImageTexture:
	if _dot != null:
		return _dot
	var size := 16
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf((c - d) / 1.5, 0.0, 1.0)))
	_dot = ImageTexture.create_from_image(img)
	return _dot


static func burst(parent: Node2D, pos: Vector2, color: Color, radius: float, count: int = 18) -> void:
	var p := CPUParticles2D.new()
	p.texture = dot_texture()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = 0.6
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 1100)
	p.initial_velocity_min = radius * 3.0
	p.initial_velocity_max = radius * 8.0
	p.damping_min = 40.0
	p.damping_max = 90.0
	p.scale_amount_min = radius * 0.006
	p.scale_amount_max = radius * 0.014

	var grad := Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = grad

	parent.add_child(p)
	p.emitting = true
	_free_later(p, p.lifetime + 0.3)


## 合成瞬間的白色衝擊環
static func ring(parent: Node2D, pos: Vector2, color: Color, radius: float) -> void:
	var n := Node2D.new()
	n.position = pos
	parent.add_child(n)
	var r := radius
	n.draw.connect(func() -> void:
		n.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1, 1, 1, 0.9), maxf(2.0, r * 0.10), true)
		n.draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 48, color, maxf(1.5, r * 0.06), true))
	n.queue_redraw()

	var tw := n.create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2(2.1, 2.1), 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "modulate:a", 0.0, 0.34)
	tw.chain().tween_callback(n.queue_free)


static func float_text(parent: Node2D, pos: Vector2, text: String, color: Color,
		font_size: int = 34, rise: float = 90.0) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(320, 0)
	l.size = Vector2(320, float(font_size) + 8.0)
	l.position = pos - Vector2(160.0, float(font_size) * 0.6)
	l.z_index = 60
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.12, 0.85))
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 5))
	parent.add_child(l)

	l.scale = Vector2(0.5, 0.5)
	l.pivot_offset = Vector2(160.0, float(font_size) * 0.5)

	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", l.position.y - rise, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.15)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


static func _free_later(node: Node, delay: float) -> void:
	var t := node.get_tree().create_timer(delay)
	t.timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free())
