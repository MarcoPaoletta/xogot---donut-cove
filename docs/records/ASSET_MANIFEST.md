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
| `restaurant/Rabbit_Cyan.gltf` | `scenes/actors/baker.tscn`, `scenes/sea/ship.tscn` (deck bunny), `scenes/props/holo/` none | 0.42 | Baker. Measured 4.16 tall in file units, 1.75 m with ears. Clips used: Idle, Walk, Run, Idle_Holding, Walk_Holding, Run_Holding, Yes, HitReact |
| `restaurant/Rabbit_Pink.gltf` | `scenes/actors/helper.tscn`, `scenes/props/holo/holo_rabbit.tscn` | 0.40, 0.42 | Helper bunny and her pad hologram |
| `pirate/Characters_Anne.gltf`, `Characters_Henry.gltf`, `Characters_Sharky.gltf`, `Characters_Mako.gltf` | `scenes/actors/customer_*.tscn` | 1.0 | Regular customers (1.65 to 1.85 m). Clips: Idle, Walk, Yes, Wave, No |
| `pirate/Characters_Captain_Barbarossa.gltf` | `scenes/actors/customer_captain.tscn` | 1.0 | Rare customer, pays 3 times |
| `pirate/Characters_Skeleton.gltf` | `scenes/props/statue.tscn`, `scenes/props/holo/holo_skeleton.tscn` | 1.25, 1.2 | Statue frozen at 0.35 s of `Sword` |
| `pirate/Characters_Shark.gltf` | `scenes/sea/shark.tscn` | 0.5 | 2.8 m. Clips: Swim, Swim_Fast, Swim_Bite |
| `pirate/Characters_Tentacle.gltf` | `scenes/sea/tentacle.tscn`, `scenes/props/tinted/tentacle_dark.tscn` (Kraken) | 0.3, 0.5 | 5.9 m and 9.9 m above its root. Clips: Tentacle_Idle, Tentacle_Attack |
| `pirate/Ship_Large.gltf` | `scenes/sea/ship.tscn`, `scenes/props/holo/holo_ship.tscn` | 0.8, 0.13 | 12.3 m, bow rotated to the ship's forward axis |
| `pirate/Prop_Cannon.gltf` | `scenes/sea/ship.tscn` (4), `scenes/island/island.tscn`, `scenes/props/holo/holo_cannon.tscn` | 0.9, 1.3, 1.0 | Deck cannons and beach decor |
| `pirate/Prop_CannonBall.gltf` | `scenes/sea/cannonball.tscn`, `scenes/island/island.tscn` | 1.15, 1.0 | |
| `pirate/Prop_Chest_Gold.gltf` | `scenes/sea/loot_chest.tscn`, `scenes/sea/golden_chest.tscn`, `scenes/island/island.tscn` | 0.75, 1.7, 0.9 | |
| `pirate/Prop_Coins.gltf`, `Prop_GoldBag.gltf`, `Prop_Bomb.gltf`, `Prop_Barrel.gltf` | `scenes/sea/loot_coins.tscn`, `scenes/island/island.tscn`, `scenes/island/kitchen_line.tscn` | 2.2, 1.2 to 1.5 | Loot and decor |
| `pirate/Environment_Dock.gltf`, `Environment_Dock_Pole.gltf` | `scenes/island/dock.tscn`, `scenes/props/counter.tscn` (rope posts at 0.3) | 1.0 | 7 dock pieces, 15.3 m |
| `pirate/Environment_Cliff1` to `4` | `scenes/props/tinted/cliff*_rock.tscn`, placed in `scenes/island/island.tscn`, `scenes/sea/islet.tscn` | 1.0 to 1.3 | Flat warm grey override |
| `pirate/Environment_Rock_1` to `5`, `Environment_PalmTree_1` to `3`, `Environment_LargeBones`, `Prop_Skull` | `scenes/island/island.tscn`, `scenes/sea/islet.tscn` | rocks 0.8 to 3.4, palms 1.4 to 2.0, bones 0.4, skull 7.0 | Rim and decor; the skull is the skull rock |
| `pirate/Environment_House1.gltf` | `scenes/props/donut_house.tscn`, `scenes/props/holo/holo_house.tscn` | 0.55, 0.14 | The Captain's Donut House, 7.4 m |
| `restaurant/Environment_Counter_Straight_2.gltf` | `scenes/props/tinted/counter_bar_sage.tscn`, two in `scenes/props/counter.tscn` | 0.42 | 3.4 m counter, sage override, native cream top, glass case and register |
| `restaurant/Environment_Counter_Straight.gltf`, `Environment_Counter_Sink.gltf`, `Environment_Cabinet_Shelves.gltf` | `scenes/props/tinted/*_sage.tscn`, in `scenes/island/kitchen_line.tscn` | 0.42 | |
| `restaurant/Environment_Bowl.gltf`, `Environment_Plate.gltf` | `scenes/island/kitchen_line.tscn` | 0.42 | |
| `food/Donut1.obj`, `Donut4.obj`, `Donut2.obj`, `Donut3.obj` | `scenes/props/donut_strawberry.tscn`, `donut_chocolate.tscn`, `donut_honey.tscn`, `donut_plain.tscn` | 0.58 | 0.5 m wide, 0.168 m per stack slot. Palette overrides in `materials/pal/` |
| `food/KetchupBottle.obj`, `MustardBottle.obj` | `scenes/island/kitchen_line.tscn` | 0.5 | |
| `interior/Kitchen_Oven.obj` | `scenes/props/oven_*.tscn`, oven pad holograms | 0.75 | 0.76 m wide, 1.21 m tall |
| `interior/Shelf_Small1.obj` | `scenes/props/oven_*.tscn` (rack) | 0.75 | |
| `interior/Shelf_1.obj`, `Kitchen_Fridge.obj` | `scenes/island/kitchen_line.tscn` | 0.62, 0.58 | Donut shelves in wood, fridge 1.9 m |
| `interior/Table_RoundSmall.obj`, `Chair_1.obj`, `Houseplant_3.obj` | `scenes/props/table_set.tscn` | 0.7, 0.6, 0.8 | White table, pink and mint chairs |

Not used (spare stock): the other rabbits and the panda, `Ship_Small`, `Enemy_Tentacle`, the weapons and UI props of the pirate kit, the other interior and food models.

Import settings: unchanged defaults for every model. The OBJ packs (food, interior) store their `Kd` colours in linear space and import too dark; the fix is saved materials in `materials/pal/` assigned as surface overrides on the instances, the source files are untouched.

Fonts: `assets/fonts/LilitaOne-Regular.ttf` (Lilita One, SIL Open Font Licence 1.1, Google Fonts, licence text in `assets/fonts/LilitaOne-OFL.txt`).
