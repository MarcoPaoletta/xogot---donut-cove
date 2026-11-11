class_name MenuCameraDirector
extends Node3D
## Plays the child `MenuCameraShot` sequence in tree order with a hard cut
## between shots. The title shows the real island; the camera never sits still.

@export var active: bool = false:
	set(value):
		active = value
		if active and is_inside_tree():
			_shot_index = -1
			_advance()
@export var camera: Camera3D

var _shot_index: int = -1
var _shot_time: float = 0.0
var _current: MenuCameraShot = null


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _shots() -> Array[MenuCameraShot]:
	var result: Array[MenuCameraShot] = []
	for child: Node in get_children():
		if child is MenuCameraShot and (child as MenuCameraShot).enabled:
			result.append(child as MenuCameraShot)
	return result


func make_current() -> void:
	if camera != null:
		camera.current = true


func _advance() -> void:
	var shots: Array[MenuCameraShot] = _shots()
	if shots.is_empty():
		return
	_shot_index = (_shot_index + 1) % shots.size()
	_current = shots[_shot_index]
	_shot_time = 0.0
	if camera != null:
		camera.fov = _current.fov


func _process(delta: float) -> void:
	if not active or _current == null or camera == null:
		return
	_shot_time += delta
	if _shot_time >= _current.duration:
		_advance()
	var t: float = clampf(_shot_time / _current.duration, 0.0, 1.0)
	camera.global_transform = _current.sample(t)
