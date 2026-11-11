class_name EndCard
extends CanvasLayer
## The end card: a celebration, not a game over. Shows the session numbers and
## returns to the island with "Keep playing".

@export var root_control: Control
@export var panel: Control
@export var stats_label: Label
@export var keep_button: Button


func _ready() -> void:
	visible = false
	keep_button.pressed.connect(close)


func open(game: Game) -> void:
	var seconds: int = int(game.session_time)
	var best: float = float(GameSettings.get_value("best_time", 0.0))
	if best <= 0.0 or game.session_time < best:
		GameSettings.set_value("best_time", snappedf(game.session_time, 0.1))
	stats_label.text = "Coins earned: %s\nDonuts sold: %s\nSharks sent under: %d\nTentacles sent under: %d\nTime: %d:%02d" % [
		MoneyCounter.format_number(Wallet.lifetime_earned), MoneyCounter.format_number(Wallet.stat(&"donuts_sold")),
		Wallet.stat(&"sharks"), Wallet.stat(&"tentacles"), floori(float(seconds) / 60.0), seconds % 60]
	visible = true
	root_control.modulate.a = 0.0
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ONE * 0.7
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(root_control, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	keep_button.grab_focus()
	if game.baker != null:
		game.baker.control_enabled = false


func close() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: visible = false)
	var game: Game = get_tree().get_first_node_in_group(&"game") as Game
	if game != null and game.baker != null and game.mode == Game.Mode.ISLAND:
		game.baker.control_enabled = true
