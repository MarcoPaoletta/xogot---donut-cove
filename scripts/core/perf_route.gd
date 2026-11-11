extends Node3D
## The performance route (GDD Section 15). Instances the real main scene with
## everything unlocked and flies a camera through the authored waypoints for
## 40 s at 1920 by 1080 with the frame cap and vsync off, sampling the
## `Performance` monitors every frame after a warm up.
##
## Prints one `PERF_ROW|...` line and writes the raw samples to
## `user://perf/perf_<label>.csv`. The waypoints are `Marker3D` children of
## `Waypoints`, each one a camera pose; the route passes them at equal times.

@export var label: String = "run"
@export var duration: float = 40.0
@export var warmup: float = 3.0
@export var camera: Camera3D
@export var waypoints: Node3D
@export var main: Node

var _time: float = 0.0
var _last_usec: int = 0
var _frame_ms: PackedFloat32Array = PackedFloat32Array()
var _draws: PackedInt32Array = PackedInt32Array()
var _tris: PackedInt32Array = PackedInt32Array()
var _vram: float = 0.0
var _done: bool = false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_window().size = Vector2i(1920, 1080)
	camera.current = true
	await get_tree().create_timer(0.5).timeout
	if main != null and main.has_method(&"perf_prepare"):
		main.call(&"perf_prepare")
	camera.current = true
	_last_usec = Time.get_ticks_usec()


func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	var now: int = Time.get_ticks_usec()
	var frame: float = float(now - _last_usec) / 1000.0
	_last_usec = now
	_fly(clampf(_time / (warmup + duration), 0.0, 1.0))
	camera.current = true
	if _time < warmup:
		return
	_frame_ms.append(frame)
	_draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_tris.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	_vram = maxf(_vram, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	if _time >= warmup + duration:
		_finish()


func _fly(t: float) -> void:
	var count: int = waypoints.get_child_count()
	if count == 0:
		return
	var at: float = t * float(count - 1)
	var index: int = mini(int(at), count - 2) if count > 1 else 0
	var a: Node3D = waypoints.get_child(index) as Node3D
	var b: Node3D = waypoints.get_child(mini(index + 1, count - 1)) as Node3D
	var f: float = smoothstep(0.0, 1.0, at - float(index))
	camera.global_transform = a.global_transform.interpolate_with(b.global_transform, f)


func _finish() -> void:
	_done = true
	var sorted_ms: Array = Array(_frame_ms)
	sorted_ms.sort()
	var total: float = 0.0
	for ms: float in sorted_ms:
		total += ms
	var frames: int = sorted_ms.size()
	var avg_fps: float = 1000.0 * float(frames) / maxf(total, 0.001)
	var slow_count: int = maxi(frames / 100, 1)
	var slow_total: float = 0.0
	for i in slow_count:
		slow_total += float(sorted_ms[frames - 1 - i])
	var low_fps: float = 1000.0 * float(slow_count) / maxf(slow_total, 0.001)
	var p95: float = float(sorted_ms[mini(int(float(frames) * 0.95), frames - 1)])
	var max_draws: int = 0
	var max_tris: int = 0
	for value: int in _draws:
		max_draws = maxi(max_draws, value)
	for value: int in _tris:
		max_tris = maxi(max_tris, value)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://perf"))
	var file: FileAccess = FileAccess.open("user://perf/perf_%s.csv" % label, FileAccess.WRITE)
	if file != null:
		file.store_line("frame_ms,draw_calls,triangles")
		for i in _frame_ms.size():
			file.store_line("%.3f,%d,%d" % [_frame_ms[i], _draws[i], _tris[i]])
		file.close()
	print("PERF_ROW|%s|%.0f|%.0f|%.2f|%d|%d|%.0f|%d" % [label, avg_fps, low_fps, p95, max_draws, max_tris, _vram / 1048576.0, frames])
