class_name Cannonball
extends Node3D
## A cannonball in flight. It follows an arc to the aim point on the water and
## hits every sea enemy standing within reach of the splash.

@export var damage: int = 1
@export var splash_radius: float = 1.2


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func launch(target: Vector3, time: float, apex: float) -> void:
	ItemFlight.fly(self, func() -> Vector3: return target, time, apex, 1.0, _land)


func _land(_ball: Node3D) -> void:
	var hit: bool = false
	for node: Node in get_tree().get_nodes_in_group(&"sea_enemies"):
		var enemy: Node3D = node as Node3D
		if enemy == null or not enemy.has_method(&"take_hit"):
			continue
		var reach: float = float(enemy.get(&"hit_radius")) + splash_radius
		var gap: Vector3 = enemy.global_position - global_position
		gap.y = 0.0
		if gap.length() <= reach and bool(enemy.call(&"can_be_hit")):
			enemy.call(&"take_hit", damage, global_position)
			hit = true
	if hit:
		Fx.burst(Fx.IMPACT, self, global_position + Vector3.UP * 0.6)
		Audio.play_varied(&"impact", 0.1)
		get_tree().call_group(&"game_camera", &"add_trauma", 0.2)
	else:
		Fx.burst(Fx.SPLASH, self, global_position)
		Audio.play_varied(&"splash", 0.15, -5.0)
	queue_free()
