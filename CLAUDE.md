# Donut Cove (Claude Fable 5.2 build, xo only)

Read `AGENTS.md` first. Then read `skills/game-dev/SKILL.md` (local only, never committed or distributed), the godot-xo skill, `docs/context/xo-windows.md`, `KICKOFF.md` and every document and concept named in `AGENTS.md` before taking action.

When Marco writes a short line such as "Read KICKOFF.md and create the complete game, no stop", execute the prompt block of `KICKOFF.md` as your instructions.

This is an autonomous build. Build the complete game, not a plan or partial prototype. **Godot is driven only through Xogot's xo, with `bash tools/xo`. No Godot AI and no MCP of any kind**: never install, connect or call one, even if your session lists its tools. Assets are the CC0 Quaternius models in `assets/quaternius/`. Run the performance check after every milestone. Never stop until the definition of done; the only valid stop is xo unable to reach this editor after recovery.
