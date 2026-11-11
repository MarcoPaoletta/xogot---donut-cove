# xo on Windows: use `tools/xo`, never the bare `xo.exe`

**Rule for every agent on this project:** drive the Godot editor with `bash tools/xo <xo arguments>` (Git Bash).
Start the editor with `bash tools/xo up`. Do not call `xo.exe` directly and do not use `xo launch`.

Measured on 2026-11-11 with xo 0.1.0, Godot 4.7.2 stable, Windows 11 Pro build 26300.

## What is broken

xo talks to the editor through a unix domain socket (`%LOCALAPPDATA%\xo\run\godot-N.sock`). On this machine:

1. **The CLI cannot connect to that socket.** Every command fails with
   `connect ...godot-1.sock: An invalid argument was supplied. (10022)`, also with the sandbox off.
   `xo list` still shows the editor, because that only reads the registry JSON.
2. **The socket file survives the editor and cannot be deleted** (`Error 1920: The file cannot be accessed by
   the system`, also through `fsutil reparsepoint delete`). The next editor with the same instance name fails to
   bind it (`xo: cannot start server: bind ... (10022)` in the editor log) and then starts **no** server at all,
   TCP included.
3. `xo doctor` reports "addon files are not next to the xo executable" unless `XO_ADDON_DIR` points at
   `<xo folder>/addons/xo`.

It is not caused by the other open editors or by the GodotAI MCP: those are separate processes on their own
ports (6005, 6006 and the godot-ai ports). Each project keeps its own channel, so both work side by side.

## The workaround (what `tools/xo` does)

- Starts the editor with `XO_TCP_LISTEN=127.0.0.1:47321` and `XO_TCP_TOKEN=<token>`, so the addon opens a TCP
  listener. The project setting `xo/network/tcp_listen` alone did not open it; the env vars do.
- Uses a **new instance name on every start** (`donut-HHMMSS`), so the bind never meets a stale socket file.
- Keeps its runtime files in `%LOCALAPPDATA%\xo\run-tcp` (`XO_RUNTIME_DIR`). The token lives there in
  `donut-cove.token`, outside the repo.
- Sends every command with `--connect 127.0.0.1:47321 --token <token>`.

Commands:

| Command | Effect |
| :-- | :-- |
| `bash tools/xo up` | Start the editor, or reuse it, and wait until xo answers (about 30 s cold). |
| `bash tools/xo editor state` | Any xo command works this way. |
| `bash tools/xo down` | Quit the editor (refuses with unsaved changes; add nothing, save first). |

If Marco opened the editor by hand (double click), xo cannot reach it: close it and run `bash tools/xo up`.

A second project on the same machine needs its own port: set `XO_PORT` or change the default in its copy.

## Not verified yet

- `project run` and the `game *` commands over TCP (no scene existed when this was written). Check the first run.

## Cleanup left on disk

Undeletable stale sockets remain in `%LOCALAPPDATA%\xo\run\godot-1.sock` and `%LOCALAPPDATA%\xo\run2\`. They
are harmless as long as nobody reuses the name `godot-1` in those folders. A reboot may release them.

## To carry back to the Hub

This lesson belongs in `Marco's Hub/Letta/Skills/game-dev/references/xogot-xo/` (stock Godot xo on Windows),
and is worth reporting to the xo developers as a bug: AF_UNIX connect and bind fail with WSAEINVAL.
