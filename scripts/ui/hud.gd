class_name Hud
extends CanvasLayer
## The in game HUD: the coin counter and the coin flights on the island, plus
## the cannonball row, the hold and the hull bar at sea. Everything else the
## island needs is shown by the world itself.
##
## All controls are authored in `hud.tscn`; this script shows, hides and fills.

@export var coin_flight: HudCoinFlight
@export var root_control: Control
@export var sea_panel: Control
@export var ammo_row: Control
@export var hold_label: Label
@export var hull_bar: ProgressBar
@export var fade_rect: ColorRect
@export var mute_icon: Control
@export var mute_slash: Control

var _ship: Ship = null
var _fade: Tween = null
var _hidden_by_key: bool = false


func _ready() -> void:
	if sea_panel != null:
		sea_panel.visible = false
	if fade_rect != null:
		fade_rect.modulate.a = 0.0
		fade_rect.visible = false
	Audio.mute_changed.connect(_on_mute_changed)
	_on_mute_changed(Audio.muted)


## Flies `amount` as coins from a world position to the counter. The wallet
## only grows as the coins land.
static func collect_coins(context: Node, at: Vector3, amount: int) -> void:
	if context == null or not context.is_inside_tree():
		return
	var hud: Hud = context.get_tree().get_first_node_in_group(&"hud") as Hud
	if hud != null and hud.coin_flight != null and hud.root_control.visible:
		hud.coin_flight.collect(at, amount)
	else:
		Wallet.add(amount, at)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"hide_hud") and root_control != null:
		_hidden_by_key = not _hidden_by_key
		root_control.modulate.a = 0.0 if _hidden_by_key else 1.0


## Shows or hides the whole HUD (the title hides it).
func show_hud(show_it: bool) -> void:
	if root_control != null:
		root_control.visible = show_it


## Switches the sea widgets on and binds them to the ship.
func show_sea(show_it: bool) -> void:
	if sea_panel == null:
		return
	if show_it and _ship == null:
		_ship = get_tree().get_first_node_in_group(&"ship") as Ship
		if _ship != null:
			_ship.ammo_changed.connect(_on_ammo)
			_ship.hull_changed.connect(_on_hull)
			_ship.hold_changed.connect(_on_hold)
	if show_it and _ship != null:
		_on_ammo(_ship.ammo, _ship.ammo_max)
		_on_hull(_ship.hull, _ship.hull_max)
		_on_hold(_ship.hold)
	sea_panel.visible = show_it
	if show_it:
		sea_panel.pivot_offset = sea_panel.size * 0.5
		sea_panel.scale = Vector2.ONE * 0.6
		create_tween().tween_property(sea_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Fades the whole screen to black (1) or back (0). Awaitable.
func fade(alpha: float, time: float) -> void:
	if fade_rect == null:
		return
	fade_rect.visible = true
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(fade_rect, "modulate:a", alpha, time)
	await _fade.finished
	if alpha <= 0.0:
		fade_rect.visible = false


func _on_ammo(ammo: int, _ammo_max: int) -> void:
	if ammo_row == null:
		return
	for i in ammo_row.get_child_count():
		var ball: Control = ammo_row.get_child(i) as Control
		var loaded: bool = i < ammo
		var was: bool = ball.modulate.a > 0.9
		ball.modulate.a = 1.0 if loaded else 0.28
		if loaded and not was:
			ball.pivot_offset = ball.size * 0.5
			ball.scale = Vector2.ONE * 1.4
			ball.create_tween().tween_property(ball, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_hull(hull: float, hull_max: float) -> void:
	if hull_bar == null:
		return
	hull_bar.max_value = hull_max
	create_tween().tween_property(hull_bar, "value", hull, 0.2)


func _on_hold(loot: int) -> void:
	if hold_label == null:
		return
	hold_label.text = MoneyCounter.format_number(loot)
	hold_label.pivot_offset = hold_label.size * 0.5
	hold_label.scale = Vector2.ONE * 1.25
	hold_label.create_tween().tween_property(hold_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_mute_changed(muted: bool) -> void:
	if mute_slash != null:
		mute_slash.visible = muted
	if mute_icon != null:
		mute_icon.pivot_offset = mute_icon.size * 0.5
		mute_icon.scale = Vector2.ONE * 1.2
		mute_icon.create_tween().tween_property(mute_icon, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
