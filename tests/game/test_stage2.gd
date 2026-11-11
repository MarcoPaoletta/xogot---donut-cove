extends RefCounted
## Behaviour check of Stage 2: pads 2 to 8 are bought by standing on them, each
## reveal appears and works, and the helper serves on her own for 60 s.
## Run with: xo project run --wait ; xo game eval --file tests/game/test_stage2.gd --timeout 200

var tree: SceneTree
var root: Window


func _check(name: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + name + ("" if detail == "" else ": " + detail))


func _buy(main: Game, pad_id: StringName) -> bool:
	var pad: UnlockPad = main.pad(pad_id)
	if pad == null or not pad.available:
		return false
	Wallet.add(pad.remaining() + 5)
	main.baker.teleport(pad.global_position + Vector3(0.0, 0.05, 0.0), 0.0)
	var waited: float = 0.0
	while not pad.done and waited < 12.0:
		await tree.create_timer(0.2).timeout
		waited += 0.2
	main.baker.teleport(Vector3(-1.0, 0.05, -1.6), 0.0)
	await tree.create_timer(0.6).timeout
	return pad.done


func _run() -> void:
	var main: Game = tree.current_scene as Game
	main.start_game(true)
	var baker: Baker = main.baker
	var queue: CustomerQueue = main.counter.queue
	for pad_id: StringName in [&"oven2", &"display_case", &"backpack", &"oven3", &"statue", &"tables", &"helper", &"oven_speed"]:
		var bought: bool = await _buy(main, pad_id)
		_check("pad %s bought by standing" % pad_id, bought)
	_check("three flavors can be ordered", queue.kinds.size() == 3, str(queue.kinds))
	_check("queue has 6 slots", queue.open_slots == 6)
	_check("display case shown", (main.get_node("Counter/DisplayCase") as Node3D).visible)
	_check("capacity is 10", baker.carry_stack.capacity == 10)
	_check("statue shown", (main.get_node("Reveals/Statue") as Node3D).visible)
	_check("tips and rare customer on", is_equal_approx(queue.pay_multiplier, 1.2) and queue.rare_enabled)
	_check("tables shown and open", (main.get_node("Reveals/Table1") as TableSet).visible and (main.get_node("Reveals/Table1") as TableSet).open)
	var helper: Helper = main.get_node("Reveals/Helper") as Helper
	_check("helper shown", helper.visible)
	var fast: bool = true
	for node: Node in tree.get_nodes_in_group(&"ovens"):
		fast = fast and is_equal_approx((node as Oven).speed_multiplier, 1.4)
	_check("ovens bake 40 percent faster", fast)
	_check("next pad is the ship", main.next_pad() != null and main.next_pad().pad_id == &"ship")
	# The helper alone for 60 s of game time (the baker stands away from every zone).
	baker.teleport(Vector3(10.4, 0.05, -1.4), 0.0)
	var sold_before: int = Wallet.stat(&"donuts_sold")
	var moved: float = 0.0
	var last: Vector3 = helper.global_position
	var still: float = 0.0
	var longest_still: float = 0.0
	Engine.time_scale = 3.0
	var elapsed: float = 0.0
	while elapsed < 60.0:
		await tree.create_timer(0.5).timeout
		elapsed += 0.5
		var step: float = helper.global_position.distance_to(last)
		moved += step
		last = helper.global_position
		still = still + 0.5 if step < 0.02 else 0.0
		longest_still = maxf(longest_still, still)
	Engine.time_scale = 1.0
	var sold: int = Wallet.stat(&"donuts_sold") - sold_before
	_check("helper sold donuts on her own in 60 s", sold >= 8, "sold %d, walked %.0f m" % [sold, moved])
	_check("helper never stuck longer than 12 s", longest_still <= 12.0, "%.1f s" % longest_still)
	_check("coins wait on the cash tray", main.counter.cash_waiting() > 0, str(main.counter.cash_waiting()))
	var seated: int = (main.get_node("Reveals/Table1") as TableSet).ready_customers().size() + (main.get_node("Reveals/Table2") as TableSet).ready_customers().size()
	_check("pirates sit at the tables", seated > 0, str(seated))
	print("purchases ", main.purchase_log)
