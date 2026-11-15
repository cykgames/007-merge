extends Node
## 临时冒烟测试：自动投放 + 触发技能 + 检查结束流程。
## 用法: godot --headless --path <proj> res://tests/smoke.tscn

var main: Node2D
var frame := 0


func _ready() -> void:
	seed(12345)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	print("autoloads: SaveData=", get_node_or_null("/root/SaveData") != null,
		" Sfx=", get_node_or_null("/root/Sfx") != null)


func _process(_delta: float) -> void:
	frame += 1
	if main == null or not is_instance_valid(main):
		get_tree().quit()
		return

	if frame % 10 == 0 and frame < 700:
		main._cooldown = 0.0
		main.preview.position.x = randf_range(GameLayout.WALL_L + 70.0, GameLayout.WALL_R - 70.0)
		main._drop()

	if frame == 200:
		main.energy = 100.0
		main._use_skill(1)
		print("[200] shake ok, energy=", main.energy)

	if frame == 260:
		main.energy = 100.0
		main._use_skill(2)
		print("[260] rainbow ok, current_tier=", main.current_tier)

	if frame == 320:
		main.energy = 100.0
		main._use_skill(0)
		var kids: Array = main.fruits_root.get_children()
		if kids.size() > 0:
			main._swing_hammer(kids[0].global_position)
		print("[320] hammer ok, energy=", main.energy, " armed=", main.hammer_armed)

	if frame == 400:
		main._spawn_fruit(3, Vector2(GameLayout.center_x() - 30.0, 500.0), Vector2.ZERO)
		main._spawn_fruit(3, Vector2(GameLayout.center_x() + 30.0, 500.0), Vector2.ZERO)

	if frame == 500:
		main._spawn_fruit(FruitDB.MAX_TIER, Vector2(GameLayout.center_x() - 100.0, 700.0), Vector2(200, 0))
		main._spawn_fruit(FruitDB.MAX_TIER, Vector2(GameLayout.center_x() + 100.0, 700.0), Vector2(-200, 0))

	if frame == 700:
		print("[700] score=", main.score, " fruits=", main.fruits_root.get_child_count(),
			" unlocked=", SaveData.unlocked_tier, " danger=", main._danger,
			" playing=", main._playing)

	if frame == 1500:
		print("[1500] score=", main.score, " fruits=", main.fruits_root.get_child_count(),
			" playing=", main._playing,
			" gameover_visible=", main.game_over_panel.visible,
			" best=", SaveData.best_score)
		get_tree().quit()
