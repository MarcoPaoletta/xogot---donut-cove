extends RefCounted
## Plays one full tycoon loop with real input and saves frames at exact
## moments for the contact sheet (scoop, MAX, trail, recover, serve, coins,
## cash, counter roll, pad drain, reveal).
## Run in the game: xo game eval --file <this> --timeout 60

const OUT: String = "user://contact/"

var tree: SceneTree
var root: Window
var _index: int = 0


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.resize(960, 540, Image.INTERPOLATE_BILINEAR)
	_index += 1
	image.save_png("%s%02d_%s.png" % [OUT, _index, label])


func _wait(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var main: Game = tree.current_scene as Game
	var baker: Baker = main.baker
	baker.teleport(Vector3(-5.3, 0.05, -4.5), PI)
	await _wait(0.1)
	await _shot("scoop_arc")
	await _wait(0.14)
	await _shot("scoop_chain")
	await _wait(1.3)
	await _shot("stack_full_max")
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await _wait(0.45)
	await _shot("run_tower_trails")
	await _wait(0.35)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await _wait(0.06)
	await _shot("stop_tower_swings")
	await _wait(0.6)
	await _shot("tower_recovered")
	baker.teleport(Vector3(2.18, 0.05, 1.55), 2.2)
	await _wait(0.12)
	await _shot("serve_arc")
	await _wait(0.2)
	await _shot("serve_cadence")
	await _wait(0.45)
	await _shot("coins_to_tray")
	await _wait(1.2)
	await _shot("cash_pile")
	baker.teleport(Vector3(1.56, 0.05, 0.77), 2.2)
	await _wait(0.2)
	await _shot("cash_to_hud")
	await _wait(0.35)
	await _shot("counter_rolls")
	await _wait(1.0)
	var pad: UnlockPad = main.next_pad()
	baker.teleport(pad.global_position + Vector3(0.0, 0.05, 0.3), PI)
	await _wait(0.25)
	await _shot("pad_drain_start")
	await _wait(0.4)
	await _shot("pad_drain_fast")
	while not pad.done:
		await tree.process_frame
	await _wait(0.25)
	await _shot("purchase_pops_in")
	await _wait(0.8)
	await _shot("purchase_settled")
	print("frames ", _index, " at ", ProjectSettings.globalize_path(OUT))
