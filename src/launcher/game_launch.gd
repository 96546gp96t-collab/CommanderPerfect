class_name GameLaunch
extends RefCounted
## What the start screen ([Launcher]) hands to the game it starts: whether
## the game opens its main menu straight away (it does when the player
## picked it on the start screen), and which command-line options skip the
## start screen altogether (for testing).

const LAUNCHER_SCENE := "res://src/launcher/launcher.tscn"
const KEEN_1_SCENE := "res://src/game/level_view.tscn"
## Start in level N (80 is the world map) instead of at the title.
const LEVEL_OPTION := "--level="
## Show the ending straight away.
const ENDING_OPTION := "--ending"

static var _menu_requested := false


## The game should open its main menu as soon as it is shown.
static func request_menu() -> void:
	_menu_requested = true


## Whether the game should open its main menu; asks only once.
static func take_menu_request() -> bool:
	var requested := _menu_requested
	_menu_requested = false
	return requested


## Whether [param arguments] (the user arguments on the command line) ask
## to start in a level or in the ending: then Keen 1 starts at once.
static func skips_launcher(arguments: PackedStringArray) -> bool:
	for argument in arguments:
		if argument.begins_with(LEVEL_OPTION) or argument == ENDING_OPTION:
			return true
	return false
