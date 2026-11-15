class_name Fruit
extends RigidBody2D
## 一個可以掉落、滾動、與同伴合成的水果。
## 只負責"發現自己該合成了"，真正的合成由 game.gd 統一處理。

signal merge_requested(a: Fruit, b: Fruit)

var tier: int = 0
var radius: float = 24.0

## 正在合成中的水果不再參與任何判定，等待被 queue_free
var is_merging: bool = false

## 落地（碰到過任何東西）之後才納入死亡線判定，否則剛投放就會誤判
var has_landed: bool = false

@onready var _shape: CollisionShape2D = $Shape
@onready var skin: FruitSkin = $Skin


## 必須在 add_child 之前調用
func setup(t: int) -> void:
	tier = t
	radius = FruitDB.radius_of(t)


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape.shape = circle

	skin.tier = tier
	# 大水果更重，堆疊時不會被小水果頂飛
	mass = maxf(0.4, radius * radius / 900.0)

	body_entered.connect(_on_body_entered)

	skin.scale = Vector2(0.35, 0.35)
	var tw := create_tween()
	tw.tween_property(skin, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_body_entered(body: Node) -> void:
	has_landed = true
	if is_merging:
		return
	var other := body as Fruit
	if other == null or other.is_merging:
		return
	if not FruitDB.can_merge(tier, other.tier):
		return
	# 兩邊都會收到 body_entered，讓 id 小的一方發起，避免重複合成
	if get_instance_id() > other.get_instance_id():
		return

	is_merging = true
	other.is_merging = true
	merge_requested.emit(self, other)
