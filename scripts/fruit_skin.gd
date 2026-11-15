class_name FruitSkin
extends Node2D
## 只負責顯示一個水果外觀的節點。水果本體、掉落預覽、下一個預覽都共用它。

@export var tier: int = 0:
	set(value):
		tier = value
		queue_redraw()


func _draw() -> void:
	FruitArt.draw_fruit(self, tier)


## 讓外觀縮放到指定的顯示半徑（用於 UI 裏的小預覽）
func fit_to_radius(display_radius: float) -> void:
	var s := display_radius / FruitDB.radius_of(tier)
	scale = Vector2(s, s)
