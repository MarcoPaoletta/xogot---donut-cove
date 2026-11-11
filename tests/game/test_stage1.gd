extends RefCounted
## Behaviour check of the Stage 1 loop: scoop, serve, collect the cash, buy pad 1.
## Run with: xo project run --wait ; xo game eval --file tests/game/test_stage1.gd --timeout 60

var tree: SceneTree
var root: Window


func _check(name: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("" if detail == "" else ": " + detail))


func _run() -> void:
	var main: Game = tree.current_scene as Game
	var baker: Baker = main.baker
	var stack: CarryStack = baker.get_carry_stack()
	_check("start cash", Wallet.cash == 60, str(Wallet.cash))
	_check("muted at boot", AudioServer.is_bus_mute(0))
	_check("arrow points at the oven", main.arrow.target == main.first_oven.pickup_zone)
	baker.teleport(Vector3(-5.3, 0.05, -4.6), PI)
	await tree.create_timer(2.0).timeout
	_check("stack filled from the rack", stack.count() >= 4, str(stack.count()))
	_check("arrow points at the counter", main.arrow.target == main.counter.serve_zone)
	baker.teleport(Vector3(2.18, 0.05, 1.55), 0.0)
	await tree.create_timer(3.0).timeout
	_check("donuts served", stack.count() < 4 or Wallet.stat(&"donuts_sold") > 0, "sold %d" % Wallet.stat(&"donuts_sold"))
	baker.teleport(Vector3(1.56, 0.05, 0.77), 0.0)
	await tree.create_timer(2.5).timeout
	_check("cash collected", Wallet.cash > 60, str(Wallet.cash))
	var pad: UnlockPad = main.pad(&"oven2")
	_check("pad 1 offered", pad.available)
	var before: int = Wallet.cash
	baker.teleport(pad.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	await tree.create_timer(3.0).timeout
	_check("pad 1 bought", pad.done, "paid from %d to %d" % [before, Wallet.cash])
	_check("pad drained exactly its price", before - Wallet.cash == 40, str(before - Wallet.cash))
	var oven2: Oven = main.get_node("Ovens/Oven2") as Oven
	await tree.create_timer(1.0).timeout
	_check("oven 2 revealed and baking", oven2.visible and oven2.active)
	_check("chocolate can be ordered", main.counter.queue.kinds.has(&"chocolate"))
	print("purchases ", main.purchase_log)
