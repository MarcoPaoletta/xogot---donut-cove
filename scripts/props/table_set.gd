class_name TableSet
extends ShopCounter
## A round table with two chairs. Pirates walk in, sit, order 2 to 3 donuts,
## eat and leave a coin pile on the table. It is the counter again: the same
## serve zone, feed cadence and cash tray, with seated customers instead of a
## queue front.
##
## The table, the chairs, the seat markers, the zones and the tray are
## authored in `table_set.tscn`. Customers come from the shop queue's scenes.

@export var seats_root: Node3D
## The shop queue: lends its customer scenes, flavors and entrance.
@export var shop_queue: CustomerQueue
## Seconds between arrivals while a seat is free.
@export var arrival_interval: float = 9.0
@export var seat_height: float = 0.42
## False until the tables pad is bought.
@export var open: bool = true

var _seated: Dictionary = {}
var _arrival_timer: float = 3.0


func _process(delta: float) -> void:
	super._process(delta)
	if not open or shop_queue == null or seats_root == null:
		return
	_arrival_timer -= delta
	if _arrival_timer > 0.0:
		return
	_arrival_timer = arrival_interval * randf_range(0.8, 1.2)
	for index in seats_root.get_child_count():
		if not _seated.has(index):
			_seat_customer(index)
			return


func on_unlocked() -> void:
	open = true
	_arrival_timer = 1.5


func ready_customers() -> Array[Customer]:
	var result: Array[Customer] = []
	for index: int in _seated.keys():
		var customer: Customer = _seated[index] as Customer
		if is_instance_valid(customer) and customer.is_ready():
			result.append(customer)
	return result


func _seat_customer(index: int) -> void:
	var customer: Customer = shop_queue.create_walker(2, 3)
	if customer == null:
		return
	var seat: Node3D = seats_root.get_child(index) as Node3D
	_seated[index] = customer
	customer.sit_at(seat.global_position, seat.global_rotation.y, seat_height)
	customer.served.connect(_on_customer_served)
	customer.departed.connect(func(_who: Customer) -> void: _seated.erase(index))
	customer.tree_exited.connect(func() -> void:
		if _seated.get(index) == customer:
			_seated.erase(index)
	)
