extends Node2D
## 左側的進化圖鑑：顯示 11 級水果的進化鏈，沒解鎖的畫成灰色剪影。

## 歷史解鎖到的最高等級
var unlocked: int = -1:
	set(value):
		unlocked = value
		queue_redraw()

## 本局剛合成出來的等級，會高亮一下
var highlight: int = -1:
	set(value):
		highlight = value
		queue_redraw()

const MIN_R := 13.0
const MAX_R := 33.0
const GAP := 16.0

var _pulse := 0.0


func _process(delta: float) -> void:
	if highlight >= 0:
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	var count := FruitDB.FRUITS.size()
	var total := 0.0
	for t in count:
		total += _icon_radius(t) * 2.0 + GAP
	total -= GAP

	var y := (GameLayout.SCREEN.y - total) * 0.5 + 20.0

	# 背板
	draw_rect(Rect2(4, y - 34, 108, total + 68), Color(0, 0, 0, 0.18), true)

	var prev := Vector2.ZERO
	for t in count:
		var r := _icon_radius(t)
		var c := Vector2(GameLayout.CODEX_X, y + r)

		if t > 0:
			draw_line(prev, c - Vector2(0, r + 2), Color(1, 1, 1, 0.12), 2.0, true)

		if t <= unlocked:
			if t == highlight:
				var glow: float = 0.5 + 0.5 * sin(_pulse * 8.0)
				draw_circle(c, r + 8.0, Color(1, 0.85, 0.4, 0.25 + 0.35 * glow))
			draw_set_transform(c, 0.0, Vector2.ONE * (r / FruitDB.radius_of(t)))
			FruitArt.draw_fruit(self, t)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(c, r, Color(1, 1, 1, 0.07))
			draw_arc(c, r, 0.0, TAU, 28, Color(1, 1, 1, 0.16), 2.0, true)

		prev = c + Vector2(0, r + 2)
		y += r * 2.0 + GAP


func _icon_radius(tier: int) -> float:
	return lerpf(MIN_R, MAX_R, float(tier) / float(FruitDB.MAX_TIER))
