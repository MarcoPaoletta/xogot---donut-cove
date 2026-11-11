class_name MoneyCounter
extends Label
## The HUD coin counter. The number never jumps: it rolls toward the real
## value, punches up when money lands and shakes red on a rejected purchase.
##
## Font, size and colours are set in the HUD scene; this script only animates.

@export var roll_speed: float = 10.0
@export var gain_color: Color = Color(0.3, 0.62, 0.2)
@export var loss_color: Color = Color(0.9, 0.25, 0.2)
@export var punch_scale: float = 1.18
## The control that punches (the whole pill), or this label when empty.
@export var punch_target: Control

var _shown: float = 0.0
var _target: int = 0
var _punch: Tween = null
var _flash: Tween = null
var _rest_color: Color = Color.WHITE


func _ready() -> void:
	if punch_target == null:
		punch_target = self
	_rest_color = self_modulate
	_target = Wallet.cash
	_shown = float(_target)
	Wallet.changed.connect(set_value)
	Wallet.rejected.connect(func(_amount: int) -> void: reject())
	_refresh()


func _process(delta: float) -> void:
	if is_equal_approx(_shown, float(_target)):
		return
	_shown = lerpf(_shown, float(_target), 1.0 - exp(-roll_speed * delta))
	if absf(_shown - float(_target)) < 0.5:
		_shown = float(_target)
	_refresh()


func set_value(value: int) -> void:
	var gained: bool = value > _target
	_target = value
	_tint(gain_color if gained else loss_color)
	if gained:
		_pop()


## The shake of a purchase that cannot be paid.
func reject() -> void:
	_tint(loss_color)
	_kill_punch()
	_punch = create_tween()
	for i in 4:
		var side: float = 1.0 if i % 2 == 0 else -1.0
		_punch.tween_property(punch_target, "rotation", side * 0.05, 0.04)
	_punch.tween_property(punch_target, "rotation", 0.0, 0.05)


## 2300 becomes "2,300".
static func format_number(value: int) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out


func _refresh() -> void:
	text = format_number(roundi(_shown))


func _pop() -> void:
	_kill_punch()
	punch_target.pivot_offset = punch_target.size * 0.5
	punch_target.scale = Vector2.ONE * punch_scale
	_punch = create_tween()
	_punch.tween_property(punch_target, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _kill_punch() -> void:
	if _punch != null and _punch.is_valid():
		_punch.kill()
	punch_target.rotation = 0.0


func _tint(color: Color) -> void:
	if _flash != null and _flash.is_valid():
		_flash.kill()
	self_modulate = color
	_flash = create_tween()
	_flash.tween_property(self, "self_modulate", _rest_color, 0.35).set_trans(Tween.TRANS_SINE)
