extends Node
## Autoload `Audio`. Boot mute, the mute toggle on `M`, pooled one shot sounds
## and the music player.
##
## The Master bus is muted when the game boots and `toggle_mute` flips it on
## every screen. The players are authored in `audio.tscn`; this script only
## picks a free one. Sounds are looked up by name in `res://assets/audio/sfx/`
## and music in `res://assets/audio/music/`, so callers never hold streams.

signal mute_changed(muted: bool)

const SFX_DIR: String = "res://assets/audio/sfx/"
const MUSIC_DIR: String = "res://assets/audio/music/"

var muted: bool = true

var _streams: Dictionary = {}
var _next: int = 0
var _music_name: StringName = &""
var _duck: Tween = null

@onready var _music: AudioStreamPlayer = $Music
@onready var _ambience: AudioStreamPlayer = $Ambience
@onready var _pool: Node = $Pool


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_muted(true)
	var waves: AudioStream = _stream(MUSIC_DIR, &"ambience")
	if waves != null and _ambience != null:
		_loop(waves)
		_ambience.stream = waves
		_ambience.play()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_mute"):
		set_muted(not muted)
		get_viewport().set_input_as_handled()


func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(0, muted)
	mute_changed.emit(muted)


## Plays a one shot by file name (without extension). Unknown names are
## silent, so gameplay can be written before the sound exists.
func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _stream(SFX_DIR, sound)
	if stream == null or _pool.get_child_count() == 0:
		return
	var player: AudioStreamPlayer = _pool.get_child(_next) as AudioStreamPlayer
	_next = (_next + 1) % _pool.get_child_count()
	player.stream = stream
	player.pitch_scale = clampf(pitch, 0.3, 3.0)
	player.volume_db = volume_db
	player.play()


## `play` with a little random pitch, for physical sounds.
func play_varied(sound: StringName, spread: float = 0.08, volume_db: float = 0.0) -> void:
	play(sound, randf_range(1.0 - spread, 1.0 + spread), volume_db)


## Cross fades to a music loop by file name. Empty stops the music.
func play_music(track: StringName, fade: float = 0.8) -> void:
	if track == _music_name:
		return
	_music_name = track
	var stream: AudioStream = _stream(MUSIC_DIR, track)
	var tween: Tween = create_tween()
	tween.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	tween.tween_callback(func() -> void:
		_music.stream = stream
		if stream != null:
			_loop(stream)
			_music.play()
		else:
			_music.stop()
	)
	tween.tween_property(_music, "volume_db", -8.0, fade * 0.5)


## Dips the music for a moment so a fanfare reads.
func duck(depth_db: float = -9.0, time: float = 1.2) -> void:
	if _duck != null and _duck.is_valid():
		_duck.kill()
	var bus: int = AudioServer.get_bus_index(&"Music")
	if bus < 0:
		return
	_duck = create_tween()
	_duck.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v), 0.0, depth_db, 0.12)
	_duck.tween_interval(time * 0.5)
	_duck.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v), depth_db, 0.0, time * 0.5)


func _loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _stream(dir: String, sound: StringName) -> AudioStream:
	if sound == &"":
		return null
	var key: String = dir + String(sound)
	if _streams.has(key):
		return _streams[key] as AudioStream
	var found: AudioStream = null
	for ext: String in [".ogg", ".wav"]:
		if ResourceLoader.exists(key + ext):
			found = load(key + ext) as AudioStream
			break
	_streams[key] = found
	return found
