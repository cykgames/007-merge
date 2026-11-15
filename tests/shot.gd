extends Node
## 开发用截图：跑一段自动投放后把画面存成 res://tests/shot.png
## 用法: godot --path <proj> res://tests/shot.tscn --resolution 720x1280

var main: Node2D
var frame := 0
var _done := false


func _ready() -> void:
	seed(2024)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _process(_delta: float) -> void:
	frame += 1
	if _done:
		return
	if frame % 22 == 0 and frame < 460:
		main._cooldown = 0.0
		main.preview.position.x = randf_range(GameLayout.WALL_L + 80.0, GameLayout.WALL_R - 80.0)
		main._drop()
	if frame == 300:
		main.energy = 100.0
		main._refresh_ui()
	if frame == 560:
		_done = true
		_capture()


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("shot size: ", img.get_size(), "  score=", main.score)
	img.save_png("res://tests/shot.png")

	# 再拍一张结算界面
	main._game_over()
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/shot_over.png")
	get_tree().quit()
