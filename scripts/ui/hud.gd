class_name Hud
extends CanvasLayer
## The in game HUD: the coin counter and the coin flights. Everything else
## the island needs is shown by the world itself.
##
## Sea widgets (cannonballs, hold, hull) are children that the ship toggles.

@export var coin_flight: HudCoinFlight
@export var root_control: Control


## Flies `amount` as coins from a world position to the counter. The wallet
## only grows as the coins land.
static func collect_coins(context: Node, at: Vector3, amount: int) -> void:
	if context == null or not context.is_inside_tree():
		return
	var hud: Hud = context.get_tree().get_first_node_in_group(&"hud") as Hud
	if hud != null and hud.coin_flight != null:
		hud.coin_flight.collect(at, amount)
	else:
		Wallet.add(amount, at)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"hide_hud") and root_control != null:
		root_control.visible = not root_control.visible
