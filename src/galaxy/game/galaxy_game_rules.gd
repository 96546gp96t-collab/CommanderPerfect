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

## The world map (Omni CK_MapFlagSpawn, CK_FlippingFlagSpawn): where a
## done level's flag stands from its holder's tile corner (Keen 4 0x60,
## Keen 5 -0x50 across), whether the flag of the level just finished is
## thrown there from Keen (Keen 4; Keen 5 has no thrown flag) and where
## that throw ends.
var map_flag_offset := Vector2i(0x60, -0x1E0)
var throws_map_flag := true
var map_flag_throw_offset := Vector2i(0x60, -0x260)

## The boxes and the status window (milestone E6): the font of the
## original's windows, the names of the episode's runs of texts in its
## program ([member GalaxyEpisode.text_lengths]) and which text of the
## game run is which (Keen 4's numbers by default; -1 for a text the
## episode does not have: Keen 5 shows a picture for "Game Over!").
var menu_font := 0
var status_texts := "status"
var game_texts := "game"
## The run of texts whose first is the B+A+T cheat's box (E7).
var cheat_texts := "cheat"
var game_over_text := 0
var demo_text := 3
var try_again_intro_text := 7
var try_again_text := 8
var exit_text := 9
var one_moment_text := 12
## Keen counting down while a map "loads" is this many pictures from the
## end of the picture range (Omni PIC_COUNTDOWN5; Keen 4 6, Keen 5 7: its
## GAMEOVER picture comes after the count-down).
var countdown_from_end := 6

## What the episode shows between its games (milestone E7; Keen 4's
## numbers by default, Omni `ck_inter.c`, `ck_text.c`, `GFXCHUNK.CK*`):
## the pictures counted from the end of the picture range (the title, the
## story's picture, the first of the credits), the misc chunks of the
## intro's two words, the story's font and run of messages.
var title_from_end := 12
var story_from_end := 13
var first_credit_from_end := 17
var credit_count := 4
var left_word_misc := 1
var right_word_misc := 2
var story_font := 2
var story_messages := "story"
## The intro's words: alone and overlapping (an empty array: Keen 4's dark
## and light grey, drawn by adding); the story picture's palette (EGA
## numbers per colour of the picture; empty: Keen 4's).
var intro_word_colors: Array[Color] = []
var story_colors := PackedInt32Array()
## The DEMO sign (a sprite) at the top middle of the view.
var demo_sign_sprite := 5
## The high scores: the map behind the table and the demo played on it,
## the number of places, where the original's table lies in the known
## programs, the table's margins and colour (the print colour XORed over
## the map), and the tile shown per counted thing (Keen 4's council
## members; -1: no extra column).
var high_score_map := 19
var high_score_demo := 4
var high_score_count := 8
var high_score_offsets := PackedInt32Array()
var high_score_top := 0x33
var high_score_left := 0x18
var high_score_right := 0x128
var high_score_color := 15
var high_score_icon_tile := 71
## The help (F1) and the end pages: the menu picture and the pointer
## (counted from the start of the picture range), the text of each topic in
## the menu's order, the first of the frame's five pictures (later
## releases), the end texts (the secret end: -1 when the episode has none)
## and the blinking arrow's two pictures.
var help_menu_picture := 0
var help_pointer_picture := 39
var help_topic_texts := PackedInt32Array([0, 2, 1, 6, 3])
var page_frame_picture := 74
var end_text := 4
var secret_end_text := -1
var arrow_dim_picture := 41
var arrow_bright_picture := 42
## The songs of the screens between the games, each named by the map
## whose song it is (Omni StartMusic takes a map; -1: none, the music
## stops): the story, the end, game over, the help (Keen 5 plays one, Keen
## 4 stops the music).
var story_song := 12
var ending_song := 7
var game_over_song := -1
var help_song := -1

## Sound and music (milestone E8; Omni `EPISODE.CK*`): the number of sounds
## per device (the PC speaker's from chunk 0, the AdLib's after them), the
## number of songs (the last chunks of the audio file), the sounds by the
## names the code plays, the song of every map (-1: none).
var sound_count := 52
var song_count := 6
var sound_names: Dictionary[StringName, int] = {}
var map_songs := PackedInt32Array()

## The pictures behind the levels: the episode's own folder (such as
## res://assets/backgrounds/keen5) and its plain sky tiles; none means no
## level ever shows a picture.
var backdrop_folder := ""
var sky_tiles := PackedInt32Array()


## Where the episode's high scores are kept (its own user folder).
func high_scores_path() -> String:
	return user_folder.path_join("high_scores.json")


## Where the episode's rendered AdLib sounds and songs are kept (its own
## user folder, never another episode's).
func sound_cache_folder() -> String:
	return user_folder.path_join("cache")


## Where the episode's own settings are kept (the quiet AdLib sounds, the
## score box; the sound device and the music are the shared settings').
func settings_path() -> String:
	return user_folder.path_join("settings.cfg")


## The song of map [param map]; -1 for none.
func song_for_map(map: int) -> int:
	if map < 0 or map >= map_songs.size():
		return -1
	return map_songs[map]


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
