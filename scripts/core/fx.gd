class_name Fx
extends RefCounted
## One place to spawn the saved effect scenes: floating numbers and one shot
## particle bursts. Every effect is its own scene in `scenes/fx/`; this helper
## only instantiates it at a spot and lets it free itself.

const POP_NUMBER: PackedScene = preload("res://scenes/fx/pop_number.tscn")
const HEARTS: PackedScene = preload("res://scenes/fx/fx_hearts.tscn")
const SAD_PUFF: PackedScene = preload("res://scenes/fx/fx_sad_puff.tscn")
const DUST_RING: PackedScene = preload("res://scenes/fx/fx_dust_ring.tscn")
const CONFETTI: PackedScene = preload("res://scenes/fx/fx_confetti.tscn")
const COIN_BURST: PackedScene = preload("res://scenes/fx/fx_coin_burst.tscn")

const GOLD: Color = Color(1.0, 0.86, 0.25)
const RARE: Color = Color(1.0, 0.55, 0.95)
const RED: Color = Color(1.0, 0.36, 0.3)
const WHITE: Color = Color(1.0, 1.0, 1.0)


## A floating "+12" at `at`, added next to `context` in the tree.
static func pop_number(context: Node, at: Vector3, text: String, color: Color = GOLD, size: float = 1.0) -> void:
	if context == null or not context.is_inside_tree():
		return
	var number: PopNumber = POP_NUMBER.instantiate() as PopNumber
	context.get_tree().current_scene.add_child(number)
	number.global_position = at
	number.scale = Vector3.ONE * size
	number.pop(text, color)


## Plays a one shot burst scene at `at`. The burst frees itself.
static func burst(scene: PackedScene, context: Node, at: Vector3, size: float = 1.0) -> Node3D:
	if scene == null or context == null or not context.is_inside_tree():
		return null
	var fx: Node3D = scene.instantiate() as Node3D
	context.get_tree().current_scene.add_child(fx)
	fx.global_position = at
	fx.scale = Vector3.ONE * size
	return fx
