class_name KeyBindings
extends RefCounted
## The keys for walking, jumping and so on, which the player can change in
## the Controls menu. Only keyboard keys are changed; the controller buttons
## stay as they are.
##
## Changing an action replaces its first key and keeps the others (the
## arrows keep WASD, for example). A key belongs to one action only: giving
## it to another action takes it away from the first.

## The actions that can be changed, with the names the menu shows.
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
## Keys the game itself uses; they cannot be given to an action.
const RESERVED_KEYS: Array[Key] = [KEY_ESCAPE, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6]


## The physical keycodes of the keys of [param action], in order.
static func keys_of(action: String) -> Array[Key]:
	var keys: Array[Key] = []
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and not _has_modifier(key):
			keys.append(key.physical_keycode)
	return keys


## Names of the keys of [param action], for the menu: "LEFT, A".
static func describe(action: String) -> String:
	var names := PackedStringArray()
	for key in keys_of(action):
		names.append(key_name(key))
	return ", ".join(names) if not names.is_empty() else "-"


static func key_name(key: Key) -> String:
	return OS.get_keycode_string(key).to_upper()


## Whether [param key] may be given to an action.
static func can_bind(key: Key) -> bool:
	return key != KEY_NONE and not RESERVED_KEYS.has(key)


## Makes [param key] the first key of [param action], and takes it away from
## every other action that is in [constant ACTIONS].
static func bind(action: String, key: Key) -> void:
	if not can_bind(key):
		return
	for other: String in ACTIONS:
		_remove_key(other, key)
	var keys := keys_of(action)
	if not keys.is_empty():
		keys.remove_at(0)
	keys.insert(0, key)
	set_keys(action, keys)


## Replaces the keyboard keys of [param action] with [param keys]; the
## controller buttons stay.
static func set_keys(action: String, keys: Array[Key]) -> void:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and not _has_modifier(key):
			InputMap.action_erase_event(action, event)
	for code in keys:
		var event := InputEventKey.new()
		event.physical_keycode = code
		InputMap.action_add_event(action, event)


## Puts every action back as it is in the project settings.
static func reset() -> void:
	for action: String in ACTIONS:
		var setting: Variant = ProjectSettings.get_setting("input/" + action)
		if not setting is Dictionary:
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in setting.events:
			InputMap.action_add_event(action, event)


## The keys of every action, to store in the settings.
static func to_dict() -> Dictionary:
	var data := {}
	for action: String in ACTIONS:
		data[action] = Array(keys_of(action))
	return data


## Applies keys stored with [method to_dict]. Unknown actions and keys are
## ignored.
static func apply_dict(data: Dictionary) -> void:
	for action: String in ACTIONS:
		var stored: Variant = data.get(action)
		if not stored is Array:
			continue
		var keys: Array[Key] = []
		for code: Variant in stored:
			if (code is int or code is float) and can_bind(int(code) as Key):
				keys.append(int(code) as Key)
		set_keys(action, keys)


static func _remove_key(action: String, key: Key) -> void:
	var keys := keys_of(action)
	if keys.has(key):
		keys.erase(key)
		set_keys(action, keys)


## Keys with Shift and the like held are the cheats, not normal bindings.
static func _has_modifier(key: InputEventKey) -> bool:
	return key.shift_pressed or key.ctrl_pressed or key.alt_pressed or key.meta_pressed
