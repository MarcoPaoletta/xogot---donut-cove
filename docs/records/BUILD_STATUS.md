# Build status

Definition of done matrix (GDD Section 18) with evidence paths, and a `Could not complete` list. Written at the end of the build on 2026-11-11.

Every number here comes from a tool, a test or a file. A passing suite is not a playtest: the game has not been played by a person yet.

| # | Item | Status | Evidence |
| :-- | :-- | :-- | :-- |
| 1 | `comparison-final.png` passes Section 1 | Partly. The file exists (three concept and build pairs stacked) and the layouts carry the concept's elements and counts, but the pairs do not read as the same frame: see `Could not complete` 1 | `docs/records/evidence/comparison-final.png`, rounds `comparison-01.png` to `comparison-12.png` |
| 2 | Full run from the title to the end card by keyboard and mouse, without the debug panel, in 4 to 6 minutes, purchase times logged | Done by a bot, not by a person. Real speed: 309.0 s (5:09). Island input is real movement actions; at sea the ship's autopilot steers and fires | `tests/game/bot_full_run.gd`; times in `BUILD_NOTES.md` (M9) |
| 3 | Tycoon perceptual gate on a saved contact sheet | Done as a sheet of 16 frames captured by the game itself; judged by the builder on stills, with no sound heard | `docs/records/evidence/tycoon-contact-sheet.png` (final), `tycoon-contact-sheet-m1.png` |
| 4 | Every pad bought and its reveal seen; the helper serves alone for 60 s | Done. 12 pads; helper sold 42 donuts alone in 60 s, longest standstill under 12 s | `tests/game/test_stage2.gd` (22 of 22), `test_finale.gd` (13 of 13) |
| 5 | Sea: 10 boarding and docking cycles; enemies hit, take damage and drop loot; hull 0 limps home; the Kraken can be won | Done | `tests/game/test_sea.gd` (16 of 16) |
| 6 | Every performance row within budget, M8 included, or the gap documented | Rows M2, M3, M4 to M6, M7 and M9 pass. The two M8 rows miss the fps budget under outside GPU load and are documented; M9 is the same content and passes | `docs/records/PERFORMANCE.md`, `evidence/perf_*.csv` |
| 7 | Clean script diagnostics, no new editor errors, clean game console on a full run | Done. 48 scripts with zero diagnostics, `xo editor state` zero new errors, the real speed run logged 14 console entries with 0 errors and 0 warnings | `xo script check` on every script; console read after the M9 run |
| 8 | `scenes/main.tscn` shows the whole world; element scenes open, are selectable and editable, an edit survives save, reopen and Play | Done for the structure (11 of 11) and for one edit: `Glow.light_energy` of `oven_strawberry.tscn` set to 1.1, saved, reloaded from disk, read back in the running game, then restored | `tests/editor/test_structure.gd`; BUILD_NOTES M9 |
| 9 | Master bus muted at boot, `M` toggles it on every screen | Done. Checked at the title, in play and from the pause screen | `test_stage1.gd`, `test_finale.gd`, M0 run |
| 10 | Expand aspect checks with captures | Done at 1920x1055, 1280x720, 1680x720 and 1280x1024: title, island HUD, pause, sea HUD | `docs/records/evidence/aspect_*.png` |
| 11 | Records of Section 16 filled, `XO_FEEDBACK.md` included | Done. The usage log lacks Marco's `/usage` reading (not given) | `docs/records/` |
| 12 | Windows debug export at `build/donut-cove-windows/Donut Cove.exe` that boots to the title | Done through `xo export execute`. 124 MB, pack embedded. Booted and recorded 120 frames | `docs/records/evidence/export-boot-title.png` |
| 13 | `skills/`, `.claude/settings.local.json` and tokens never committed, `addons/xo/` unchanged; commit, tag `v1`, branch `v1` pushed | Done | `git ls-files` shows none of them; tag and branch pushed at the end |

Behaviour suites on the final build: 63 checks, 63 pass (`test_stage1` 12, `test_stage2` 22, `test_sea` 16, `test_finale` 13). Structural suite: 11 of 11.

## Could not complete

1. **Concept match is not one to one.** The build has the concept's elements, counts and palette family, but the three pairs do not read as the same frame. Measured reasons: the concepts are drawn with a much wider lens than the stated camera (FOV 38, pitch 48), so the stall view shows no sea, ship or horizon; the pack ship has brown and cream sails, not red and white; the pack rocks and cliffs are rounder and the island props are sparser than the paintings. The camera numbers of GDD Section 8 were kept. Closing this gap needs either a different camera than the GDD states or art outside the allowed packs.
2. **No human playtest and no listening test.** Everything was verified by suites, a bot and screenshots. The audio was baked and its playback state checked, but nobody heard the mix: levels and the music itself are unjudged.
3. **The full run is a bot's.** It presses real movement actions on the island, but at sea the ship steers, aims and fires through its own autopilot instead of the mouse. Bot runs measured 5:09 at real speed and 5:23, 5:49 and 6:06 at 3x; one earlier real speed run never sailed again because of a bot rule, since fixed.
4. **Seated pirates have no sitting clip.** They use `Idle` lowered onto the chair (the pirate rigs ship without one, as the GDD allows), which clips their legs into the seat.
5. **Plan usage numbers.** Marco's `/usage` reading was not given at the start or the end, so the usage log has the exact tokens only.
6. **The exported `Donut Cove.console.exe` wrapper** fails to start the game (`CreateProcess failed, error 193`); `Donut Cove.exe` itself runs. Not investigated further: the wrapper is only for console output.

## V2 (2026-11-11)

Marco's feedback after v1, all applied in one pass. Details and numbers in `BUILD_NOTES.md` (V2).

| Request | Status | Evidence |
| :-- | :-- | :-- |
| The hologram shows which building it is, at its real place | Done | `evidence/v2-pad-brackets-hologram.png`; `test_stage2` |
| Pads flat on the floor, rounded corners, no fill, coin and price as 3D objects on the floor | Done | `evidence/v2-pad-brackets-hologram.png` |
| Paying fills the hologram into the real object | Done | `evidence/v2-hologram-filling.png` |
| Clear what each thing does | Done as a name on every pad and one decoration offered at a time | same captures |
| Mouse pan and wheel zoom | Done | `test_stage2` (zoom 1.4x, pan 2.5 m, drift back) |
| Donuts carried in front, no backpack | Done | `test_stage2` |
| About five more things to buy for the kitchen | Done, five optional decorations | `evidence/v2-kitchen-decorations.png`; `test_stage2` |
| Better order bubble | Done | `evidence/v2-order-bubbles-queue.png` |
| Coin model from the new kit | Done | `ASSET_MANIFEST.md` |
| NPCs face where they walk | Done, measured 98 percent of frames off before and 0.3 percent after | `BUILD_NOTES.md` |

Suites on the V2 build: 82 behaviour checks and 12 structural, all pass. Bot full run 5:27 at real speed. Performance row V2 passes.

Still open in V2: no human playtest of this build, no video (not wanted for V2), and the two unrepeated readings listed in the notes.
