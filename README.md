# 003 · Fruit Merge

Status: prototype
Engine: Godot 4.7.2 (GL Compatibility)
Platform: Android (arm64) / Windows / Web

Suika-like 水果合成 puzzle：點一下投放、同級水果相撞合成進化，
11 級櫻桃→大西瓜。連鎖倍率、能量三技能（錘子／搖一搖／彩虹果）、
雙西瓜爆炸、跨局進化圖鑑、死亡線 2.2 秒搶救窗。

**零圖片／音訊素材**：水果全用 `draw_*` 程序化繪製，音效運行時正弦波合成。
唯一二进制資源：站酷快樂體（SIL OFL 1.1）。

## 操作

- 觸控：點一下投放、按住拖曳瞄準、下方按鈕用技能
- 桌面：滑鼠瞄準、左鍵/空格投放、1/2/3 技能、右鍵/Esc 取消錘子、R 重開

## 來源

MIT base: [jlake/merge-fruits](https://github.com/jlake/merge-fruits) — 見 NOTICE.md。

## 開發

```bash
godot --headless --path . res://tests/smoke.tscn
godot --headless --path . --export-release "Android" build/003-merge.apk
```

Part of the [cykgames](https://github.com/cykgames) catalog.
