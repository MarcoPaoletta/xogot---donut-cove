class_name JuicyButton
extends Button
## A button that tweens on hover (1.06) and press (0.97) and ticks. The look
## comes from the project theme; this script only animates.

@export var hover_scale: float = 1.06
@export var press_scale: float = 0.97

var _tween: Tween = null


func _ready() -> void:
	mouse_entered.connect(func() -> void: _to(hover_scale); Audio.play(&"ui_hover", 1.0, -10.0))
	mouse_exited.connect(func() -> void: _to(1.0))
	focus_entered.connect(func() -> void: _to(hover_scale))
	focus_exited.connect(func() -> void: _to(1.0))
	button_down.connect(func() -> void: _to(press_scale))
	button_up.connect(func() -> void: _to(hover_scale if is_hovered() else 1.0))
	pressed.connect(func() -> void: Audio.play(&"ui_click"))


func _to(value: float) -> void:
	pivot_offset = size * 0.5
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * value, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
