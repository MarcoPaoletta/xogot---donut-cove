# Performance

Target: 60 fps at 1920x1080 on an RTX 3060 (GDD Section 15). One row per check, at the end of every milestone M2 to M8. Measured on `tests/perf_route.tscn`, frame cap and vsync off during the measurement only.

| Date and time | Milestone | Change since previous row | Avg fps | 1% low | p95 frame ms | Max draw calls | Max triangles | VRAM | Pass |
| :-- | :-- | :-- | --: | --: | --: | --: | --: | --: | :-- |
| 2026-11-11 16:56 | M2 | First row: island, stall, kitchen line, dock, water, one pad | 197 | 108 | 6.36 | 337 | 628,528 | 477 MB | yes |
| 2026-11-11 17:08 | M3 | Pads 1 to 12 placed, three ovens, display case, statue, two table sets with seated pirates, helper bunny, compact island | 197 | 144 | 6.16 | 420 | 792,698 | 535 MB | yes |
