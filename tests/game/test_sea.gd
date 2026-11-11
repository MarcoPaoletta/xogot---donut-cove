extends RefCounted
## Behaviour check of the sea: boarding and docking cycles, sailing, cannons,
## sharks and tentacles taking hits and dropping loot, the hold unloading at
## the dock, the hull reaching zero, and the Kraken.
## Run with: xo project run --wait ; xo game eval --file tests/game/test_sea.gd --timeout 400

var tree: SceneTree
var root: Window


func _check(name: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("" if detail == "" else ": " + detail))


func _wait(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


func _board(main: Game) -> void:
	main.baker.teleport(main.boarding_pad.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	var waited: float = 0.0
	while main.mode != Game.Mode.SEA and waited < 4.0:
		await _wait(0.1)
		waited += 0.1


func _run() -> void:
	var main: Game = tree.current_scene as Game
	main.start_game(true)
	Wallet.add(6000)
	for i in 9:
		main.debug_unlock_next()
	await _wait(0.5)
	var ship: Ship = main.ship
	ship.snap_to_mooring()
	_check("ship bought and moored", ship.visible and main.is_bought(&"ship"))
	_check("boarding pad shown", main.boarding_pad.visible)

	# Ten boarding and docking cycles.
	var cycles: int = 0
	for i in 10:
		await _board(main)
		if main.mode != Game.Mode.SEA:
			break
		await _wait(0.6)
		ship.request_dock()
		var waited: float = 0.0
		while main.mode != Game.Mode.ISLAND and waited < 4.0:
			await _wait(0.1)
			waited += 0.1
		if main.mode == Game.Mode.ISLAND and main.baker.visible and main.baker.control_enabled:
			cycles += 1
		main.baker.teleport(Vector3(-1.0, 0.05, -1.6), 0.0)
		await _wait(0.3)
	_check("ten boarding and docking cycles", cycles == 10, str(cycles))
	_check("double cannons pad offered after the first voyage", main.pad(&"double_cannons").available)

	# A voyage on autopilot: sail, fire, collect.
	await _board(main)
	_check("sea camera is current", root.get_camera_3d() == main.sea_camera.camera or root.get_camera_3d() == main.blend_camera)
	ship.autopilot = true
	ship.god_mode = true
	Engine.time_scale = 3.0
	var cash_before: int = Wallet.cash
	var sailed_from: Vector3 = ship.global_position
	var far: float = 0.0
	var elapsed: float = 0.0
	while elapsed < 75.0 and (Wallet.stat(&"sharks") < 1 or Wallet.stat(&"tentacles") < 1 or ship.hold < 150):
		await _wait(1.0)
		elapsed += 1.0
		far = maxf(far, ship.global_position.distance_to(sailed_from))
	_check("the ship sailed away from the dock", far > 30.0, "%.0f m" % far)
	_check("a shark went down", Wallet.stat(&"sharks") >= 1, str(Wallet.stat(&"sharks")))
	_check("a tentacle went down", Wallet.stat(&"tentacles") >= 1, str(Wallet.stat(&"tentacles")))
	_check("loot reached the hold", ship.hold > 0, str(ship.hold))
	var hold: int = ship.hold
	Engine.time_scale = 1.0
	ship.autopilot = false
	ship.request_dock()
	await _wait(4.5)
	_check("the hold unloads into the wallet at the dock", Wallet.cash == cash_before + hold and hold > 0, "%d + %d = %d" % [cash_before, hold, Wallet.cash])
	_check("Kraken is ready after a voyage of 150 or more", main.kraken_ready == (hold >= 150), "hold %d" % hold)

	# The hull reaches zero: limp home with half the loot.
	main.baker.teleport(Vector3(-1.0, 0.05, -1.6), 0.0)
	await _wait(0.3)
	main.kraken_ready = false
	await _board(main)
	ship.god_mode = false
	ship.add_loot(100)
	ship.global_position += Vector3(30.0, 0.0, -30.0)
	ship.damage(60.0)
	ship.damage(60.0)
	await _wait(2.5)
	_check("hull at zero limps home to the island", main.mode == Game.Mode.ISLAND and is_equal_approx(ship.hull, ship.hull_max))
	await _wait(2.5)

	# The Kraken.
	main.baker.teleport(Vector3(-1.0, 0.05, -1.6), 0.0)
	await _wait(0.3)
	await _board(main)
	ship.autopilot = true
	ship.god_mode = true
	main.debug_start_kraken()
	await _wait(0.5)
	_check("the Kraken rises", main.sea_life.kraken_active)
	Engine.time_scale = 4.0
	elapsed = 0.0
	while elapsed < 150.0 and not main.kraken_done:
		await _wait(1.0)
		elapsed += 1.0
	Engine.time_scale = 1.0
	_check("the Kraken can be won", main.kraken_done, "%.0f s of game time" % elapsed)
	await _wait(1.0)
	_check("the golden chest floats", tree.get_nodes_in_group(&"loot").size() > 0)
	ship.autopilot = false
	ship.request_dock()
	await _wait(2.0)
	_check("the Kraken flag opens the house pad", main.flags.has(&"kraken_won"))
	print("stats sharks %d tentacles %d cash %d" % [Wallet.stat(&"sharks"), Wallet.stat(&"tentacles"), Wallet.cash])
