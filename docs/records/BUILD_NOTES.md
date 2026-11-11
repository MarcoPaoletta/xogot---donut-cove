# Build notes

Every decision, tuned dial, final light value, final scale, pad price and the measured time of each purchase. One line per item, newest at the bottom.


* M0. Font: Lilita One (OFL, Google Fonts), `assets/fonts/LilitaOne-Regular.ttf`, set as `gui/theme/custom_font`. Chosen for chunky rounded digits that read at a distance; Fredoka and Baloo 2 were the alternatives downloaded.
* M0. `Audio` autoload is a scene (`scenes/core/audio.tscn`): a Music player and a pool of 12 one shot players authored as nodes. Sounds are looked up by file name, so gameplay code is written before the sound files exist.
* M0. Buses: Master, Music, SFX (`default_bus_layout.tres`). Master is muted in `Audio._ready`; `M` toggles. Verified in a run: muted at boot `true`, after `M` `false`.
* M0. The saved mute state is not restored at boot: the boot mute rule wins. `user://settings.json` keeps fullscreen and best time.
* M0. Extra dev action `concept_cam` (Tab) for the concept cameras, removed before the final build.
* M1. Tycoon scripts adapted from the tycoon-juice reference and written through xo as project scripts in `scripts/core/` (`ItemFlight`, `CarryStack`, `ItemTray`, `PopNumber`, `ObjectiveArrow`, `Wallet`), plus `Oven`, `ShopCounter`, `CustomerQueue`, `Customer`, `OrderBubble`, `MoneyCounter`, `HudCoinFlight`, `Hud`, `IslandCamera`, `UnlockPad`, `Game`.
* M1. Physics interpolation is on, so everything moved in `_process` (stack items, flying items, customers, bubbles, camera rig, arrow) has `physics_interpolation_mode = OFF`, and the stack reads the baker through `get_global_transform_interpolated()`. Without this the tower jittered against the interpolated body.
* M1. Stack dials: capacity 6, item_height 0.13, follow_k_bottom 40, follow_k_top 11, pickup 0.3 s apex 0.8. Measured at 6 m/s with 6 donuts: bottom lag 0.142 m, top lag 0.55 m, back to 0.0 m 0.8 s after stopping.
* M1. Pitch ladder follows the chain of pickups (step 0.06, reset after 0.6 s) instead of the stack count, as the reference suggests for trays.
* M1. Animation: one `AnimationTree` per character scene with a saved blend tree (`assets/anim/bunny_tree.tres`, `pirate_tree.tres`): `Loco` blend space by speed, `Hold` blend space for the carrying clips mixed by `Carry`, one shots `Shot_Yes`, `Shot_HitReact`, `Shot_Wave`, `Shot_No` (fade in 0.25 s). Holding blend 0.75 s; locomotion blend 0.3 s (exported), because a 0.75 s idle to run blend slid the feet at 6 m/s.
* M1. The clips import without loops; `CharacterAnim._ready` sets `LOOP_LINEAR` on the locomotion clips in memory, so the import settings stay at their defaults.
* M1. The old Quaternius OBJ packs (food, interior) store `Kd` in linear space and import far too dark (white 0.36). Corrected colours are saved materials in `materials/pal/` assigned as surface overrides on the instances; the source files are untouched. The oven `Glass` surface is a dark window with a warm orange emission.
* M1. Regular customers are Anne, Henry, Sharky and Mako. Captain Barbarossa is only the rare customer, so he reads as special.
* M1. Oven scale 0.75 (0.76 m wide, 1.21 m tall) instead of 0.55: at 0.55 the ovens were smaller than the donuts on the rack. Rack is `Shelf_Small1` at 0.75 beside the oven, 4 by 1 by 2 slots (capacity 8).
* M2. Camera: yaw is minus 30 degrees (camera south west, looking north east), which puts the kitchen upper left and the dock upper right as in Concept 1. Pitch 48, FOV 38 as stated. Distance 11.5 m. With pitch 48 and FOV 38 the horizon is above the frame; the concept's horizon line at 9 percent needs a far wider lens than the stated FOV, so the stated numbers win.
* M2. Light after the first rounds: ACES, exposure 0.8, white 6, ambient 0.42 (sky contribution 0.35), sun 1.15 at elevation 55 from the upper left, glow additive 0.45 with threshold 0.95, saturation 1.18, contrast 1.05. Exposure 1.0 with sun 1.3 washed the sand to cream through ACES.
* M2. Sand is one shader surface: dry, light patches and a wet rim by world height. Water is one plane: vertical depth colour, a foam band by vertical depth (constant width at any view angle), a drifting ripple, facets and glints. `sea_time` is a shader global written by the `Sea` node.
* M2. Pads sit south west of the stall (three shared spots A, B, C) off the oven to counter path: a pad on that path drained coins by accident in the first capture.
