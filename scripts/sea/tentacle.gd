class_name Tentacle
extends Node3D
## A kraken tentacle. It rises from a bubbling patch, sways, and slams across
## the deck after a shadow and a rumble warn for 1.2 s. Three hits (six for the
## Kraken's) send it back under and a treasure chest floats up.
##
## The model, its AnimationPlayer and the shadow disc are authored in the
## tentacle scenes. The model curls toward its local +X.

signal died(tentacle: Tentacle)

enum State { RISING, IDLE, TELEGRAPH, SLAM, SINKING, DEAD }

@export var health: int = 3
@export var hit_radius: float = 1.8
@export var slam_reach: float = 7.0
@export var slam_damage: float = 15.0
@export var telegraph_time: float = 1.2
@export var idle_gap: Vector2 = Vector2(3.0, 5.5)
## Seconds before it sinks on its own. Zero keeps it up (the Kraken).
@export var lifetime: float = 24.0
## False while another Kraken tentacle has the turn.
@export var attack_enabled: bool = true
@export var loot_scene: PackedScene
@export var loot_value: Vector2i = Vector2i(60, 100)
@export var visual: Node3D
@export var animation_player: AnimationPlayer
@export var shadow: Node3D
@export var bubbles: GPUParticles3D
## How far under the water the root starts and ends.
@export var depth: float = 7.0

var _state: State = State.RISING
var _state_time: float = 0.0
var _age: float = 0.0
var _idle_for: float = 3.0
var _yaw: float = 0.0
var _hit_done: bool = false
var _rest_y: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group(&"sea_enemies")
	if animation_player != null and animation_player.has_animation(&"Tentacle_Idle"):
		animation_player.get_animation(&"Tentacle_Idle").loop_mode = Animation.LOOP_LINEAR
		animation_player.play(&"Tentacle_Idle")
	if shadow != null:
		shadow.visible = false
	_idle_for = randf_range(idle_gap.x, idle_gap.y)
	_yaw = randf() * TAU
	_rest_y = Sea.level - 0.4
	global_position.y = _rest_y - depth
	if bubbles != null:
		bubbles.emitting = true
	Audio.play_varied(&"tentacle_rise", 0.1, -4.0)


func can_be_hit() -> bool:
	return _state != State.DEAD and _state != State.SINKING and _state != State.RISING


func is_up() -> bool:
	return _state == State.IDLE or _state == State.TELEGRAPH or _state == State.SLAM


func take_hit(amount: int, at: Vector3) -> void:
	if not can_be_hit():
		return
	health -= amount
	Fx.pop_number(self, at + Vector3.UP * 2.0, "-%d" % amount, Fx.WHITE, 1.2)
	if visual != null:
		ItemFlight.squash(visual, 0.2, 0.3)
	if health <= 0:
		_die()


## Sinks without loot (the ship left, or the Kraken fight ended).
func leave() -> void:
	if _state == State.DEAD or _state == State.SINKING:
		return
	_state = State.SINKING
	_state_time = 0.0
	remove_from_group(&"sea_enemies")
	if shadow != null:
		shadow.visible = false


func _process(delta: float) -> void:
	_state_time += delta
	_age += delta
	var ship: Ship = _ship()
	match _state:
		State.RISING:
			global_position.y = lerpf(_rest_y - depth, _rest_y, ease(clampf(_state_time / 0.9, 0.0, 1.0), 0.4))
			if _state_time >= 0.9:
				_state = State.IDLE
				_state_time = 0.0
				if bubbles != null:
					bubbles.emitting = false
		State.IDLE:
			if ship != null:
				_face(ship.global_position - global_position, delta, 2.5)
			var near: bool = ship != null and _flat(ship.global_position - global_position).length() < slam_reach * 1.5
			if attack_enabled and near and _state_time >= _idle_for:
				_state = State.TELEGRAPH
				_state_time = 0.0
				Audio.play(&"tentacle_rumble")
			elif lifetime > 0.0 and _age > lifetime and not near:
				leave()
		State.TELEGRAPH:
			if ship != null:
				_face(ship.global_position - global_position, delta, 5.0)
			if shadow != null:
				shadow.visible = true
				var reach: Vector3 = Vector3(cos(_yaw), 0.0, -sin(_yaw)) * slam_reach * 0.5
				shadow.global_position = Vector3(global_position.x + reach.x, Sea.level + 0.14, global_position.z + reach.z)
				shadow.global_rotation = Vector3(0.0, _yaw, 0.0)
				var grow: float = clampf(_state_time / telegraph_time, 0.0, 1.0)
				shadow.scale = Vector3(lerpf(0.4, 1.0, grow), 1.0, lerpf(0.6, 1.0, grow))
			if _state_time >= telegraph_time:
				_state = State.SLAM
				_state_time = 0.0
				_hit_done = false
				if animation_player != null:
					animation_player.play(&"Tentacle_Attack", 0.15)
		State.SLAM:
			if not _hit_done and _state_time >= 0.42:
				_hit_done = true
				_slam(ship)
			if _state_time >= 0.95:
				_state = State.IDLE
				_state_time = 0.0
				_idle_for = randf_range(idle_gap.x, idle_gap.y)
				if shadow != null:
					shadow.visible = false
				if animation_player != null:
					animation_player.play(&"Tentacle_Idle", 0.4)
		State.SINKING, State.DEAD:
			global_position.y -= depth * delta / 0.9
			if _state_time >= 0.9:
				queue_free()
	if visual != null:
		visual.rotation.y = _yaw


func _slam(ship: Ship) -> void:
	var tip: Vector3 = global_position + Vector3(cos(_yaw), 0.0, -sin(_yaw)) * slam_reach * 0.6
	Fx.burst(Fx.SPLASH, self, Vector3(tip.x, Sea.level, tip.z), 2.2)
	Audio.play_varied(&"tentacle_slam", 0.06)
	get_tree().call_group(&"game_camera", &"add_trauma", 0.35)
	if ship == null:
		return
	var gap: Vector3 = _flat(ship.global_position - global_position)
	var along: float = gap.dot(Vector3(cos(_yaw), 0.0, -sin(_yaw)))
	var side: float = absf(gap.dot(Vector3(sin(_yaw), 0.0, cos(_yaw))))
	if along > -1.0 and along < slam_reach and side < 3.2:
		ship.damage(slam_damage)


func _die() -> void:
	_state = State.DEAD
	_state_time = 0.0
	remove_from_group(&"sea_enemies")
	if shadow != null:
		shadow.visible = false
	Wallet.bump(&"tentacles")
	Fx.burst(Fx.SPLASH, self, Vector3(global_position.x, Sea.level, global_position.z), 2.4)
	Fx.burst(Fx.BUBBLES, self, Vector3(global_position.x, Sea.level, global_position.z))
	Fx.burst(Fx.COIN_BURST, self, Vector3(global_position.x, Sea.level + 0.8, global_position.z))
	Audio.play_varied(&"enemy_down", 0.08, 2.0)
	get_tree().call_group(&"game_camera", &"add_trauma", 0.3)
	if loot_scene != null:
		var loot: FloatingLoot = loot_scene.instantiate() as FloatingLoot
		loot.value = randi_range(loot_value.x, loot_value.y)
		get_tree().current_scene.add_child(loot)
		loot.global_position = Vector3(global_position.x, Sea.level + 0.2, global_position.z)
	died.emit(self)


func _ship() -> Ship:
	var ship: Ship = get_tree().get_first_node_in_group(&"ship") as Ship
	return ship if ship != null and ship.is_sailing() else null


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## The model curls toward +X, so the yaw that points +X along `direction`.
func _face(direction: Vector3, delta: float, k: float) -> void:
	var flat: Vector3 = _flat(direction)
	if flat.length() > 0.01:
		_yaw = lerp_angle(_yaw, atan2(-flat.z, flat.x), 1.0 - exp(-k * delta))
