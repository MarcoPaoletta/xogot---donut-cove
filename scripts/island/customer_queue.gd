class_name CustomerQueue
extends Node3D
## The line of pirates at the counter. Spawns customers at the entrance,
## assigns them to the slot markers in order and moves the line up when the
## front one leaves.
##
## The slots, the spawn point and the exit point are `Marker3D` nodes authored
## in the scene. The customers are instances of the saved customer scenes.

signal customer_served(customer: Customer, amount: int)

@export var customer_scenes: Array[PackedScene] = []
@export var rare_scene: PackedScene
@export var slots_root: Node3D
@export var spawn_point: Marker3D
@export var exit_point: Marker3D
## Seconds between arrivals.
@export var spawn_interval: float = 4.0
## How many slot markers are open (4 at the start, 6 with the display case).
@export var open_slots: int = 4
## Customers already standing in line when the game starts.
@export var initial_customers: int = 2
## Flavors that can be ordered (one per built oven).
@export var kinds: Array[StringName] = [&"strawberry"]
@export var running: bool = true

## Tips (the statue pad).
var pay_multiplier: float = 1.0
var rare_enabled: bool = false
var rare_interval: float = 60.0

var _line: Array[Customer] = []
var _spawn_timer: float = 0.0
var _rare_timer: float = 20.0
var _last_scene: int = -1


func _ready() -> void:
	for i in mini(initial_customers, _slot_count()):
		var customer: Customer = _create(false)
		if customer == null:
			break
		_line.append(customer)
		customer.place_at(_slot_position(i), _slot_yaw(i))
		customer.bubble_size(_bubble_size(i))


func _process(delta: float) -> void:
	if not running:
		return
	_spawn_timer += delta
	if rare_enabled:
		_rare_timer -= delta
	if _spawn_timer >= spawn_interval and _line.size() < _slot_count():
		_spawn_timer = 0.0
		var rare: bool = rare_enabled and _rare_timer <= 0.0 and rare_scene != null
		if rare:
			_rare_timer = rare_interval
		spawn(rare)


## The customer standing at the counter and ready to be served, or null.
func front() -> Customer:
	if _line.is_empty():
		return null
	var first: Customer = _line[0]
	return first if is_instance_valid(first) and first.is_ready() else null


func line_size() -> int:
	return _line.size()


func add_kind(kind: StringName) -> void:
	if not kinds.has(kind):
		kinds.append(kind)


## Adds one walking customer. Returns null when the line is full.
func spawn(rare: bool = false) -> Customer:
	if _line.size() >= _slot_count():
		return null
	var customer: Customer = _create(rare)
	if customer == null:
		return null
	customer.global_position = spawn_point.global_position if spawn_point != null else global_position
	_line.append(customer)
	var index: int = _line.size() - 1
	customer.go_to(_slot_position(index), _slot_yaw(index), true)
	customer.bubble_size(_bubble_size(index))
	if rare:
		get_tree().call_group(&"game_camera", &"focus_beat", _slot_position(0))
		Audio.play(&"rare_fanfare")
	return customer


## A customer that walks in from the entrance but does not join the line
## (the tables). The caller tells it where to go.
func create_walker(order_min: int = 2, order_max: int = 3) -> Customer:
	var scene: PackedScene = _pick_scene()
	if scene == null:
		return null
	var customer: Customer = scene.instantiate() as Customer
	add_child(customer)
	customer.global_position = spawn_point.global_position if spawn_point != null else global_position
	var order: Dictionary = {}
	if not kinds.is_empty():
		order[kinds[randi() % kinds.size()]] = randi_range(order_min, order_max)
	customer.setup(order, pay_multiplier, false, exit_point.global_position if exit_point != null else global_position)
	return customer


## Frees every customer (restart).
func clear_all() -> void:
	for customer: Customer in _line:
		if is_instance_valid(customer):
			customer.queue_free()
	_line.clear()
	_spawn_timer = 0.0


func _create(rare: bool) -> Customer:
	var scene: PackedScene = rare_scene if rare else _pick_scene()
	if scene == null:
		return null
	var customer: Customer = scene.instantiate() as Customer
	add_child(customer)
	customer.setup(_make_order(), pay_multiplier, rare, exit_point.global_position if exit_point != null else global_position)
	customer.served.connect(_on_served)
	customer.departed.connect(_on_departed)
	return customer


func _pick_scene() -> PackedScene:
	if customer_scenes.is_empty():
		return null
	var index: int = randi() % customer_scenes.size()
	if index == _last_scene and customer_scenes.size() > 1:
		index = (index + 1) % customer_scenes.size()
	_last_scene = index
	return customer_scenes[index]


## 1 to 3 donuts. With three flavors about a third of the orders mix two.
func _make_order() -> Dictionary:
	var result: Dictionary = {}
	if kinds.is_empty():
		return result
	var total: int = randi_range(1, 3)
	var first: StringName = kinds[randi() % kinds.size()]
	if kinds.size() >= 3 and total >= 2 and randf() < 0.33:
		var second: StringName = first
		while second == first:
			second = kinds[randi() % kinds.size()]
		result[first] = total - 1
		result[second] = 1
	else:
		result[first] = total
	return result


func _slot_count() -> int:
	if slots_root == null:
		return 0
	return mini(open_slots, slots_root.get_child_count())


func _slot_position(index: int) -> Vector3:
	return (slots_root.get_child(index) as Node3D).global_position


## The first in line shows a full bubble, the rest a smaller one.
func _bubble_size(index: int) -> float:
	return 1.0 if index == 0 else 0.6


func _slot_yaw(index: int) -> float:
	return (slots_root.get_child(index) as Node3D).global_rotation.y


func _on_served(customer: Customer, amount: int) -> void:
	customer_served.emit(customer, amount)


func _on_departed(customer: Customer) -> void:
	_line.erase(customer)
	for i in _line.size():
		if is_instance_valid(_line[i]):
			_line[i].go_to(_slot_position(i), _slot_yaw(i), true)
			_line[i].bubble_size(_bubble_size(i))
