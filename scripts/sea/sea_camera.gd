class_name SeaCamera
extends Node3D
## The camera at sea (always perspective): behind and above the ship, framed
## like Concept 3 with the helm in the lower left and the bow and the sea
## ahead. The position is rigid to the ship; only the rotation is smoothed to
## the heading. It pulls back 15 percent at top speed.

@export var ship: Ship
@export var camera: Camera3D
## Camera position in the frame of the smoothed heading (x right, y up, z behind).
@export var offset: Vector3 = Vector3(3.2, 8.2, 12.5)
## Where the camera looks, in the same frame.
@export var look_offset: Vector3 = Vector3(-1.5, 1.2, -9.0)
@export var base_fov: float = 50.0
@export var yaw_k: float = 3.0
@export var pull_back: float = 0.15
@export var shake_max_offset: float = 0.5
@export var shake_decay: float = 1.5
## False until the ship is boarded.
@export var live: bool = false
## Wheel zoom, as a factor of the authored offset.
@export var zoom_min: float = 0.7
@export var zoom_max: float = 1.9

var _yaw: float = 0.0
var _trauma: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _fov_tween: Tween = null
var _zoom: float = 1.0
var _zoom_target: float = 1.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_noise.frequency = 1.0
	if camera != null:
		camera.fov = base_fov


func _unhandled_input(event: InputEvent) -> void:
	if not live or not (event is InputEventMouseButton) or not event.pressed:
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_target = clampf(_zoom_target - 0.1, zoom_min, zoom_max)
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_target = clampf(_zoom_target + 0.1, zoom_min, zoom_max)


func _process(delta: float) -> void:
	_time += delta
	_zoom = lerpf(_zoom, _zoom_target, 1.0 - exp(-10.0 * delta))
	if ship == null or camera == null:
		return
	var ship_yaw: float = ship.global_rotation.y
	_yaw = lerp_angle(_yaw, ship_yaw, 1.0 - exp(-yaw_k * delta))
	var speed01: float = clampf(absf(ship.speed) / ship.top_speed, 0.0, 1.0)
	var basis_yaw: Basis = Basis(Vector3.UP, _yaw)
	var at: Vector3 = ship.global_position + basis_yaw * (offset * _zoom * (1.0 + pull_back * speed01))
	global_position = at
	camera.global_position = at
	camera.look_at(ship.global_position + basis_yaw * look_offset, Vector3.UP)
	_trauma = maxf(_trauma - shake_decay * delta, 0.0)
	var amount: float = _trauma * _trauma
	camera.h_offset = _noise.get_noise_2d(_time * 50.0, 0.0) * shake_max_offset * amount * 3.0
	camera.v_offset = _noise.get_noise_2d(0.0, _time * 50.0) * shake_max_offset * amount * 3.0


## Snaps the heading (when the ship is boarded).
func snap() -> void:
	if ship != null:
		_yaw = ship.global_rotation.y


func add_trauma(amount: float) -> void:
	if live:
		_trauma = minf(_trauma + amount, 1.0)


func fov_kick(extra_degrees: float = 4.0, time: float = 0.4) -> void:
	if camera == null or not live:
		return
	if _fov_tween != null and _fov_tween.is_valid():
		_fov_tween.kill()
	camera.fov = base_fov + extra_degrees
	_fov_tween = create_tween()
	_fov_tween.tween_property(camera, "fov", base_fov, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## The island camera owns focus beats; at sea the view already shows the action.
func focus_beat(_point: Vector3, _travel: float = 0.55, _hold: float = 0.9, _back: float = 0.7) -> void:
	pass


func sees(_point: Vector3) -> bool:
	return true
