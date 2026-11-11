class_name Statue
extends Node3D
## The pirate statue: the skeleton model frozen on one frame of a clip, on a
## plinth. The model and the plinth are authored in `statue.tscn`.

@export var animation_player: AnimationPlayer
@export var clip: StringName = &"Sword"
## Where in the clip the pose is taken, in seconds.
@export var pose_time: float = 0.35


func _ready() -> void:
	if animation_player == null or not animation_player.has_animation(clip):
		return
	animation_player.play(clip)
	animation_player.seek(pose_time, true)
	animation_player.pause()
