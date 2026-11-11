class_name Baker
extends CharacterBody3D
## The bunny baker. Camera relative movement on the ground plane, a visual
## model that faces the input, and the back stack.
##
## The physics body never rotates: the yaw lives in `_model_yaw` and is written
## to the `Visual` child (player-controller reference, bugs A to C).

@export var run_speed: float = 6.0
## Seconds from standing to full speed. Short, with no slide.
@export var accel_time: float = 0.08
@export var turn_k: float = 16.0
@export var lean_degrees: float = 7.0
@export var gravity: float = 24.0
@export var carry_stack: CarryStack
@export var visual: Node3D
@export var anim: CharacterAnim
@export var max_label: Label3D
@export var run_dust: GPUParticles3D

## False while a screen, the ship or a cutscene owns the input.
var control_enabled: bool = true

var _model_yaw: float = 0.0
var _max_tween: Tween = null


func _ready() -> void:
	if carry_stack != null:
		carry_stack.rejected_full.connect(_on_rejected_full)
		carry_stack.item_removed.connect(func(_item: Node3D, _count: int) -> void: _hide_max())
	if max_label != null:
		max_label.visible = false
		max_label.position.y = 1.4 + float(carry_stack.capacity) * carry_stack.item_height * 0.9 if carry_stack != null else 2.6


func get_carry_stack() -> CarryStack:
	return carry_stack


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if control_enabled:
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var camera: Camera3D = get_viewport().get_camera_3d()
	var yaw: float = camera.global_rotation.y if camera != null else 0.0
	var wish: Vector3 = Basis(Vector3.UP, yaw) * Vector3(input.x, 0.0, input.y)
	wish.y = 0.0
	if wish.length() > 1.0:
		wish = wish.normalized()
	var rate: float = run_speed / maxf(accel_time, 0.001) * delta
	velocity.x = move_toward(velocity.x, wish.x * run_speed, rate)
	velocity.z = move_toward(velocity.z, wish.z * run_speed, rate)
	if is_on_floor():
		velocity.y = -1.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	var speed01: float = Vector2(velocity.x, velocity.z).length() / run_speed
	if wish.length() > 0.05:
		_model_yaw = lerp_angle(_model_yaw, atan2(wish.x, wish.z), 1.0 - exp(-turn_k * delta))
	if visual != null:
		visual.rotation = Vector3(deg_to_rad(lean_degrees) * speed01, _model_yaw, 0.0)
	if run_dust != null:
		run_dust.emitting = speed01 > 0.6 and is_on_floor()
	if anim != null:
		anim.set_speed01(speed01)
		anim.set_holding(carry_stack != null and carry_stack.count() > 0)


## Places the baker without a physics interpolation smear.
func teleport(point: Vector3, yaw: float = 0.0) -> void:
	global_position = point
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	_model_yaw = yaw
	if visual != null:
		visual.rotation = Vector3(0.0, _model_yaw, 0.0)
	reset_physics_interpolation()


## Bigger stack: the tower she carries in her arms holds more.
func upgrade_backpack(_level: int, capacity: int) -> void:
	carry_stack.capacity = capacity
	if max_label != null:
		max_label.position.y = 1.4 + float(capacity) * carry_stack.item_height * 0.9
	if visual != null:
		ItemFlight.squash(visual, 0.5, 0.35)
	Fx.burst(Fx.DUST_RING, self, global_position + Vector3.UP * 0.2, 0.7)


## The happy hop after a purchase.
func cheer() -> void:
	if anim != null:
		anim.fire(&"Yes")


func _on_rejected_full() -> void:
	Audio.play_varied(&"reject", 0.05)
	if max_label == null:
		return
	if _max_tween != null and _max_tween.is_valid():
		_max_tween.kill()
	max_label.visible = true
	max_label.scale = Vector3.ONE * 0.4
	_max_tween = create_tween()
	_max_tween.tween_property(max_label, "scale", Vector3.ONE * 1.25, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_max_tween.tween_property(max_label, "scale", Vector3.ONE, 0.1)
	_max_tween.tween_interval(1.2)
	_max_tween.tween_callback(_hide_max)


func _hide_max() -> void:
	if max_label != null and (carry_stack == null or not carry_stack.is_full()):
		max_label.visible = false
