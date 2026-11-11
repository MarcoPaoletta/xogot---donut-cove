class_name UnlockPad
extends Area3D
## The glowing buy square. The baker stands on it and coins drain out of the
## wallet into the pad, slowly at first and then faster, while the price counts
## down. At zero the purchase pops into the world.
##
## Authored in `unlock_pad.tscn`: the plate, the fill and the price pill. The
## level adds a child named `Ghost`: the mint hologram of what the pad buys. What the pad buys is placed in the level, hidden, and tagged
## with the group `reveal_<pad_id>`; this script only drains, reports and
## reveals.

signal progress_changed(paid: int, price: int)
signal unlocked(pad: UnlockPad)

@export var pad_id: StringName = &""
@export var price: int = 100
## Cash per second at the first moment of standing on the pad.
@export var pay_rate_start: float = 30.0
## The rate multiplies up to this while the baker keeps standing there.
@export var pay_rate_boost: float = 8.0
@export var boost_time: float = 1.4
@export var coin_scene: PackedScene
@export var coin_interval: float = 0.05
@export var price_label: Label3D
@export var price_pill: Node3D
@export var fill: Node3D

## False while the pad waits for its turn in the sequence.
var available: bool = false
var done: bool = false

var _paid: int = 0
var _carrier: Node3D = null
var _held: float = 0.0
var _accumulator: float = 0.0
var _coin_cooldown: float = 0.0
var _poor_notified: bool = false
var _rest_scale: Vector3 = Vector3.ONE
var _time: float = 0.0
var _ghost: Node3D = null
var _ghost_y: float = 0.0


func _ready() -> void:
	_rest_scale = scale
	_ghost = get_node_or_null(^"Ghost") as Node3D
	if _ghost != null:
		_ghost_y = _ghost.position.y
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	visible = false
	monitoring = false
	for target: Node in get_tree().get_nodes_in_group(_group()):
		_lock(target as Node3D)
	_refresh()


func remaining() -> int:
	return price - _paid


## Shows the pad with a pop and lets it take money.
func offer() -> void:
	if done or available:
		return
	available = true
	monitoring = true
	scale = _rest_scale
	ItemFlight.pop_in(self, 0.4, 1.12)


## Completes the pad at once with its normal reveal (presenter panel).
func unlock_now() -> void:
	if done:
		return
	_paid = price
	_refresh()
	_complete()


func _process(delta: float) -> void:
	_time += delta
	if _ghost != null and available:
		_ghost.position.y = _ghost_y + 0.1 + sin(_time * 2.2) * 0.06
	if _carrier == null or done or not available:
		return
	if Wallet.cash <= 0:
		if not _poor_notified:
			_poor_notified = true
			_reject()
		return
	_held += delta
	var boost: float = lerpf(1.0, pay_rate_boost, ease(clampf(_held / boost_time, 0.0, 1.0), 2.0))
	_accumulator += pay_rate_start * boost * delta
	var chunk: int = mini(int(_accumulator), remaining())
	chunk = mini(chunk, Wallet.cash)
	if chunk <= 0:
		return
	_accumulator -= float(chunk)
	if not Wallet.try_spend(chunk):
		return
	_paid += chunk
	_refresh()
	progress_changed.emit(_paid, price)
	_spawn_coin(delta)
	if _paid >= price:
		_complete()


func _group() -> StringName:
	return StringName("reveal_" + String(pad_id))


func _refresh() -> void:
	if price_label != null:
		price_label.text = MoneyCounter.format_number(remaining())
	if fill != null:
		var progress: float = clampf(float(_paid) / float(maxi(price, 1)), 0.0, 1.0)
		fill.visible = progress > 0.0
		fill.scale = Vector3(maxf(progress, 0.02), 1.0, maxf(progress, 0.02))


func _spawn_coin(delta: float) -> void:
	_coin_cooldown -= delta
	if coin_scene == null or _coin_cooldown > 0.0 or _carrier == null:
		return
	_coin_cooldown = coin_interval
	var coin: Node3D = coin_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(coin)
	coin.global_position = _carrier.global_position + Vector3.UP * 1.4
	coin.scale = Vector3.ONE * 0.8
	var center: Vector3 = global_position + Vector3.UP * 0.25
	ItemFlight.fly(coin, func() -> Vector3: return center, 0.3, 0.6, 1.0, func(landed: Node3D) -> void:
		if is_instance_valid(landed):
			landed.queue_free()
	)
	var progress: float = float(_paid) / float(maxi(price, 1))
	Audio.play(&"pad_tick", 0.9 + progress * 0.9, -7.0)
	if price_pill != null:
		ItemFlight.squash(price_pill, 0.08, 0.1)


func _reject() -> void:
	Audio.play_varied(&"reject", 0.05)
	Wallet.rejected.emit(remaining())
	if price_pill == null:
		return
	var tween: Tween = create_tween()
	var rest: Vector3 = price_pill.position
	for i in 4:
		var side: float = 0.12 if i % 2 == 0 else -0.12
		tween.tween_property(price_pill, "position:x", rest.x + side, 0.04)
	tween.tween_property(price_pill, "position:x", rest.x, 0.05)


func _complete() -> void:
	done = true
	available = false
	_carrier = null
	set_deferred(&"monitoring", false)
	Audio.play(&"unlock")
	Audio.duck()
	var first: Node3D = null
	var stagger: float = 0.0
	for node: Node in get_tree().get_nodes_in_group(_group()):
		var target: Node3D = node as Node3D
		if target == null:
			continue
		if first == null:
			first = target
		get_tree().create_timer(stagger).timeout.connect(_reveal.bind(target))
		stagger += 0.08
	var focus: Vector3 = first.global_position if first != null else global_position
	var camera: IslandCamera = get_tree().get_first_node_in_group(&"game_camera") as IslandCamera
	if camera != null:
		if not camera.sees(focus):
			camera.focus_beat(focus)
		camera.add_trauma(0.3)
		camera.fov_kick(3.0, 0.45)
	Fx.burst(Fx.CONFETTI, self, global_position + Vector3.UP * 0.4)
	unlocked.emit(self)
	var shrink: Tween = create_tween()
	shrink.tween_interval(0.2)
	shrink.tween_property(self, "scale", _rest_scale * 0.01, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	shrink.tween_callback(func() -> void: visible = false)


func _lock(target: Node3D) -> void:
	if target == null:
		return
	target.visible = false
	target.process_mode = Node.PROCESS_MODE_DISABLED


func _reveal(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	target.process_mode = Node.PROCESS_MODE_INHERIT
	ItemFlight.pop_in(target, 0.42, 1.15)
	Fx.burst(Fx.DUST_RING, self, target.global_position + Vector3.UP * 0.15)
	Fx.burst(Fx.CONFETTI, self, target.global_position + Vector3.UP * 1.2)
	if target.has_method(&"on_unlocked"):
		target.call(&"on_unlocked")


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player") and not done:
		_carrier = body
		_held = 0.0
		_poor_notified = false


func _on_body_exited(body: Node3D) -> void:
	if body == _carrier:
		_carrier = null
