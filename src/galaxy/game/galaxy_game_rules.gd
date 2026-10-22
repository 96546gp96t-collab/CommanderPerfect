class_name GalaxyGameRules
extends RefCounted
## The numbers and tables of one Galaxy episode that the shared Galaxy game
## ([GalaxyLevelScreen], [GalaxyPlayScreen], [GalaxyLevelSession],
## [GalaxyStart]) needs: where its files are and how they are read, its
## maps, the info values that place Keen and the scroll blocks, its items,
## its sprites by name, the pictures behind its levels and its user folder.
## The episode fills them in ([method Keen5Episode.game_rules]); what an
## episode does that the others do not (creatures, its own doors, its
## people) comes through the virtual hooks of those classes, not from here.
## The defaults are Keen 4's numbers where Keen 4 and 5 agree (Omni
## `EPISODE.CK4`, `EPISODE.CK5`; docs/keen5/research.md §1, §5, §6).

## The episode's name in messages ("Keen 5").
var name := ""
## Returns the episode's [GameFiles], or null when they are not found
## (such as [method Keen5Files.locate]).
var locate_files: Callable
## Reads the episode from [GameFiles] into a [GalaxyData], or null (such
## as [method Keen5Episode.load_data]).
var load_data: Callable
## The folder the files belong in and the option that names another one,
## for the message when they are missing.
var data_folder := ""
var data_dir_option := ""
## The game's own folder in the user folder (settings, saves, the sound
## cache), such as [code]user://keen5[/code].
var user_folder := ""

## The world map, the levels and the last map (the high scores).
var world_map := 0
var first_level := 1
var last_level := 17
var last_map := 19
## Map slots the episode leaves empty (Keen 5: 14).
var missing_maps := PackedInt32Array()

## Info values (Omni CKx_ScanInfoLayer): Keen standing facing right or left
## (also the score box), Keen on the world map.
var keen_right_info := 1
var keen_left_info := 2
var map_keen_info := 3
## Scroll blocks: a row the view never scrolls over, a column; -1 for an
## episode without them (Keen 5 has no column blocks: its 26 is the arrival
## on Korath III).
var row_block_info := 25
var column_block_info := 26
## Items lying as sprites: info [member first_item_info] is item 0, and so
## on up to [member last_item_info]; [member more_item_infos] gives the
## item of other values (Keen 5: 70 is item 12, the keycard; Omni
## CK5_ScanInfoLayer); [member low_stunner_info] is a stunner only while
## Keen has fewer than [member low_shots] charges.
var first_item_info := 57
var last_item_info := 68
var more_item_infos: Dictionary[int, int] = {}
var low_stunner_info := 34
var low_shots := 5

## Keen standing, facing right and left, and on the world map (sprite
## indices).
var keen_stand_right_sprite := 6
var keen_stand_left_sprite := 14
var map_keen_sprite := -1
## Every sprite the game asks for by name: Keen's ([GalaxyKeenActions]),
## the items' (ITEM_n, SHADOW_n), the shot's, the splash, the score box
## (SCOREBOX).
var sprites: Dictionary[StringName, int] = {}

## A new game: lives, charges, the first extra life; the charges in a
## stunner item, more on Easy (Omni CK_KeenGetItem).
var start_lives := 3
var start_shots := 5
var first_extra_life := 20000
var stunner_charges := 5
var easy_stunner_charges := 8

## The pictures behind the levels: the episode's own folder (such as
## res://assets/backgrounds/keen5) and its plain sky tiles; none means no
## level ever shows a picture.
var backdrop_folder := ""
var sky_tiles := PackedInt32Array()


## The message when the files are not found.
func missing_data_message() -> String:
	return (
		"%s data not found. Put the files in %s or start with: -- %sPATH"
		% [name, data_folder, data_dir_option]
	)


## The message when the files in [param directory] cannot be read.
func unreadable_message(directory: String) -> String:
	return "The %s files in %s could not be read." % [name, directory]


## Whether map [param number] is one of the episode's levels (not the
## world map, not the high scores).
func is_level(number: int) -> bool:
	return number >= first_level and number <= last_level and not missing_maps.has(number)


## The level after [param number]: the next one that exists, the first
## after the last.
func next_level(number: int) -> int:
	var next := number + 1
	while not is_level(next):
		next = first_level if next > last_level else next + 1
	return next


## The item that info value [param info] places, or -1 (the low stunner
## is not counted: it depends on the charges).
func item_of_info(info: int) -> int:
	if info >= first_item_info and info <= last_item_info:
		return info - first_item_info
	return more_item_infos.get(info, -1)


## The charges a stunner item gives on [param level].
func charges_for(level: GalaxyDifficulty.Level) -> int:
	return easy_stunner_charges if level == GalaxyDifficulty.Level.EASY else stunner_charges


## The sprite that standing Keen shows facing [param facing] (1 right).
func keen_stand_sprite(facing: int) -> int:
	return keen_stand_right_sprite if facing > 0 else keen_stand_left_sprite


## Every sprite a played map can show (for xBRZ): all of [member sprites]
## and the second frame of every item lying as a sprite.
func level_sprites() -> PackedInt32Array:
	var shown: Dictionary[int, bool] = {}
	for sprite_name in sprites:
		shown[sprites[sprite_name]] = true
		if String(sprite_name).begins_with("ITEM_"):
			shown[sprites[sprite_name] + 1] = true
	return PackedInt32Array(shown.keys())
