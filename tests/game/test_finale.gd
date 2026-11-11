extends RefCounted
## Behaviour check of the title, the pause screen and the finale.
## Run with: xo project run --wait ; xo game eval --file tests/game/test_finale.gd --timeout 60

var tree: SceneTree
var root: Window


func _check(name: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("" if detail == "" else ": " + detail))


func _run() -> void:
	var main: Game = tree.current_scene as Game
	var title: TitleScreen = main.title as TitleScreen
	_check("boots to the title", main.mode == Game.Mode.TITLE and title.visible and not main.playing)
	_check("HUD hidden on the title", not main.hud.root_control.visible)
	_check("muted at boot", AudioServer.is_bus_mute(0))
	_check("title camera is the director's", root.get_camera_3d() == title.director.camera)
	title.start_button.pressed.emit()
	await tree.create_timer(0.8).timeout
	_check("Start begins the session", main.playing and main.mode == Game.Mode.ISLAND and main.hud.root_control.visible)
	_check("stall camera after Start", root.get_camera_3d() == main.island_camera.camera)
	var pause: PauseMenu = main.get_node("Screens/Pause") as PauseMenu
	pause.open()
	await tree.create_timer(0.4, true).timeout
	_check("pause stops the tree", tree.paused and pause.visible)
	pause.mute_button.pressed.emit()
	_check("mute toggles from the pause screen", not AudioServer.is_bus_mute(0))
	pause.mute_button.pressed.emit()
	pause.close()
	await tree.create_timer(0.4, true).timeout
	_check("resume", not tree.paused and not pause.visible)
	main.flags[&"first_voyage"] = true
	main.flags[&"kraken_won"] = true
	Wallet.add(9000)
	for i in 12:
		main.debug_unlock_next()
	await tree.create_timer(1.0).timeout
	_check("every pad bought", main.next_pad() == null, str(main.purchase_log.size()))
	_check("the house stands", (main.house as Node3D).visible)
	await tree.create_timer(5.2).timeout
	var card: EndCard = main.end_card as EndCard
	_check("end card opens", card.visible, card.stats_label.text.replace("\n", " | "))
	card.keep_button.pressed.emit()
	await tree.create_timer(0.5).timeout
	_check("keep playing returns control", not card.visible and main.baker.control_enabled)
