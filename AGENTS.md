# Donut Cove (Claude Fable 5.2 build, Godot driven only through Xogot's xo)

Read these files in full before touching the project, in this order:

1. `skills/game-dev/SKILL.md` when present locally (private authoring reference on Marco's workstation). Open the `references/` it points to when the task touches them, at least `quick-gameplay`, `tycoon-juice`, `player-controller`, `third-person-camera`, `menu-camera-cuts`, `concept-match`, `visual-feedback-review`, `launch-settings`, `z-fighting` and `xogot-xo`. Never commit it, never push it, never copy it into a shared or public repo, never paste it into project docs.
2. The godot-xo skill (`.claude/skills/godot-xo/SKILL.md`) and the `references/` its routing table names for each task.
3. `docs/context/xo-windows.md` (how xo reaches the editor on this machine: always `bash tools/xo`).
4. `KICKOFF.md` (your instructions; the builder model of this project is Claude Fable 5.2).
5. `docs/Donut Cove - Build GDD.md` (the complete build contract).
6. Every file in `docs/records/`.
7. Every image in `concept/` at full size.

## Rules that decide success

1. **xo only. No Godot AI, no MCP.** Godot is driven exclusively through Xogot's xo CLI (via `bash tools/xo`) and the godot-xo skill. Never install, enable, connect or call Godot AI (`godot-ai`, `addons/godot_ai`), Fennara or any other Godot MCP, even if your session lists tools from them: Marco's user level configuration has a Godot AI server for other projects, and `.claude/settings.json` denies it here. This video is about xo; a second bridge on screen is a problem with the sponsor.
2. **Never edit the editor's files by hand.** Scenes, resources, scripts, shaders, materials, project settings, autoloads and the InputMap change through xo commands (`xo scene`, `xo node`, `xo script create` / `patch`, `xo resource`, `xo material`, `xo project setting`, `xo inputmap`, `xo batch`, `xo eval` only when nothing structured exists). Never write `.tscn`, `.tres`, `.res`, `.gd`, `.gdshader` or `project.godot` with a file tool, a redirect or Python. Markdown in `docs/records/` is the only thing you write directly.
3. **Every game element has its own saved scene** with named, selectable nodes and focused behavior; the world composes instances; `scenes/main.tscn` shows the whole world in the editor before Play. No node trees built in code, no `@tool` scene builders, no monolithic game script. Runtime spawns instantiate saved scenes, effects included.
4. **Assets:** only the CC0 Quaternius models already in `assets/quaternius/` (GDD Section 11), plus Godot native water, sky, glass, coins, pads, particles and UI, and one downloaded OFL font. No other packs, no generators, no models from other projects on this machine. A pack is a bank, not a checklist.
5. **Do not touch** `addons/xo/`, `tools/xo`, `docs/context/xo-windows.md` or `.claude/skills/godot-xo/`. If xo misbehaves, log it in `docs/records/XO_FEEDBACK.md` and work around it.
6. **The contract is frozen.** Never edit the GDD, this file, `CLAUDE.md`, `KICKOFF.md`, `README.md`, `START_HERE.md` or the concepts. Decisions go in `docs/records/BUILD_NOTES.md`.
7. **Performance:** 60 fps at 1920x1080 on Marco's RTX 3060. Run the performance check of GDD Section 15 at the end of every milestone M2 to M8 and fix a failing row before the next milestone.
8. **Product ready is the minimum.** No default Godot UI or font, dead inputs, snapping transitions, open loops, debug overlays left on, or placeholders. The game boots muted; `M` unmutes.
9. **Never stop.** Build until the definition of done (GDD Section 18). The only valid stop: xo cannot reach this project's editor after the recovery below. Everything else: decide, log it, continue, and list leftovers under `Could not complete`. Verifying is something you do, not something you ask.
10. **Git:** commit after each milestone with plain messages that describe the change only, with no AI attribution lines. Never commit `skills/`, `.claude/settings.local.json`, tokens or `build/`.

## Tool recovery

If a command times out or the editor stops answering: `bash tools/xo up` (it reuses or restarts the editor on its TCP port), then `bash tools/xo editor state` before editing. If Marco opened the editor by double click, xo cannot reach it: ask him to close it, then run `bash tools/xo up`. If the running game hits a breakpoint: `xo debug errors`, then `xo debug resume`.
