class_name Customer
extends Node3D
## A pirate customer: walks to a queue slot, shows an order bubble, takes the
## donuts that fly to it, pays and leaves happy, or leaves grumpy when its
## patience runs out.
##
## The model, the `CharacterAnim` tree, the bubble and the receive point are
## authored in each customer scene. This script moves and reacts.

signal served(customer: Customer, amount: int)
signal departed(customer: Customer)

enum State { WALKING_IN, WAITING, LEAVING }

@export var walk_speed: float = 2.6
## Seconds a customer waits at its slot before leaving grumpy.
@export var patience: float = 50.0
## Seconds a seated customer eats before it leaves.
@export var eat_time: float = 5.0
## How far the model sinks when it sits on a chair (the pack has no sitting clip for pirates).
@export var seat_drop: float = 0.22
@export var turn_k: float = 10.0
@export var anim: CharacterAnim
@export var bubble: OrderBubble
@export var visual: Node3D
@export var receive_point: Marker3D

## Kind to count still wanted.
var order: Dictionary = {}
var is_rare: bool = false

var _pending: Dictionary = {}
var _amount: int = 0
var _state: State = State.WALKING_IN
var _target: Vector3 = Vector3.ZERO
var _exit: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _face_yaw: float = 0.0
var _has_face: bool = false
var _wait: float = 0.0
var _seated: bool = false
var _seat_height: float = 0.0


## `new_order` maps a flavor to a count. The payment is fixed here so tips and
## the rare multiplier are part of the order, not of the moment of sale.
func setup(new_order: Dictionary, multiplier: float, rare: bool, exit_point: Vector3) -> void:
	order = new_order.duplicate()
	_pending = new_order.duplicate()
	is_rare = rare
	_exit = exit_point
	var total: float = 0.0
	for kind: StringName in order.keys():
		total += float(Flavors.price(kind)) * float(order[kind])
	_amount = maxi(roundi(total * multiplier * (3.0 if rare else 1.0)), 1)
	_wait = patience
	_refresh_bubble(false)


## Walks to `point`. `face_yaw` is where it looks once it stands there.
func go_to(point: Vector3, face_yaw: float = 0.0, use_face: bool = false) -> void:
	_target = point
	_face_yaw = face_yaw
	_has_face = use_face


## The size of the order bubble (see `OrderBubble.set_size`).
func bubble_size(factor: float) -> void:
	if bubble != null:
		bubble.set_size(factor)


## Puts the customer on a spot at once (the queue that is already there at boot).
func place_at(point: Vector3, face_yaw: float) -> void:
	global_position = point
	_target = point
	_yaw = face_yaw
	_face_yaw = face_yaw
	_has_face = true
	_state = State.WAITING
	if visual != null:
		visual.global_rotation = Vector3(0.0, _yaw, 0.0)


## Walks to a chair and sits there. `height` is the seat height above the sand.
func sit_at(point: Vector3, face_yaw: float, height: float) -> void:
	_seated = true
	_seat_height = height
	go_to(point, face_yaw, true)


func _ready() -> void:
	add_to_group(&"customers")


## Everyone on the island cheers at the finale.
func cheer() -> void:
	if anim != null and _state != State.LEAVING:
		anim.fire(&"Yes" if randf() < 0.5 else &"Wave")


func is_ready() -> bool:
	return _state == State.WAITING and _arrived()


## The next flavor this customer still needs sent, or empty.
func wants() -> StringName:
	if _state == State.LEAVING:
		return &""
	for kind: StringName in _pending.keys():
		if int(_pending[kind]) > 0:
			return kind
	return &""


## The customer takes another flavor instead (the one the carrier holds).
func substitute(from_kind: StringName, to_kind: StringName) -> void:
	if to_kind == &"" or from_kind == to_kind or not order.has(from_kind):
		return
	var old_price: int = Flavors.price(from_kind)
	var count: int = int(order[from_kind])
	var waiting: int = int(_pending.get(from_kind, 0))
	order.erase(from_kind)
	_pending.erase(from_kind)
	order[to_kind] = int(order.get(to_kind, 0)) + count
	_pending[to_kind] = int(_pending.get(to_kind, 0)) + waiting
	_amount = maxi(_amount + count * (Flavors.price(to_kind) - old_price), 1)
	_wait = maxf(_wait, 12.0)
	_refresh_bubble(true)
	Audio.play_varied(&"pirate_grumpy", 0.1, -8.0)


## Marks one donut of `kind` as on its way, so no extra one is sent.
func reserve(kind: StringName) -> void:
	_pending[kind] = int(_pending.get(kind, 0)) - 1


func receive_position() -> Vector3:
	return receive_point.global_position if receive_point != null else global_position + Vector3.UP


## A donut landed. It is consumed here.
func receive(item: Node3D) -> void:
	var kind: StringName = &""
	if is_instance_valid(item):
		kind = item.get_meta("kind", &"")
		item.queue_free()
	if _state == State.LEAVING:
		return
	# A donut that was already flying when the order changed flavor still counts.
	var key: StringName = kind
	if not order.has(key) or int(order[key]) <= 0:
		key = &""
		for open_kind: StringName in order.keys():
			if int(order[open_kind]) > 0:
				key = open_kind
				break
	if key != &"":
		order[key] = int(order[key]) - 1
		_pending[key] = mini(int(_pending.get(key, 0)), int(order[key]))
	Wallet.bump(&"donuts_sold")
	Audio.play_varied(&"donut_land", 0.1, -4.0)
	if visual != null:
		ItemFlight.squash(visual, 0.12, 0.2)
	if _remaining() <= 0:
		_happy()
	else:
		_refresh_bubble(true)


func _process(delta: float) -> void:
	var to: Vector3 = _target - global_position
	to.y = 0.0
	var moving: bool = to.length() > 0.08
	if moving:
		var step: float = minf(walk_speed * delta, to.length())
		global_position += to.normalized() * step
		_yaw = lerp_angle(_yaw, atan2(to.x, to.z), 1.0 - exp(-turn_k * delta))
	elif _has_face and _state != State.LEAVING:
		_yaw = lerp_angle(_yaw, _face_yaw, 1.0 - exp(-turn_k * delta))
	if visual != null:
		# World yaw: the queue that owns the customer is rotated with the counter.
		visual.global_rotation = Vector3(0.0, _yaw, 0.0)
		var sit: float = (_seat_height - seat_drop) if (_seated and not moving and _state == State.WAITING) else 0.0
		visual.position.y = lerpf(visual.position.y, sit, 1.0 - exp(-10.0 * delta))
	if anim != null:
		anim.set_speed01(1.0 if moving else 0.0)
	match _state:
		State.WALKING_IN:
			if not moving:
				_state = State.WAITING
		State.WAITING:
			if not moving:
				_wait -= delta
				if _wait <= 0.0:
					_grumpy()
		State.LEAVING:
			if not moving:
				queue_free()


func _arrived() -> bool:
	var to: Vector3 = _target - global_position
	to.y = 0.0
	return to.length() <= 0.12


func _remaining() -> int:
	var total: int = 0
	for kind: StringName in order.keys():
		total += int(order[kind])
	return total


func _refresh_bubble(pop: bool) -> void:
	if bubble == null:
		return
	for kind: StringName in order.keys():
		if int(order[kind]) > 0:
			bubble.show_order(kind, int(order[kind]), pop)
			return
	bubble.hide_bubble()


func _happy() -> void:
	if bubble != null:
		bubble.hide_bubble()
	if anim != null:
		anim.fire(&"Yes" if randf() < 0.5 else &"Wave")
	Audio.play_varied(&"pirate_happy", 0.12, -3.0)
	Fx.burst(Fx.HEARTS, self, receive_position() + Vector3.UP * 0.5)
	served.emit(self, _amount)
	_leave(eat_time if _seated else 0.7)


func _grumpy() -> void:
	if bubble != null:
		bubble.hide_bubble()
	if anim != null:
		anim.fire(&"No")
	Audio.play_varied(&"pirate_grumpy", 0.1, -3.0)
	Fx.burst(Fx.SAD_PUFF, self, receive_position() + Vector3.UP * 0.5)
	_leave(0.9)


func _leave(delay: float) -> void:
	_has_face = false
	if not _seated:
		_state = State.LEAVING
		departed.emit(self)
	_target = global_position
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if _seated:
			_seated = false
			_state = State.LEAVING
			departed.emit(self)
		_target = _exit
	)
