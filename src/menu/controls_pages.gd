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
	var menu := Menu.create(MenuController.CONTROLS, ["  " + Lang.text("CONTROLS")])
	menu.add(Lang.text("One player"), MenuController.KEY_SET, 0)
	menu.add(Lang.text("Two players: player %d") % 1, MenuController.KEY_SET, 1)
	menu.add(Lang.text("Two players: player %d") % 2, MenuController.KEY_SET, 2)
	menu.add(Lang.text("Controllers"), MenuController.CONTROLLERS)
	menu.add(Lang.text("Reset to defaults"), &"reset")
	return menu


## The keys of one set (0 playing alone, 1 or 2 a player of two); pick one
## to change it. The last row leads to the set's controller buttons.
static func key_set(set_index: int) -> Menu:
	var menu := Menu.create(MenuController.KEY_SET, [_title(set_index), _pick_one()])
	for action: String in _actions(set_index):
		var label := _action_name(action)
		menu.add("%-7s %s" % [label, KeyBindings.describe(action)], StringName(action))
	menu.add(Lang.text("Controller buttons"), MenuController.BUTTON_SET, set_index)
	return menu


## The controller buttons of one set, as [method key_set] has the keys.
static func button_set(set_index: int) -> Menu:
	var menu := Menu.create(
		MenuController.BUTTON_SET,
		["  " + Lang.text("BUTTONS: %s") % _title(set_index).strip_edges(), _pick_one()]
	)
	for action: String in _actions(set_index):
		var label := _action_name(action)
		menu.add("%-7s %s" % [label, ButtonBindings.describe(action)], StringName(action))
	return menu


## The controller of each of two players; pick one, then press a button on
## his controller. Playing alone, every controller works.
static func controllers() -> Menu:
	var menu := (
		Menu
		. create(
			MenuController.CONTROLLERS,
			[
				"  " + Lang.text("CONTROLLERS"),
				"  " + Lang.text("When two play. Alone,"),
				"  " + Lang.text("every controller works."),
			]
		)
	)
	for player in PlayerControllers.PLAYER_COUNT:
		var pad := PlayerControllers.describe(player, PAD_TEXT_LENGTH)
		var label := Lang.text("Player %d  %s") % [player + 1, pad]
		menu.add(label, MenuController.PLAYER_PAD, player)
	menu.add(Lang.text("Both automatic"), MenuController.AUTOMATIC_PADS)
	return menu


static func key_prompt(action: String) -> Menu:
	var lines := [
		Lang.text("Press the new key for"), Lang.text("%s, or Escape.") % _upper_name(action)
	]
	return Menu.create(MenuController.PRESS_KEY, lines)


static func button_prompt(action: String) -> Menu:
	var lines := [
		Lang.text("Press the new button for"),
		Lang.text("%s on a controller,") % _upper_name(action),
		Lang.text("or Back (Escape)."),
	]
	return Menu.create(MenuController.NEW_BUTTON, lines)


static func controller_prompt(player: int) -> Menu:
	var lines := [
		Lang.text("Press a button on the"),
		Lang.text("controller of PLAYER %d,") % (player + 1),
		Lang.text("or Escape."),
	]
	return Menu.create(MenuController.PRESS_BUTTON, lines)


static func _title(set_index: int) -> String:
	if set_index == 0:
		return "  " + Lang.text("ONE PLAYER")
	return "  " + Lang.text("PLAYER %d OF TWO") % set_index


static func _pick_one() -> String:
	return "  " + Lang.text("Pick one to change it")


## The name of [param action] in the menu ("Jump"), in the language in use.
static func _action_name(action: String) -> String:
	return Lang.text(KeyBindings.action_name(action))


static func _actions(set_index: int) -> Array:
	if set_index == 0:
		return KeyBindings.ACTIONS.keys()
	return KeyBindings.PLAYER_ACTIONS[set_index - 1].keys()


static func _upper_name(action: String) -> String:
	return _action_name(action).to_upper()
