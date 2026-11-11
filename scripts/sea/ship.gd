class_name Ship
extends Node3D
## The bought ship: sailing, the cannons, the hold and the hull.
##
## `W` accelerates, `S` slows and reverses, `A` and `D` turn. The mouse aims on
## the water and the cannon on the side that faces the aim point fires. Loot
## that the ship reaches goes into the hold and is unloaded at the dock.
##
## The hull, the deck bunny, the cannons, the muzzle markers, the wake, the aim
## ring and the arc dots are authored in `ship.tscn`. The ship moves in
## `_process` on the water plane (no physics body), so it is rigid on screen.

signal sailing_changed(sailing: bool)
signal docked(loot: int)
signal ammo_changed(ammo: int, ammo_max: int)
signal hull_changed(hull: float, hull_max: float)
signal hold_changed(loot: int)
signal wrecked

enum State { MOORED, SAILING, RETURNING }

@export_group("Sailing")
@export var top_speed: float = 9.0
## Seconds from rest to top speed.
@export var accel_time: float = 1.2
@export var reverse_speed: float = 2.0
@export var turn_rate_degrees: float = 55.0
@export var bank_degrees: float = 6.0
## The island the hull may not cross (ellipse half sizes, with margin).
@export var island_half_size: Vector2 = Vector2(18.5, 15.0)
@export var sea_radius: float = 140.0
@export var islets: Array[Vector3] = [Vector3(58.0, 0.0, -42.0), Vector3(-52.0, 0.0, 46.0)]
@export var islet_radius: float = 9.0

@export_group("Cannons")
@export var ammo_max: int = 5
@export var reload_time: float = 0.8
@export var aim_min: float = 6.0
@export var aim_max: float = 34.0
## Half of the firing arc of each side, in degrees.
@export var half_arc_degrees: float = 60.0
@export var cannonball_scene: PackedScene
@export var muzzle_flash_scene: PackedScene
@export var double_cannons: bool = false
## The performance route sails and fires by itself.
@export var autopilot: bool = false

@export_group("Hull")
@export var hull_max: float = 100.0
@export var god_mode: bool = false

@export_group("Nodes")
@export var hull_pivot: Node3D
@export var deck_bunny: Node3D
@export var port_cannons: Node3D
@export var starboard_cannons: Node3D
@export var wake: GPUParticles3D
@export var spray: GPUParticles3D
@export var aim_ring: Node3D
@export var aim_dots: Node3D
@export var deck_flash: MeshInstance3D

var speed: float = 0.0
var hold: int = 0
var hull: float = 100.0
var ammo: int = 5

var _state: State = State.MOORED
var _yaw: float = 0.0
var _mooring_position: Vector3 = Vector3.ZERO
var _mooring_yaw: float = 0.0
var _roll: float = 0.0
var _reload: float = 0.0
var _left_dock: bool = false
var _aim_point: Vector3 = Vector3.ZERO
var _aim_valid: bool = false
var _aim_side: int = 0
var _fire_cooldown: float = 0.0
var _time: float = 0.0
var _tween: Tween = null


func _ready() -> void:
	add_to_group(&"ship")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_mooring_position = global_position
	_mooring_yaw = global_rotation.y
	_yaw = _mooring_yaw
	hull = hull_max
	ammo = ammo_max
	_show_aim(false)
	if deck_bunny != null:
		deck_bunny.visible = false
	if deck_flash != null:
		deck_flash.visible = false


## Called by the ship pad: the ship sails in from the sea and moors.
func on_unlocked() -> void:
	var from: Vector3 = _mooring_position + Vector3(26.0, 0.0, -22.0)
	global_position = from
	_set_yaw(_mooring_yaw + 0.9)
	_state = State.RETURNING
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "global_position", _mooring_position, 2.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_yaw, _yaw, _mooring_yaw, 2.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(func() -> void: _state = State.MOORED)
	Audio.play(&"ship_horn")


func is_sailing() -> bool:
	return _state == State.SAILING


func mooring_position() -> Vector3:
	return _mooring_position


func forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


## The baker boarded: the helm is live.
func start_sailing() -> void:
	if _state != State.MOORED:
		return
	_state = State.SAILING
	_left_dock = false
	speed = 0.0
	if deck_bunny != null:
		deck_bunny.visible = true
		ItemFlight.pop_in(deck_bunny, 0.3, 1.15)
	sailing_changed.emit(true)
	ammo_changed.emit(ammo, ammo_max)
	hull_changed.emit(hull, hull_max)
	hold_changed.emit(hold)


## Sails back to the mooring and reports the loot in the hold.
func request_dock() -> void:
	if _state != State.SAILING:
		return
	_return_to_mooring(0.9, true)


## Loot that reached the ship.
func add_loot(amount: int) -> void:
	hold += amount
	hold_changed.emit(hold)


func set_double_cannons(enabled: bool) -> void:
	double_cannons = enabled
	reload_time = 0.5 if enabled else 0.8


## Damage to the hull. At zero the ship limps home with half of its loot.
func damage(amount: float) -> void:
	if _state != State.SAILING:
		return
	Audio.play_varied(&"hull_hit", 0.08)
	get_tree().call_group(&"game_camera", &"add_trauma", 0.45)
	_flash_deck()
	Fx.burst(Fx.SPLASH, self, global_position + Vector3.UP * 0.5, 1.6)
	if god_mode:
		return
	hull = maxf(hull - amount, 0.0)
	hull_changed.emit(hull, hull_max)
	if hull <= 0.0:
		hold = int(float(hold) * 0.5)
		hold_changed.emit(hold)
		_state = State.RETURNING
		speed = 0.0
		_show_aim(false)
		wrecked.emit()


## Ends the sail in at once (presenter panel, performance route).
func snap_to_mooring() -> void:
	if _state == State.SAILING:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	global_position = _mooring_position
	_set_yaw(_mooring_yaw)
	_state = State.MOORED


## Puts the ship back at the dock at once (after the limp home fade).
func moor_now() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	global_position = _mooring_position
	_set_yaw(_mooring_yaw)
	hull = hull_max
	hull_changed.emit(hull, hull_max)
	_finish_docking()


func _process(delta: float) -> void:
	_time += delta
	_bob(delta)
	if _state != State.SAILING:
		_emit_trails(false)
		return
	_sail(delta)
	_reload_cannons(delta)
	_aim()
	_fire_cooldown -= delta
	if autopilot:
		_auto_aim()
	if (Input.is_action_pressed(&"fire") or autopilot) and _fire_cooldown <= 0.0:
		_fire()
	var to_dock: float = Vector2(global_position.x - _mooring_position.x, global_position.z - _mooring_position.z).length()
	if to_dock > 22.0:
		_left_dock = true
	if autopilot:
		return
	if (_left_dock and to_dock < 7.5) or (Input.is_action_just_pressed(&"interact") and to_dock < 18.0):
		request_dock()


func _sail(delta: float) -> void:
	var throttle: float = Input.get_axis(&"move_down", &"move_up")
	var steer: float = Input.get_axis(&"move_right", &"move_left")
	if autopilot:
		throttle = 1.0
		steer = _autopilot_steer()
	var target: float = 0.0
	if throttle > 0.0:
		target = top_speed
	elif throttle < 0.0:
		target = -reverse_speed
	var rate: float = top_speed / maxf(accel_time, 0.01)
	if throttle == 0.0:
		rate *= 0.35
	speed = move_toward(speed, target, rate * delta)
	var speed01: float = clampf(absf(speed) / top_speed, 0.0, 1.0)
	var turn: float = deg_to_rad(turn_rate_degrees) * lerpf(0.3, 1.0, speed01) * steer
	if speed < 0.0:
		turn = -turn
	var at: Vector3 = global_position + forward() * speed * delta
	var from_center: float = Vector2(at.x, at.z).length()
	# The soft ring: a current turns the ship back toward the island.
	if from_center > sea_radius - 18.0:
		var home_yaw: float = atan2(at.x, at.z)
		var pull: float = clampf((from_center - (sea_radius - 18.0)) / 18.0, 0.0, 1.0)
		turn += wrapf(home_yaw - _yaw, -PI, PI) * pull * 1.4
		if from_center > sea_radius:
			at = at * (sea_radius / from_center)
	at = _keep_off_land(at)
	global_position = Vector3(at.x, global_position.y, at.z)
	_set_yaw(_yaw + turn * delta)
	_roll = lerpf(_roll, -steer * deg_to_rad(bank_degrees) * speed01, 1.0 - exp(-4.0 * delta))
	_emit_trails(true)


## Pushes a position out of the island ellipse and the islet circles.
func _keep_off_land(at: Vector3) -> Vector3:
	var e: Vector2 = Vector2(at.x / island_half_size.x, at.z / island_half_size.y)
	if e.length() < 1.0:
		var out: Vector2 = e.normalized() if e.length() > 0.001 else Vector2.RIGHT
		at.x = out.x * island_half_size.x
		at.z = out.y * island_half_size.y
		speed = move_toward(speed, 0.0, 30.0 * get_process_delta_time())
	for islet: Vector3 in islets:
		var away: Vector2 = Vector2(at.x - islet.x, at.z - islet.z)
		if away.length() < islet_radius:
			away = away.normalized() * islet_radius if away.length() > 0.001 else Vector2(islet_radius, 0.0)
			at.x = islet.x + away.x
			at.z = islet.z + away.y
			speed = move_toward(speed, 0.0, 30.0 * get_process_delta_time())
	return at


func _bob(_delta: float) -> void:
	var here: Vector3 = global_position
	var water: float = Sea.height_at(here.x, here.z)
	global_position.y = water
	if hull_pivot != null:
		var ahead: Vector3 = here + forward() * 3.0
		var pitch: float = atan2(Sea.height_at(ahead.x, ahead.z) - water, 3.0) * 1.6
		hull_pivot.rotation = Vector3(pitch + sin(_time * 1.3) * 0.012, 0.0, _roll + sin(_time * 0.9) * 0.02)


func _set_yaw(value: float) -> void:
	_yaw = value
	rotation.y = _yaw


func _emit_trails(sailing: bool) -> void:
	if wake != null:
		wake.emitting = sailing and absf(speed) > 1.0
	if spray != null:
		spray.emitting = sailing and speed > top_speed * 0.6


func _reload_cannons(delta: float) -> void:
	if ammo >= ammo_max:
		_reload = 0.0
		return
	_reload += delta
	if _reload >= reload_time:
		_reload = 0.0
		ammo += 1
		ammo_changed.emit(ammo, ammo_max)
		Audio.play(&"reload", 1.0 + 0.08 * float(ammo), -10.0)


## Where the mouse points on the water, and which side can reach it.
func _aim() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse)
	var normal: Vector3 = camera.project_ray_normal(mouse)
	if absf(normal.y) < 0.001:
		return
	var distance: float = (Sea.level - origin.y) / normal.y
	if distance <= 0.0:
		_show_aim(false)
		_aim_valid = false
		return
	var point: Vector3 = origin + normal * distance
	var flat: Vector3 = point - global_position
	flat.y = 0.0
	var reach: float = clampf(flat.length(), aim_min, aim_max)
	flat = flat.normalized() * reach if flat.length() > 0.01 else forward() * aim_min
	_aim_point = Vector3(global_position.x + flat.x, Sea.level, global_position.z + flat.z)
	var right: Vector3 = Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var side_dot: float = flat.normalized().dot(right)
	_aim_side = 1 if side_dot >= 0.0 else -1
	_aim_valid = absf(side_dot) >= cos(deg_to_rad(half_arc_degrees))
	_show_aim(true)
	if aim_ring != null:
		aim_ring.global_position = _aim_point + Vector3.UP * 0.12
		aim_ring.global_rotation = Vector3.ZERO
		aim_ring.scale = Vector3.ONE * (1.0 if _aim_valid else 0.55)
	if aim_dots != null:
		var from: Vector3 = _muzzle(_aim_side, 0)
		var count: int = aim_dots.get_child_count()
		for i in count:
			var dot: Node3D = aim_dots.get_child(i) as Node3D
			var t: float = float(i + 1) / float(count + 1)
			var apex: float = _apex(from.distance_to(_aim_point))
			var control: Vector3 = (from + _aim_point) * 0.5 + Vector3.UP * apex * 2.0
			dot.global_position = ItemFlight.bezier(from, control, _aim_point, t)
			dot.visible = _aim_valid


## Autopilot: head for the nearest loot, else close in on the nearest enemy,
## else sail a wide circle.
func _autopilot_steer() -> float:
	var goal: Vector3 = Vector3.INF
	var best: float = 70.0
	for node: Node in get_tree().get_nodes_in_group(&"loot"):
		var gap: float = (node as Node3D).global_position.distance_to(global_position)
		if gap < best:
			best = gap
			goal = (node as Node3D).global_position
	if goal == Vector3.INF:
		best = 90.0
		for node: Node in get_tree().get_nodes_in_group(&"sea_enemies"):
			var gap: float = (node as Node3D).global_position.distance_to(global_position)
			if gap < best and gap > 15.0:
				best = gap
				goal = (node as Node3D).global_position
	if goal == Vector3.INF:
		return 0.3
	var want: float = atan2(-(goal.x - global_position.x), -(goal.z - global_position.z))
	return clampf(wrapf(want - _yaw, -PI, PI) * 2.0, -1.0, 1.0)


## Autopilot: aim at the nearest enemy in range, or abeam.
func _auto_aim() -> void:
	var best: Node3D = null
	var best_gap: float = aim_max
	for node: Node in get_tree().get_nodes_in_group(&"sea_enemies"):
		var gap: float = (node as Node3D).global_position.distance_to(global_position)
		if gap < best_gap:
			best_gap = gap
			best = node as Node3D
	var right: Vector3 = Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var at: Vector3 = best.global_position if best != null else global_position + right * 14.0
	var flat: Vector3 = at - global_position
	flat.y = 0.0
	_aim_point = Vector3(at.x, Sea.level, at.z)
	_aim_side = 1 if flat.dot(right) >= 0.0 else -1
	_aim_valid = flat.length() >= aim_min


func _show_aim(show_it: bool) -> void:
	if aim_ring != null:
		aim_ring.visible = show_it
	if aim_dots != null:
		aim_dots.visible = show_it


func _apex(distance: float) -> float:
	return clampf(distance * 0.18, 1.2, 5.0)


func _side_root(side: int) -> Node3D:
	return starboard_cannons if side > 0 else port_cannons


func _muzzle(side: int, index: int) -> Vector3:
	var cannons: Node3D = _side_root(side)
	if cannons == null or cannons.get_child_count() == 0:
		return global_position + Vector3.UP * 2.0
	var cannon: Node3D = cannons.get_child(mini(index, cannons.get_child_count() - 1)) as Node3D
	var muzzle: Node3D = cannon.get_node_or_null(^"Muzzle") as Node3D
	return muzzle.global_position if muzzle != null else cannon.global_position


func _fire() -> void:
	if not _aim_valid:
		_fire_cooldown = 0.3
		Audio.play_varied(&"reject", 0.05, -4.0)
		Fx.burst(Fx.SAD_PUFF, self, _muzzle(_aim_side, 0), 0.6)
		return
	if ammo <= 0:
		_fire_cooldown = 0.25
		Audio.play_varied(&"click_empty", 0.05, -6.0)
		return
	ammo -= 1
	ammo_changed.emit(ammo, ammo_max)
	_fire_cooldown = 0.28
	var shots: int = 2 if double_cannons else 1
	for i in shots:
		var target: Vector3 = _aim_point
		if shots > 1:
			var spread: Vector3 = forward() * (1.4 if i == 0 else -1.4)
			target += spread
		_shoot(_aim_side, i, target)
	get_tree().call_group(&"game_camera", &"add_trauma", 0.15)
	Audio.play_varied(&"cannon", 0.12)


func _shoot(side: int, index: int, target: Vector3) -> void:
	var from: Vector3 = _muzzle(side, index)
	if muzzle_flash_scene != null:
		Fx.burst(muzzle_flash_scene, self, from)
	var cannons: Node3D = _side_root(side)
	if cannons != null and cannons.get_child_count() > 0:
		var cannon: Node3D = cannons.get_child(mini(index, cannons.get_child_count() - 1)) as Node3D
		var rest: Vector3 = cannon.position
		var kick: Tween = cannon.create_tween()
		kick.tween_property(cannon, "position", rest - Vector3(float(side) * 0.35, 0.0, 0.0), 0.05)
		kick.tween_property(cannon, "position", rest, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if cannonball_scene == null:
		return
	var ball: Cannonball = cannonball_scene.instantiate() as Cannonball
	get_tree().current_scene.add_child(ball)
	ball.global_position = from
	var distance: float = from.distance_to(target)
	ball.launch(target, clampf(distance / 26.0, 0.35, 1.1), _apex(distance))


func _return_to_mooring(time: float, report: bool) -> void:
	_state = State.RETURNING
	speed = 0.0
	_show_aim(false)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "global_position:x", _mooring_position.x, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "global_position:z", _mooring_position.z, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var from_yaw: float = _yaw
	var to_yaw: float = from_yaw + wrapf(_mooring_yaw - from_yaw, -PI, PI)
	_tween.tween_method(_set_yaw, from_yaw, to_yaw, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.chain().tween_callback(_finish_docking if report else func() -> void: _state = State.MOORED)


func _finish_docking() -> void:
	_state = State.MOORED
	_roll = 0.0
	if deck_bunny != null:
		deck_bunny.visible = false
	var loot: int = hold
	hold = 0
	hold_changed.emit(hold)
	sailing_changed.emit(false)
	docked.emit(loot)


func _flash_deck() -> void:
	if deck_flash == null:
		return
	deck_flash.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(func() -> void: deck_flash.visible = false)
