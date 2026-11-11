# Measurement log

Build start (local time), each milestone M0 to M9, time to first playable, end, wall clock, concept match rounds, every human intervention with the time.


| Event | Local time | Note |
| :-- | :-- | :-- |
| Build start | 2026-11-11 15:59:35 | KICKOFF.md read. Plan usage at start: not given. |
| M0 done | 2026-11-11 16:07:59 | Settings, InputMap, layers, folders, font, Audio and Wallet autoloads, boot mute verified in a run. |
| M1 done | 2026-11-11 16:50:22 | Stack lab (`tests/stack_lab.tscn`), back stack, scoop and serve cadences, coins to HUD, pitch ladder hooks, MAX. Contact sheet `evidence/tycoon-contact-sheet-m1.png`. |
| Time to first playable | 2026-11-11 16:50:22 | Stage 1 loop with pad 1 in `scenes/main.tscn`; `tests/game/test_stage1.gd` 13 of 13 PASS. About 49 minutes after the build start. |
| M2 done | 2026-11-11 16:56:51 | Beach stall: island, kitchen line, counter with queue rope, dock, cliffs, palms, decor, water, sky, ConceptCam_Stall, pad 1. Concept match rounds 1 to 3 (comparison-01 to 03). Performance row M2 passes. |
| M3 done | 2026-11-11 17:08:59 | Pads 2 to 8 with reveals, three flavors, tables with seated pirates, statue, helper bunny, rare captain, ConceptCam_Island, compact island (concept rounds 4 and 5). `tests/game/test_stage2.gd` 22 of 22 PASS. |
| M4 done | 2026-11-11 17:40:59 | Ship pad with sail in, boarding ring, sea camera, sailing with bank and bob, islets, soft sea ring, ConceptCam_Sea. M4, M5 and M6 were built in one pass and share one performance row. |
| M5 done | 2026-11-11 17:40:59 | Cannons with aim arc and ring, sharks, tentacles, floating loot, the hold, docking and unloading, pads 10 and 11, sea HUD. `tests/game/test_sea.gd` 16 of 16 PASS (10 boarding and docking cycles, limp home, loot unloaded). |
| M6 done | 2026-11-11 17:40:59 | Kraken (three giant tentacles in turn, storm grade, golden chest, slow motion), Captain's Donut House, end card, title screen with camera director, pause screen. `tests/game/test_finale.gd` 13 of 13 PASS. |
| M7 done | 2026-11-11 18:11:51 | Title with camera director, pause, end card, fades, sea HUD, mute icon, baked music and effects (`tools/bake_audio.py`). First complete run by the bot: 323.4 s (5:23) from Start to the house, at 3x time scale. |
| M8 done | 2026-11-11 18:27:15 | Presenter panel (F1), showcase cameras (F2), HUD hide (F3), expand aspect captures at 1920x1055, 1280x720, 1680x720 and 1280x1024, concept rounds 6 to 12 and `comparison-final.png`, look pass. Concept match rounds in total: 12. |
| M9 done, build end | 2026-11-11 19:20:00 | Gate: 63 behaviour checks and 11 structural checks pass, real speed bot run 5:09, final contact sheet, edit persistence check, Windows debug export booted, performance row M9 passes, records. |

## Summary

| Measure | Value |
| :-- | :-- |
| Build start | 15:59:35 |
| Build end | 19:20:00 |
| Wall clock | 3 h 20 min |
| Time to first playable (Stage 1 loop with pad 1 in the main scene) | 50 min 47 s (16:50:22) |
| M0 | 8 min 24 s |
| M1 (stack lab and first playable) | 42 min 23 s |
| M2 | 6 min 29 s (most of the stall was assembled inside M1's time; M2 closed the concept rounds 1 to 3 and the first performance row) |
| M3 | 12 min 8 s |
| M4, M5 and M6 (built in one pass) | 32 min |
| M7 | 30 min 52 s |
| M8 | 15 min 24 s |
| M9 | 52 min 45 s (three real speed bot runs of 5 to 8 minutes each, a substitution bug found by the first one) |
| Concept match rounds | 12 (`comparison-01.png` to `comparison-12.png`) |

## Human interventions during the build

None between 15:59:35 and the end. Before the build start, in the same session: Marco asked to get xo working on this Windows machine (the TCP wrapper `tools/xo`, 15:40 to 15:55) and said to build the game without stopping once the GDD arrived; a message from the Hub session repeated that brief.

## Notes on the measurements

* The lead session started at 15:40 for the xo setup, 19 minutes before the build start. `tools/usage_snapshot.py` counts whole sessions that start at or after `--since`, so with `--since 15:59:35` it reports zero for this session (the snapshots labelled build start, M0 and M2). The final snapshot uses `--since 2026-11-11T15:40` and therefore includes the setup and the wait for the GDD: it is an upper bound for the build.
* Other Godot editors and a running game of other projects shared the PC and its GPU during the whole build (see the note in `PERFORMANCE.md`).
