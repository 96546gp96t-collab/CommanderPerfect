class_name ControlsPages
extends RefCounted
## The menus of the controls of Keen 1-3, for [MenuController]: the keys of
## playing alone and of each of two players, the controller buttons of each
## of those sets ([ButtonBindings]), which controller each of two players
## uses ([PlayerControllers]), and the windows that wait for a new key or
## button.

## Longest name of a controller in the controllers menu.
const PAD_TEXT_LENGTH := 20


## The keys for playing alone and for each of two players, the controllers.
static func controls() -> Menu:
	var menu := Menu.create(MenuController.CONTROLS, ["  CONTROLS"])
	menu.add("One player", MenuController.KEY_SET, 0)
	menu.add("Two players: player 1", MenuController.KEY_SET, 1)
	menu.add("Two players: player 2", MenuController.KEY_SET, 2)
	menu.add("Controllers", MenuController.CONTROLLERS)
	menu.add("Reset to defaults", &"reset")
	return menu


## The keys of one set (0 playing alone, 1 or 2 a player of two); pick one
## to change it. The last row leads to the set's controller buttons.
static func key_set(set_index: int) -> Menu:
	var menu := Menu.create(MenuController.KEY_SET, [_title(set_index), "  Pick one to change it"])
	for action: String in _actions(set_index):
		var label := KeyBindings.action_name(action)
		menu.add("%-7s %s" % [label, KeyBindings.describe(action)], StringName(action))
	menu.add("Controller buttons", MenuController.BUTTON_SET, set_index)
	return menu


## The controller buttons of one set, as [method key_set] has the keys.
static func button_set(set_index: int) -> Menu:
	var menu := Menu.create(
		MenuController.BUTTON_SET,
		["  BUTTONS: " + _title(set_index).strip_edges(), "  Pick one to change it"]
	)
	for action: String in _actions(set_index):
		var label := KeyBindings.action_name(action)
		menu.add("%-7s %s" % [label, ButtonBindings.describe(action)], StringName(action))
	return menu


## The controller of each of two players; pick one, then press a button on
## his controller. Playing alone, every controller works.
static func controllers() -> Menu:
	var menu := Menu.create(
		MenuController.CONTROLLERS,
		["  CONTROLLERS", "  When two play. Alone,", "  every controller works."]
	)
	for player in PlayerControllers.PLAYER_COUNT:
		var pad := PlayerControllers.describe(player, PAD_TEXT_LENGTH)
		menu.add("Player %d  %s" % [player + 1, pad], MenuController.PLAYER_PAD, player)
	menu.add("Both automatic", MenuController.AUTOMATIC_PADS)
	return menu


static func key_prompt(action: String) -> Menu:
	var lines := ["Press the new key for", "%s, or Escape." % _upper_name(action)]
	return Menu.create(MenuController.PRESS_KEY, lines)


static func button_prompt(action: String) -> Menu:
	var lines := [
		"Press the new button for", "%s on a controller," % _upper_name(action), "or Back (Escape)."
	]
	return Menu.create(MenuController.NEW_BUTTON, lines)


static func controller_prompt(player: int) -> Menu:
	var lines := ["Press a button on the", "controller of PLAYER %d," % (player + 1), "or Escape."]
	return Menu.create(MenuController.PRESS_BUTTON, lines)


static func _title(set_index: int) -> String:
	return "  ONE PLAYER" if set_index == 0 else "  PLAYER %d OF TWO" % set_index


static func _actions(set_index: int) -> Array:
	if set_index == 0:
		return KeyBindings.ACTIONS.keys()
	return KeyBindings.PLAYER_ACTIONS[set_index - 1].keys()


static func _upper_name(action: String) -> String:
	return KeyBindings.action_name(action).to_upper()
