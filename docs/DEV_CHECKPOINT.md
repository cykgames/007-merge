# 007-merge dev checkpoint (2026-11-15)

Status: prototype (playable core verified on device; audit + release pending)

## Renumber 003 → 007 (2026-11-15 ~21:15, user instruction)

- Serial 003 collided: catalog 003 = 003-shmup (Space Shooter); local dirs
  003-outpost / 003-shooter also claimed 003. User picked 007.
- Verified free: GitHub org repos = 001..006 + .github (API list),
  cykgames/007-merge = 404; no local 007-* dir before rename.
- Local dir renamed 003-merge → 007-merge. NO remote repo existed yet
  (repo creation still awaits user consent) → nothing to rename on GitHub.
- Early commit messages keep "003-merge:" prefix (history preserved; hashes
  1ae3ca1/b3ba441 stable so lessons/plan evidence refs remain valid).
- Workspace evidence screenshots keep pre-rename names:
  artifacts/003_device{,2,3}.png, artifacts/003_a57_install.png.
- App identity unchanged: config/name "Fruit Merge", Android package
  com.cykgames.fruitmerge → A54/A57 keep the installed APK, no reinstall.

## What this is

Suika-like fruit merge puzzle, solo-produced by cykbot6 per user direction
("one agent, one independent production; pick one yourself"). Base:
jlake/merge-fruits (MIT), fresh git history, attribution in NOTICE.md.
Design ref studied: Checkroth/yokai-suika (MIT, no code copied).

## Verified (evidence)

- Headless smoke (Godot 4.7.2): autoloads, shake/rainbow/hammer costs,
  merge scoring, codex unlock, death-line 2.2s game-over, best score persist.
- Desktop screenshots: docs/screenshots/{gameplay,game_over}.png — zh-Hant
  fully renders (ZCOOL KuaiLe; its zero glyph is a rounded box, NOT tofu).
- Android: build/007-merge.apk (29.7MB, arm64-v8a only, debug-signed per 001
  precedent), installed A54 (<DEVICE_SERIAL>, USB). Portrait full-screen after
  `display/window/handheld/orientation=1`. Two adb taps dropped two fruits;
  preview + aim guide follow touch. Screenshots: cykbot6 workspace
  artifacts/003_device{,2,3}.png (pre-rename names).
- A57 (SM_A576B, WiFi <LAN_IP>:5555) installed + launched 2026-11-15:
  zh-Hant renders, gameplay live; 16:9 letterbox bars on 19.5:9 screen =
  known polish item. Screenshot: cykbot6 artifacts/003_a57_install.png.

## Build / test commands

```
set GODOT=%USERPROFILE%\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe
%GODOT% --headless --path . --import          # first time / after asset changes
%GODOT% --headless --path . res://tests/smoke.tscn
%GODOT% --path . res://tests/shot.tscn --resolution 720x1280
%GODOT% --headless --path . --export-debug "Android" build/007-merge.apk
```

## Gotchas (also in cykagent6 docs/lessons.md)

- Godot 4.7 ignores preset `screen/orientation`; use project setting
  `display/window/handheld/orientation` (1=portrait).
- Fresh project copy needs `--headless --import` before headless tests.
- Android export requires `import_etc2_astc=true`.
- Release export needs a keystore; use `--export-debug` (001 precedent).

## Open / next

1. Subagent audits (correctness + edge), 2 consecutive passes.
2. Catalog row in cykgames-org profile/README.md as 007 (genre: puzzle).
3. Repo creation (new_game.py now computes serial 007) + push: AWAIT USER CONSENT.
4. Polish candidates: drag-release drop UX, fill letterbox bars with backdrop,
   Web export font fallback (SystemFont names are desktop-only; embedded
   ZCOOL covers common hanzi, rare zh-Hant glyphs may tofu on Web).
5. Privacy scrub before first push (own commits only; upstream not imported).
