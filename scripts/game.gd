extends Node2D
## 水果合成 —— 主遊戲邏輯。

const FRUIT_SCENE := preload("res://scenes/fruit.tscn")

const DROP_COOLDOWN := 0.40
const COMBO_WINDOW := 1.6      ## 這麼久之內的連續合成算一次連鎖
const COMBO_MAX_MULT := 5.0
const DANGER_LIMIT := 2.2      ## 越線停留這麼久就結束
const ENERGY_MAX := 100.0

enum Skill { HAMMER, SHAKE, RAINBOW }

const SKILL_NAMES: Array[String] = ["錘子", "搖一搖", "彩虹果"]
const SKILL_COSTS: Array[float] = [30.0, 45.0, 100.0]

@onready var backdrop: Node2D = $Backdrop
@onready var codex: Node2D = $Codex
@onready var fruits_root: Node2D = $Fruits
@onready var effects_root: Node2D = $Effects
@onready var preview: FruitSkin = $Preview
@onready var camera: Camera2D = $Camera

@onready var score_label: Label = $UI/Hud/ScoreLabel
@onready var best_label: Label = $UI/Hud/BestLabel
@onready var combo_label: Label = $UI/Hud/ComboLabel
@onready var next_skin: FruitSkin = $UI/Hud/NextBox/NextSkin
@onready var energy_bar: ProgressBar = $UI/Hud/EnergyBar
@onready var energy_label: Label = $UI/Hud/EnergyLabel
@onready var skill_bar: HBoxContainer = $UI/Hud/SkillBar
@onready var game_over_panel: Control = $UI/GameOver
@onready var over_score: Label = $UI/GameOver/Box/VBox/ScoreLabel
@onready var over_best: Label = $UI/GameOver/Box/VBox/BestLabel
@onready var over_title: Label = $UI/GameOver/Box/VBox/TitleLabel
@onready var restart_button: Button = $UI/GameOver/Box/VBox/RestartButton

var score := 0
var energy := 0.0
var combo := 0
var current_tier := 0
var next_tier := 0
var hammer_armed := false

var _playing := true
var _cooldown := 0.0
var _combo_timer := 0.0
var _danger := 0.0
var _shake := 0.0
var _skill_buttons: Array[Button] = []
var _guide: Node2D


func _ready() -> void:
	randomize()

	_guide = Node2D.new()
	_guide.draw.connect(_draw_guide)
	preview.add_child(_guide)

	_build_skill_buttons()
	_style_energy_bar()
	_style_button(restart_button)
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.pressed.connect(_restart)

	codex.unlocked = SaveData.unlocked_tier
	game_over_panel.visible = false

	current_tier = FruitDB.random_spawn_tier()
	next_tier = FruitDB.random_spawn_tier()
	_apply_current_tier()
	_refresh_ui()


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_shake = maxf(0.0, _shake - delta * 55.0)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake

	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo = 0
	_update_combo_label()

	if _playing:
		_update_preview(delta)
		_check_danger(delta)

	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hammer_armed else Input.CURSOR_ARROW)


# ---------------------------------------------------------------- 輸入

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_restart()
		return

	if not _playing:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if hammer_armed:
				_swing_hammer(get_global_mouse_position())
			else:
				_drop()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			hammer_armed = false
			_refresh_ui()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_drop()
			KEY_1:
				_use_skill(Skill.HAMMER)
			KEY_2:
				_use_skill(Skill.SHAKE)
			KEY_3:
				_use_skill(Skill.RAINBOW)
			KEY_ESCAPE:
				hammer_armed = false
				_refresh_ui()


# ---------------------------------------------------------------- 投放

func _update_preview(delta: float) -> void:
	var r := FruitDB.radius_of(current_tier)
	var target := clampf(get_global_mouse_position().x,
			GameLayout.WALL_L + r + 4.0, GameLayout.WALL_R - r - 4.0)
	preview.position.x = lerpf(preview.position.x, target, clampf(delta * 22.0, 0.0, 1.0))
	preview.modulate.a = lerpf(0.25, 0.9, 1.0 - _cooldown / DROP_COOLDOWN)


func _drop() -> void:
	if not _playing or _cooldown > 0.0:
		return

	var f: Fruit = FRUIT_SCENE.instantiate()
	f.setup(current_tier)
	f.position = Vector2(preview.position.x, GameLayout.DROP_Y)
	f.merge_requested.connect(_on_merge_requested)
	fruits_root.add_child(f)
	f.linear_velocity = Vector2(0, 140)

	Sfx.play_drop()

	current_tier = next_tier
	next_tier = FruitDB.random_spawn_tier()
	_apply_current_tier()
	_cooldown = DROP_COOLDOWN
	_refresh_ui()


func _apply_current_tier() -> void:
	preview.tier = current_tier
	next_skin.tier = next_tier
	next_skin.fit_to_radius(34.0)
	if _guide != null:
		_guide.queue_redraw()


func _draw_guide() -> void:
	var r := FruitDB.radius_of(current_tier)
	var y := r + 14.0
	var end := GameLayout.FLOOR_Y - GameLayout.DROP_Y
	var col := FruitDB.color_of(current_tier)
	col.a = 0.22
	while y < end:
		var y2 := minf(y + 14.0, end)
		_guide.draw_line(Vector2(0, y), Vector2(0, y2), col, 3.0, true)
		y = y2 + 12.0


# ---------------------------------------------------------------- 合成

func _on_merge_requested(a: Fruit, b: Fruit) -> void:
	# 由物理回調觸發，延後到幀末再改動場景樹
	_do_merge.call_deferred(a, b)


func _do_merge(a: Fruit, b: Fruit) -> void:
	if not _playing or not is_instance_valid(a) or not is_instance_valid(b):
		return

	var pos := (a.global_position + b.global_position) * 0.5
	var vel := (a.linear_velocity + b.linear_velocity) * 0.25
	var result := FruitDB.merge_result(a.tier, b.tier)
	var col := FruitDB.color_of(maxi(a.tier, b.tier))
	var old_radius := maxf(a.radius, b.radius)

	a.queue_free()
	b.queue_free()

	combo += 1
	_combo_timer = COMBO_WINDOW
	var mult := minf(1.0 + 0.25 * float(combo - 1), COMBO_MAX_MULT)

	var base := 0
	if result == FruitDB.ANNIHILATE:
		base = 300
		energy = minf(energy + 30.0, ENERGY_MAX)
		Fx.burst(effects_root, pos, col, old_radius, 40)
		Fx.ring(effects_root, pos, Color(1, 1, 1), old_radius * 1.4)
		Fx.float_text(effects_root, pos, "雙西瓜爆炸！", Color("ff5470"), 40)
		_shake = 22.0
		Sfx.play_pop()
	else:
		base = FruitDB.value_of(result)
		energy = minf(energy + 3.0 + result * 2.0, ENERGY_MAX)
		_spawn_fruit(result, pos, vel)
		Fx.burst(effects_root, pos, col, old_radius)
		Fx.ring(effects_root, pos, col, FruitDB.radius_of(result))
		_shake = maxf(_shake, minf(FruitDB.radius_of(result) * 0.08, 15.0))
		Sfx.play_merge(result)
		_on_reached(result, pos)

	var gain := int(round(base * mult))
	score += gain

	Fx.float_text(effects_root, pos, "+%d" % gain, Color(1, 1, 1), 32)
	if combo >= 2:
		Fx.float_text(effects_root, pos + Vector2(0, -52), "連鎖 x%d" % combo,
				Color("ffd166"), 30, 70.0)
		Sfx.play_combo(combo)

	_refresh_ui()


func _spawn_fruit(tier: int, pos: Vector2, vel: Vector2) -> void:
	var f: Fruit = FRUIT_SCENE.instantiate()
	f.setup(tier)
	f.position = pos
	f.has_landed = true
	f.merge_requested.connect(_on_merge_requested)
	fruits_root.add_child(f)
	f.linear_velocity = vel


## 合出了某個等級：更新圖鑑，首次解鎖給個儀式感
func _on_reached(tier: int, pos: Vector2) -> void:
	codex.highlight = tier
	if SaveData.unlock(tier):
		codex.unlocked = SaveData.unlocked_tier
		Sfx.play_unlock()
		Fx.float_text(effects_root, pos + Vector2(0, -110),
				"圖鑑解鎖：%s" % FruitDB.name_of(tier), Color("8ef6c0"), 34, 110.0)
	if tier == FruitDB.MAX_TIER:
		Fx.float_text(effects_root, Vector2(GameLayout.center_x(), 420.0),
				"大西瓜誕生！", Color("ffd166"), 56, 130.0)
		_shake = 20.0


# ---------------------------------------------------------------- 技能

func _use_skill(skill: int) -> void:
	if not _playing:
		return
	var cost := SKILL_COSTS[skill]

	match skill:
		Skill.HAMMER:
			# 錘子先進入待命狀態，真正砸中水果才扣能量
			hammer_armed = not hammer_armed and energy >= cost
		Skill.SHAKE:
			if energy < cost:
				return
			energy -= cost
			for child in fruits_root.get_children():
				var f := child as Fruit
				if f == null or f.is_merging:
					continue
				var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.4, -0.5)).normalized()
				f.apply_central_impulse(dir * f.mass * 340.0)
				f.apply_torque_impulse(randf_range(-1.0, 1.0) * f.mass * 900.0)
			_shake = 18.0
			Sfx.play_pop()
			Fx.float_text(effects_root, Vector2(GameLayout.center_x(), 700.0),
					"搖一搖！", Color("9be7ff"), 40)
		Skill.RAINBOW:
			if energy < cost:
				return
			energy -= cost
			current_tier = FruitDB.WILD
			_apply_current_tier()
			Sfx.play_unlock()
			Fx.float_text(effects_root, Vector2(preview.position.x, GameLayout.DROP_Y + 70.0),
					"彩虹果！可與任意水果合成", Color("ff7fd0"), 28)

	_refresh_ui()


func _swing_hammer(world_pos: Vector2) -> void:
	var cost := SKILL_COSTS[Skill.HAMMER]
	if energy < cost:
		hammer_armed = false
		_refresh_ui()
		return

	var target: Fruit = null
	for child in fruits_root.get_children():
		var f := child as Fruit
		if f == null or f.is_merging:
			continue
		if world_pos.distance_to(f.global_position) > f.radius:
			continue
		if target == null or f.radius < target.radius:
			target = f
	if target == null:
		return

	energy -= cost
	hammer_armed = false
	Fx.burst(effects_root, target.global_position, FruitDB.color_of(target.tier), target.radius, 26)
	Fx.ring(effects_root, target.global_position, Color(1, 1, 1), target.radius)
	Sfx.play_pop()
	_shake = 10.0
	target.is_merging = true
	target.queue_free()
	_refresh_ui()


# ---------------------------------------------------------------- 死亡線

func _check_danger(delta: float) -> void:
	var over := false
	for child in fruits_root.get_children():
		var f := child as Fruit
		if f == null or f.is_merging or not f.has_landed:
			continue
		if f.global_position.y - f.radius < GameLayout.DEATH_Y:
			over = true
			break

	_danger = clampf(_danger + (delta if over else -delta * 1.6), 0.0, DANGER_LIMIT)
	backdrop.danger = _danger / DANGER_LIMIT

	if _danger >= DANGER_LIMIT:
		_game_over()


func _game_over() -> void:
	_playing = false
	preview.visible = false
	hammer_armed = false
	# 定格整罐水果，避免結算介面後面還在滾動、還在加分
	for child in fruits_root.get_children():
		var f := child as Fruit
		if f != null:
			f.freeze = true
	Sfx.play_game_over()

	var is_record := SaveData.submit_score(score)
	over_title.text = "新紀錄！" if is_record else "遊戲結束"
	over_score.text = "本局得分  %d" % score
	over_best.text = "最高分  %d" % SaveData.best_score
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.35)
	_refresh_ui()


func _restart() -> void:
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- UI

func _refresh_ui() -> void:
	score_label.text = str(score)
	best_label.text = "最高 %d" % maxi(SaveData.best_score, score)
	energy_bar.value = energy
	energy_label.text = "能量 %d / %d" % [int(energy), int(ENERGY_MAX)]

	for i in _skill_buttons.size():
		var b := _skill_buttons[i]
		var affordable := energy >= SKILL_COSTS[i]
		b.disabled = not affordable or not _playing
		if i == Skill.HAMMER and hammer_armed:
			b.text = "%d  取消" % (i + 1)
			b.modulate = Color("ffd166")
		else:
			b.text = "%d %s %d" % [i + 1, SKILL_NAMES[i], int(SKILL_COSTS[i])]
			b.modulate = Color.WHITE


func _update_combo_label() -> void:
	if combo >= 2 and _combo_timer > 0.0:
		combo_label.visible = true
		combo_label.text = "連鎖 x%d" % combo
		combo_label.modulate.a = clampf(_combo_timer / COMBO_WINDOW + 0.35, 0.0, 1.0)
	else:
		combo_label.visible = false


func _build_skill_buttons() -> void:
	for i in SKILL_NAMES.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(178, 80)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 21)
		b.add_theme_color_override("font_color", Color(1, 1, 1))
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
		_style_button(b)
		b.pressed.connect(_use_skill.bind(i))
		b.tooltip_text = _skill_tip(i)
		skill_bar.add_child(b)
		_skill_buttons.append(b)


func _skill_tip(skill: int) -> String:
	match skill:
		Skill.HAMMER:
			return "敲掉任意一個水果（點按鈕後再點水果）"
		Skill.SHAKE:
			return "搖晃整罐水果，製造新的接觸機會"
		Skill.RAINBOW:
			return "下一個變成彩虹果，可與任意水果合成"
	return ""


func _style_button(b: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.14)
	normal.set_corner_radius_all(16)
	normal.set_border_width_all(2)
	normal.border_color = Color(1, 1, 1, 0.22)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.26)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(1, 1, 1, 0.36)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0, 0, 0, 0.28)
	disabled.border_color = Color(1, 1, 1, 0.08)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _style_energy_bar() -> void:
	energy_bar.max_value = ENERGY_MAX
	energy_bar.show_percentage = false

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.35)
	bg.set_corner_radius_all(9)

	var fg := StyleBoxFlat.new()
	fg.bg_color = Color("ffd166")
	fg.set_corner_radius_all(9)

	energy_bar.add_theme_stylebox_override("background", bg)
	energy_bar.add_theme_stylebox_override("fill", fg)
