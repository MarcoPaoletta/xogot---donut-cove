class_name Game
extends Node3D
## The session of Donut Cove: start cash, the pad sequence, what each pad
## changes, the objective arrow and the session clock.
##
## The world is authored in `main.tscn`; this script only connects the pieces
## that already exist there. Pads are the children of `Pads`, in buying order.

signal pad_bought(pad_id: StringName)
signal session_started

@export var start_cash: int = 60
## How many unbought pads are offered at once (the concept shows two).
@export var pads_offered: int = 2
@export var baker: Baker
@export var pads_root: Node3D
@export var arrow: ObjectiveArrow
@export var counter: ShopCounter
@export var first_oven: Oven

## Flags that gate pads: `first_voyage`, `kraken_won`.
var flags: Dictionary = {}
var playing: bool = false
var session_time: float = 0.0
var purchase_log: Array[String] = []

var _pads: Array[UnlockPad] = []
var _first_sale_done: bool = false


func _ready() -> void:
	add_to_group(&"game")
	for child: Node in pads_root.get_children():
		if child is UnlockPad:
			var pad: UnlockPad = child as UnlockPad
			_pads.append(pad)
			pad.unlocked.connect(_on_pad_unlocked)
	if counter != null:
		counter.sale.connect(func(_amount: int, _at: Vector3) -> void: _first_sale_done = true)
	Wallet.reset(start_cash)
	Wallet.changed.connect(func(_cash: int) -> void: _update_arrow())
	begin_session()


func _process(delta: float) -> void:
	if playing:
		session_time += delta
	_update_arrow()


## Starts the clock and offers the first pads.
func begin_session() -> void:
	playing = true
	session_time = 0.0
	_offer_pads()
	session_started.emit()


func set_flag(flag: StringName) -> void:
	flags[flag] = true
	_offer_pads()


## The next pad that can be bought, or null.
func next_pad() -> UnlockPad:
	for pad: UnlockPad in _pads:
		if not pad.done and _gate_open(pad):
			return pad
	return null


func pad(pad_id: StringName) -> UnlockPad:
	for candidate: UnlockPad in _pads:
		if candidate.pad_id == pad_id:
			return candidate
	return null


func is_bought(pad_id: StringName) -> bool:
	var found: UnlockPad = pad(pad_id)
	return found != null and found.done


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
				queue.spawn_interval = 3.0
		&"backpack":
			_set_capacity(10)
		&"backpack2":
			_set_capacity(16)
		&"statue":
			if queue != null:
				queue.pay_multiplier = 1.2
				queue.rare_enabled = true
		&"oven_speed":
			for node: Node in get_tree().get_nodes_in_group(&"ovens"):
				(node as Oven).speed_multiplier = 1.4
				Fx.burst(Fx.DUST_RING, self, (node as Node3D).global_position + Vector3.UP)


func _set_capacity(value: int) -> void:
	if baker == null:
		return
	baker.carry_stack.capacity = value
	Fx.pop_number(self, baker.global_position + Vector3.UP * 2.6, "MAX %d" % value, Fx.WHITE, 1.2)


func _update_arrow() -> void:
	if arrow == null or baker == null:
		return
	var goal: Node3D = null
	var upcoming: UnlockPad = next_pad()
	if purchase_log.is_empty() and not _first_sale_done:
		if baker.carry_stack.count() == 0 and first_oven != null:
			goal = first_oven.pickup_zone
		elif counter != null:
			goal = counter.serve_zone
	elif counter != null and counter.cash_waiting() > 0 and (upcoming == null or Wallet.cash < upcoming.remaining()):
		goal = counter.cash_zone
	elif upcoming != null:
		goal = upcoming
	if goal != arrow.target:
		arrow.point_at(goal)
