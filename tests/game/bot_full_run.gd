extends RefCounted
## A full run from the title to the end card without the presenter panel.
## On the island the bot presses the real movement actions (the same input a
## keyboard sends) and decides like a player: scoop, serve, collect, stand on
## the next pad. At sea it switches the ship's autopilot on (steering, aiming
## and firing are then driven by the ship itself) and docks with the hold.
## It prints the purchase times. This is a pacing measurement, not a playtest.
## Run with: xo project run --wait ; xo game eval --file tests/game/bot_full_run.gd --timeout 500

var tree: SceneTree
var root: Window

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const DOCK_GATE: Vector3 = Vector3(11.5, 0.0, -0.5)
const SOUTH_OF_COUNTER: Vector3 = Vector3(5.8, 0.0, 3.6)

var main: Game
var baker: Baker
var _stuck: float = 0.0
var _last: Vector3 = Vector3.ZERO
var _sidestep: float = 0.0
var _voyage_time: float = 0.0
var _speed: float = 3.0
var debug: bool = false
var _printed: float = 0.0


func _release() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


## Presses the movement actions that walk toward `point` on the fixed camera.
func _walk(point: Vector3, delta: float) -> bool:
	var to: Vector3 = point - baker.global_position
	to.y = 0.0
	if to.length() < 0.45:
		_release()
		return true
	var dir: Vector3 = to.normalized()
	if baker.global_position.distance_to(_last) < 6.0 * delta * 0.25:
		_stuck += delta
	else:
		_stuck = 0.0
	_last = baker.global_position
	if _stuck > 0.5:
		_sidestep = 0.45
		_stuck = 0.0
	if _sidestep > 0.0:
		_sidestep -= delta
		dir = dir.cross(Vector3.UP).normalized()
	var camera: Camera3D = root.get_camera_3d()
	var yaw: float = camera.global_rotation.y if camera != null else 0.0
	var local: Vector3 = Basis(Vector3.UP, -yaw) * dir
	_press(&"move_right", local.x > 0.35)
	_press(&"move_left", local.x < -0.35)
	_press(&"move_down", local.z > 0.35)
	_press(&"move_up", local.z < -0.35)
	return false


func _press(action: StringName, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


## Walks a route of points; returns true at the end.
func _route(points: Array, delta: float) -> bool:
	for point: Vector3 in points:
		var gap: Vector3 = point - baker.global_position
		gap.y = 0.0
		if gap.length() > 0.6:
			_walk(point, delta)
			return false
	_release()
	return true


func _on_dock() -> bool:
	return baker.global_position.x > 12.5


## The points that lead to `goal`, around the counter and through the dock gate.
func _path_to(goal: Vector3) -> Array:
	var here: Vector3 = baker.global_position
	var points: Array = []
	var goal_on_dock: bool = goal.x > 12.5
	if goal_on_dock and here.x < 11.2:
		if here.x < 5.0:
			points.append(SOUTH_OF_COUNTER)
		points.append(DOCK_GATE)
	elif not goal_on_dock and here.x > 6.4:
		if here.x > 11.8:
			points.append(DOCK_GATE)
		points.append(SOUTH_OF_COUNTER)
	points.append(goal)
	return points


func _pick_oven() -> Oven:
	var wanted: StringName = main.counter.wanted_kind()
	var best: Oven = null
	var best_count: int = 0
	for node: Node in tree.get_nodes_in_group(&"ovens"):
		var oven: Oven = node as Oven
		if not oven.active or oven.rack_count() <= 0:
			continue
		if oven.kind == wanted and oven.rack_count() >= 2:
			return oven
		if oven.rack_count() > best_count:
			best_count = oven.rack_count()
			best = oven
	return best


func _island_goal() -> Vector3:
	var stack: CarryStack = baker.carry_stack
	var pad: UnlockPad = main.next_pad()
	if pad != null and pad.available and Wallet.cash >= pad.remaining():
		return pad.global_position
	if main.is_bought(&"ship") and not main.kraken_done and (main.voyages == 0 or main.kraken_ready):
		return main.boarding_pad.global_position
	if main.counter.cash_waiting() > 0 and (stack.is_empty() or (pad != null and Wallet.cash + main.counter.cash_waiting() >= pad.remaining())):
		return main.counter.cash_zone.global_position
	var wanted: StringName = main.counter.wanted_kind()
	if not stack.is_empty() and (wanted == &"" or stack.has_kind(wanted) or stack.is_full()):
		return main.counter.serve_zone.global_position
	var oven: Oven = _pick_oven()
	if oven != null and not stack.is_full():
		return oven.pickup_zone.global_position
	if not stack.is_empty():
		return main.counter.serve_zone.global_position
	return main.counter.cash_zone.global_position


func _sea(delta: float) -> void:
	var ship: Ship = main.ship
	_voyage_time += delta
	ship.autopilot = true
	var enough: bool = ship.hold >= 160 or _voyage_time > 75.0
	if main.kraken_ready or main.sea_life.kraken_active:
		enough = false
	if main.kraken_done:
		enough = tree.get_nodes_in_group(&"loot").is_empty() or _voyage_time > 110.0
	if enough:
		ship.autopilot = false
		ship.request_dock()
		_voyage_time = 0.0


func _run() -> void:
	main = tree.current_scene as Game
	baker = main.baker
	var title: TitleScreen = main.title as TitleScreen
	title.start_button.pressed.emit()
	await tree.create_timer(0.7).timeout
	Engine.time_scale = _speed
	var carrying_at: float = -1.0
	while not main.ended and main.session_time < 480.0:
		var delta: float = 1.0 / 60.0
		if main.mode == Game.Mode.SEA:
			_release()
			_sea(tree.root.get_process_delta_time())
		else:
			if carrying_at < 0.0 and baker.carry_stack.count() > 0:
				carrying_at = main.session_time
			var goal: Vector3 = _island_goal()
			_route(_path_to(goal), delta)
			if debug and main.session_time - _printed > 12.0 and main.session_time > 150.0:
				_printed = main.session_time
				print("t %.0f pos %s goal %s cash %d tray %d stack %d" % [main.session_time, baker.global_position.snappedf(0.1), goal.snappedf(0.1), Wallet.cash, main.counter.cash_waiting(), baker.carry_stack.count()])
		await tree.physics_frame
	_release()
	Engine.time_scale = 1.0
	print("carrying donuts at %.1f s" % carrying_at)
	print("ended %s at %.1f s, voyages %d" % [main.ended, main.session_time, main.voyages])
	print("purchases ", main.purchase_log)
	print("stats sold %d sharks %d tentacles %d earned %d" % [Wallet.stat(&"donuts_sold"), Wallet.stat(&"sharks"), Wallet.stat(&"tentacles"), Wallet.lifetime_earned])
