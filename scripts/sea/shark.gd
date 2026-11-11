class_name Shark
extends Node3D
## A shark. It circles with its fin showing (around the ship when one is
## sailing, around its home point otherwise), then charges and leaps at the
## hull after a red ring warns for a second. Two hits send it under in a
## splash with floating coins.
##
## The model, its AnimationPlayer and the warning ring are authored in
## `shark.tscn`. The shark moves in `_process` on the water.

signal died(shark: Shark)

enum State { CIRCLE, TELEGRAPH, CHARGE, RECOVER, DEAD }

@export var health: int = 2
@export var hit_radius: float = 1.7
@export var circle_radius: float = 15.0
@export var swim_speed: float = 6.5
@export var charge_speed: float = 13.0
@export var bite_damage: float = 10.0
@export var telegraph_time: float = 1.0
@export var attack_gap: Vector2 = Vector2(6.0, 11.0)
@export var loot_scene: PackedScene
@export var loot_value: Vector2i = Vector2i(15, 25)
@export var visual: Node3D
@export var animation_player: AnimationPlayer
@export var warning_ring: Node3D
## How deep the body swims, so only the fin shows.
@export var swim_depth: float = 0.75

var home: Vector3 = Vector3.ZERO

var _state: State = State.CIRCLE
var _angle: float = 0.0
var _direction: float = 1.0
var _yaw: float = 0.0
var _attack_timer: float = 8.0
var _state_time: float = 0.0
var _charge_from: Vector3 = Vector3.ZERO
var _clip: StringName = &""


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group(&"sea_enemies")
	_angle = randf() * TAU
	_direction = 1.0 if randf() < 0.5 else -1.0
	_attack_timer = randf_range(attack_gap.x, attack_gap.y)
	if animation_player != null:
		for clip: String in ["Swim", "Swim_Fast"]:
			if animation_player.has_animation(clip):
				animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	if warning_ring != null:
		warning_ring.visible = false
	_play(&"Swim")


func can_be_hit() -> bool:
	return _state != State.DEAD


func take_hit(amount: int, at: Vector3) -> void:
	if _state == State.DEAD:
		return
	health -= amount
	Fx.pop_number(self, at + Vector3.UP * 1.2, "-%d" % amount, Fx.WHITE, 1.1)
	if visual != null:
		ItemFlight.squash(visual, 0.35, 0.25)
	if health <= 0:
		_die()
	else:
		_state = State.RECOVER
		_state_time = 0.0
		_hide_warning()


func _process(delta: float) -> void:
	_state_time += delta
	var ship: Ship = _ship()
	var water: float = Sea.height_at(global_position.x, global_position.z)
	match _state:
		State.CIRCLE:
			_circle(delta, ship.global_position if ship != null else home)
			global_position.y = water - swim_depth
			if ship != null:
				_attack_timer -= delta
				var gap: float = _flat(ship.global_position - global_position).length()
				if _attack_timer <= 0.0 and gap < circle_radius * 1.6:
					_state = State.TELEGRAPH
					_state_time = 0.0
					Audio.play_varied(&"shark_warn", 0.08, -4.0)
		State.TELEGRAPH:
			global_position.y = water - swim_depth * 0.6
			if ship == null:
				_state = State.CIRCLE
				_hide_warning()
			else:
				_face(_flat(ship.global_position - global_position), delta, 8.0)
				if warning_ring != null:
					warning_ring.visible = true
					warning_ring.global_position = Vector3(ship.global_position.x, Sea.level + 0.15, ship.global_position.z)
					warning_ring.global_rotation = Vector3.ZERO
					var pulse: float = 1.0 + 0.25 * sin(_state_time * 18.0)
					warning_ring.scale = Vector3(pulse, 1.0, pulse)
				if _state_time >= telegraph_time:
					_state = State.CHARGE
					_state_time = 0.0
					_charge_from = global_position
					_play(&"Swim_Fast")
		State.CHARGE:
			if ship == null:
				_state = State.RECOVER
				_state_time = 0.0
				_hide_warning()
			else:
				var to: Vector3 = _flat(ship.global_position - global_position)
				_face(to, delta, 10.0)
				global_position += to.normalized() * charge_speed * delta
				var total: float = maxf(_flat(ship.global_position - _charge_from).length(), 0.1)
				var done: float = clampf(1.0 - to.length() / total, 0.0, 1.0)
				global_position.y = water - swim_depth + sin(done * PI) * 2.2 + done * 1.2
				if to.length() < 2.4:
					_bite(ship)
				elif _state_time > 3.0:
					_state = State.RECOVER
					_state_time = 0.0
					_hide_warning()
		State.RECOVER:
			_hide_warning()
			global_position += Vector3(sin(_yaw), 0.0, cos(_yaw)) * swim_speed * delta
			global_position.y = lerpf(global_position.y, water - swim_depth, 1.0 - exp(-5.0 * delta))
			if _state_time > 1.6:
				_state = State.CIRCLE
				_attack_timer = randf_range(attack_gap.x, attack_gap.y)
				_play(&"Swim")
		State.DEAD:
			pass
	if visual != null:
		visual.rotation.y = _yaw


func _circle(delta: float, center: Vector3) -> void:
	_angle += _direction * (swim_speed / circle_radius) * delta
	var goal: Vector3 = Vector3(center.x + cos(_angle) * circle_radius, 0.0, center.z + sin(_angle) * circle_radius)
	var to: Vector3 = _flat(goal - global_position)
	var step: float = minf(swim_speed * 1.5 * delta, to.length())
	if to.length() > 0.01:
		global_position += to.normalized() * step
		_face(to, delta, 5.0)


func _bite(ship: Ship) -> void:
	_play(&"Swim_Bite")
	ship.damage(bite_damage)
	Audio.play_varied(&"shark_bite", 0.08)
	_state = State.RECOVER
	_state_time = 0.0
	_yaw += PI * 0.75
	_hide_warning()


func _die() -> void:
	_state = State.DEAD
	_hide_warning()
	remove_from_group(&"sea_enemies")
	Wallet.bump(&"sharks")
	Fx.burst(Fx.SPLASH, self, global_position + Vector3.UP * 0.4, 1.6)
	Fx.burst(Fx.BUBBLES, self, global_position)
	Fx.burst(Fx.COIN_BURST, self, global_position + Vector3.UP * 0.6)
	Audio.play_varied(&"enemy_down", 0.08)
	if loot_scene != null:
		var loot: FloatingLoot = loot_scene.instantiate() as FloatingLoot
		loot.value = randi_range(loot_value.x, loot_value.y)
		get_tree().current_scene.add_child(loot)
		loot.global_position = Vector3(global_position.x, Sea.level + 0.2, global_position.z)
	died.emit(self)
	var sink: Tween = create_tween().set_parallel(true)
	sink.tween_property(self, "global_position:y", global_position.y - 3.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(self, "scale", scale * 0.6, 0.7)
	sink.chain().tween_callback(queue_free)


func _ship() -> Ship:
	var ship: Ship = get_tree().get_first_node_in_group(&"ship") as Ship
	return ship if ship != null and ship.is_sailing() else null


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _face(direction: Vector3, delta: float, k: float) -> void:
	if direction.length() > 0.01:
		_yaw = lerp_angle(_yaw, atan2(direction.x, direction.z), 1.0 - exp(-k * delta))


func _hide_warning() -> void:
	if warning_ring != null:
		warning_ring.visible = false


func _play(clip: StringName) -> void:
	if animation_player == null or clip == _clip or not animation_player.has_animation(clip):
		return
	_clip = clip
	animation_player.play(clip, 0.3)
