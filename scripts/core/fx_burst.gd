class_name FxBurst
extends Node3D
## A one shot effect scene: restarts every particle child when it enters the
## tree and frees itself when the longest one is done.

@export var life: float = 1.5


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for child: Node in get_children():
		if child is GPUParticles3D:
			(child as GPUParticles3D).restart()
			(child as GPUParticles3D).emitting = true
	get_tree().create_timer(life).timeout.connect(queue_free)
