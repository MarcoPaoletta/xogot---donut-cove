class_name Oven
extends Node3D
## A producer: bakes one donut flavor onto its own rack. A carrier standing in
## the pickup zone scoops the rack onto its stack on an accelerating cadence.
##
## The oven model, the rack (`ItemTray`), the zone, the door point, the glow
## and the FULL label are authored in the oven scene. This script bakes,
## transfers and reports.

signal baked(item: Node3D)
signal blocked_changed(blocked: bool)

@export var donut_scene: PackedScene
@export var kind: StringName = &"strawberry"
@export var bake_interval: float = 1.6
## Donuts already on the rack when the oven starts.
@export var start_stock: int = 0
## False for an oven that still waits for its unlock pad.
@export var active: bool = true
@export var tray: ItemTray
@export var door_point: Marker3D
@export var pickup_zone: Area3D
@export var full_label: Label3D
@export var glow: OmniLight3D
@export var puff: GPUParticles3D

@export_group("Scoop cadence")
@export var scoop_first: float = 0.16
@export var scoop_factor: float = 0.88
@export var scoop_floor: float = 0.05

## Multiplies the bake rate (the oven speed pad).
var speed_multiplier: float = 1.0

var _bake_timer: float = 0.0
var _carriers: Dictionary = {}
var _blocked: bool = false
var _glow_rest: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	if pickup_zone != null:
		pickup_zone.body_entered.connect(_on_body_entered)
		pickup_zone.body_exited.connect(_on_body_exited)
	if full_label != null:
		full_label.visible = false
	if glow != null:
		_glow_rest = glow.light_energy
	if active:
		for i in start_stock:
			_bake()


## Called by the unlock pad that reveals this oven.
func on_unlocked() -> void:
	active = true
	_bake_timer = bake_interval * 0.5


func rack_count() -> int:
	return tray.count() if tray != null else 0


## Fills the rack at once (presenter panel).
func fill_rack() -> void:
	if not active or tray == null:
		return
	while not tray.is_full():
		_bake()


func _process(delta: float) -> void:
	_time += delta
	if glow != null:
		glow.light_energy = _glow_rest * (1.0 + 0.25 * sin(_time * 4.0)) if active else 0.0
	if not active or tray == null:
		return
	var full: bool = tray.is_full()
	if full != _blocked:
		_blocked = full
		blocked_changed.emit(_blocked)
		_show_full(_blocked)
	if not full:
		_bake_timer += delta * speed_multiplier
		if _bake_timer >= bake_interval:
			_bake_timer = 0.0
			_bake()
	for carrier: Node3D in _carriers.keys():
		_serve_carrier(carrier, delta)


func _bake() -> void:
	if donut_scene == null or tray == null or tray.is_full():
		return
	var item: Node3D = donut_scene.instantiate() as Node3D
	item.set_meta("kind", kind)
	add_child(item)
	item.global_position = door_point.global_position if door_point != null else global_position
	tray.push(item)
	if puff != null:
		puff.restart()
	Audio.play_varied(&"oven_ding", 0.06, -8.0)
	baked.emit(item)


func _serve_carrier(carrier: Node3D, delta: float) -> void:
	if not is_instance_valid(carrier):
		_carriers.erase(carrier)
		return
	var state: Dictionary = _carriers[carrier]
	state["cooldown"] = float(state["cooldown"]) - delta
	if float(state["cooldown"]) > 0.0 or tray.is_empty():
		return
	var stack: CarryStack = carrier.call(&"get_carry_stack") as CarryStack
	if stack == null:
		return
	if stack.is_full():
		if not bool(state["warned"]):
			state["warned"] = true
			stack.notify_full()
		return
	if tray.transfer_to_stack(stack):
		state["interval"] = maxf(float(state["interval"]) * scoop_factor, scoop_floor)
		state["cooldown"] = float(state["interval"])


func _on_body_entered(body: Node3D) -> void:
	if body.has_method(&"get_carry_stack"):
		_carriers[body] = {"interval": scoop_first, "cooldown": 0.0, "warned": false}


func _on_body_exited(body: Node3D) -> void:
	_carriers.erase(body)


func _show_full(show_it: bool) -> void:
	if full_label == null:
		return
	full_label.visible = show_it
	if show_it:
		full_label.scale = Vector3.ONE * 0.3
		var tween: Tween = full_label.create_tween()
		tween.tween_property(full_label, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
