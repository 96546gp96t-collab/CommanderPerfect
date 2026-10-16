class_name GameLaunch
extends RefCounted
## What the start screen ([Launcher]) hands to the game it starts: whether
## the game opens its main menu straight away (it does when the player
## picked it on the start screen), and which command-line options skip the
## start screen altogether (for testing).

const LAUNCHER_SCENE := "res://src/launcher/launcher.tscn"
const KEEN_1_SCENE := "res://src/game/level_view.tscn"
const KEEN_2_SCENE := "res://src/keen2/keen2_view.tscn"
## Start in level N (80 is the world map) instead of at the title.
const LEVEL_OPTION := "--level="
## Show the ending straight away.
const ENDING_OPTION := "--ending"
## Which game the other options are for: --game=2 starts Keen 2 (also in the
## data viewer and the graphics export). Without it everything is Keen 1.
const GAME_OPTION := "--game="
const KEEN_2_GAME := "2"

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
## to start in a level or in the ending, or pick Keen 2: then that game
## starts at once ([method scene_for]).
static func skips_launcher(arguments: PackedStringArray) -> bool:
	for argument in arguments:
		if argument.begins_with(LEVEL_OPTION) or argument == ENDING_OPTION:
			return true
	return wants_keen_2(arguments)


## Whether [param arguments] pick Keen 2 with [constant GAME_OPTION].
static func wants_keen_2(arguments: PackedStringArray) -> bool:
	return arguments.has(GAME_OPTION + KEEN_2_GAME)


## The scene that [param arguments] start when they skip the start screen:
## Keen 2 with --game=2, otherwise Keen 1.
static func scene_for(arguments: PackedStringArray) -> String:
	return KEEN_2_SCENE if wants_keen_2(arguments) else KEEN_1_SCENE
