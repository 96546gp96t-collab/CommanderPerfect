class_name Keen4Settings
extends GalaxySettings
## Keen 4's own settings, kept apart from the shared ones ([UserSettings]:
## keys and the picture), as the original keeps them in its CONFIG.CK4:
## whether the score box is shown (Omni ck_scoreBoxEnabled; on in a new
## installation) and whether the AdLib sounds are the quiet ones (D11; Omni
## sd_quietAdlibSfx, off). Stored in a ConfigFile in Keen 4's user folder;
## the shared [GalaxySettings] (since milestone E13).

const DEFAULT_PATH := "user://keen4/settings.cfg"


func _init() -> void:
	path = DEFAULT_PATH


## The settings stored at [param file_path], with the defaults for what
## is missing.
static func load_from(file_path := DEFAULT_PATH) -> Keen4Settings:
	var settings := Keen4Settings.new()
	settings.read(file_path)
	return settings
