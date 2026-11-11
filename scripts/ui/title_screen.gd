class_name TitleScreen
extends CanvasLayer
## The title: the live island behind, toured by the menu camera director, with
## the logo and the Start and Quit buttons. Start fades to the stall camera.

@export var root_control: Control
@export var fade_rect: ColorRect
@export var start_button: Button
@export var quit_button: Button
@export var logo: Control
@export var director: MenuCameraDirector

var _game: Game = null
var _time: float = 0.0


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	fade_rect.visible = false


func _process(delta: float) -> void:
	_time += delta
	if logo != null and visible:
		logo.rotation = sin(_time * 1.3) * 0.015
		logo.scale = Vector2.ONE * (1.0 + sin(_time * 2.0) * 0.012)


func open(game: Game) -> void:
	_game = game
	visible = true
	root_control.modulate.a = 0.0
	create_tween().tween_property(root_control, "modulate:a", 1.0, 0.5)
	if director != null:
		director.active = true
		director.make_current()
	start_button.grab_focus()
	Audio.play_music(&"island")
	GameSettings.apply_fullscreen(get_window())


## Hides the title. `instant` is for tests and the performance route.
func close(instant: bool) -> void:
	if director != null:
		director.active = false
	if instant:
		visible = false
		return
	var tween: Tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: visible = false)


func _on_start() -> void:
	if _game == null:
		return
	start_button.disabled = true
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.2)
	tween.tween_callback(func() -> void:
		root_control.visible = false
		_game.start_game(false)
	)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void: visible = false)
