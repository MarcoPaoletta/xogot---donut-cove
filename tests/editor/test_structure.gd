extends Node
## Structural checks, run in the editor with `xo test run --root res://tests/editor`.
## They look at the saved scenes and the project settings only: behaviour is
## covered by the suites in `tests/game/`, which run inside the game.

const MAIN: String = "res://scenes/main.tscn"

const ELEMENT_SCENES: PackedStringArray = [
	"res://scenes/actors/baker.tscn", "res://scenes/actors/helper.tscn", "res://scenes/actors/customer_anne.tscn",
	"res://scenes/actors/customer_henry.tscn", "res://scenes/actors/customer_sharky.tscn",
	"res://scenes/actors/customer_mako.tscn", "res://scenes/actors/customer_captain.tscn",
	"res://scenes/props/donut_strawberry.tscn", "res://scenes/props/donut_chocolate.tscn",
	"res://scenes/props/donut_honey.tscn", "res://scenes/props/oven_strawberry.tscn",
	"res://scenes/props/oven_chocolate.tscn", "res://scenes/props/oven_honey.tscn", "res://scenes/props/counter.tscn",
	"res://scenes/props/table_set.tscn", "res://scenes/props/statue.tscn", "res://scenes/props/coin.tscn",
	"res://scenes/props/order_bubble.tscn", "res://scenes/props/donut_house.tscn",
	"res://scenes/island/unlock_pad.tscn", "res://scenes/island/objective_arrow.tscn", "res://scenes/island/island.tscn",
	"res://scenes/island/kitchen_line.tscn", "res://scenes/island/dock.tscn", "res://scenes/island/sky.tscn",
	"res://scenes/sea/sea.tscn", "res://scenes/sea/ship.tscn", "res://scenes/sea/cannonball.tscn",
	"res://scenes/sea/shark.tscn", "res://scenes/sea/tentacle.tscn", "res://scenes/sea/tentacle_kraken.tscn",
	"res://scenes/sea/loot_coins.tscn", "res://scenes/sea/loot_chest.tscn", "res://scenes/sea/golden_chest.tscn",
	"res://scenes/sea/boarding_pad.tscn", "res://scenes/sea/sea_camera.tscn", "res://scenes/core/island_camera.tscn",
	"res://scenes/ui/hud.tscn", "res://scenes/ui/title_screen.tscn", "res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/end_card.tscn", "res://scenes/ui/presenter_panel.tscn", "res://scenes/fx/pop_number.tscn",
	"res://scenes/fx/fx_confetti.tscn", "res://scenes/fx/fx_dust_ring.tscn", "res://scenes/fx/fx_splash.tscn",
	"res://scenes/fx/fx_muzzle_flash.tscn",
]

const DECOR_IDS: PackedStringArray = ["kitchen_floor", "plants", "lamps", "prep_counter", "pot_shelf"]
const MAIN_NODES: PackedStringArray = [
	"Sky/WorldEnvironment", "Sky/Sun", "Sea/Water", "Sea/Ship", "Sea/SeaLife", "Sea/Islet1", "Sea/Islet2", "Island/Ground",
	"Island/KitchenLine", "Island/Dock", "Ovens/Oven1", "Ovens/Oven2", "Ovens/Oven3", "Counter/Queue", "Counter/CashTray",
	"Counter/DisplayCase", "Pads", "Reveals/Statue", "Reveals/Table1", "Reveals/Table2", "Reveals/Helper", "Reveals/House",
	"Baker", "IslandCamera/Camera3D", "SeaCamera/Camera3D", "BoardingPad", "ObjectiveArrow", "Hud",
	"ConceptCams/ConceptCam_Stall", "ConceptCams/ConceptCam_Island", "ConceptCams/ConceptCam_Sea", "MenuCameras/Camera3D",
	"Screens/Title", "Screens/Pause", "Screens/EndCard", "Screens/Presenter",
]

const PAD_IDS: PackedStringArray = ["oven2", "display_case", "backpack", "oven3", "statue", "tables", "helper",
	"oven_speed", "ship", "backpack2", "double_cannons", "house"]

var _main: Node = null


func before_all() -> void:
	_main = (load(MAIN) as PackedScene).instantiate()


func after_all() -> void:
	if _main != null:
		_main.free()
		_main = null


func test_main_scene_is_set() -> Variant:
	return ProjectSettings.get_setting("application/run/main_scene") == MAIN


func test_every_element_has_its_own_scene() -> Variant:
	for path: String in ELEMENT_SCENES:
		if not ResourceLoader.exists(path):
			return "missing " + path
	return true


func test_main_shows_the_whole_world() -> Variant:
	for path: String in MAIN_NODES:
		if _main.get_node_or_null(path) == null:
			return "missing node " + path
	return true


## The nodes of `group` under `node` (the scene under test is not in the tree).
func _grouped(node: Node, group: String, found: Array[Node] = []) -> Array[Node]:
	if node.is_in_group(group):
		found.append(node)
	for child: Node in node.get_children():
		_grouped(child, group, found)
	return found


func test_pads_are_in_buying_order() -> Variant:
	var pads: Node = _main.get_node("Pads")
	if pads.get_child_count() != PAD_IDS.size():
		return "expected %d pads, found %d" % [PAD_IDS.size(), pads.get_child_count()]
	for i in PAD_IDS.size():
		if String(pads.get_child(i).get("pad_id")) != PAD_IDS[i]:
			return "pad %d is %s" % [i, pads.get_child(i).get("pad_id")]
		if int(pads.get_child(i).get("price")) <= 0:
			return "pad %s has no price" % PAD_IDS[i]
		# The hologram is the placed target itself, or a `Ghost` child for an upgrade.
		if pads.get_child(i).get_node_or_null("Ghost") == null and _grouped(_main, "reveal_" + PAD_IDS[i]).is_empty():
			return "pad %s has no hologram" % PAD_IDS[i]
		if pads.get_child(i).get("ghost_material") == null:
			return "pad %s has no hologram material" % PAD_IDS[i]
	return true


func test_five_optional_decorations_are_placed_hidden() -> Variant:
	var pads: Node = _main.get_node("DecorPads")
	if pads.get_child_count() != DECOR_IDS.size():
		return "expected %d decoration pads, found %d" % [DECOR_IDS.size(), pads.get_child_count()]
	for i in DECOR_IDS.size():
		if String(pads.get_child(i).get("pad_id")) != DECOR_IDS[i]:
			return "decoration %d is %s" % [i, pads.get_child(i).get("pad_id")]
		var targets: Array[Node] = _grouped(_main, "reveal_" + DECOR_IDS[i])
		if targets.is_empty():
			return "decoration %s buys nothing" % DECOR_IDS[i]
		for target: Node in targets:
			if (target as Node3D).visible:
				return "decoration %s is visible before it is bought" % DECOR_IDS[i]
	return true


func test_unlock_targets_are_placed_hidden() -> Variant:
	for path: String in ["Ovens/Oven2", "Ovens/Oven3", "Reveals/Statue", "Reveals/Table1", "Reveals/Table2", "Reveals/Helper",
			"Reveals/House", "Sea/Ship", "BoardingPad", "Counter/DisplayCase"]:
		var node: Node3D = _main.get_node(path) as Node3D
		if node.visible:
			return path + " is visible before its pad"
	return (_main.get_node("Ovens/Oven1") as Node3D).visible


func test_menu_has_three_to_five_shots() -> Variant:
	var shots: int = _main.get_node("MenuCameras").get_child_count() - 1
	return shots >= 3 and shots <= 5


func test_cameras_are_perspective() -> Variant:
	for path: String in ["IslandCamera/Camera3D", "SeaCamera/Camera3D", "ConceptCams/ConceptCam_Stall", "MenuCameras/Camera3D"]:
		if (_main.get_node(path) as Camera3D).projection != Camera3D.PROJECTION_PERSPECTIVE:
			return path + " is not perspective"
	return true


func test_project_settings() -> Variant:
	var expected: Dictionary = {
		"display/window/stretch/mode": "canvas_items", "display/window/stretch/aspect": "expand",
		"display/window/size/viewport_width": 1920, "display/window/size/viewport_height": 1080,
		"physics/common/physics_interpolation": true, "physics/3d/physics_engine": "Jolt Physics",
	}
	for key: String in expected.keys():
		if ProjectSettings.get_setting(key) != expected[key]:
			return "%s is %s" % [key, ProjectSettings.get_setting(key)]
	return true


func test_physics_layers_are_named() -> Variant:
	var names: PackedStringArray = ["world", "player", "ship", "npcs", "enemies", "projectiles", "pickups", "triggers"]
	for i in names.size():
		if ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % (i + 1)) != names[i]:
			return "layer %d is not %s" % [i + 1, names[i]]
	return true


func test_input_actions_exist() -> Variant:
	for action: String in ["move_up", "move_down", "move_left", "move_right", "fire", "interact", "pause", "toggle_mute",
			"debug_panel", "showcase_cam", "hide_hud"]:
		if not ProjectSettings.has_setting("input/" + action):
			return "missing action " + action
	return not ProjectSettings.has_setting("input/concept_cam")


func test_only_two_autoloads() -> Variant:
	var found: PackedStringArray = []
	for property: Dictionary in ProjectSettings.get_property_list():
		var key: String = property["name"]
		if key.begins_with("autoload/"):
			found.append(key.trim_prefix("autoload/"))
	found.sort()
	return true if found == PackedStringArray(["Audio", "Wallet"]) else "autoloads are %s" % [found]
