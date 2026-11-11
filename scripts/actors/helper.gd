class_name Helper
extends CharacterBody3D
## The helper bunny. She owns a `CarryStack` and uses the same oven racks and
## the same counter zones as the baker, so her automation shows exactly the
## feedback the player's own work shows.
##
## Loop: walk to an oven that has donuts (the flavor the front customer wants
## when there is one), scoop a load, walk to the counter, feed, repeat.

enum State { IDLE, TO_OVEN, SCOOPING, TO_COUNTER, SERVING }

@export var run_speed: float = 4.6
@export var turn_k: float = 12.0
@export var gravity: float = 24.0
## Donuts she carries per trip.
@export var load_size: int = 4
@export var carry_stack: CarryStack
@export var visual: Node3D
@export var anim: CharacterAnim
@export var counter: ShopCounter
## Seconds she waits at a station with nothing happening before she moves on.
@export var patience: float = 4.0

var _state: State = State.IDLE
var _oven: Oven = null
var _goal: Vector3 = Vector3.ZERO
var _model_yaw: float = 0.0
var _idle: float = 0.0
var _last_count: int = 0
var _stuck: float = 0.0
var _last_position: Vector3 = Vector3.ZERO


func get_carry_stack() -> CarryStack:
	return carry_stack


func on_unlocked() -> void:
	_state = State.IDLE
	_idle = 0.3
	if anim != null:
		anim.fire(&"Yes")


func _physics_process(delta: float) -> void:
	var wish: Vector3 = Vector3.ZERO
	match _state:
		State.IDLE:
			_idle -= delta
			if _idle <= 0.0:
				_plan()
		State.TO_OVEN, State.TO_COUNTER:
			var to: Vector3 = _goal - global_position
			to.y = 0.0
			if to.length() < 0.35:
				_arrive()
			else:
				wish = to.normalized()
		State.SCOOPING:
			_wait_for_change(delta)
			if carry_stack.count() >= load_size or carry_stack.is_full() or _idle <= 0.0:
				_go_counter()
		State.SERVING:
			_wait_for_change(delta)
			if carry_stack.is_empty() or _idle <= 0.0:
				_state = State.IDLE
				_idle = 0.2
	velocity.x = move_toward(velocity.x, wish.x * run_speed, run_speed * 12.0 * delta)
	velocity.z = move_toward(velocity.z, wish.z * run_speed, run_speed * 12.0 * delta)
	velocity.y = -1.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	_unstick(delta, wish)
	var speed01: float = Vector2(velocity.x, velocity.z).length() / 6.0
	if wish.length() > 0.05:
		_model_yaw = lerp_angle(_model_yaw, atan2(wish.x, wish.z), 1.0 - exp(-turn_k * delta))
	if visual != null:
		visual.rotation = Vector3(0.0, _model_yaw, 0.0)
	if anim != null:
		anim.set_speed01(speed01)
		anim.set_holding(carry_stack.count() > 0)


## Chooses the next trip.
func _plan() -> void:
	if counter == null:
		return
	if not carry_stack.is_empty():
		var wanted: StringName = counter.wanted_kind()
		if wanted == &"" or carry_stack.has_kind(wanted):
			_go_counter()
			return
	_oven = _pick_oven()
	if _oven == null:
		if not carry_stack.is_empty():
			_go_counter()
		else:
			_idle = 0.6
		return
	_goal = _oven.pickup_zone.global_position
	_goal.y = global_position.y
	_state = State.TO_OVEN


func _pick_oven() -> Oven:
	var wanted: StringName = counter.wanted_kind()
	var best: Oven = null
	var best_count: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"ovens"):
		var oven: Oven = node as Oven
		if oven == null or not oven.active or oven.rack_count() <= 0:
			continue
		if oven.kind == wanted and not carry_stack.has_kind(wanted):
			return oven
		if oven.rack_count() > best_count:
			best_count = oven.rack_count()
			best = oven
	return best


func _go_counter() -> void:
	_goal = counter.serve_zone.global_position
	_goal.y = global_position.y
	_state = State.TO_COUNTER


func _arrive() -> void:
	_idle = patience
	_last_count = carry_stack.count()
	_state = State.SCOOPING if _state == State.TO_OVEN else State.SERVING


func _wait_for_change(delta: float) -> void:
	if carry_stack.count() != _last_count:
		_last_count = carry_stack.count()
		_idle = patience
	else:
		_idle -= delta


## If something blocks the straight line for a while, step sideways.
func _unstick(delta: float, wish: Vector3) -> void:
	if wish == Vector3.ZERO:
		_stuck = 0.0
		_last_position = global_position
		return
	if global_position.distance_to(_last_position) < run_speed * delta * 0.3:
		_stuck += delta
	else:
		_stuck = maxf(_stuck - delta, 0.0)
	_last_position = global_position
	if _stuck > 0.5:
		var side: Vector3 = wish.cross(Vector3.UP).normalized()
		global_position += side * 0.6
		_stuck = 0.0
