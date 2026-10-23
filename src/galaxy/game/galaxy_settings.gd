class_name GalaxySettings
extends RefCounted
## A Galaxy episode's own settings (made from Keen 4's [Keen4Settings],
## milestone E8), kept apart from the shared ones ([UserSettings]: keys,
## the picture, the sound device, the music), as the original keeps them
## in its CONFIG file: whether the score box is shown (Omni
## ck_scoreBoxEnabled; on in a new installation) and whether the AdLib
## sounds are the quiet ones (Omni sd_quietAdlibSfx, off). Stored in a
## ConfigFile in the episode's own user folder
## ([method GalaxyGameRules.settings_path]); the control panel sets them
## (Keen 5: milestone E9).

const SECTION := "game"

var path := ""
var score_box := true
var quiet_adlib := false


## The settings stored at [param file_path], with the defaults for what
## is missing.
static func load_from(file_path: String) -> GalaxySettings:
	var settings := GalaxySettings.new()
	settings.read(file_path)
	return settings


## Takes over the settings stored at [param file_path] (and keeps that
## path), with the defaults for what is missing.
func read(file_path: String) -> void:
	path = file_path
	if not FileAccess.file_exists(file_path):
		return
	var config := ConfigFile.new()
	if config.load(file_path) != OK:
		push_error("%s could not be read; using the default settings." % file_path)
		return
	score_box = bool(config.get_value(SECTION, "score_box", true))
	quiet_adlib = bool(config.get_value(SECTION, "quiet_adlib", false))


## Writes the settings. Returns false (and says why) when that fails.
func save() -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var config := ConfigFile.new()
	config.set_value(SECTION, "score_box", score_box)
	config.set_value(SECTION, "quiet_adlib", quiet_adlib)
	var error := config.save(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
		return false
	return true
