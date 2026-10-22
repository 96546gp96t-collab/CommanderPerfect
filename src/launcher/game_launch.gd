class_name GameLaunch
extends RefCounted
## What the start screen ([Launcher]) hands to the game it starts: whether
## the game opens its main menu straight away (it does when the player
## picked it on the start screen), and which command-line options skip the
## start screen altogether (for testing).

const LAUNCHER_SCENE := "res://src/launcher/launcher.tscn"
const KEEN_1_SCENE := "res://src/game/level_view.tscn"
const KEEN_2_SCENE := "res://src/keen2/keen2_view.tscn"
const KEEN_3_SCENE := "res://src/keen3/keen3_view.tscn"
const KEEN_4_SCENE := "res://src/keen4/keen4_view.tscn"
const KEEN_5_SCENE := "res://src/keen5/keen5_view.tscn"
## Start in level N (80 is the world map) instead of at the title.
const LEVEL_OPTION := "--level="
## Show the ending straight away.
const ENDING_OPTION := "--ending"
## Which game the other options are for: --game=2 starts Keen 2, --game=3
## Keen 3, --game=4 Keen 4, --game=5 Keen 5 (also in the data viewer and
## the graphics export). Without it everything is Keen 1.
const GAME_OPTION := "--game="
const KEEN_2_GAME := "2"
const KEEN_3_GAME := "3"
const KEEN_4_GAME := "4"
const KEEN_5_GAME := "5"

static var _menu_requested := false
static var _join_requested: OnlineJoin


## A game to join online that the next game picks up when it starts: the
## player chose a host who plays another game, so the game switched over
## (see [OnlinePlay]). By IP [member address], through Steam [member
## lobby_id].
class OnlineJoin:
	extends RefCounted
	var address := ""
	var lobby_id := 0
	var password := ""


## The next game should join [param join] as soon as it is shown.
static func request_join(join: OnlineJoin) -> void:
	_join_requested = join


## The game to join, or null; asks only once.
static func take_join_request() -> OnlineJoin:
	var join := _join_requested
	_join_requested = null
	return join


## The game should open its main menu as soon as it is shown.
static func request_menu() -> void:
	_menu_requested = true


## Whether the game should open its main menu; asks only once.
static func take_menu_request() -> bool:
	var requested := _menu_requested
	_menu_requested = false
	return requested


## Whether [param arguments] (the user arguments on the command line) ask
## to start in a level or in the ending, or pick Keen 2, 3, 4 or 5: then that
## game starts at once ([method scene_for]).
static func skips_launcher(arguments: PackedStringArray) -> bool:
	for argument in arguments:
		if argument.begins_with(LEVEL_OPTION) or argument == ENDING_OPTION:
			return true
	return game_number(arguments) != 1


## Whether [param arguments] pick Keen 2 with [constant GAME_OPTION].
static func wants_keen_2(arguments: PackedStringArray) -> bool:
	return arguments.has(GAME_OPTION + KEEN_2_GAME)


## Whether [param arguments] pick Keen 3 with [constant GAME_OPTION].
static func wants_keen_3(arguments: PackedStringArray) -> bool:
	return arguments.has(GAME_OPTION + KEEN_3_GAME)


## Whether [param arguments] pick Keen 4 with [constant GAME_OPTION].
static func wants_keen_4(arguments: PackedStringArray) -> bool:
	return arguments.has(GAME_OPTION + KEEN_4_GAME)


## Whether [param arguments] pick Keen 5 with [constant GAME_OPTION].
static func wants_keen_5(arguments: PackedStringArray) -> bool:
	return arguments.has(GAME_OPTION + KEEN_5_GAME)


## The game that [param arguments] pick: 2 with --game=2, 3 with --game=3,
## 4 with --game=4, 5 with --game=5, otherwise 1. When several are given
## the lowest wins, so every combination that worked before Keen 4 or 5
## gives the same game.
static func game_number(arguments: PackedStringArray) -> int:
	if wants_keen_2(arguments):
		return 2
	if wants_keen_3(arguments):
		return 3
	if wants_keen_4(arguments):
		return 4
	if wants_keen_5(arguments):
		return 5
	return 1


## The scene that [param arguments] start when they skip the start screen:
## Keen 2 with --game=2, Keen 3 with --game=3, Keen 4 with --game=4,
## Keen 5 with --game=5, otherwise Keen 1.
static func scene_for(arguments: PackedStringArray) -> String:
	match game_number(arguments):
		2:
			return KEEN_2_SCENE
		3:
			return KEEN_3_SCENE
		4:
			return KEEN_4_SCENE
		5:
			return KEEN_5_SCENE
	return KEEN_1_SCENE
