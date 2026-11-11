extends Node
## Expand aspect capture (GDD Section 14.1). Instances the real main scene and
## saves the title, the island with its HUD, the pause screen and the sea with
## its HUD at the size the window was started with, to
## `user://aspect/<width>x<height>_<screen>.png`, then quits.
##
## The editor runs the game embedded at a fixed size, so this scene is started
## as its own window: `Godot --path . --resolution 1280x720 res://tests/aspect_capture.tscn`.

@export var main: Game


func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	await _save("1_title")
	main.start_game(true)
	Wallet.add(1500)
	for i in 4:
		main.debug_unlock_next()
	main.baker.teleport(Vector3(-5.3, 0.05, -4.6), PI)
	await _wait(1.6)
	main.baker.teleport(Vector3(-0.6, 0.05, -0.8), 1.0)
	await _wait(0.8)
	await _save("2_island")
	var pause: PauseMenu = main.get_node("Screens/Pause") as PauseMenu
	pause.open()
	await _wait(0.5)
	await _save("3_pause")
	pause.close()
	await _wait(0.4)
	Wallet.add(3000)
	for i in 5:
		main.debug_unlock_next()
	await _wait(0.4)
	main.ship.snap_to_mooring()
	main.baker.teleport(main.boarding_pad.global_position + Vector3(0, 0.05, 0), 0.0)
	await _wait(1.3)
	main.ship.autopilot = true
	main.ship.god_mode = true
	await _wait(5.0)
	await _save("4_sea")
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var window: Window = get_window()
	var image: Image = window.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://aspect"))
	image.save_png("user://aspect/%dx%d_%s.png" % [window.size.x, window.size.y, label])
