class_name MenuCameraShot
extends Node3D
## One title shot. Its transform is the start frame; the movement type and its
## parameters do the rest. Reorder the nodes to reorder the sequence.

enum Movement { STATIC, MOVE, ORBIT }

@export var enabled: bool = true
@export var duration: float = 4.0
@export var movement: Movement = Movement.MOVE
@export var fov: float = 45.0
@export_group("Move")
@export var end_offset: Vector3 = Vector3(0, -2, 0)
@export var end_rotation_offset_degrees: Vector3 = Vector3.ZERO
@export_group("Orbit")
@export var orbit_target: Vector3 = Vector3.ZERO
@export var orbit_degrees: float = 30.0
@export_group("Common")
@export var ease_ends: bool = true


func sample(t: float) -> Transform3D:
	var f: float = t
	if ease_ends:
		f = t * t * (3.0 - 2.0 * t)
	var xf: Transform3D = global_transform
	match movement:
		Movement.MOVE:
			xf.origin = global_transform.origin + end_offset * f
			var turn: Vector3 = end_rotation_offset_degrees * f
			xf.basis = global_transform.basis * Basis.from_euler(Vector3(deg_to_rad(turn.x), deg_to_rad(turn.y), deg_to_rad(turn.z)))
		Movement.ORBIT:
			var angle: float = deg_to_rad(orbit_degrees) * f
			var offset: Vector3 = global_transform.origin - orbit_target
			xf.origin = orbit_target + offset.rotated(Vector3.UP, angle)
			xf.basis = global_transform.basis.rotated(Vector3.UP, angle)
	return xf
