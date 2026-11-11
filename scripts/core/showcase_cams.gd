class_name ShowcaseCams
extends Node3D
## The concept cameras and the showcase orbit. `F2` cycles the child cameras
## (the three concept views, then a slow orbit of the island) and returns to
## the gameplay camera after the last one. In a development build `Tab` does
## the same without the orbit.
##
## The cameras are authored as children; this script only makes one current.

@export var orbit_camera: Camera3D
@export var orbit_center: Vector3 = Vector3(2.0, 0.0, 0.0)
@export var orbit_radius: float = 46.0
@export var orbit_height: float = 30.0
@export var orbit_speed: float = 0.16
## The dev shortcut (`concept_cam`) only works in debug builds.
@export var dev_shortcut: bool = true

var _index: int = -1
var _previous: Camera3D = null
var _angle: float = 0.6


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"showcase_cam"):
		cycle(true)
	elif dev_shortcut and OS.is_debug_build() and event.is_action_pressed(&"concept_cam"):
		cycle(false)


func _process(delta: float) -> void:
	if orbit_camera != null and orbit_camera.current:
		_angle += orbit_speed * delta
		var at: Vector3 = orbit_center + Vector3(sin(_angle) * orbit_radius, orbit_height, cos(_angle) * orbit_radius)
		orbit_camera.look_at_from_position(at, orbit_center)


## Next camera, or back to the gameplay camera after the last one.
func cycle(with_orbit: bool) -> void:
	var cameras: Array[Camera3D] = []
	for child: Node in get_children():
		if child is Camera3D and (with_orbit or child != orbit_camera):
			cameras.append(child as Camera3D)
	if cameras.is_empty():
		return
	if _index < 0:
		_previous = get_viewport().get_camera_3d()
	_index += 1
	if _index >= cameras.size():
		release()
		return
	cameras[_index].current = true


## Shows one concept camera by name (comparison shots).
func show_camera(camera_name: String) -> void:
	var camera: Camera3D = get_node_or_null(camera_name) as Camera3D
	if camera == null:
		return
	if _index < 0:
		_previous = get_viewport().get_camera_3d()
	_index = camera.get_index()
	camera.current = true


func release() -> void:
	_index = -1
	if _previous != null and is_instance_valid(_previous):
		_previous.current = true
	_previous = null
