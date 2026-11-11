# Audio licences

Every music track and sound effect: file, source, licence, author. Original baked audio: the generating script.


All audio in this build is original and baked offline by `tools/bake_audio.py` (numpy synthesis: plucked strings, marimba, soft percussion, reed organ, whistle, strings, low drums; no samples, no chiptune voices). No third party audio is used, so there is no licence to credit. Re bake with `C:\Python314\python.exe -E -P tools/bake_audio.py` (needs numpy, scipy, soundfile and ffmpeg for the Vorbis encode).

| File | What | Length |
| :-- | :-- | :-- |
| `assets/audio/music/island.ogg` | Shop loop: ukulele style strum, marimba melody (A, B, A' sections), shaker, kick, rim. 100 bpm, 24 bars, seamless | 57.6 s |
| `assets/audio/music/sea.ogg` | Sea shanty variant in 6/8: stomp, reed organ, plucked bass, whistle and reed tune. 36 bars, seamless | 47.0 s |
| `assets/audio/music/kraken.ogg` | Kraken variant: low drums, string ostinato and stabs in D minor. 130 bpm, 26 bars, seamless | 48.0 s |
| `assets/audio/music/ambience.ogg` | Waves and gulls, seamless | 32.0 s |
| `assets/audio/sfx/*.wav` (33 files) | pickup, pickup_soft, serve, donut_land, coin, coin_drop, pad_tick, reject, click_empty, oven_ding, ui_hover, ui_click, unlock, fanfare, rare_fanfare, pirate_happy, pirate_grumpy, cannon, splash, impact, hull_hit, reload, shark_warn, shark_bite, tentacle_rise, tentacle_rumble, tentacle_slam, enemy_down, kraken_roar, ship_horn, board, firework, limp_home | 0.05 to 2.2 s |

The pitch ladders (pickups, coins, pad ticks) are played by code from one file each with a rising `pitch_scale`.
