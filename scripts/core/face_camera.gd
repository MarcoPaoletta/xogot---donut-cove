class_name FaceCamera
extends Node3D
## Turns its children to the current camera every frame, keeping the scale
## authored in the scene. For world space UI made of several parts (price
## pills, bubbles) that must read from the fixed angle.

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera != null:
		global_basis = camera.global_basis.orthonormalized().scaled(global_basis.get_scale())
