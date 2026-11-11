class_name Sea
extends Node3D
## The sea: one water plane with the water shader. This node owns the wave
## clock (the `sea_time` shader global) and answers how high the water is at a
## point, so everything that floats bobs on the same waves the shader draws.

const WAVE_LENGTH: float = 14.0
const WAVE_HEIGHT: float = 0.10

static var time: float = 0.0
## World height of the calm water surface.
static var level: float = -0.35


func _ready() -> void:
	level = global_position.y


func _process(delta: float) -> void:
	time += delta
	RenderingServer.global_shader_parameter_set(&"sea_time", time)


## Height of the water surface at a world position (same formula as the shader).
static func height_at(x: float, z: float) -> float:
	var k: float = TAU / WAVE_LENGTH
	var w: float = sin(x * k + time * 1.1) * 0.6 + sin(z * k * 1.3 - time * 0.9) * 0.4 + sin((x + z) * k * 0.6 + time * 0.6) * 0.3
	return level + w * WAVE_HEIGHT
