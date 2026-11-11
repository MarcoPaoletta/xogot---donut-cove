class_name FloatingLoot
extends Node3D
## Loot on the water: coins and chests that bob with the waves and glint. When
## the ship sails within reach they fly to it on an arc and join the hold.

@export var value: int = 20
@export var pull_radius: float = 4.5
@export var bob_height: float = 0.12
@export var spin_speed: float = 1.4
## A chest splits into more coins on the HUD.
@export var is_chest: bool = false

var _time: float = 0.0
var _taken: bool = false
var _base: float = 0.25


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group(&"loot")
	_time = randf() * 6.0
	ItemFlight.pop_in(self, 0.35, 1.2)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	global_position.y = Sea.height_at(global_position.x, global_position.z) + _base + sin(_time * 2.4) * bob_height
	rotation.y += spin_speed * delta
	var ship: Ship = get_tree().get_first_node_in_group(&"ship") as Ship
	if ship == null or not ship.is_sailing():
		return
	var gap: Vector3 = ship.global_position - global_position
	gap.y = 0.0
	if gap.length() <= pull_radius:
		_taken = true
		var target: Callable = func() -> Vector3: return ship.global_position + Vector3.UP * 2.2
		ItemFlight.fly(self, target, 0.4, 1.6, 1.0, func(_item: Node3D) -> void:
			ship.add_loot(value)
			Fx.pop_number(ship, ship.global_position + Vector3.UP * 3.6, "+%d" % value, Fx.GOLD, 1.3 if is_chest else 1.0)
			Audio.play(&"coin", 1.0 + randf() * 0.5 if not is_chest else 0.8)
			if is_chest:
				Fx.burst(Fx.COIN_BURST, ship, ship.global_position + Vector3.UP * 2.4)
			queue_free()
		)
