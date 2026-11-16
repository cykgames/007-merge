extends Node
## Headless core-rule test for 007-merge -- the repo's FIRST automated test
## (before this, tools/ had only probe_hud_font.gd and tests/smoke.gd printed
## state without a single assert or exit code).
##
## Run: godot --headless --path . res://tools/test_core.tscn
##
## Proves (exit 0 = pass, 1 = fail; marker MERGE_TEST_PASS / MERGE_TEST_FAIL):
## 1. _drop() adds exactly one fruit and advances current_tier to next_tier.
## 2. Negative control: a second drop inside DROP_COOLDOWN adds nothing.
## 3. Two same-tier fruits spawned in contact merge through the REAL physics
##    pipeline (body_entered -> merge_requested -> _do_merge): score increases
##    and the fruit count follows the 2->1 rule.
## 4. FruitDB merge table: same tier +1, different tiers NO_MERGE, max tier
##    ANNIHILATE, WILD promotes the other fruit, WILD+max ANNIHILATE,
##    WILD+WILD -> WILD_MERGE_TIER.
## L0 only: rules/state, NOT a touch proof (no GUI event pipeline involved).
## May write the DESKTOP headless user:// save via SaveData.unlock -- never
## the phone save; irrelevant to the released APK.
## Author: cykbot9 (AI agent).

var main: Node2D
var frame := 0
var _fails := 0
var _score_before := 0
var _count_before := 0


func _ready() -> void:
	seed(777)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	# Deterministic tiers for the drop assertions.
	main.current_tier = 0
	main.next_tier = 1
	main._apply_current_tier()


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


func _process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		_count_before = main.fruits_root.get_child_count()
		main._cooldown = 0.0
		main.preview.position.x = GameLayout.center_x()
		main._drop()
		_check("drop_adds_one_fruit",
			main.fruits_root.get_child_count() == _count_before + 1)
		_check("drop_advances_tier", main.current_tier == 1)
		var c: int = main.fruits_root.get_child_count()
		main._drop()   # still inside DROP_COOLDOWN -> must be refused
		_check("cooldown_blocks_second_drop",
			main.fruits_root.get_child_count() == c)
	elif frame == 60:
		# Two cherries spawned overlapping -> real contact merge.
		var cx := GameLayout.center_x()
		_score_before = main.score
		_count_before = main.fruits_root.get_child_count()
		main._spawn_fruit(0, Vector2(cx - 20.0, 500.0), Vector2.ZERO)
		main._spawn_fruit(0, Vector2(cx + 20.0, 500.0), Vector2.ZERO)
	elif frame == 180:
		_check("contact_merge_scored", main.score > _score_before)
		_check("contact_merge_count_2_to_1",
			main.fruits_root.get_child_count() < _count_before + 2)
		_check("table_same_tier_plus_1", FruitDB.merge_result(3, 3) == 4)
		_check("table_diff_tiers_no_merge",
			FruitDB.merge_result(2, 5) == FruitDB.NO_MERGE)
		_check("table_max_tier_annihilate",
			FruitDB.merge_result(FruitDB.MAX_TIER, FruitDB.MAX_TIER) == FruitDB.ANNIHILATE)
		_check("table_wild_promotes", FruitDB.merge_result(FruitDB.WILD, 3) == 4)
		_check("table_wild_plus_max_annihilate",
			FruitDB.merge_result(FruitDB.WILD, FruitDB.MAX_TIER) == FruitDB.ANNIHILATE)
		_check("table_wild_wild",
			FruitDB.merge_result(FruitDB.WILD, FruitDB.WILD) == FruitDB.WILD_MERGE_TIER)
		_check("value_triangular", FruitDB.value_of(1) == 3 and FruitDB.value_of(3) == 10)
		if _fails == 0:
			print("MERGE_TEST_PASS")
		else:
			print("MERGE_TEST_FAIL fails=", _fails)
		get_tree().quit(0 if _fails == 0 else 1)
	elif frame > 600:
		print("MERGE_TEST_FAIL timeout")
		get_tree().quit(1)