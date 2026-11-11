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
