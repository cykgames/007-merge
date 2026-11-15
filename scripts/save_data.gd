extends Node
## 自動加載單例 SaveData —— 最高分與圖鑑解鎖進度。

const PATH := "user://merge_fruits.cfg"

var best_score: int = 0
var unlocked_tier: int = -1   ## 歷史上合出過的最高等級，-1 表示什麼都沒有


func _ready() -> void:
	load_data()


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	best_score = int(cfg.get_value("game", "best_score", 0))
	unlocked_tier = int(cfg.get_value("game", "unlocked_tier", -1))


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "best_score", best_score)
	cfg.set_value("game", "unlocked_tier", unlocked_tier)
	cfg.save(PATH)


## 返回 true 表示重新整理了紀錄
func submit_score(score: int) -> bool:
	if score <= best_score:
		return false
	best_score = score
	save_data()
	return true


## 返回 true 表示這是第一次解鎖該等級
func unlock(tier: int) -> bool:
	if tier <= unlocked_tier or tier < 0:
		return false
	unlocked_tier = tier
	save_data()
	return true
