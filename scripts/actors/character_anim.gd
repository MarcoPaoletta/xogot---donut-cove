class_name CharacterAnim
extends AnimationTree
## Drives the blend tree of a rigged character (bunnies and pirates) so clips
## always blend and never snap.
##
## The tree resource is authored (`assets/anim/*.tres`): a `Loco` blend space
## by speed, an optional `Hold` blend space for the carrying clips mixed in by
## `Carry`, and one `Shot_<Clip>` one shot per contact clip. This script only
## moves the parameters toward their targets.

@export var has_hold: bool = false
## Seconds for a full change between idle and run.
@export var locomotion_blend_time: float = 0.3
## Seconds to blend into and out of the carrying pose.
@export var hold_blend_time: float = 0.75
@export var loop_clips: PackedStringArray = PackedStringArray([
	"Idle", "Walk", "Run", "Idle_Holding", "Walk_Holding", "Run_Holding",
	"Swim", "Swim_Fast", "Tentacle_Idle", "Sitting_Idle", "Sitting_Eating"])

var _speed: float = 0.0
var _speed_target: float = 0.0
var _hold: float = 0.0
var _hold_target: float = 0.0


func _ready() -> void:
	var player: AnimationPlayer = get_node_or_null(anim_player) as AnimationPlayer
	if player != null:
		for clip: String in loop_clips:
			if player.has_animation(clip):
				player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	active = true


func _process(delta: float) -> void:
	_speed = move_toward(_speed, _speed_target, delta / maxf(locomotion_blend_time, 0.01))
	set(&"parameters/Loco/blend_position", _speed)
	if has_hold:
		_hold = move_toward(_hold, _hold_target, delta / maxf(hold_blend_time, 0.01))
		set(&"parameters/Hold/blend_position", _speed)
		set(&"parameters/Carry/blend_amount", _hold)


## 0 is standing, 1 is the fastest clip.
func set_speed01(value: float) -> void:
	_speed_target = clampf(value, 0.0, 1.0)


func set_holding(value: bool) -> void:
	_hold_target = 1.0 if value else 0.0


## Plays a contact clip (`Yes`, `Wave`, `No`, `HitReact`) over the locomotion.
func fire(clip: StringName) -> void:
	set("parameters/Shot_%s/request" % clip, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
