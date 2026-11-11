class_name IslandCamera
extends Node3D
## The fixed angle perspective camera of the island (never orthographic).
## The `Camera3D` child keeps the pitch and distance authored in the scene;
## this rig only translates, so the angle never changes.
##
## It follows the target rigidly on X and Z (no positional smoothing), clamps
## to the island, and smooths only the focus beats, the FOV kicks and the
## shake.

@export var target: Node3D
@export var camera: Camera3D
@export var base_fov: float = 38.0
## The rig stays inside this rectangle on the ground (x, z, width, depth).
@export var limits: Rect2 = Rect2(-12.0, -8.0, 24.0, 16.0)
@export var shake_max_offset: float = 0.35
@export var shake_decay: float = 1.6
## False while another camera (title, ship, showcase) owns the view.
@export var following: bool = true

var _focus_point: Vector3 = Vector3.ZERO
var _focus_weight: float = 0.0
var _focus_tween: Tween = null
var _trauma: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _fov_tween: Tween = null


func _ready() -> void:
	_noise.frequency = 1.0
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if camera != null:
		camera.fov = base_fov


func _process(delta: float) -> void:
	_time += delta
	if target != null and following:
		var at: Vector3 = target.get_global_transform_interpolated().origin
		var goal: Vector3 = Vector3(
			clampf(at.x, limits.position.x, limits.end.x), 0.0,
			clampf(at.z, limits.position.y, limits.end.y))
		global_position = goal.lerp(_focus_point, _focus_weight)
	if camera != null:
		_trauma = maxf(_trauma - shake_decay * delta, 0.0)
		var amount: float = _trauma * _trauma
		camera.h_offset = _noise.get_noise_2d(_time * 55.0, 0.0) * shake_max_offset * amount * 3.0
		camera.v_offset = _noise.get_noise_2d(0.0, _time * 55.0) * shake_max_offset * amount * 3.0


## Travels to `point`, holds, and returns to the target. Input stays live.
func focus_beat(point: Vector3, travel: float = 0.55, hold: float = 0.9, back: float = 0.7) -> void:
	_focus_point = Vector3(point.x, 0.0, point.z)
	if _focus_tween != null and _focus_tween.is_valid():
		_focus_tween.kill()
	_focus_tween = create_tween()
	_focus_tween.tween_property(self, "_focus_weight", 1.0, travel).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_focus_tween.tween_interval(hold)
	_focus_tween.tween_property(self, "_focus_weight", 0.0, back).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## True when `point` is comfortably inside the frame.
func sees(point: Vector3) -> bool:
	if camera == null or camera.is_position_behind(point):
		return false
	var screen: Vector2 = camera.unproject_position(point)
	var rect: Rect2 = camera.get_viewport().get_visible_rect().grow(-140.0)
	return rect.has_point(screen)


## Small shake. 0.15 is a tick, 0.3 a purchase, 0.6 a boom.
func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


## The FOV widens for a moment and settles.
func fov_kick(extra_degrees: float = 4.0, time: float = 0.4) -> void:
	if camera == null:
		return
	if _fov_tween != null and _fov_tween.is_valid():
		_fov_tween.kill()
	camera.fov = base_fov + extra_degrees
	_fov_tween = create_tween()
	_fov_tween.tween_property(camera, "fov", base_fov, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
