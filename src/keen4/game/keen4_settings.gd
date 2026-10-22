class_name Keen4Settings
extends RefCounted
## Keen 4's own settings, kept apart from the shared ones ([UserSettings]:
## keys and the picture), as the original keeps them in its CONFIG.CK4:
## whether the score box is shown (Omni ck_scoreBoxEnabled; on in a new
## installation) and whether the AdLib sounds are the quiet ones (D11; Omni
## sd_quietAdlibSfx, off). Stored in a ConfigFile in Keen 4's user folder.

const DEFAULT_PATH := "user://keen4/settings.cfg"
const SECTION := "game"

var path := DEFAULT_PATH
var score_box := true
var quiet_adlib := false


## The settings stored at [param file_path], with the defaults for what
## is missing.
static func load_from(file_path := DEFAULT_PATH) -> Keen4Settings:
	var settings := Keen4Settings.new()
	settings.path = file_path
	if not FileAccess.file_exists(file_path):
		return settings
	var config := ConfigFile.new()
	if config.load(file_path) != OK:
		push_error("%s could not be read; using the default settings." % file_path)
		return settings
	settings.score_box = bool(config.get_value(SECTION, "score_box", true))
	settings.quiet_adlib = bool(config.get_value(SECTION, "quiet_adlib", false))
	return settings


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
