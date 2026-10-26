class_name UserSettings
extends RefCounted
## The settings the game remembers between sessions: full screen or a
## window, the shape and style of the picture ([DisplaySettings]), whether
## sound is on, whether the extra levels are on, the keys ([KeyBindings])
## and the controllers of two players ([PlayerControllers]),
## and for playing online the player's name and the last address he joined.
## Stored in a ConfigFile in the user folder of Godot.

const DEFAULT_PATH := "user://settings.cfg"
const DISPLAY := "display"
const SOUND := "sound"
const GAME := "game"
const CONTROLS := "controls"
const ONLINE := "online"

var path := DEFAULT_PATH
var display := DisplaySettings.new()
var sound_enabled := true
## Keen 4 and later: the sound device ("off", "pc" for the PC speaker or
## "adlib") and whether the AdLib music plays; the original's default with
## a sound card is the AdLib with music (the user's choice).
var sound_device := "adlib"
var music_enabled := true
## The extras of the game itself, not in the original: the ship as a level
## of its own, where Keen puts the parts back ([ShipLevels]), and playing the
## level with the pogo stick again until he has it. On unless the player
## switched them off (the user's choice).
var extra_levels := true
## The game starts in full screen unless the player switched that off.
var fullscreen := true
## The name shown to the other player when playing online by IP; empty
## until the player typed one. Over Steam his Steam name is used.
var online_name := ""
## The address the player last joined by IP.
var online_address := ""
## The password the player chose for hosting; empty: a new random one each
## time he hosts.
var host_password := ""


## The settings stored at [param file_path], with the defaults for whatever
## is missing. Applies the stored keys and controllers to the input map.
static func load_from(file_path := DEFAULT_PATH) -> UserSettings:
	PlayerControllers.watch()
	var settings := UserSettings.new()
	settings.path = file_path
	var config := ConfigFile.new()
	if not FileAccess.file_exists(file_path):
		return settings
	if config.load(file_path) != OK:
		push_error("%s could not be read; using the default settings." % file_path)
		return settings
	var widescreen := bool(config.get_value(DISPLAY, "widescreen", true))
	settings.display.aspect = (
		DisplaySettings.Aspect.WIDESCREEN if widescreen else DisplaySettings.Aspect.ORIGINAL
	)
	settings.display.correct_pixel_aspect = bool(
		config.get_value(DISPLAY, "correct_pixel_aspect", true)
	)
	settings.fullscreen = bool(config.get_value(DISPLAY, "fullscreen", true))
	settings.display.graphics = DisplaySettings.graphics_named(
		str(config.get_value(DISPLAY, "graphics", ""))
	)
	settings.display.smooth_motion = bool(config.get_value(DISPLAY, "smooth_motion", false))
	settings.display.backgrounds = bool(config.get_value(DISPLAY, "backgrounds", true))
	settings.display.realistic = bool(config.get_value(DISPLAY, "realistic", false))
	settings.sound_enabled = bool(config.get_value(SOUND, "enabled", true))
	settings.sound_device = str(config.get_value(SOUND, "device", "adlib"))
	settings.music_enabled = bool(config.get_value(SOUND, "music", true))
	settings.extra_levels = bool(config.get_value(GAME, "extra_levels", true))
	var stored_name := str(config.get_value(ONLINE, "name", "")).strip_edges()
	settings.online_name = PlayerName.clean(stored_name) if not stored_name.is_empty() else ""
	settings.online_address = str(config.get_value(ONLINE, "address", "")).left(
		MenuController.ADDRESS_LENGTH
	)
	settings.host_password = str(config.get_value(ONLINE, "host_password", "")).left(
		MenuController.PASSWORD_LENGTH
	)
	var keys: Variant = config.get_value(CONTROLS, "keys", {})
	if keys is Dictionary:
		KeyBindings.apply_dict(keys)
	PlayerControllers.apply_array(config.get_value(CONTROLS, "controllers", []))
	return settings


## Writes the settings, with the keys and controllers as they are now.
## Returns false (and says why) when that fails.
func save() -> bool:
	var config := ConfigFile.new()
	config.set_value(DISPLAY, "widescreen", display.aspect == DisplaySettings.Aspect.WIDESCREEN)
	config.set_value(DISPLAY, "correct_pixel_aspect", display.correct_pixel_aspect)
	config.set_value(DISPLAY, "fullscreen", fullscreen)
	config.set_value(DISPLAY, "graphics", DisplaySettings.graphics_name(display.graphics))
	config.set_value(DISPLAY, "smooth_motion", display.smooth_motion)
	config.set_value(DISPLAY, "backgrounds", display.backgrounds)
	config.set_value(DISPLAY, "realistic", display.realistic)
	config.set_value(SOUND, "enabled", sound_enabled)
	config.set_value(SOUND, "device", sound_device)
	config.set_value(SOUND, "music", music_enabled)
	config.set_value(GAME, "extra_levels", extra_levels)
	config.set_value(CONTROLS, "keys", KeyBindings.to_dict())
	config.set_value(CONTROLS, "controllers", PlayerControllers.to_array())
	config.set_value(ONLINE, "name", online_name)
	config.set_value(ONLINE, "address", online_address)
	config.set_value(ONLINE, "host_password", host_password)
	var error := config.save(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
		return false
	return true
