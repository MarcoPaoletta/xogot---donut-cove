class_name ShopCounter
extends Node3D
## The counter. A carrier standing in the serve zone feeds the front customer
## from its stack on an accelerating cadence; a happy customer pays in physical
## coins that land on the cash tray; the baker walking over the tray sends the
## coins to the HUD.
##
## The counter model, the zones, the cash tray and the queue are authored in
## the scenes. Coins are instances of the saved coin scene.

signal sale(amount: int, at: Vector3)

@export var queue: CustomerQueue
@export var serve_zone: Area3D
@export var cash_zone: Area3D
@export var cash_tray: ItemTray
@export var coin_scene: PackedScene
## Value of one coin on the tray. Bigger sales make more coins.
@export var coin_value: int = 4

## Seconds a carrier with the wrong flavors waits before the front customer changes its order.
@export var substitute_after: float = 1.6

@export_group("Feed cadence")
@export var feed_first: float = 0.22
@export var feed_factor: float = 0.85
@export var feed_floor: float = 0.06

@export_group("Cash cadence")
@export var cash_first: float = 0.07
@export var cash_factor: float = 0.9
@export var cash_floor: float = 0.03

var _carriers: Dictionary = {}
var _collector: Node3D = null
var _cash_interval: float = 0.0
var _cash_cooldown: float = 0.0


func _ready() -> void:
	serve_zone.body_entered.connect(_on_serve_entered)
	serve_zone.body_exited.connect(func(body: Node3D) -> void: _carriers.erase(body))
	cash_zone.body_entered.connect(_on_cash_entered)
	cash_zone.body_exited.connect(_on_cash_exited)
	if queue != null:
		queue.customer_served.connect(_on_customer_served)


## The customers that can take a donut right now. The counter serves the front
## of its queue; a table serves whoever is seated.
func ready_customers() -> Array[Customer]:
	var result: Array[Customer] = []
	if queue != null:
		var first: Customer = queue.front()
		if first != null:
			result.append(first)
	return result


## True when some ready customer wants a flavor (helpers ask before walking).
func wanted_kind() -> StringName:
	for customer: Customer in ready_customers():
		var kind: StringName = customer.wants()
		if kind != &"":
			return kind
	return &""


func _process(delta: float) -> void:
	for carrier: Node3D in _carriers.keys():
		_feed(carrier, delta)
	if _collector != null:
		_collect(delta)


## Value of every coin waiting on the tray.
func cash_waiting() -> int:
	var total: int = 0
	for child: Node in cash_tray.get_children():
		total += int(child.get_meta("value", 0))
	return total


func _feed(carrier: Node3D, delta: float) -> void:
	if not is_instance_valid(carrier):
		_carriers.erase(carrier)
		return
	var state: Dictionary = _carriers[carrier]
	state["cooldown"] = float(state["cooldown"]) - delta
	if float(state["cooldown"]) > 0.0:
		return
	var stack: CarryStack = carrier.call(&"get_carry_stack") as CarryStack
	if stack == null or stack.is_empty():
		return
	var customer: Customer = null
	var kind: StringName = &""
	for candidate: Customer in ready_customers():
		var wanted: StringName = candidate.wants()
		if wanted != &"" and stack.has_kind(wanted):
			customer = candidate
			kind = wanted
			break
	if customer == null:
		# Nobody wants what this carrier holds. After a short wait the customer at the
		# front takes what there is, so a full stack of another flavor never blocks the line.
		state["stall"] = float(state.get("stall", 0.0)) + delta
		var waiting: Array[Customer] = ready_customers()
		if float(state["stall"]) >= substitute_after and not waiting.is_empty():
			var unwanted: StringName = waiting[0].wants()
			if unwanted != &"":
				waiting[0].substitute(unwanted, stack.top_kind())
			state["stall"] = 0.0
		return
	state["stall"] = 0.0
	customer.reserve(kind)
	stack.send_top(customer.receive_position, 0.24, 0.7, customer.receive, kind)
	Audio.play(&"serve", 1.0 + 0.05 * float(state["chain"]))
	state["chain"] = int(state["chain"]) + 1
	state["interval"] = maxf(float(state["interval"]) * feed_factor, feed_floor)
	state["cooldown"] = float(state["interval"])


func _collect(delta: float) -> void:
	if not is_instance_valid(_collector):
		_collector = null
		return
	_cash_cooldown -= delta
	if _cash_cooldown > 0.0 or cash_tray.is_empty():
		return
	var who: Node3D = _collector
	var head: Callable = func() -> Vector3: return who.global_position + Vector3.UP * 1.6
	cash_tray.send_top(head, 0.2, 0.5, _on_coin_collected)
	_cash_interval = maxf(_cash_interval * cash_factor, cash_floor)
	_cash_cooldown = _cash_interval


func _on_coin_collected(coin: Node3D) -> void:
	if not is_instance_valid(coin):
		return
	var value: int = int(coin.get_meta("value", 1))
	var at: Vector3 = coin.global_position
	coin.queue_free()
	Hud.collect_coins(self, at, value)


func _on_customer_served(customer: Customer, amount: int) -> void:
	var at: Vector3 = customer.receive_position()
	Fx.pop_number(self, at + Vector3.UP * 0.6, "+%d" % amount, Fx.GOLD if not customer.is_rare else Fx.RARE, 1.4 if customer.is_rare else 1.0)
	sale.emit(amount, at)
	var coins: int = clampi(ceili(float(amount) / float(maxi(coin_value, 1))), 1, 10)
	var share: int = floori(float(amount) / float(coins))
	var extra: int = amount - share * coins
	for i in coins:
		var value: int = share + (extra if i == coins - 1 else 0)
		_drop_coin(at, value, 0.05 * float(i))


func _drop_coin(at: Vector3, value: int, delay: float) -> void:
	if coin_scene == null:
		Hud.collect_coins(self, at, value)
		return
	if cash_tray.is_full():
		# The pile is at its visible limit: the value joins the top coin.
		var top: Node = cash_tray.get_child(cash_tray.get_child_count() - 1) if cash_tray.get_child_count() > 0 else null
		if top != null:
			top.set_meta("value", int(top.get_meta("value", 0)) + value)
		else:
			Hud.collect_coins(self, at, value)
		return
	var coin: Node3D = coin_scene.instantiate() as Node3D
	coin.set_meta("value", value)
	add_child(coin)
	coin.global_position = at
	cash_tray.push(coin, delay)
	get_tree().create_timer(delay + 0.28).timeout.connect(func() -> void: Audio.play_varied(&"coin_drop", 0.12, -6.0))


func _on_serve_entered(body: Node3D) -> void:
	if body.has_method(&"get_carry_stack"):
		_carriers[body] = {"interval": feed_first, "cooldown": 0.0, "chain": 0}


func _on_cash_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_collector = body
		_cash_interval = cash_first
		_cash_cooldown = 0.0


func _on_cash_exited(body: Node3D) -> void:
	if body == _collector:
		_collector = null
