class_name Game
extends Node3D
## The session of Donut Cove: the title, the start cash, the pad sequence, and
## what each pad changes, boarding and docking, the Kraken, the finale, the
## objective arrow and the session clock.
##
## The world is authored in `main.tscn`; this script only connects the pieces
## that already exist there. Pads are the children of `Pads`, in buying order.

signal pad_bought(pad_id: StringName)
signal session_started
signal sea_changed(at_sea: bool)
signal finale_done

enum Mode { TITLE, ISLAND, SEA }

@export var start_cash: int = 60
## How many unbought pads are offered at once (the concept shows two).
@export var pads_offered: int = 2
## Loot a voyage must bring home before the Kraken wakes.
@export var kraken_loot: int = 150
@export var kraken_reward: int = 900

@export_group("Island")
@export var baker: Baker
@export var pads_root: Node3D
@export var arrow: ObjectiveArrow
@export var counter: ShopCounter
@export var first_oven: Oven
@export var island_camera: IslandCamera

@export_group("Sea")
@export var ship: Ship
@export var sea_camera: SeaCamera
@export var boarding_pad: BoardingPad
@export var sea_life: SeaLife
@export var dock_point: Marker3D
@export var golden_chest_scene: PackedScene

@export_group("World")
@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var blend_camera: Camera3D
@export var house: Node3D

@export_group("Screens")
@export var hud: Hud
@export var title: Node
@export var end_card: Node

## Flags that gate pads: `first_voyage`, `kraken_won`.
var flags: Dictionary = {}
var mode: Mode = Mode.TITLE
var playing: bool = false
var session_time: float = 0.0
var purchase_log: Array[String] = []
var voyages: int = 0
var kraken_ready: bool = false
var kraken_done: bool = false
var ended: bool = false

var _pads: Array[UnlockPad] = []
var _first_sale_done: bool = false
var _blend: Tween = null
var _grade: Tween = null
var _sun_rest: float = 1.0
var _saturation_rest: float = 1.0
var _brightness_rest: float = 1.0


func _ready() -> void:
	add_to_group(&"game")
	Engine.time_scale = 1.0
	for child: Node in pads_root.get_children():
		if child is UnlockPad:
			var found: UnlockPad = child as UnlockPad
			_pads.append(found)
			found.unlocked.connect(_on_pad_unlocked)
	if counter != null:
		counter.sale.connect(func(_amount: int, _at: Vector3) -> void: _first_sale_done = true)
	if boarding_pad != null:
		boarding_pad.boarded.connect(board)
	if ship != null:
		ship.docked.connect(_on_docked)
		ship.wrecked.connect(_on_wrecked)
	if sea_life != null:
		sea_life.kraken_defeated.connect(_on_kraken_defeated)
	if sun != null:
		_sun_rest = sun.light_energy
	if world_environment != null and world_environment.environment != null:
		_saturation_rest = world_environment.environment.adjustment_saturation
		_brightness_rest = world_environment.environment.adjustment_brightness
		world_environment.environment.fog_enabled = false
	Wallet.reset(start_cash)
	if title == null:
		start_game(true)
	else:
		_enter_title()


func _process(delta: float) -> void:
	if playing:
		session_time += delta
	_update_arrow()
	if mode == Mode.SEA and kraken_ready and not kraken_done and sea_life != null and not sea_life.kraken_active:
		var away: Vector3 = ship.global_position - ship.mooring_position()
		away.y = 0.0
		if away.length() > 26.0:
			_start_kraken()


## Leaves the title and starts the session. `instant` skips the fade (tests).
func start_game(instant: bool = false) -> void:
	if playing:
		return
	mode = Mode.ISLAND
	if title != null and title.has_method(&"close"):
		title.call(&"close", instant)
	if island_camera != null:
		island_camera.following = true
		if island_camera.camera != null:
			island_camera.camera.current = true
	if baker != null:
		baker.control_enabled = true
	if hud != null:
		hud.show_hud(true)
	Audio.play_music(&"island")
	begin_session()


## Starts the clock and offers the first pads.
func begin_session() -> void:
	playing = true
	session_time = 0.0
	_offer_pads()
	session_started.emit()


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func set_flag(flag: StringName) -> void:
	flags[flag] = true
	_offer_pads()


## The next pad that can be bought, or null.
func next_pad() -> UnlockPad:
	for candidate: UnlockPad in _pads:
		if not candidate.done and _gate_open(candidate):
			return candidate
	return null


func pad(pad_id: StringName) -> UnlockPad:
	for candidate: UnlockPad in _pads:
		if candidate.pad_id == pad_id:
			return candidate
	return null


func is_bought(pad_id: StringName) -> bool:
	var found: UnlockPad = pad(pad_id)
	return found != null and found.done


# ------------------------------------------------------------------ the sea

## The baker hops onto the deck and the sea camera takes over.
func board() -> void:
	if mode != Mode.ISLAND or ship == null or ship.is_sailing():
		return
	ship.start_sailing()
	if not ship.is_sailing():
		return
	mode = Mode.SEA
	voyages += 1
	baker.control_enabled = false
	baker.visible = false
	baker.process_mode = Node.PROCESS_MODE_DISABLED
	sea_camera.snap()
	sea_camera.live = true
	island_camera.following = false
	_blend_to(sea_camera.camera)
	if hud != null:
		hud.show_sea(true)
	if arrow != null:
		arrow.player = ship
	Audio.play_music(&"sea")
	Audio.play(&"board")
	_set_sea_fog(true)
	sea_changed.emit(true)


## The ship is back at the dock: unload the hold and return to the island.
func _on_docked(loot: int) -> void:
	_leave_ship()
	if loot > 0:
		_unload(loot)
	set_flag(&"first_voyage")
	if loot >= kraken_loot and not kraken_done:
		kraken_ready = true
	if not kraken_done and sea_life != null and sea_life.kraken_active:
		sea_life.clear_all()
		_grade_storm(false)


func _leave_ship() -> void:
	mode = Mode.ISLAND
	baker.process_mode = Node.PROCESS_MODE_INHERIT
	baker.visible = true
	baker.teleport(dock_point.global_position if dock_point != null else baker.global_position, -PI * 0.5)
	baker.control_enabled = true
	sea_camera.live = false
	island_camera.following = true
	_blend_to(island_camera.camera)
	if hud != null:
		hud.show_sea(false)
	if arrow != null:
		arrow.player = baker
	Audio.play_music(&"island")
	_set_sea_fog(false)
	sea_changed.emit(false)


## Coins fly from the ship along the dock to the HUD counter.
func _unload(loot: int) -> void:
	var bursts: int = clampi(ceili(float(loot) / 40.0), 1, 10)
	var share: int = floori(float(loot) / float(bursts))
	var from: Vector3 = ship.global_position + Vector3.UP * 2.0
	var to: Vector3 = baker.global_position + Vector3.UP * 1.5
	for i in bursts:
		var amount: int = share + (loot - share * bursts if i == bursts - 1 else 0)
		var at: Vector3 = from.lerp(to, float(i) / float(maxi(bursts - 1, 1)))
		get_tree().create_timer(0.12 * float(i)).timeout.connect(func() -> void:
			Hud.collect_coins(self, at, amount)
			Fx.burst(Fx.COIN_BURST, self, at, 0.7)
		)
	Fx.pop_number(self, to + Vector3.UP, "+%d" % loot, Fx.GOLD, 1.5)


## The hull reached zero: a cartoon fade, and the ship is back at the dock.
func _on_wrecked() -> void:
	Audio.play(&"limp_home")
	if hud != null:
		await hud.fade(1.0, 0.4)
	ship.moor_now()
	if hud != null:
		hud.fade(0.0, 0.5)


func _start_kraken() -> void:
	sea_life.start_kraken()
	if not sea_life.kraken_active:
		return
	_grade_storm(true)
	Audio.play_music(&"kraken", 0.5)
	Audio.play(&"kraken_roar")
	get_tree().call_group(&"game_camera", &"add_trauma", 0.6)


func _on_kraken_defeated(at: Vector3) -> void:
	kraken_done = true
	kraken_ready = false
	_grade_storm(false)
	Audio.play(&"fanfare")
	Audio.play_music(&"sea")
	Fx.burst(Fx.CONFETTI, self, at + Vector3.UP * 2.0, 2.0)
	Fx.burst(Fx.SPLASH, self, at, 3.0)
	if golden_chest_scene != null:
		var chest: FloatingLoot = golden_chest_scene.instantiate() as FloatingLoot
		chest.value = kraken_reward
		add_child(chest)
		chest.global_position = at
	_slow_motion(0.5, 0.4)
	set_flag(&"kraken_won")


func _slow_motion(scale_to: float, seconds: float) -> void:
	Engine.time_scale = scale_to
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


## The stormy teal grade of the Kraken fight, and back.
func _grade_storm(on: bool) -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env: Environment = world_environment.environment
	if _grade != null and _grade.is_valid():
		_grade.kill()
	_grade = create_tween().set_parallel(true)
	_grade.tween_property(env, "adjustment_brightness", _brightness_rest * (0.72 if on else 1.0), 0.8)
	_grade.tween_property(env, "adjustment_saturation", _saturation_rest * (0.75 if on else 1.0), 0.8)
	if sun != null:
		_grade.tween_property(sun, "light_energy", _sun_rest * (0.5 if on else 1.0), 0.8)
		_grade.tween_property(sun, "light_color", Color(0.6, 0.95, 0.9) if on else Color(1.0, 0.957, 0.878), 0.8)


func _set_sea_fog(on: bool) -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env: Environment = world_environment.environment
	env.fog_enabled = on
	if on:
		env.fog_light_color = Color(0.62, 0.86, 0.95)
		env.fog_density = 0.0014
		env.fog_sky_affect = 0.0


## One tween of position, rotation and FOV from the current camera to `to`.
func _blend_to(to: Camera3D, time: float = 0.45) -> void:
	var from: Camera3D = get_viewport().get_camera_3d()
	if blend_camera == null or from == null or to == null or from == to:
		if to != null:
			to.current = true
		return
	if _blend != null and _blend.is_valid():
		_blend.kill()
	var start: Transform3D = from.global_transform
	var start_fov: float = from.fov
	blend_camera.global_transform = start
	blend_camera.fov = start_fov
	blend_camera.current = true
	_blend = create_tween()
	_blend.tween_method(func(t: float) -> void:
		blend_camera.global_transform = start.interpolate_with(to.global_transform, t)
		blend_camera.fov = lerpf(start_fov, to.fov, t)
	, 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blend.tween_callback(func() -> void: to.current = true)


# ------------------------------------------------------------------ pads

func _gate_open(candidate: UnlockPad) -> bool:
	match candidate.pad_id:
		&"double_cannons":
			return flags.has(&"first_voyage")
		&"house":
			return flags.has(&"kraken_won")
	return true


func _offer_pads() -> void:
	var offered: int = 0
	for candidate: UnlockPad in _pads:
		if candidate.done or not _gate_open(candidate):
			continue
		candidate.offer()
		offered += 1
		if offered >= pads_offered:
			break


func _on_pad_unlocked(bought: UnlockPad) -> void:
	purchase_log.append("%s at %.1f s" % [bought.pad_id, session_time])
	print("PURCHASE %s %.1f" % [bought.pad_id, session_time])
	if baker != null:
		baker.cheer()
	_apply(bought.pad_id)
	pad_bought.emit(bought.pad_id)
	_offer_pads()


## What a pad changes besides revealing its targets.
func _apply(pad_id: StringName) -> void:
	var queue: CustomerQueue = counter.queue if counter != null else null
	match pad_id:
		&"oven2":
			if queue != null:
				queue.add_kind(&"chocolate")
		&"oven3":
			if queue != null:
				queue.add_kind(&"honey")
		&"display_case":
			if queue != null:
				queue.open_slots = 6
				queue.spawn_interval = 1.8
		&"backpack":
			_set_capacity(1, 10)
		&"backpack2":
			_set_capacity(2, 16)
		&"statue":
			if queue != null:
				queue.pay_multiplier = 1.2
				queue.rare_enabled = true
		&"oven_speed":
			for node: Node in get_tree().get_nodes_in_group(&"ovens"):
				(node as Oven).speed_multiplier = 1.4
				Fx.burst(Fx.DUST_RING, self, (node as Node3D).global_position + Vector3.UP)
		&"double_cannons":
			if ship != null:
				ship.set_double_cannons(true)
		&"house":
			_finale()


func _set_capacity(level: int, value: int) -> void:
	if baker == null:
		return
	baker.upgrade_backpack(level, value)
	Fx.pop_number(self, baker.global_position + Vector3.UP * 2.6, "MAX %d" % value, Fx.WHITE, 1.2)


## The Captain's Donut House: a long camera beat, cheers, then the end card.
func _finale() -> void:
	ended = true
	var at: Vector3 = house.global_position if house != null else baker.global_position
	if island_camera != null:
		island_camera.focus_beat(at, 0.8, 3.2, 1.0)
	Audio.play(&"fanfare")
	for node: Node in get_tree().get_nodes_in_group(&"customers"):
		if node.has_method(&"cheer"):
			node.call(&"cheer")
	for i in 6:
		get_tree().create_timer(0.35 * float(i)).timeout.connect(func() -> void:
			Fx.burst(Fx.CONFETTI, self, at + Vector3(randf_range(-4.0, 4.0), randf_range(3.0, 6.0), randf_range(-2.0, 2.0)), 1.6)
			Audio.play_varied(&"firework", 0.2, -4.0)
		)
	await get_tree().create_timer(4.6).timeout
	if end_card != null and end_card.has_method(&"open"):
		end_card.call(&"open", self)
	finale_done.emit()


func _update_arrow() -> void:
	if arrow == null or baker == null:
		return
	var goal: Node3D = null
	if mode == Mode.TITLE:
		goal = null
	elif mode == Mode.SEA:
		if kraken_done or ship.hold >= kraken_loot:
			goal = boarding_pad
	else:
		var upcoming: UnlockPad = next_pad()
		if purchase_log.is_empty() and not _first_sale_done:
			if baker.carry_stack.count() == 0 and first_oven != null:
				goal = first_oven.pickup_zone
			elif counter != null:
				goal = counter.serve_zone
		elif counter != null and counter.cash_waiting() > 0 and (upcoming == null or Wallet.cash < upcoming.remaining()):
			goal = counter.cash_zone
		elif upcoming != null and upcoming.available:
			goal = upcoming
		elif boarding_pad != null and is_bought(&"ship"):
			goal = boarding_pad
	if goal != arrow.target:
		arrow.point_at(goal)


func _enter_title() -> void:
	mode = Mode.TITLE
	if baker != null:
		baker.control_enabled = false
	if hud != null:
		hud.show_hud(false)
	if title != null and title.has_method(&"open"):
		title.call(&"open", self)


# ------------------------------------------------------------------ presenter and tests

## Buys the next pad at once with its normal reveal (presenter panel).
func debug_unlock_next() -> void:
	var upcoming: UnlockPad = next_pad()
	if upcoming != null:
		upcoming.offer()
		upcoming.unlock_now()


func debug_fill_racks() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"ovens"):
		(node as Oven).fill_rack()


func debug_start_kraken() -> void:
	kraken_ready = true
	if mode == Mode.SEA:
		_start_kraken()


## The performance route asks for the busiest state: everything bought,
## racks full, the helper working, the ship at sea with enemies around it.
func perf_prepare() -> void:
	start_game(true)
	flags[&"first_voyage"] = true
	flags[&"kraken_won"] = true
	kraken_done = true
	ended = true
	for i in _pads.size():
		var upcoming: UnlockPad = next_pad()
		if upcoming == null:
			break
		upcoming.offer()
		upcoming.unlock_now()
	debug_fill_racks()
	Wallet.add(5000)
	end_card = null
	if ship != null:
		ship.snap_to_mooring()
		ship.autopilot = true
		ship.god_mode = true
		board()
