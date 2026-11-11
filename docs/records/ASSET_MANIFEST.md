# Asset manifest and restore registry

All models are free CC0 1.0 packs by Quaternius (quaternius.com), licence verified on each pack page on 2026-11-11. They were copied unmodified on 2026-11-11 from the zips downloaded on 2026-11-06 into `D:\_Programming\Game Development\Games - Letta Collaborations\Xogot\_asset-packs (2026-11-06)\`, and they are committed in this private repository, so a clone restores them. No generation credits, no accounts.

| Project folder | Pack | Page | Format | Files |
| :-- | :-- | :-- | :-- | --: |
| `assets/quaternius/pirate/` | Pirate Kit (Nov 2023), complete glTF set | https://quaternius.com/packs/piratekit.html | glTF, embedded textures | 72 |
| `assets/quaternius/restaurant/` | Sushi Restaurant Kit (May 2023), subset | https://quaternius.com/packs/sushirestaurantkit.html | glTF, embedded textures | 40 |
| `assets/quaternius/food/` | Ultimate Food Pack (Oct 2019), subset | https://quaternius.com/packs/ultimatefood.html | OBJ plus MTL | 13 models |
| `assets/quaternius/interior/` | Ultimate House Interior Pack (June 2020), subset | https://quaternius.com/packs/ultimatehomeinterior.html | OBJ plus MTL | 32 models |

Restore: copy the same file names from the `glTF` (pirate, restaurant) or `OBJ` (food, interior) folders of those zips into the folders above.

## Measured in the files (2026-11-11, file units, skinned sizes approximate)

| Model | Size x, y, z | Notes |
| :-- | :-- | :-- |
| Pirate characters | height 1.5 to 1.85 | 14 clips: Death, Duck, HitReact, Idle, Jump, Jump_Idle, Jump_Land, No, Punch, Run, Sword, Walk, Wave, Yes |
| `Characters_Shark` | 2.3, 2.0, 5.6 | Clips: Swim, Swim_Bite, Swim_Fast |
| `Characters_Tentacle` | 2.75, 19.7, 2.2 | Rigged. Clips: Tentacle_Attack, Tentacle_Attack2, Tentacle_Idle, Tentacle_Poke |
| `Enemy_Tentacle` | 0.85, 6.1, 0.67 | Not rigged, no clips |
| `Ship_Large` / `Ship_Small` | 15.4, 11.5, 5.3 / 5.2, 2.0, 3.6 | |
| `Environment_House1` | 13.5, 6.8, 4.6 | The ship shaped house (finale) |
| `Rabbit_Cyan` and the other rabbits, `Panda` | height 4.16 (rabbits), 3.33 (panda) | 30 clips including Idle_Holding, Run_Holding, Walk_Holding, Chop_*, Pan_*, Assembly_*, Sitting_* |
| Restaurant counters | 4.0, 1.92, 1.77 | Restaurant kit is about 2.4 times the pirate scale |
| `Kitchen_Oven` / `Kitchen_Fridge` | 1.01, 1.62, 1.12 / 1.3, 3.31, 1.3 | |
| `Donut1` to `Donut4` | 0.86, 0.29, 0.87 | Donut1 pink with sprinkles, Donut2 yellow glaze, Donut3 plain, Donut4 chocolate drizzle |

## Used by the game (filled by the builder)

| Model | Scene | Final scale | Notes |
| :-- | :-- | :-- | :-- |
