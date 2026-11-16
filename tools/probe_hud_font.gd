extends Node
## Regression probe for the "white slanted box over the score" device report.
## Root cause was ZCOOL KuaiLe's zero glyph (a slanted hollow quadrilateral),
## not a stray node. Asserts the score readout now uses the embedded Outfit
## font and that no visible HUD control overlaps the score label rect.
## Run: godot --headless --path . res://tools/probe_hud_font.tscn

func _ready() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var failures: Array[String] = []
	var score: Label = main.get_node("UI/Hud/ScoreLabel")
	var best: Label = main.get_node("UI/Hud/BestLabel")
	for lbl: Label in [score, best]:
		var f: Font = lbl.get_theme_font("font")
		var path: String = f.resource_path if f != null else ""
		print("%s font: %s" % [lbl.name, path])
		if not path.ends_with("Outfit.ttf"):
			failures.append("%s not using Outfit: %s" % [lbl.name, path])
	var hud: Control = main.get_node("UI/Hud")
	for c in hud.get_children():
		if c is Control and c.visible and c != score \
				and score.get_global_rect().intersects(c.get_global_rect()):
			failures.append("HUD overlap with score: %s" % c.name)
	if failures.is_empty():
		print("PROBE PASS: score/best use Outfit digits; no HUD node overlaps the score rect")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("PROBE FAIL: ", f)
		get_tree().quit(1)