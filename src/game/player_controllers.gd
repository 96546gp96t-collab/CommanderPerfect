class_name PlayerControllers
extends RefCounted
## Which game controller (a gamepad over USB or Bluetooth; Godot sees both
## the same way) each of two players uses, chosen in the Controls menu of
## every game. An extra of CommanderPerfect.
##
## Playing alone, every controller steers Keen, as before: the actions of
## [constant KeyBindings.ACTIONS] take buttons from any device. When two
## play, each player's actions ([constant KeyBindings.PLAYER_ACTIONS]) get
## his own buttons ([ButtonBindings]) and the sticks of playing alone, but
## only from that player's own controller.
##
## A player's controller is either chosen (by pressing a button on it in
## the menu) or automatic. Automatic players get the connected controllers
## nobody chose, in the order Godot numbers them: player 1 the first, player
## 2 the next. A chosen controller is remembered by its GUID (its make and
## model) and which of the connected controllers with that GUID it was, so
## that two controllers of the same kind stay apart. A controller belongs to
## one player only.
##
## Controllers come and go (Bluetooth), so the buttons are given out again
## whenever one connects or disconnects ([method watch]).


## A connected controller: Godot's device number, its name and its GUID.
class Pad:
	var device := 0
	var name := ""
	var guid := ""

	static func create(pad_device: int, pad_name: String, pad_guid: String) -> Pad:
		var pad := Pad.new()
		pad.device = pad_device
		pad.name = pad_name
		pad.guid = pad_guid
		return pad


## A player without a controller.
const NO_DEVICE := -1
const PLAYER_COUNT := 2
## Which action of playing alone lends its stick, and its buttons until
## the player changes them, to which action of a player (the part after
## "p1_" / "p2_").
const BUTTONS_FROM: Dictionary[String, String] = {
	"left": "move_left",
	"right": "move_right",
	"up": "move_up",
	"down": "move_down",
	"jump": "jump",
	"pogo": "pogo",
	"fire": "fire",
}
## Words that every controller's name has and that say nothing about which
## one it is; left out of the short names in the menus.
const FILLER_WORDS: PackedStringArray = ["CONTROLLER", "WIRELESS", "GAMEPAD", "JOYSTICK"]
## The keys of a chosen controller in the settings.
const GUID_KEY := "guid"
const NAME_KEY := "name"
const INDEX_KEY := "index"
## The words of [method describe_short] (the Galaxy watch's box).
const AUTO_WORD := "AUTO"
const OFF_WORD := "OFF"

## Per player: an empty dictionary when his controller is automatic, else
## the chosen one ({guid, name, index}).
static var _chosen: Array[Dictionary] = [{}, {}]
## For tests: the connected controllers to use instead of Godot's.
static var _test_pads: Array[Pad] = []
static var _use_test_pads := false
static var _watching := false


## The controllers connected now, in Godot's order.
static func connected() -> Array[Pad]:
	if _use_test_pads:
		return _test_pads.duplicate()
	var pads: Array[Pad] = []
	var devices := Input.get_connected_joypads()
	devices.sort()
	for device in devices:
		pads.append(Pad.create(device, Input.get_joy_name(device), Input.get_joy_guid(device)))
	return pads


## For tests: pretend [param pads] are connected (null: Godot's again), and
## give the buttons out anew.
static func pretend_connected(pads: Variant) -> void:
	_use_test_pads = pads != null
	_test_pads.clear()
	if pads != null:
		_test_pads.append_array(pads)
	apply()


## Whether [param player] (0 or 1) has a controller of his own choice.
static func is_chosen(player: int) -> bool:
	return not _chosen[player].is_empty()


## Gives [param player] the controller with Godot's number [param device]
## (one of [method connected]); the other player loses it if it was his.
static func choose(player: int, device: int) -> void:
	var pads := connected()
	var pad := _pad_with_device(pads, device)
	if pad == null:
		return
	var index := 0
	for other in pads:
		if other.device == device:
			break
		if other.guid == pad.guid:
			index += 1
	_chosen[player] = {GUID_KEY: pad.guid, NAME_KEY: pad.name, INDEX_KEY: index}
	for other_player in PLAYER_COUNT:
		if other_player != player and _chosen[other_player] == _chosen[player]:
			_chosen[other_player] = {}
	apply()


## Both players' controllers automatic again.
static func reset() -> void:
	_chosen = [{}, {}]
	apply()


## Godot's number of the controller of each player now, or
## [constant NO_DEVICE].
static func devices() -> Array[int]:
	var pads := connected()
	var result: Array[int] = []
	result.resize(PLAYER_COUNT)
	result.fill(NO_DEVICE)
	var taken: Array[int] = []
	for player in PLAYER_COUNT:
		var pad := _chosen_pad(pads, player)
		if pad != null:
			result[player] = pad.device
			taken.append(pad.device)
	for player in PLAYER_COUNT:
		if is_chosen(player):
			continue
		for pad in pads:
			if not taken.has(pad.device):
				result[player] = pad.device
				taken.append(pad.device)
				break
	return result


## Puts each player's controller buttons on his actions: his buttons
## ([ButtonBindings]) and the stick of the matching action of playing
## alone, from his device only. His keyboard keys stay as they are.
static func apply() -> void:
	var player_devices := devices()
	for player in PLAYER_COUNT:
		var prefix := "p%d_" % (player + 1)
		for part: String in BUTTONS_FROM:
			var action := prefix + part
			if not InputMap.has_action(action):
				continue
			for event in InputMap.action_get_events(action):
				if _is_controller_event(event):
					InputMap.action_erase_event(action, event)
			if player_devices[player] == NO_DEVICE:
				continue
			var device := player_devices[player]
			for code in ButtonBindings.buttons_of(action):
				InputMap.action_add_event(action, ButtonBindings.event_of(code, device))
			for event in InputMap.action_get_events(BUTTONS_FROM[part]):
				if _is_controller_event(event) and not ButtonBindings.is_button_event(event):
					var stick := event.duplicate() as InputEvent
					stick.device = device
					InputMap.action_add_event(action, stick)


## Gives the buttons out again whenever a controller connects or
## disconnects. Safe to call more than once.
static func watch() -> void:
	if _watching:
		return
	_watching = true
	Input.joy_connection_changed.connect(_on_connection_changed)
	apply()


## What the menus show for [param player]'s controller: its number in the
## list of connected controllers and its short name ("1 XBOX"), "AUTO "
## before it when it is automatic, "AUTO -" when there is none, and a
## chosen one that is not connected with "(OFF)" after it.
static func describe(player: int, max_length := 0) -> String:
	var pads := connected()
	var device := devices()[player]
	var text := ""
	if device != NO_DEVICE:
		var pad := _pad_with_device(pads, device)
		text = "%d %s" % [pads.find(pad) + 1, short_name(pad.name)]
	elif is_chosen(player):
		text = "%s (OFF)" % short_name(str(_chosen[player][NAME_KEY]))
	else:
		text = "-"
	if not is_chosen(player):
		text = "AUTO " + text
	return text.left(max_length) if max_length > 0 else text


## [method describe] for a small box: the controller's number and short
## name ("1 XBOX") when it was chosen, "OFF" when that one is not
## connected; "AUTO 1" or "AUTO -" when it is automatic.
static func describe_short(player: int, max_length: int) -> String:
	var pads := connected()
	var device := devices()[player]
	var number := "-"
	if device != NO_DEVICE:
		number = str(pads.find(_pad_with_device(pads, device)) + 1)
	if not is_chosen(player):
		return Lang.text(AUTO_WORD) + " " + number
	if device == NO_DEVICE:
		return Lang.text(OFF_WORD)
	var pad := _pad_with_device(pads, device)
	return ("%s %s" % [number, short_name(pad.name)]).left(max_length)


## [param pad_name] in capitals without the words every controller has:
## "Xbox Wireless Controller" becomes "XBOX".
static func short_name(pad_name: String) -> String:
	var words := PackedStringArray()
	for word in pad_name.to_upper().split(" ", false):
		if not FILLER_WORDS.has(word):
			words.append(word)
	if words.is_empty():
		return pad_name.to_upper().strip_edges()
	return " ".join(words)


## The choices, to store in the settings: one dictionary per player.
static func to_array() -> Array:
	return _chosen.duplicate(true)


## Applies choices stored with [method to_array]; anything unreadable is
## automatic.
static func apply_array(data: Variant) -> void:
	_chosen = [{}, {}]
	if data is Array:
		for player in mini(PLAYER_COUNT, data.size()):
			var stored: Variant = data[player]
			if stored is Dictionary and stored.get(GUID_KEY) is String:
				_chosen[player] = {
					GUID_KEY: stored[GUID_KEY],
					NAME_KEY: str(stored.get(NAME_KEY, "")),
					INDEX_KEY: maxi(0, int(stored.get(INDEX_KEY, 0))),
				}
	apply()


static func _on_connection_changed(_device: int, _connected: bool) -> void:
	apply()


static func _chosen_pad(pads: Array[Pad], player: int) -> Pad:
	if not is_chosen(player):
		return null
	var index := 0
	for pad in pads:
		if pad.guid == _chosen[player][GUID_KEY]:
			if index == _chosen[player][INDEX_KEY]:
				return pad
			index += 1
	return null


static func _pad_with_device(pads: Array[Pad], device: int) -> Pad:
	for pad in pads:
		if pad.device == device:
			return pad
	return null


static func _is_controller_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion
