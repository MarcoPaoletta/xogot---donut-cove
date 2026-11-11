class_name SeaLife
extends Node3D
## Keeps the sea alive: about three sharks and two tentacles around the island
## at any moment, respawning out of view, and the Kraken fight.
##
## Sharks and tentacles are instances of their saved scenes. Without a sailing
## ship the sharks circle their home points off the island (the fins the
## island view shows); with one they hunt it.

signal kraken_started
signal kraken_defeated(at: Vector3)

@export var shark_scene: PackedScene
@export var tentacle_scene: PackedScene
@export var kraken_tentacle_scene: PackedScene
@export var shark_count: int = 3
@export var tentacle_count: int = 2
## Distance from the island centre where idle sharks circle.
@export var home_ring: Vector2 = Vector2(34.0, 52.0)
@export var island_keepout: float = 24.0
@export var active: bool = true

var kraken_active: bool = false

var _sharks: Array[Shark] = []
var _tentacles: Array[Tentacle] = []
var _kraken: Array[Tentacle] = []
var _shark_timer: float = 0.5
var _tentacle_timer: float = 2.0
var _turn: int = 0
var _turn_timer: float = 0.0


func _process(delta: float) -> void:
	if not active:
		return
	_prune()
	if kraken_active:
		_run_kraken(delta)
		return
	_shark_timer -= delta
	if _sharks.size() < shark_count and _shark_timer <= 0.0:
		_shark_timer = 2.5
		_spawn_shark()
	_tentacle_timer -= delta
	if _tentacles.size() < tentacle_count and _tentacle_timer <= 0.0:
		_tentacle_timer = 5.0
		_spawn_tentacle()


## Three giant tentacles rise in a ring around the ship.
func start_kraken() -> void:
	var ship: Ship = _ship()
	if kraken_active or ship == null or kraken_tentacle_scene == null:
		return
	kraken_active = true
	for tentacle: Tentacle in _tentacles:
		if is_instance_valid(tentacle):
			tentacle.leave()
	_tentacles.clear()
	var centre: Vector3 = ship.global_position + ship.forward() * 6.0
	for i in 3:
		var angle: float = TAU * float(i) / 3.0 + 0.5
		var tentacle: Tentacle = kraken_tentacle_scene.instantiate() as Tentacle
		tentacle.attack_enabled = false
		add_child(tentacle)
		tentacle.global_position = _off_island(Vector3(centre.x + cos(angle) * 12.0, 0.0, centre.z + sin(angle) * 12.0))
		_kraken.append(tentacle)
	_turn = 0
	_turn_timer = 2.0
	kraken_started.emit()


## Removes every enemy and loot item (restart).
func clear_all() -> void:
	for group: Array in [_sharks, _tentacles, _kraken]:
		for enemy: Node in group:
			if is_instance_valid(enemy):
				enemy.queue_free()
		group.clear()
	for loot: Node in get_tree().get_nodes_in_group(&"loot"):
		loot.queue_free()
	kraken_active = false


func enemy_count() -> int:
	return _sharks.size() + _tentacles.size() + _kraken.size()


func _run_kraken(delta: float) -> void:
	if _kraken.is_empty():
		kraken_active = false
		var ship: Ship = _ship()
		var at: Vector3 = ship.global_position + ship.forward() * 9.0 if ship != null else global_position
		kraken_defeated.emit(Vector3(at.x, Sea.level, at.z))
		return
	_turn_timer -= delta
	if _turn_timer <= 0.0:
		_turn_timer = 4.5
		_turn = (_turn + 1) % _kraken.size()
	for i in _kraken.size():
		_kraken[i].attack_enabled = i == _turn


func _spawn_shark() -> void:
	if shark_scene == null:
		return
	var shark: Shark = shark_scene.instantiate() as Shark
	var angle: float = randf() * TAU
	var radius: float = randf_range(home_ring.x, home_ring.y)
	shark.home = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	add_child(shark)
	var ship: Ship = _ship()
	var at: Vector3 = shark.home
	if ship != null:
		at = _behind_view(ship.global_position, 30.0)
	shark.global_position = Vector3(at.x, Sea.level - 1.0, at.z)
	_sharks.append(shark)


func _spawn_tentacle() -> void:
	if tentacle_scene == null:
		return
	var ship: Ship = _ship()
	var at: Vector3 = Vector3.ZERO
	if ship != null:
		var side: float = 6.0 if randf() < 0.5 else -6.0
		var right: Vector3 = ship.forward().cross(Vector3.UP)
		at = ship.global_position + ship.forward() * randf_range(15.0, 21.0) + right * side
	else:
		var angle: float = randf() * TAU
		var radius: float = randf_range(home_ring.x, home_ring.y)
		at = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	var tentacle: Tentacle = tentacle_scene.instantiate() as Tentacle
	add_child(tentacle)
	tentacle.global_position = _off_island(Vector3(at.x, 0.0, at.z))
	_tentacles.append(tentacle)


## A point out of the camera's view, `distance` away from `centre`.
func _behind_view(centre: Vector3, distance: float) -> Vector3:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var back: Vector3 = Vector3(0.0, 0.0, 1.0)
	if camera != null:
		back = camera.global_basis.z
		back.y = 0.0
		back = back.normalized() if back.length() > 0.01 else Vector3(0.0, 0.0, 1.0)
	var side: Vector3 = back.cross(Vector3.UP) * randf_range(-14.0, 14.0)
	return _off_island(centre + back * distance + side)


func _off_island(at: Vector3) -> Vector3:
	var flat: Vector2 = Vector2(at.x, at.z)
	if flat.length() < island_keepout:
		flat = flat.normalized() * island_keepout if flat.length() > 0.01 else Vector2(island_keepout, 0.0)
	return Vector3(flat.x, at.y, flat.y)


func _ship() -> Ship:
	var ship: Ship = get_tree().get_first_node_in_group(&"ship") as Ship
	return ship if ship != null and ship.is_sailing() else null


func _prune() -> void:
	for i in range(_sharks.size() - 1, -1, -1):
		if not is_instance_valid(_sharks[i]) or not _sharks[i].can_be_hit():
			_sharks.remove_at(i)
	for group: Array in [_tentacles, _kraken]:
		for i in range(group.size() - 1, -1, -1):
			var tentacle: Tentacle = group[i] as Tentacle
			if not is_instance_valid(tentacle) or not tentacle.is_in_group(&"sea_enemies"):
				group.remove_at(i)
