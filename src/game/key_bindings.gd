class_name KeyBindings
extends RefCounted
## The keys for walking, jumping and so on, which the player can change in
## the Controls menu. Only keyboard keys are changed; the controller buttons
## stay as they are (which controller each of two players uses is
## [PlayerControllers]'s).
##
## There are three sets of keys. Playing alone uses [constant ACTIONS]: the
## arrows or WASD, with the keys of the original. When two play on one
## keyboard, each player has a set of his own ([constant PLAYER_ACTIONS]):
## player 1 on the left side of the keyboard, player 2 on the right.
##
## Changing an action replaces its first key and keeps the others (the
## arrows keep WASD, for example). A key belongs to one action only among
## the keys that are used at the same time: giving it to another action
## takes it away from the first. The keys for one player and the keys for
## two players are never used at the same time, so they may overlap.
##
## A key is stored as a code: its physical keycode, plus which of the two
## keys it is for keys such as Shift that are on both sides of the keyboard
## (see [method code_of]).

## The actions for playing alone, with the names the menu shows.
const ACTIONS: Dictionary[String, String] = {
	"move_left": "Left",
	"move_right": "Right",
	"move_up": "Up",
	"move_down": "Down",
	"jump": "Jump",
	"pogo": "Pogo",
	"fire": "Fire",
	"status": "Status",
}
## The actions of each player when two play, with the names the menu shows.
## Up and down came last (milestone D12): Keen 4 needs them in its levels
## (poles, doors, looking); Keen 1-3 do not use them in levels, and on their
## world map the keys of playing alone steer as well.
const PLAYER_ACTIONS: Array[Dictionary] = [
	{
		"p1_left": "Left",
		"p1_right": "Right",
		"p1_jump": "Jump",
		"p1_pogo": "Pogo",
		"p1_fire": "Fire",
		"p1_up": "Up",
		"p1_down": "Down",
	},
	{
		"p2_left": "Left",
		"p2_right": "Right",
		"p2_jump": "Jump",
		"p2_pogo": "Pogo",
		"p2_fire": "Fire",
		"p2_up": "Up",
		"p2_down": "Down",
	},
]
## The status screen is there in both ways of playing.
const SHARED_ACTION := "status"
## Keys the game itself uses; they cannot be given to an action.
const RESERVED_KEYS: Array[Key] = [
	KEY_ESCAPE, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8
]
## A code keeps the side of the keyboard above the keycode.
const LOCATION_SHIFT := 32
const KEYCODE_MASK := (1 << LOCATION_SHIFT) - 1
## Names for keys whose own name is long, or that read better as a sign.
const SHORT_NAMES: Dictionary[Key, String] = {
	KEY_QUOTELEFT: "`",
	KEY_PERIOD: ".",
	KEY_COMMA: ",",
	KEY_SLASH: "/",
	KEY_BACKSLASH: "\\",
	KEY_SEMICOLON: ";",
	KEY_APOSTROPHE: "'",
	KEY_BRACKETLEFT: "[",
	KEY_BRACKETRIGHT: "]",
	KEY_MINUS: "-",
	KEY_EQUAL: "=",
}
const LOCATION_NAMES: Dictionary[KeyLocation, String] = {
	KEY_LOCATION_LEFT: "LEFT ",
	KEY_LOCATION_RIGHT: "RIGHT ",
}


## The code of the key of [param event]: its physical keycode, and for a
## key that is on both sides of the keyboard (Shift, Alt, ...) which one.
static func code_of(event: InputEventKey) -> int:
	return make_code(event.physical_keycode, event.location)


static func make_code(key: Key, location := KEY_LOCATION_UNSPECIFIED) -> int:
	return key | (location << LOCATION_SHIFT)


static func keycode(code: int) -> Key:
	return (code & KEYCODE_MASK) as Key


static func location(code: int) -> KeyLocation:
	return (code >> LOCATION_SHIFT) as KeyLocation


## Every action whose keys can be changed.
static func all_actions() -> Array[String]:
	var actions: Array[String] = []
	actions.append_array(ACTIONS.keys())
	for player_actions in PLAYER_ACTIONS:
		actions.append_array(player_actions.keys())
	return actions


## The name of [param action] in the menu.
static func action_name(action: String) -> String:
	if ACTIONS.has(action):
		return ACTIONS[action]
	for player_actions in PLAYER_ACTIONS:
		if player_actions.has(action):
			return player_actions[action]
	return action


## The codes of the keys of [param action], in order.
static func keys_of(action: String) -> Array[int]:
	var keys: Array[int] = []
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and not _has_modifier(key):
			keys.append(code_of(key))
	return keys


## Names of the keys of [param action], for the menu: "LEFT, A".
static func describe(action: String) -> String:
	var names := PackedStringArray()
	for code in keys_of(action):
		names.append(key_name(code))
	return ", ".join(names) if not names.is_empty() else "-"


## The name of the key with [param code]: "A", "LEFT SHIFT", "/".
static func key_name(code: int) -> String:
	var key := keycode(code)
	var key_text: String = SHORT_NAMES.get(key, OS.get_keycode_string(key).to_upper())
	return LOCATION_NAMES.get(location(code), "") + key_text


## Whether the key with [param code] may be given to an action.
static func can_bind(code: int) -> bool:
	var key := keycode(code)
	return key != KEY_NONE and not RESERVED_KEYS.has(key)


## Makes the key with [param code] the first key of [param action], and
## takes it away from every other action that is used at the same time.
static func bind(action: String, code: int) -> void:
	if not can_bind(code):
		return
	for other in actions_used_with(action):
		_remove_key(other, code)
	var keys := keys_of(action)
	if not keys.is_empty():
		keys.remove_at(0)
	keys.insert(0, code)
	set_keys(action, keys)


## The actions whose keys are in use at the same time as those of
## [param action], [param action] included.
static func actions_used_with(action: String) -> Array[String]:
	var alone: Array[String] = []
	alone.append_array(ACTIONS.keys())
	var together: Array[String] = [SHARED_ACTION]
	for player_actions in PLAYER_ACTIONS:
		together.append_array(player_actions.keys())
	if action == SHARED_ACTION:
		alone.append_array(together)
		return alone
	return alone if ACTIONS.has(action) else together


## Replaces the keyboard keys of [param action] with the keys with
## [param codes]; the controller buttons stay.
static func set_keys(action: String, codes: Array[int]) -> void:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and not _has_modifier(key):
			InputMap.action_erase_event(action, event)
	for code in codes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode(code)
		event.location = location(code)
		InputMap.action_add_event(action, event)


## Puts every action back as it is in the project settings.
static func reset() -> void:
	for action in all_actions():
		var setting: Variant = ProjectSettings.get_setting("input/" + action)
		if not setting is Dictionary:
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in setting.events:
			InputMap.action_add_event(action, event)
	# The players' controller buttons were erased with the rest.
	PlayerControllers.apply()


## The keys of every action, to store in the settings.
static func to_dict() -> Dictionary:
	var data := {}
	for action in all_actions():
		data[action] = Array(keys_of(action))
	return data


## Applies keys stored with [method to_dict]. Unknown actions and keys are
## ignored; actions that are missing (from an older version) keep their
## keys.
static func apply_dict(data: Dictionary) -> void:
	for action in all_actions():
		var stored: Variant = data.get(action)
		if not stored is Array:
			continue
		var codes: Array[int] = []
		for code: Variant in stored:
			if (code is int or code is float) and can_bind(int(code)):
				codes.append(int(code))
		set_keys(action, codes)


static func _remove_key(action: String, code: int) -> void:
	var keys := keys_of(action)
	if keys.has(code):
		keys.erase(code)
		set_keys(action, keys)


## Keys with Shift and the like held are the cheats, not normal bindings.
static func _has_modifier(key: InputEventKey) -> bool:
	return key.shift_pressed or key.ctrl_pressed or key.alt_pressed or key.meta_pressed
