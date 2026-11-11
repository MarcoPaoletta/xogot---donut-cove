# Performance

Target: 60 fps at 1920x1080 on an RTX 3060 (GDD Section 15). One row per check, at the end of every milestone M2 to M8. Measured on `tests/perf_route.tscn`, frame cap and vsync off during the measurement only.

| Date and time | Milestone | Change since previous row | Avg fps | 1% low | p95 frame ms | Max draw calls | Max triangles | VRAM | Pass |
| :-- | :-- | :-- | --: | --: | --: | --: | --: | --: | :-- |
| 2026-11-11 16:56 | M2 | First row: island, stall, kitchen line, dock, water, one pad | 197 | 108 | 6.36 | 337 | 628,528 | 477 MB | yes |
| 2026-11-11 17:08 | M3 | Pads 1 to 12 placed, three ovens, display case, statue, two table sets with seated pirates, helper bunny, compact island | 197 | 144 | 6.16 | 420 | 792,698 | 535 MB | yes |
| 2026-11-11 17:39 | M4-M6 | Ship, sea camera, islets, cannons, sharks, tentacles, loot, Kraken, house, title and end screens (built in one pass, measured with the ship sailing on autopilot and firing) | 191 | 139 | 6.37 | 501 | 880,146 | 608 MB | yes |
| 2026-11-11 18:11 | M7 | Audio (three music loops, ambience, 33 effects), presenter panel, HUD sea widgets and mute icon, economy retune | 189 | 145 | 6.36 | 502 | 940,316 | 595 MB | yes |
| 2026-11-11 18:25 | M8 | Presenter panel, showcase cameras, bigger donuts and taller tower, running dust, warmer sand and deeper water, sea camera on the starboard quarter | 73 | 42 | 17.80 | 507 | 949,252 | 600 MB | NO |
| 2026-11-11 18:28 | M8 (repeat) | Same build as the row above, measured again 3 minutes later | 84 | 49 | 16.51 | 513 | 949,206 | 599 MB | NO (outside load) |
| 2026-11-11 19:17 | M9 | Final build (same content as M8) | 161 | 113 | 7.62 | 520 | 964,924 | 595 MB | yes |

**Note on the two M8 rows.** They miss the fps budget, but the load is not this game's: `nvidia-smi` read 76 percent GPU utilization and 5,900 MiB in use *before* the route started, from other Godot editors and a running game of other projects on the same PC (processes `Godot_v4.7.2-stable_mono_win64` and `Paint the Strip`), and 97 percent during the route. Draw calls (507 to 513), triangles (949 K) and video memory (600 MB) are the same as the M7 row, which measured 189 fps average and 145 fps 1 percent low fifteen minutes earlier with the GPU free. The route is repeated at M9 with the result logged below.

M9 result: the same content measured at 19:17 with the GPU at 26 percent before the route passes every metric (161 fps average, 113 fps 1 percent low, 7.62 ms at the 95th percentile). The ship sails and fires on autopilot with sharks, tentacles and loot active during the sea part of the route.
| 2026-11-11 20:57 | V2 | V2: bracket pads, in place holograms, five decorations, mouse camera | 158 | 66 | 9.26 | 574 | 923,234 | 603 MB | yes |
