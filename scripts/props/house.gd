class_name DonutHouse
extends Node3D
## The Captain's Donut House, the last purchase. When it pops in, the pirate
## flag climbs its pole and the sign lights up. The model, the pole, the flag
## and the sign are authored in `donut_house.tscn`.

@export var flag: Node3D
@export var flag_top: float = 5.2
@export var flag_bottom: float = 1.0
@export var sign_light: OmniLight3D
@export var sign_donut: Node3D

var _time: float = 0.0
var _open: bool = false


func _ready() -> void:
	if flag != null:
		flag.position.y = flag_bottom


func _process(delta: float) -> void:
	_time += delta
	if sign_donut != null:
		sign_donut.rotation.y += delta * 0.8
	if flag != null and _open:
		flag.rotation.y = sin(_time * 2.4) * 0.25


func on_unlocked() -> void:
	_open = true
	if flag != null:
		var tween: Tween = create_tween()
		tween.tween_interval(0.6)
		tween.tween_property(flag, "position:y", flag_top, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if sign_light != null:
		var rest: float = sign_light.light_energy
		sign_light.light_energy = 0.0
		create_tween().tween_property(sign_light, "light_energy", rest, 1.2)
