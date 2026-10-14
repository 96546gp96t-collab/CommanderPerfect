class_name UserSettings
extends RefCounted
## The settings the game remembers between sessions: full screen or a
## window, the shape and style of the picture ([DisplaySettings]), whether
## sound is on, and the keys ([KeyBindings]). Stored in a ConfigFile in the user
## folder of Godot.

const DEFAULT_PATH := "user://settings.cfg"
const DISPLAY := "display"
const SOUND := "sound"
const CONTROLS := "controls"

var path := DEFAULT_PATH
var display := DisplaySettings.new()
var sound_enabled := true
## The game starts in full screen unless the player switched that off.
var fullscreen := true


## The settings stored at [param file_path], with the defaults for whatever
## is missing. Applies the stored keys to the input map.
static func load_from(file_path := DEFAULT_PATH) -> UserSettings:
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
	settings.sound_enabled = bool(config.get_value(SOUND, "enabled", true))
	var keys: Variant = config.get_value(CONTROLS, "keys", {})
	if keys is Dictionary:
		KeyBindings.apply_dict(keys)
	return settings


## Writes the settings, with the keys as they are now. Returns false (and
## says why) when that fails.
func save() -> bool:
	var config := ConfigFile.new()
	config.set_value(DISPLAY, "widescreen", display.aspect == DisplaySettings.Aspect.WIDESCREEN)
	config.set_value(DISPLAY, "correct_pixel_aspect", display.correct_pixel_aspect)
	config.set_value(DISPLAY, "fullscreen", fullscreen)
	config.set_value(DISPLAY, "graphics", DisplaySettings.graphics_name(display.graphics))
	config.set_value(DISPLAY, "smooth_motion", display.smooth_motion)
	config.set_value(SOUND, "enabled", sound_enabled)
	config.set_value(CONTROLS, "keys", KeyBindings.to_dict())
	var error := config.save(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
		return false
	return true
