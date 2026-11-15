# 007 · Fruit Merge

- **作者：cykbot6**（cykagent fleet，2026-11-15 獨立製作；遊戲內 HUD 底部與結算畫面有署名）
- Status: prototype（實機可玩，審查 / 發布未完成）
- Engine: Godot 4.7.2（GL Compatibility renderer）
- Platform: Android（arm64-v8a，debug-signed）/ Windows / Web
- Catalog: [cykgames](https://github.com/cykgames) 007（genre: puzzle）

Suika-like 水果合成 puzzle：點一下投放、同級水果相撞合成進化，
11 級櫻桃→大西瓜。連鎖倍率、能量三技能（錘子／搖一搖／彩虹果）、
雙西瓜爆炸、跨局進化圖鑑、死亡線 2.2 秒搶救窗。

**零圖片／音訊素材**：水果全用 `draw_*` 程序化繪製，音效運行時正弦波合成。
唯一二進位資源：站酷快樂體（SIL OFL 1.1）。

---

## 遊戲內容（機制與數值）

- **合成鏈**：11 級（tier 0 櫻桃 → tier 10 大西瓜），同級相撞 → 高一級。
  半徑 24→154px、基礎分 = 三角數 `(t+1)(t+2)/2`（`scripts/fruit_db.gd`）。
- **掉落**：只掉 tier 0–4，權重 `[30,26,20,14,10]`；投放冷卻 0.40s。
- **連鎖**：1.6s 內連續合成算同一條 chain，倍率 `1 + 0.25×(chain-1)`，上限 x5。
- **能量**：上限 100；合成 +`3+2×tier`，雙西瓜爆炸 +30。技能成本：
  - 錘子 30：先 arm（再點按鈕取消），點中水果才扣能量並敲掉它（挑半徑最小的）
  - 搖一搖 45：對全部水果施加隨機向上 impulse + torque
  - 彩虹果 100：下一個變成 WILD（tier -1），可與任意水果合成 → 對方+1；
    WILD+WILD → tier 4；WILD/大西瓜 碰大西瓜 → ANNIHILATE（雙雙消失，+300 分）
- **死亡線**：`DEATH_Y=268`；已落地水果頂端越線累計 2.2s 即 game over
  （離線以 1.6 倍速回落），越線時背景漸紅（`backdrop.danger`）。
- **跨局存檔**：最高分 + 圖鑑解鎖進度，`user://merge_fruits.cfg`
  （Android: `/data/data/com.cykgames.fruitmerge/files/`）。
- **圖鑑**：左側 11 級進化鏈，未解鎖畫灰色剪影；首次解鎖有音效+浮字。

## 操作

- 觸控：點一下投放、按住拖曳瞄準、下方按鈕用技能（`emulate_mouse_from_touch=true`）
- 桌面：滑鼠瞄準、左鍵/空格投放、1/2/3 技能、右鍵/Esc 取消錘子、R 重開

## 設計來源與授權

| 來源 | 用途 | 授權 |
|------|------|------|
| [jlake/merge-fruits](https://github.com/jlake/merge-fruits) | code base（fresh git history，未 import upstream history） | MIT，原 LICENSE 全文保留在 `NOTICE.md` |
| [Checkroth/yokai-suika](https://github.com/Checkroth/yokai-suika) | 設計參考（只有研究，**沒有抄 code**） | MIT |
| ZCOOL KuaiLe 站酷快樂體 | 唯一嵌入字型（zh-Hant 顯示） | SIL OFL 1.1，`assets/ZCOOLKuaiLe-OFL.txt` |

cykbot6 相對於 base 的修改：zh-Hant 本地化（OpenCC s2twp）、觸控提示文案、
portrait Android（arm64-v8a）export preset、GL Compatibility、改名 Fruit Merge、
cykgames 品牌（README/NOTICE/遊戲內署名）。細節見 `NOTICE.md`。

## 架構與檔案地圖（接手除錯從這裡開始）

```
scenes/main.tscn      主場景：Main(game.gd) + Backdrop + Codex + Walls(StaticBody2D)
                      + Fruits/Effects(動態容器) + Preview(FruitSkin) + Camera + UI
scenes/fruit.tscn     水果：RigidBody2D + FruitSkin 繪製，merge_requested signal
scripts/game.gd       主邏輯：投放/合成/技能/死亡線/UI 刷新（465 行，讀這支就懂八成）
scripts/game_layout.gd 佈局常量：SCREEN 720x1280、WALL_L/R 132/692、FLOOR_Y 1148、
                      DEATH_Y 268、DROP_Y 200、CODEX_X 60 ← main.tscn 碰撞體必須對齊
scripts/fruit_db.gd   水果數據表 + 合成規則（merge_result/value_of/random_spawn_tier）
scripts/fruit.gd      水果物理行為、落地判定、merge 觸發
scripts/fruit_art.gd  程序化繪製（draw_*，7 種 style：PLAIN/SEEDS/CLUSTER/...）
scripts/fruit_skin.gd 水果外觀 Node2D 包裝（Preview/NextBox/圖鑑共用）
scripts/codex.gd      左側圖鑑繪製（解鎖/高亮）
scripts/backdrop.gd   背景 + 危險漸紅
scripts/fx.gd         粒子/光圈/浮字（burst/ring/float_text）
scripts/sfx.gd        autoload：正弦波合成音效（無音訊檔）
scripts/save_data.gd  autoload：最高分 + 圖鑑存檔（ConfigFile）
tests/smoke.gd        headless 冒煙測試（見下方）
tests/shot.gd         自動投放後截圖 gameplay + game-over 兩張
```

關鍵設定（`project.godot`）：
- autoloads：`SaveData`、`Sfx`
- physics：gravity 1250；layer 1=fruit、layer 2=wall；水果碰撞在 `fruit.tscn`
- stretch `canvas_items`（720x1280 基準，letterbox 不裁切）；
  **portrait 靠 `display/window/handheld/orientation=1`**（export preset 的無效）
- 字型：`gui/theme/custom_font=res://assets/cjk_font.tres`（ZCOOL KuaiLe）

## 開發 / 測試 / 建置

環境：Windows + Godot 4.7.2（`%USERPROFILE%\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe`）。

```cmd
set GODOT=%USERPROFILE%\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe
%GODOT% --headless --path . --import                          :: 首次 / 換素材後必跑
%GODOT% --headless --path . res://tests/smoke.tscn            :: 冒煙測試
%GODOT% --path . res://tests/shot.tscn --resolution 720x1280  :: 截圖（tests/shot*.png）
%GODOT% --headless --path . --export-debug "Android" build/007-merge.apk
```

- **smoke 覆蓋**：autoloads、三技能成本/效果、merge 計分、圖鑑解鎖、
  死亡線 2.2s game-over、best score 持久化。PASS 條件：印出 score>0、
  gameover_visible=True、best>0，無 script error。
- **Android 安裝**（A54 USB / A57 WiFi，裝置細節在 fleet MEMORY.md，不入 repo）：
  `adb install -r build/007-merge.apk`（package `com.cykgames.fruitmerge`）。
- export 用 `--export-debug`：release 需要 keystore（尚未建，001-parkour 前例）。
- Android export 必須 `import_etc2_astc=true`（已設）。

## 已知問題 / 除錯線索

Gotchas（踩過的坑，詳見 cykagent6 `docs/lessons.md`）：
1. Godot 4.7 **忽略** export preset 的 `screen/orientation` → 用 project setting。
2. 新 copy 的專案沒跑 `--headless --import` 就 headless 測試 → 資源載入失敗。
3. release export 沒 keystore 會失敗 → 用 `--export-debug`。
4. ZCOOL KuaiLe 的「0」是圓框造型，**不是 tofu**；罕見 zh-Hant 字在 Web 可能缺字
   （SystemFont fallback 只在桌面有效）。

Open polish（尚未修）：
- 19.5:9 手機上下 letterbox 黑邊 → 考慮用 backdrop 填滿
- 拖曳瞄準的 release-drop UX（目前點按即投）
- Web export 字型 fallback

證據位置：
- `docs/DEV_CHECKPOINT.md` — 完整開發紀錄 + 實機驗證 + 改號（003→007）始末
- `docs/screenshots/{gameplay,game_over}.png` — 桌面 zh-Hant 渲染
- `tests/shot.png` / `tests/shot_over.png` — 最近一次自動截圖
- cykbot6 workspace `artifacts/003_device{,2,3}.png`、`003_a57_install.png`
  （A54/A57 實機；檔名保留改號前舊名）

## 發布紀律

- 🔴 push 前全歷史 privacy 清洗（LAN IP / 裝置序號 / 使用者路徑 → placeholder）；
  device facts 只放 fleet MEMORY.md，禁入 public repo。
- remote repo 尚未建立（等使用者同意）；建立後 catalog 以 007 上架。
- 早期 commit message 保留 `003-merge:` prefix（改號前歷史，hash 不變）。