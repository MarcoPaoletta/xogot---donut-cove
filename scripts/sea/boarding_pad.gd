class_name BoardingPad
extends Area3D
## The gold ring at the dock end. The baker stands on it for half a second and
## boards the ship. The ring and its arrow are authored in the scene.

signal boarded

@export var hold_time: float = 0.5
@export var ring: Node3D
@export var arrow: Node3D
## False while the ship is away.
@export var enabled: bool = true

var _carrier: Node3D = null
var _held: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group(&"player"):
			_carrier = body
			_held = 0.0
	)
	body_exited.connect(func(body: Node3D) -> void:
		if body == _carrier:
			_carrier = null
	)


func _process(delta: float) -> void:
	_time += delta
	if arrow != null:
		arrow.position.y = 0.5 + sin(_time * 3.4) * 0.12
	if ring != null:
		var pulse: float = 1.0 + sin(_time * 3.0) * 0.05
		ring.scale = Vector3(pulse, 1.0, pulse)
	if _carrier == null or not enabled:
		_held = 0.0
		return
	_held += delta
	if _held >= hold_time:
		# Keep asking while the baker stands here: the ship may still be sailing in.
		_held = 0.0
		boarded.emit()
