class_name GameLayout
extends RefCounted
## 全域性佈局常量。scenes/main.tscn 裏的碰撞體位置必須和這裏保持一致。

const SCREEN := Vector2(720, 1280)

## 罐子內壁
const WALL_L := 132.0
const WALL_R := 692.0
const FLOOR_Y := 1148.0

## 越過這條線並停留一段時間就算輸
const DEATH_Y := 268.0

## 待投放水果的高度
const DROP_Y := 200.0

## 左側圖鑑欄的中軸
const CODEX_X := 60.0

static func center_x() -> float:
	return (WALL_L + WALL_R) * 0.5
