# xo feedback for Xogot

GDD Section 0.4. One line per item: command, what happened, cause, workaround. Counts at the end.

## Failures and workarounds

## Fell back to xo eval

## Missing structured commands

## What worked well

## Known before the build (setup, 2026-11-11)

* On this Windows machine the xo CLI cannot connect to the editor unix socket (WSAEINVAL) and a stale socket blocks the next bind; worked around with the TCP wrapper `tools/xo` (details in `docs/context/xo-windows.md`).

## Build log (2026-11-11)

* OK: `project run --scene ... --wait`, `game status`, `game eval`, `game input key` and `project stop` all work over the TCP wrapper. No second instance appeared in the registry.
* Note: `game input action toggle_mute` delivers an `InputEventAction`, so a handler in `_unhandled_key_input` never sees it. `game input key M` does. Worth a line in the skill.
* Minor: `project autoload add Wallet res://scripts/core/wallet.gd` right after `script create` logged `Unrecognized UID` and `Failed to create an autoload, can't load from UID or path` once in the editor; the autoload was registered correctly and works. Looks like the uid was not in the cache yet.
* Wish: no `xo file mkdir`. Folders were created with the shell, then `xo file scan --wait`.
* OK: `xo batch` built the Audio scene (29 steps) in one call.
* BUG (Windows, Git Bash): a node path argument such as `/D1` is rewritten by MSYS to `C:/Program Files/Git/D1` before xo sees it (`Error: Could not resolve node path: C:/Program Files/Git/D1`). Workaround: `export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*"`. Worth a line in the Windows notes of the skill.
* GOTCHA (silent, cost one debug round): `xo node property set /Counter serve_zone 'NodePath("ServeZone")'` on a typed node export (`@export var serve_zone: Area3D`) saves `serve_zone = NodePath("ServeZone")` without the `node_paths=PackedStringArray(...)` header, so the export is `null` at runtime. Workaround: assign the real node through `xo eval` (`n.set("serve_zone", n.get_node("ServeZone"))`), 60 exports so far. Wish: `xo node property set --node-ref` or automatic handling of node typed exports.
* GOTCHA: `xo script create` refuses an existing file and there is no `--overwrite`. Whole file rewrites went through `xo file send` plus `xo script check`; small changes through `xo script patch`.
* GOTCHA: a `class_name` created by `xo script create` was not in the global class cache until `xo file scan --wait` (`Could not find type "Game"` in a `game eval` suite; the scan reported `script_classes_added: ["Game"]`).
* LIMIT: `xo batch` validation rejects `node property set <control> theme_override_font_sizes/font_size 40` ("has no property"), although the same command works alone. Theme overrides run one by one after the batch.
* LIMIT: `xo batch` validation rejects `node property set / metadata/kind ...`.
* LIMIT: `xo particles configure --process color_initial_ramp=res://...` and `scale_curve=res://...` fail with "Could not parse": process properties do not take resource paths. Workaround: a saved `ParticleProcessMaterial` through `xo resource create --type ParticleProcessMaterial --property scale_curve=res://...`, then `xo resource set /P process_material`.
* LIMIT: `xo resource curve <path> --points` needs `--type Curve` to create the file; the reference shows it without.
* GOOD: xo refused `material assign` on a mesh inside an instanced glTF ("Changes ... will not be saved. Enable Editable Children"). That is the silent data loss of the earlier Xogot build, now an error. Workaround used: small wrapper scenes (`scenes/props/tinted/`) with the instance made editable through `xo eval`.
* FELL BACK TO EVAL: measuring imported models (2), audio bus layout (1), AnimationNodeBlendTree resources (1), Environment with a ProceduralSkyMaterial (1), editable instances (8), typed `Array[PackedScene]` export (1), node typed exports (60).
* GOOD: `xo script create` works for `.gdshader` files too. `xo project shader-global add` worked first time.
* GOOD: `xo batch` with 200 steps built the island in a few seconds; in place rebuilds (delete the root's children, run the batch again) keep the scene file and its uid.
* GOOD: `xo game eval --file` with a complete script, `await` and real `Input.action_press` drives a whole gameplay loop and saves its own frames for the contact sheet.
* BUG (cost about 15 minutes): after replacing a script with `xo file send`, the editor keeps its old in memory `source_code` for that script. `xo script check` reads the file and passes, the game runs the new file, but in the editor new `@export` properties do not exist: `xo node property set` and `xo resource set` answer `Unknown property name`, and a node export assigned through `xo eval` is dropped without a message (the baker's `backpack` reference was lost this way). `xo file scan --wait` does not fix it and `xo script patch` does not either. Workaround: an `xo eval` that sets `script.source_code` from the file for every project script and calls `reload(true)` on all of them (three passes, because dependants compiled against stale classes), then `xo script detach` and attach again on open scenes whose placeholder was created before. Wish: `xo script create --overwrite` (or `xo script replace`) that updates the editor's copy.
* LIMIT: `xo ui draw` writes a shared script at the project root (`res://xogot_draw_recipe.gd`). It is intended, but it is a file at `res://` the agent did not ask for; worth a note in the skill next to the stray scene warning.
* GOOD: `xo theme create`, `theme stylebox` and `theme set` built the whole project theme in nine calls; `--bg r,g,b,a` works for a transparent focus style.
* GOOD: a sea behaviour suite of 16 checks (boarding cycles, autopilot voyage, limp home, Kraken) runs through one `xo game eval --file` with `Engine.time_scale` 3 to 4.
* FELL BACK TO EVAL: script reload (see the bug above), hologram and tint overrides inside glTF instances (6), typed array defaults avoided by code defaults.
* LIMIT: no way through xo to run the game in its own resizable window: `xo project run` has no size or embed option, and with the editor's "Embed Game on Next Play" on, `get_window().size = ...` answers "Embedded window can't be moved". Setting `run/window_placement/game_embed_mode` or the `game_view/embed_on_play` project metadata through `xo eval` did not change the next run. The expand aspect captures were made by starting a capture scene with the Godot binary and `--resolution`. Wish: `xo project run --no-embed` or `--resolution WxH`.
* NOTE: `xo eval` one liners: a `for` loop followed by `; return x` on the same line puts the `return` inside the loop body (GDScript rule, not an xo bug). It produced two wrong readings before it was noticed. Multi line files avoid it.
* GOOD: `xo editor screenshot --source game --max-resolution 0` returned exactly 1920 by 1080 on this Windows machine (no HiDPI scaling), so comparisons needed no rescale.
* GOOD: `xo game eval` suites drove 63 behaviour checks, a 16 frame contact sheet capture and a full five minute bot run with real `Input.action_press` movement.

## Summary and counts (2026-11-11, xo 0.1.0, Godot 4.7.2 stable, Windows 11)

What was built through xo: 72 scenes, 48 project scripts, 11 test files, 60 materials, 2 shaders, 2 animation trees, a theme, a bus layout, an environment, the InputMap (11 actions), the project settings and both autoloads.

| Kind | Count | Note |
| :-- | --: | :-- |
| `xo batch` files in the final generation | 67 | 2,375 steps in total; the largest is the main scene with 266 steps. Every scene was assembled with `scene create`, `batch`, `scene save`; layout changes were rebuilt in place. |
| Theme override properties set one by one | 54 | Batch validation rejects them (limit above). |
| Node typed exports assigned through `xo eval` | 152 | `node property set` cannot write them (gotcha above). The largest single use of eval. |
| Other `xo eval` uses | about 25 | Model measuring (3), editable instances and overrides inside glTF instances (14), blend trees (1), environment (5 passes), bus layout (1), typed array (1), script reload after `file send` (after every script replace). |
| Real failures of xo commands | 9 kinds | Listed above: MSYS path rewrite, node exports, script create overwrite, class cache, batch theme overrides, batch metadata, particle process resources, `resource curve` needing `--type`, stale script source after `file send`. |
| Silent failures (no error, wrong result) | 2 | Node exports saved as plain `NodePath`; exports dropped on a stale script. Both were found by the game crashing or a test, not by xo. |
| Things that worked first time | most | `project setting`, `inputmap`, `autoload`, `shader-global`, `scene create`, `node create --scene-type`, `resource create` and `inline`, `material create` and `assign`, `theme`, `ui anchor` and `ui draw`, `script create` (also for shaders), `script patch`, `script check`, `file send`, `project run --wait`, `game eval --file`, `game input key`, `editor screenshot --source game`, `debug errors`, `editor output`. |

Top three wishes, in order of time they would have saved: (1) node typed exports through `node property set`; (2) `script create --overwrite` that also refreshes the editor's copy; (3) theme overrides and metadata accepted by batch validation.

## Export (M9)

* GOOD: `xo export preset add`, `preset metadata --export-path --exclude-filter`, `preset option`, `preset save`, `validate` and `execute --kind project --configuration debug` produced the Windows build with no editor UI. `validate` named the missing template path exactly.
* NOTE: preset names: `xo export preset list` returns the name under `identity.preset_name`, not `name`; a script that read `name` passed `None` and got "Export preset not found".
* NOTE: with a self contained Godot (`editor_data/` next to the binary) the templates installed under `%APPDATA%` are not found; `preset option custom_template/debug '"<path>"'` fixed it without copying files.
* GOOD: `xo test run --root res://tests/editor` ran the 11 structural checks in the editor in one call and reported a clean summary.
