class_name PresenterPanel
extends CanvasLayer
## The F1 presenter panel for recording: coins, the next pad, the rare
## captain, full racks, the Kraken, loot, time scale, a god mode for the hull
## and a fresh start. Every action plays the feedback the game normally plays.
## Hidden by default; it works in the exported build too.

@export var root_control: Control
@export var buttons: Control
@export var time_button: Button
@export var god_button: Button

var _time_scales: Array[float] = [1.0, 2.0, 4.0]
var _time_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for child: Node in buttons.get_children():
		var button: Button = child as Button
		if button != null:
			button.pressed.connect(_on_pressed.bind(button.name))


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_panel"):
		visible = not visible
		get_viewport().set_input_as_handled()
		if visible:
			root_control.modulate.a = 0.0
			create_tween().tween_property(root_control, "modulate:a", 1.0, 0.15)


func _game() -> Game:
	return get_tree().get_first_node_in_group(&"game") as Game


func _on_pressed(action: StringName) -> void:
	var game: Game = _game()
	if game == null:
		return
	if not game.playing:
		game.start_game(true)
	var here: Vector3 = game.ship.global_position if game.mode == Game.Mode.SEA else game.baker.global_position
	match action:
		&"Coins100":
			Hud.collect_coins(self, here + Vector3.UP * 1.6, 100)
		&"Coins1000":
			Hud.collect_coins(self, here + Vector3.UP * 1.6, 1000)
			Fx.burst(Fx.COIN_BURST, self, here + Vector3.UP * 1.6)
		&"NextPad":
			game.debug_unlock_next()
		&"RareCaptain":
			if game.counter != null and game.counter.queue != null:
				game.counter.queue.spawn(true)
		&"FillRacks":
			game.debug_fill_racks()
		&"Kraken":
			game.debug_start_kraken()
			Fx.pop_number(self, here + Vector3.UP * 3.0, "KRAKEN!" if game.mode == Game.Mode.SEA else "KRAKEN NEXT VOYAGE", Fx.RARE, 1.2)
		&"Loot":
			if game.mode == Game.Mode.SEA:
				game.ship.add_loot(200)
				Fx.burst(Fx.COIN_BURST, self, here + Vector3.UP * 2.4)
				Fx.pop_number(self, here + Vector3.UP * 3.6, "+200", Fx.GOLD, 1.3)
			else:
				Hud.collect_coins(self, here + Vector3.UP * 1.6, 200)
		&"TimeScale":
			_time_index = (_time_index + 1) % _time_scales.size()
			Engine.time_scale = _time_scales[_time_index]
			time_button.text = "Time x%d" % int(_time_scales[_time_index])
		&"GodMode":
			game.ship.god_mode = not game.ship.god_mode
			god_button.text = "Hull god mode: on" if game.ship.god_mode else "Hull god mode: off"
		&"Erase":
			game.restart()
