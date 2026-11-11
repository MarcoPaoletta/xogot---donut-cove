extends Node
## A self playing tour of the real game for the evidence video: run with the
## donut stack, serve the crew, buy kitchen pads, then sail and shoot.
## It presses the real movement actions on the island and uses the ship's
## autopilot at sea, with the sound on, then quits.
##
## Record it with Godot's Movie Maker, in its own window:
## `Godot --path . --write-movie out.avi --fixed-fps 60 --resolution 1920x1080 res://tests/video_demo.tscn`

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

@export var main: Game

var _baker: Baker


func _ready() -> void:
	_baker = main.baker
	await _wait(2.5)
	main.start_game(true)
	Audio.set_muted(false)
	await _wait(0.6)
	# Stage 1: scoop, run with the tower, serve, collect, first pad.
	await _go(main.first_oven.pickup_zone.global_position, 2.2)
	await _go(main.counter.serve_zone.global_position, 3.6)
	await _go(main.counter.cash_zone.global_position, 1.4)
	await _go(main.pad(&"oven2").global_position, 2.6)
	# The kitchen grows: two more pads, a bigger tower from two ovens.
	Hud.collect_coins(self, _baker.global_position + Vector3.UP * 1.6, 260)
	await _go(main.pad(&"display_case").global_position, 2.4)
	await _go(main.pad(&"backpack").global_position, 2.4)
	await _go((main.get_node("Ovens/Oven2") as Oven).pickup_zone.global_position, 1.6)
	await _go(main.first_oven.pickup_zone.global_position, 1.8)
	await _go(main.counter.serve_zone.global_position, 4.0)
	await _go(main.counter.cash_zone.global_position, 1.2)
	# Set sail: the rest of the island is bought behind a fade.
	await main.hud.fade(1.0, 0.4)
	Wallet.add(4000)
	main.flags[&"first_voyage"] = true
	for i in 8:
		main.debug_unlock_next()
	await _wait(0.6)
	main.ship.snap_to_mooring()
	_baker.teleport(main.boarding_pad.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	main.hud.fade(0.0, 0.5)
	await _wait(1.6)
	main.ship.autopilot = true
	main.ship.god_mode = true
	await _wait(17.0)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Walks to `point` with the movement actions, then stands there for `stay`.
func _go(point: Vector3, stay: float) -> void:
	var limit: float = 8.0
	while limit > 0.0:
		var to: Vector3 = point - _baker.global_position
		to.y = 0.0
		if to.length() < 0.5:
			break
		var camera: Camera3D = get_viewport().get_camera_3d()
		var yaw: float = camera.global_rotation.y if camera != null else 0.0
		var local: Vector3 = Basis(Vector3.UP, -yaw) * to.normalized()
		_press(&"move_right", local.x > 0.35)
		_press(&"move_left", local.x < -0.35)
		_press(&"move_down", local.z > 0.35)
		_press(&"move_up", local.z < -0.35)
		await get_tree().physics_frame
		limit -= 1.0 / 60.0
	for action: StringName in ACTIONS:
		Input.action_release(action)
	await _wait(stay)


func _press(action: StringName, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)
