class_name HudCoinFlight
extends Control
## Money that is felt: coins fly from where they were earned to the HUD
## counter, and the number only goes up as each coin lands.
##
## `collect()` splits an amount into a few coins, projects the world position
## to the screen, flies each coin on an arc to the counter and calls
## `Wallet.add` per coin as it lands, with a chime that climbs per coin.
## The coin is the saved `hud_coin.tscn`. Full rect, mouse filter ignore.

signal coin_landed(index: int, total: int)

@export var counter: Control
@export var coin_scene: PackedScene
@export var max_coins: int = 8
@export var coin_stagger: float = 0.045
@export var flight_time: float = 0.5
@export var arc_height: float = 140.0
@export var pitch_step: float = 0.06
@export var pitch_max: float = 2.2
## The chime ladder keeps climbing while coins keep landing this close.
@export var chain_reset_time: float = 0.5

var _chain: int = 0
var _chain_timer: float = 0.0


func _process(delta: float) -> void:
	_chain_timer -= delta
	if _chain_timer <= 0.0:
		_chain = 0


## Splits `amount` into up to `max_coins` coins. Each landing adds its share.
func collect(world_position: Vector3, amount: int) -> void:
	if amount <= 0:
		return
	var start: Vector2 = size * 0.5
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera != null and not camera.is_position_behind(world_position):
		start = camera.unproject_position(world_position)
	collect_from_screen(start, amount)


func collect_from_screen(start: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	var coins: int = clampi(amount, 1, max_coins)
	var per_coin: int = floori(float(amount) / float(coins))
	var remainder: int = amount - per_coin * coins
	for i in coins:
		var share: int = per_coin + (remainder if i == coins - 1 else 0)
		if i == 0:
			_launch(start, share, i, coins)
		else:
			get_tree().create_timer(coin_stagger * float(i)).timeout.connect(_launch.bind(start, share, i, coins))


func _launch(start: Vector2, share: int, index: int, total: int) -> void:
	if coin_scene == null or counter == null:
		Wallet.add(share)
		return
	var coin: Control = coin_scene.instantiate() as Control
	add_child(coin)
	coin.pivot_offset = coin.size * 0.5
	coin.position = start - coin.pivot_offset
	var end: Vector2 = counter.global_position + counter.size * 0.5 - global_position
	var control: Vector2 = (start + end) * 0.5 + Vector2(randf_range(-60.0, 60.0), -arc_height)
	var tween: Tween = coin.create_tween()
	var step: Callable = func(t: float) -> void:
		var q0: Vector2 = start.lerp(control, t)
		var q1: Vector2 = control.lerp(end, t)
		coin.position = q0.lerp(q1, t) - coin.pivot_offset
		coin.scale = Vector2.ONE * (1.0 + 0.25 * sin(PI * t))
	var method_tween: MethodTweener = tween.tween_method(step, 0.0, 1.0, flight_time)
	method_tween.set_trans(Tween.TRANS_SINE)
	method_tween.set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		Wallet.add(share)
		Audio.play(&"coin", minf(1.0 + pitch_step * float(_chain), pitch_max), -5.0)
		_chain += 1
		_chain_timer = chain_reset_time
		coin_landed.emit(index, total)
		coin.queue_free()
	)
