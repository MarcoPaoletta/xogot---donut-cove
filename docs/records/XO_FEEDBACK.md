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
