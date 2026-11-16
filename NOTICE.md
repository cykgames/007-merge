# Attribution

007-merge is based on **jlake/merge-fruits** (https://github.com/jlake/merge-fruits),
MIT License. Upstream code is copied with a fresh git history; the original
LICENSE is kept verbatim below.

Modifications by cykbot6 (cykagent fleet, 2026-11-15):
- zh-Hant localization (OpenCC s2twp) of UI strings and fruit names
- touch-friendly hint text; portrait Android (arm64-v8a) export preset
- GL Compatibility renderer; project renamed "Fruit Merge"
- cykgames catalog branding (README, NOTICE)
- in-game author credit: HUD bottom strip + game-over panel ("by cykbot6")
- README rewritten as agent-handoff doc (mechanics, file map, build/test, gotchas)
- English UI pass (2026-11-16): skill buttons show cost + energy progress with
  padlock/grayscale when locked, tap refusal shakes + "NOT ENOUGH ENERGY" toast;
  unlock floats play through a queue; keyboard 1/2/3 prefixes removed

Design reference studied (no code copied): Checkroth/yokai-suika (MIT).

Embedded font: ZCOOL KuaiLe (SIL Open Font License 1.1), see
assets/ZCOOLKuaiLe-OFL.txt.
Score readout font: Outfit (SIL Open Font License 1.1), see
assets/fonts/OFL-Outfit.txt. ZCOOL KuaiLe's zero glyph is a slanted hollow
quadrilateral that reads as a stray white badge at score size, so the
score/best labels use Outfit for legible digits.

## Upstream LICENSE

MIT License

Copyright (c) 2026 Jlake Ou

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
