class_name ButtonBindings
extends RefCounted
## The controller buttons for jumping, firing and so on, which the player
## can change in the controls of every game, as [KeyBindings] does for the
## keys. An extra of CommanderPerfect.
##
## There are the same three sets as for the keys: playing alone
## ([constant KeyBindings.ACTIONS], the buttons of every controller), and
## each of two players ([constant KeyBindings.PLAYER_ACTIONS], the buttons
## of his own controller; [PlayerControllers] puts them on his device). Each
## player has a set of his own, so player 1 may jump with A and player 2
## with B. The sticks always walk; only the buttons change.
##
## Changing an action replaces its first button and keeps the others. A
## button belongs to one action only within a set: giving it to another
## action of the set takes it away from the first. The status button is
## shared by all sets, as its key is.
##
## A button is stored as a code: Godot's button number, or for the two
## triggers (which are axes) [constant TRIGGER_BASE] + the axis number.
## Buttons the game itself uses (the menu, skipping levels) cannot be given
## to an action ([method can_bind]).

## A trigger's code: this + its axis.
const TRIGGER_BASE := 1000
const TRIGGER_AXES: Array[JoyAxis] = [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]
## How far a trigger must be pulled to count as pressed.
const TRIGGER_PRESSED := 0.5
## Actions whose buttons are the game's own.
const RESERVED_ACTIONS: Array[String] = ["menu", "previous_level", "next_level"]
## The system's button (the logo in the middle) is never the game's.
const RESERVED_BUTTONS: Array[JoyButton] = [JOY_BUTTON_GUIDE]
## The menus name the buttons as on an Xbox controller (Godot's names: A is
## the bottom one, Cross on a PlayStation controller).
const NAMES: Dictionary[int, String] = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "BACK",
	JOY_BUTTON_GUIDE: "GUIDE",
	JOY_BUTTON_START: "START",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-UP",
	JOY_BUTTON_DPAD_DOWN: "D-DOWN",
	JOY_BUTTON_DPAD_LEFT: "D-LEFT",
	JOY_BUTTON_DPAD_RIGHT: "D-RIGHT",
	JOY_BUTTON_MISC1: "SHARE",
	JOY_BUTTON_PADDLE1: "P1",
	JOY_BUTTON_PADDLE2: "P2",
	JOY_BUTTON_PADDLE3: "P3",
	JOY_BUTTON_PADDLE4: "P4",
	JOY_BUTTON_TOUCHPAD: "TOUCHPAD",
	TRIGGER_BASE + JOY_AXIS_TRIGGER_LEFT: "LT",
	TRIGGER_BASE + JOY_AXIS_TRIGGER_RIGHT: "RT",
}

## The buttons of the players' actions that were changed; the others have
## the buttons their action of playing alone has by default.
static var _player_buttons: Dictionary[String, Array] = {}


## The code of [param event] when it presses a button or pulls a trigger,
## else -1.
static func code_of(event: InputEvent) -> int:
	var button := event as InputEventJoypadButton
	if button != null:
		return button.button_index if button.pressed else -1
	var motion := event as InputEventJoypadMotion
	if motion != null and motion.axis in TRIGGER_AXES and motion.axis_value > TRIGGER_PRESSED:
		return TRIGGER_BASE + motion.axis
	return -1


## The event for the button with [param code] on [param device] (-1: any
## controller).
static func event_of(code: int, device := -1) -> InputEvent:
	var event: InputEvent
	if code >= TRIGGER_BASE:
		var motion := InputEventJoypadMotion.new()
		motion.axis = (code - TRIGGER_BASE) as JoyAxis
		motion.axis_value = 1.0
		event = motion
	else:
		var button := InputEventJoypadButton.new()
		button.button_index = code as JoyButton
		event = button
	event.device = device
	return event


## Whether [param event] is one of the buttons this class changes (a
## button or a trigger; the sticks are not).
static func is_button_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return true
	var motion := event as InputEventJoypadMotion
	return motion != null and motion.axis in TRIGGER_AXES


## The codes of the buttons of [param action], in order.
static func buttons_of(action: String) -> Array[int]:
	var codes: Array[int] = []
	if _player_buttons.has(action):
		codes.assign(_player_buttons[action])
		return codes
	var counterpart := _counterpart(action)
	var events: Array = (
		InputMap.action_get_events(action)
		if counterpart.is_empty()
		else _default_events(counterpart)
	)
	for event: InputEvent in events:
		if is_button_event(event):
			codes.append(_code_of_binding(event))
	return codes


## Names of the buttons of [param action], for the menu: "A, RT".
static func describe(action: String) -> String:
	var names := PackedStringArray()
	for code in buttons_of(action):
		names.append(button_name(code))
	return ", ".join(names) if not names.is_empty() else "-"


static func button_name(code: int) -> String:
	return NAMES.get(code, "BUTTON %d" % code)


## Whether the button with [param code] may be given to an action.
static func can_bind(code: int) -> bool:
	if code < 0 or RESERVED_BUTTONS.has(code):
		return false
	for action in RESERVED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			if is_button_event(event) and _code_of_binding(event) == code:
				return false
	return true


## Makes the button with [param code] the first button of [param action],
## and takes it away from the other actions of its set.
static func bind(action: String, code: int) -> void:
	if not can_bind(code):
		return
	for other in actions_used_with(action):
		if other != action and buttons_of(other).has(code):
			var others := buttons_of(other)
			others.erase(code)
			set_buttons(other, others)
	var codes := buttons_of(action)
	if not codes.is_empty() and codes[0] == code:
		return
	codes.erase(code)
	if codes.is_empty():
		codes.append(code)
	else:
		codes[0] = code
	set_buttons(action, codes)


## The actions of the set of [param action] (the status button is in every
## set, so its own set is all of them).
static func actions_used_with(action: String) -> Array[String]:
	var actions: Array[String] = []
	if action == KeyBindings.SHARED_ACTION:
		return KeyBindings.all_actions()
	if KeyBindings.ACTIONS.has(action):
		actions.append_array(KeyBindings.ACTIONS.keys())
		return actions
	for player_actions in KeyBindings.PLAYER_ACTIONS:
		if player_actions.has(action):
			actions.append_array(player_actions.keys())
			actions.append(KeyBindings.SHARED_ACTION)
	return actions


## Replaces the buttons of [param action] with the buttons with
## [param codes]; its keys and sticks stay.
static func set_buttons(action: String, codes: Array[int]) -> void:
	if not _counterpart(action).is_empty():
		_player_buttons[action] = codes.duplicate()
		PlayerControllers.apply()
		return
	for event in InputMap.action_get_events(action):
		if is_button_event(event):
			InputMap.action_erase_event(action, event)
	for code in codes:
		InputMap.action_add_event(action, event_of(code))


## Every button back as it is in the project settings.
static func reset() -> void:
	_player_buttons.clear()
	for action: String in KeyBindings.ACTIONS:
		var codes: Array[int] = []
		for event in _default_events(action):
			if is_button_event(event):
				codes.append(_code_of_binding(event))
		set_buttons(action, codes)
	PlayerControllers.apply()


## The buttons of every action, to store in the settings.
static func to_dict() -> Dictionary:
	var data := {}
	for action in KeyBindings.all_actions():
		data[action] = Array(buttons_of(action))
	return data


## Applies buttons stored with [method to_dict]. Unknown actions and
## buttons are ignored; actions that are missing keep their buttons.
static func apply_dict(data: Dictionary) -> void:
	for action in KeyBindings.all_actions():
		var stored: Variant = data.get(action)
		if not stored is Array:
			continue
		var codes: Array[int] = []
		for code: Variant in stored:
			if (code is int or code is float) and can_bind(int(code)):
				codes.append(int(code))
		set_buttons(action, codes)


## For an action of one of two players, the action of playing alone whose
## buttons it has by default ("p2_jump": "jump"); empty for the others.
static func _counterpart(action: String) -> String:
	for player_actions in KeyBindings.PLAYER_ACTIONS:
		if player_actions.has(action):
			return PlayerControllers.BUTTONS_FROM.get(action.substr(action.find("_") + 1), "")
	return ""


static func _default_events(action: String) -> Array:
	var setting: Variant = ProjectSettings.get_setting("input/" + action)
	return setting.events if setting is Dictionary else []


## The code of a button or trigger as it is bound to an action.
static func _code_of_binding(event: InputEvent) -> int:
	var button := event as InputEventJoypadButton
	if button != null:
		return button.button_index
	return TRIGGER_BASE + (event as InputEventJoypadMotion).axis
