class_name OrderBubble
extends Node3D
## The order bubble over a customer: the flavor icon and how many are wanted.
##
## The bubble shape, one donut icon per flavor (children of `Icons`, named by
## flavor) and the count label are authored in `order_bubble.tscn`. The bubble
## turns to the camera every frame so it reads from the fixed angle.

@export var icons: Node3D
@export var count_label: Label3D

var _rest: Vector3 = Vector3.ONE
var _full: Vector3 = Vector3.ONE
var _tween: Tween = null


func _ready() -> void:
	_rest = scale
	_full = scale
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera != null:
		global_basis = camera.global_basis.orthonormalized().scaled(scale)


func show_order(kind: StringName, count: int, pop: bool = true) -> void:
	visible = true
	if icons != null:
		for icon: Node in icons.get_children():
			(icon as Node3D).visible = icon.name == String(kind)
	if count_label != null:
		count_label.text = "x%d" % count
	if pop:
		_pop(1.25)


## 1.0 for the customer being served, smaller for the ones further back in
## the line, so the bubbles of a queue do not cover each other.
func set_size(factor: float) -> void:
	var size: Vector3 = _full * factor
	if size.is_equal_approx(_rest):
		return
	_rest = size
	if visible:
		_pop(1.0)


func hide_bubble() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", _rest * 0.01, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void: visible = false)


func _pop(peak: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if peak > 1.0:
		scale = _rest * peak
	_tween = create_tween()
	_tween.tween_property(self, "scale", _rest, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
