class_name Keen5Episode
extends RefCounted
## The numbers of Keen 5 that the shared Galaxy readers need
## ([GalaxyEpisode]), and the few that Keen 5's own code uses. Positions are
## raw offsets in the unpacked program of v1.4, the user's version (files);
## they are only tried first, the readers search by content, so another
## version can work too. See docs/keen5/file-formats.md and
## docs/keen5/research.md §0-§1.

## The size of the program file per version: the program prints no version
## (no "(v1.4)" sign-on), so the size names it. 1.4 is the user's KEEN5E.EXE,
## packed with LZEXE (files); 1.0 is the unpacked size Commander Genius
## knows (CG `CExeFile.cpp`). An unpacked 1.4 (266,096 bytes) is found
## all the same, only its version reads "unknown".
const EXECUTABLE_SIZES: Dictionary[String, int] = {"1.0": 262176, "1.4": 106417}
const AUDIOHED_V1_4 := 0x21C80
const EGAHEAD_V1_4 := 0x21FC0
const MAPHEAD_V1_4 := 0x25990
const AUDIODCT_V1_4 := 0x35EC4
const EGADICT_V1_4 := 0x362C4
## EGAGRAPH chunks no table counts (files; Omni `GFXINFOE.CK5`): the
## texts come before the misc chunks.
const FONT_COUNT := 3
const MISC_COUNT := 5
const TEXT_COUNT := 7
const DEMO_COUNT := 5
## The 16×16 background tiles: 84 rows of 18. The last ones are empty, so
## the border cannot be worked out from the file (files: only with 1512
## every TILEINFO table lines up).
const BACK_TILE_COUNT := 1512
## Maps 0-15 have a name and a "Keen ..." text, also the empty slot 14
## (the Megarocket, files).
const LEVEL_NAME_COUNT := 16
const LEVEL_NAMES_V1_4 := 0x20040
## The story of the title loop (files): one record of 37 lines.
const STORY_MESSAGES := "story"
const STORY_SHAPE: PackedInt32Array = [37]
const STORY_V1_4 := 0x1FDE0
## The two messages after a fuse breaks (files): the Korath III fuse's,
## then the one of the four fuses that guard the elevator shaft. Found by
## their lengths: their numbers of lines (2 and 4) match too many places.
const FUSE_TEXTS := "fuse"
const FUSE_LENGTHS: PackedInt32Array = [36, 69]
const FUSE_V1_4 := 0x31BFB
## Which text of [constant FUSE_TEXTS] is which.
const KORATH_FUSE_TEXT := 0
const FUSE_TEXT := 1
## The labels of the status window (files), found by their lengths:
## location, score, extra, keycard, level, the three difficulties, keys,
## ammo, lives and drops.
const STATUS_TEXTS := "status"
const STATUS_LENGTHS: PackedInt32Array = [8, 5, 5, 7, 5, 4, 6, 4, 4, 4, 5, 7]
const STATUS_V1_4 := 0x308D3
## The run from the first memory error to "one moment" (files; Keen 5 has
## no "game over" text, it shows a picture): a memory error, the demo
## text, the arrival on Korath III, the demo recorder's three texts, the
## three lines of the box after a death, two more memory errors and the
## box when Keen leaves the map.
const GAME_TEXTS := "game"
const GAME_LENGTHS: PackedInt32Array = [31, 4, 30, 33, 22, 39, 23, 9, 18, 34, 48, 10]
const GAME_V1_4 := 0x3053E
## Which text of [constant GAME_TEXTS] is which: "DEMO", the arrival on
## Korath III, the three lines of the box after a death, "One moment".
const DEMO_TEXT := 1
const KORATH_TEXT := 2
const TRY_AGAIN_INTRO_TEXT := 6
const TRY_AGAIN_TEXT := 7
const EXIT_TEXT := 8
const ONE_MOMENT_TEXT := 11
## No "Game Over!" text (the galaxy explodes instead, milestone E7).
const NO_TEXT := -1
## Keen counting down is the seventh picture from the end (Omni
## PIC_COUNTDOWN5 = 92 of the pictures 6-98: GAMEOVER comes last).
const COUNTDOWN_FROM_END := 7
## A done level's flag stands here from its holder's corner (Omni
## CK_MapFlagSpawn, Keen 5); Keen 5 throws no flag.
const MAP_FLAG_OFFSET := Vector2i(-0x50, -0x1E0)
## The box of the B+A+T cheat, then "PAUSED" and the drive prompt (files),
## found by their lengths (the same as Keen 4's).
const CHEAT_TEXTS := "cheat"
const CHEAT_LENGTHS: PackedInt32Array = [70, 6, 3]
const CHEAT_V1_4 := 0x30881
## The start of the names of Keen 5's texts in a language file
## ([GalaxyTexts]).
const TEXT_NAMES := "keen5"
## The original's high-score table (files): 8 records of 64 bytes.
const HIGH_SCORE_COUNT := 8
const HIGH_SCORES_V1_4 := 0x33D56
## Keen standing and walking to the right, standing to the left: the same
## sprites as Keen 4's (files, seen by eye; Omni SPR_KEENSTANDR,
## SPR_KEENRUNR1, SPR_KEENSTANDL). The start screen's icon walks.
const KEEN_STAND_RIGHT_SPRITE := 6
const KEEN_WALK_RIGHT_SPRITE := 7
const KEEN_STAND_LEFT_SPRITE := 14
## The font of the original's menus and windows (the first of three).
const MENU_FONT := 0
## The world map, the levels, the empty slot and the high scores (Omni
## CK_highScoreLevel 15).
const WORLD_MAP := 0
const FIRST_LEVEL := 1
const LAST_LEVEL := 13
const EMPTY_MAP := 14
const HIGH_SCORE_MAP := 15
const LAST_MAP := 15
## Info values (Omni `ck5_misc.c:CK5_ScanInfoLayer`, research.md §6): Keen
## facing right or left, Keen on the world map; 25 a row the view never
## scrolls over (Keen 5 has no column blocks: its 26 is the arrival on
## Korath III); items 0-11 lie at 57-68, the keycard (item 12) at 70, a
## stunner at 69 only while Keen has fewer than 5 charges.
const KEEN_RIGHT_INFO := 1
const KEEN_LEFT_INFO := 2
const MAP_KEEN_INFO := 3
const ROW_BLOCK_INFO := 25
const NO_BLOCK_INFO := -1
const FIRST_ITEM_INFO := 57
const LAST_ITEM_INFO := 68
const LOW_STUNNER_INFO := 69
const KEYCARD_INFO := 70
## Keen on the world map (Omni SPR_MAPKEEN_STAND_W, chunk 244 − 102).
const MAP_KEEN_SPRITE := 142
## Keen 5's own pictures behind the levels (milestone E10,
## [Keen5BackdropPictures]): the plain sky tiles (black space 0, Korath
## III's light cyan sky 105) and the tiles that are open sky: Korath III's
## sky (the whole of level 13 is outdoors, its clouds also between the
## buildings) and the star tiles (files: at least 224 of their 256 pixels
## black, the rest white, grey or blue stars). Tile 0 is the only
## all-black tile and also the inside of every door, so it is no sign of
## open space by itself.
const BACKDROP_FOLDER := "res://assets/backgrounds/keen5"
const SPACE_TILE := 0
const KORATH_SKY_TILE := 105
const SKY_TILES: PackedInt32Array = [SPACE_TILE, KORATH_SKY_TILE]
const OPEN_SKY_TILES: PackedInt32Array = [
	KORATH_SKY_TILE,
	1,
	2,
	3,
	139,
	664,
	665,
	698,
	699,
	700,
	701,
	716,
	717,
	718,
	719,
	734,
	737,
	755,
	771,
	772,
	773,
	789,
	790,
	791,
	807,
	808,
	809,
	825,
	826,
	845,
	863,
	1100,
	1101,
	1103,
	1120
]
## What Keen 5 shows between its games (Omni `GFXCHUNK.CK5`, chunk − 6
## for a picture; files): pictures counted from the end of the range (the
## title, the story's picture, the first of four credits, the Milky Way,
## GAMEOVER), from the start (the help menu, its pointer, the end's arrows,
## the frame's first piece), the texts (HELPMENU 0, CONTROLS 1, STORY 2,
## ABOUTID 3, END 4, SECRETEND 5, ORDER 6) and the misc chunk of the
## galaxy's stars.
const TITLE_FROM_END := 11
const STORY_FROM_END := 12
const FIRST_CREDIT_FROM_END := 16
const MILKY_WAY_FROM_END := 10
const GAME_OVER_FROM_END := 1
const HELP_MENU_PICTURE := 0
const HELP_POINTER_PICTURE := 18
const ARROW_DIM_PICTURE := 20
const ARROW_BRIGHT_PICTURE := 21
const PAGE_FRAME_PICTURE := 22
const HELP_TOPIC_TEXTS: PackedInt32Array = [0, 1, 2, 6, 3]
const END_TEXT := 4
const SECRET_END_TEXT := 5
const GALAXY_MISC := 4
## The intro's words: red alone, light red over each other (Omni
## ck_terminatorPalette1: 4 and 0x1C); the story picture's palette (Omni
## ck_starWarsPalette as EGA colours: the text light cyan).
const INTRO_WORD_COLORS: Array[Color] = [Color8(170, 0, 0), Color8(255, 85, 85)]
const STORY_COLORS: PackedInt32Array = [0, 1, 8, 14, 15, 12, 6, 7, 11, 11, 11, 11, 11, 11, 11, 11]
## The DEMO sign (Omni SPR_DEMOSIGN, chunk 107 − 102).
const DEMO_SIGN_SPRITE := 5
## The high scores (Omni `EPISODE.CK5`): map 15, demo 4; the table's
## margins and colour; no extra column.
const HIGH_SCORE_DEMO := 4
const HIGH_SCORE_TOP := 0x23
const HIGH_SCORE_LEFT := 0x28
const HIGH_SCORE_RIGHT := 0x118
const HIGH_SCORE_COLOR := 12
const NO_TILE := -1
## The control panel's pictures, counted from the end of the range (Omni
## `GFXCHUNK.CK5`: PIC_MENUCARD 67 … PIC_WRISTWATCH 82 of the pictures
## 6-98; checked by eye, milestone E9): one less than Keen 4's. The keys'
## card is BUTTON SETUP, as Keen 4's.
const MENU_CARDS_FROM_END: Dictionary[StringName, int] = {
	MenuController.MAIN: 32,
	GalaxyMenuController.NEW_GAME: 31,
	MenuController.SLOTS_LOAD: 30,
	MenuController.SLOTS_SAVE: 29,
	GalaxyMenuController.CONFIGURE: 28,
	GalaxyMenuController.SOUND_CARD: 27,
	GalaxyMenuController.MUSIC_CARD: 26,
	MenuController.KEY_SET: 23,
	MenuController.OPTIONS: 21,
}
const WATCH_FROM_END := 17
const PADDLE_WAR_FROM_END := 20
const USER_FOLDER := "user://keen5"
const NAME := "Keen 5"


## The numbers above as a [GalaxyEpisode].
static func create() -> GalaxyEpisode:
	var episode := GalaxyEpisode.new()
	episode.extension = Keen5Files.EXTENSION
	episode.executables = Keen5Files.EXECUTABLES
	episode.executable_sizes = EXECUTABLE_SIZES
	episode.known_offsets = {
		GalaxyEpisode.Header.AUDIOHED: PackedInt32Array([AUDIOHED_V1_4]),
		GalaxyEpisode.Header.EGAHEAD: PackedInt32Array([EGAHEAD_V1_4]),
		GalaxyEpisode.Header.MAPHEAD: PackedInt32Array([MAPHEAD_V1_4]),
		GalaxyEpisode.Header.AUDIODCT: PackedInt32Array([AUDIODCT_V1_4]),
		GalaxyEpisode.Header.EGADICT: PackedInt32Array([EGADICT_V1_4]),
	}
	episode.font_count = FONT_COUNT
	episode.misc_count = MISC_COUNT
	episode.text_count = TEXT_COUNT
	episode.demo_count = DEMO_COUNT
	episode.back_tile_count = BACK_TILE_COUNT
	episode.texts_before_misc = true
	episode.level_name_count = LEVEL_NAME_COUNT
	episode.known_level_name_offsets = PackedInt32Array([LEVEL_NAMES_V1_4])
	episode.message_shapes = {STORY_MESSAGES: STORY_SHAPE}
	episode.known_message_offsets = {STORY_MESSAGES: PackedInt32Array([STORY_V1_4])}
	episode.text_lengths = {
		STATUS_TEXTS: STATUS_LENGTHS,
		GAME_TEXTS: GAME_LENGTHS,
		CHEAT_TEXTS: CHEAT_LENGTHS,
		FUSE_TEXTS: FUSE_LENGTHS,
	}
	episode.known_text_offsets = {
		STATUS_TEXTS: PackedInt32Array([STATUS_V1_4]),
		GAME_TEXTS: PackedInt32Array([GAME_V1_4]),
		CHEAT_TEXTS: PackedInt32Array([CHEAT_V1_4]),
		FUSE_TEXTS: PackedInt32Array([FUSE_V1_4]),
	}
	return episode


## Keen 5's pictures behind the levels for [param files] by [param rules].
static func make_backdrops(files: GameFiles, rules: GalaxyGameRules) -> GalaxyGameBackdrops:
	return Keen5BackdropPictures.with_open_tiles(files, rules, OPEN_SKY_TILES)


## The numbers of Keen 5 that the shared Galaxy game needs.
static func game_rules() -> GalaxyGameRules:
	var rules := GalaxyGameRules.new()
	rules.name = NAME
	rules.locate_files = Keen5Files.locate
	rules.load_data = load_data
	rules.data_folder = Keen5Files.SUBFOLDER
	rules.data_dir_option = Keen5Files.DATA_DIR_OPTION
	rules.user_folder = USER_FOLDER
	rules.game_id = Keen5Files.GAME_ID
	rules.world_map = WORLD_MAP
	rules.first_level = FIRST_LEVEL
	rules.last_level = LAST_LEVEL
	rules.last_map = LAST_MAP
	rules.missing_maps = PackedInt32Array([EMPTY_MAP])
	rules.keen_right_info = KEEN_RIGHT_INFO
	rules.keen_left_info = KEEN_LEFT_INFO
	rules.map_keen_info = MAP_KEEN_INFO
	rules.row_block_info = ROW_BLOCK_INFO
	rules.column_block_info = NO_BLOCK_INFO
	rules.first_item_info = FIRST_ITEM_INFO
	rules.last_item_info = LAST_ITEM_INFO
	rules.more_item_infos = {KEYCARD_INFO: Keen5Inventory.KEYCARD_ITEM}
	rules.low_stunner_info = LOW_STUNNER_INFO
	rules.keen_stand_right_sprite = KEEN_STAND_RIGHT_SPRITE
	rules.keen_stand_left_sprite = KEEN_STAND_LEFT_SPRITE
	rules.map_keen_sprite = MAP_KEEN_SPRITE
	rules.sprites = Keen5Sprites.all()
	rules.start_lives = Keen5Inventory.START_LIVES
	rules.start_shots = Keen5Inventory.START_SHOTS
	rules.first_extra_life = Keen5Inventory.FIRST_EXTRA_LIFE
	rules.map_flag_offset = MAP_FLAG_OFFSET
	rules.throws_map_flag = false
	rules.menu_font = MENU_FONT
	rules.status_texts = STATUS_TEXTS
	rules.game_texts = GAME_TEXTS
	rules.game_over_text = NO_TEXT
	rules.demo_text = DEMO_TEXT
	rules.try_again_intro_text = TRY_AGAIN_INTRO_TEXT
	rules.try_again_text = TRY_AGAIN_TEXT
	rules.exit_text = EXIT_TEXT
	rules.one_moment_text = ONE_MOMENT_TEXT
	rules.countdown_from_end = COUNTDOWN_FROM_END
	rules.backdrop_folder = BACKDROP_FOLDER
	rules.sky_tiles = SKY_TILES
	rules.make_backdrops = make_backdrops
	rules.cheat_texts = CHEAT_TEXTS
	_add_front_rules(rules)
	return rules


## The numbers of the screens between the games (milestone E7), the
## sounds and songs (E8, [Keen5Sounds]) and the control panel (E9).
static func _add_front_rules(rules: GalaxyGameRules) -> void:
	rules.title_from_end = TITLE_FROM_END
	rules.story_from_end = STORY_FROM_END
	rules.first_credit_from_end = FIRST_CREDIT_FROM_END
	rules.story_messages = STORY_MESSAGES
	rules.text_names = TEXT_NAMES
	rules.translated_runs = translated_runs()
	rules.intro_word_colors = INTRO_WORD_COLORS
	rules.story_colors = STORY_COLORS
	rules.demo_sign_sprite = DEMO_SIGN_SPRITE
	rules.high_score_map = HIGH_SCORE_MAP
	rules.high_score_demo = HIGH_SCORE_DEMO
	rules.high_score_count = HIGH_SCORE_COUNT
	rules.high_score_offsets = high_score_offsets()
	rules.high_score_top = HIGH_SCORE_TOP
	rules.high_score_left = HIGH_SCORE_LEFT
	rules.high_score_right = HIGH_SCORE_RIGHT
	rules.high_score_color = HIGH_SCORE_COLOR
	rules.high_score_icon_tile = NO_TILE
	rules.help_menu_picture = HELP_MENU_PICTURE
	rules.help_pointer_picture = HELP_POINTER_PICTURE
	rules.help_topic_texts = HELP_TOPIC_TEXTS
	rules.page_frame_picture = PAGE_FRAME_PICTURE
	rules.end_text = END_TEXT
	rules.secret_end_text = SECRET_END_TEXT
	rules.arrow_dim_picture = ARROW_DIM_PICTURE
	rules.arrow_bright_picture = ARROW_BRIGHT_PICTURE
	rules.story_song = Keen5Sounds.STORY_MAP
	rules.ending_song = Keen5Sounds.ENDING_MAP
	rules.game_over_song = Keen5Sounds.GAME_OVER_MAP
	rules.help_song = Keen5Sounds.HELP_MAP
	rules.sound_count = Keen5Sounds.SOUND_COUNT
	rules.song_count = Keen5Sounds.SONG_COUNT
	rules.sound_names = Keen5Sounds.NUMBERS
	rules.map_songs = Keen5Sounds.MAP_SONGS
	rules.menu_cards_from_end = MENU_CARDS_FROM_END
	rules.watch_from_end = WATCH_FROM_END
	rules.paddle_war_from_end = PADDLE_WAR_FROM_END


## Where the original's high-score table may be, in the known versions.
static func high_score_offsets() -> PackedInt32Array:
	return PackedInt32Array([HIGH_SCORES_V1_4])


## All of Keen 5 in [param files]; null when something is missing.
static func load_data(files: GameFiles) -> GalaxyData:
	return GalaxyData.load_from(files, create())


## The texts of each run the game shows
## ([member GalaxyGameRules.translated_runs]): the story, the status
## labels, "DEMO", the arrival on Korath III, the three lines after a
## death, "One moment", the cheat box and both fuse messages.
static func translated_runs() -> Dictionary[String, PackedInt32Array]:
	return {
		STORY_MESSAGES: PackedInt32Array([0]),
		STATUS_TEXTS: PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
		GAME_TEXTS:
		PackedInt32Array(
			[
				DEMO_TEXT,
				KORATH_TEXT,
				TRY_AGAIN_INTRO_TEXT,
				TRY_AGAIN_TEXT,
				EXIT_TEXT,
				ONE_MOMENT_TEXT
			]
		),
		CHEAT_TEXTS: PackedInt32Array([0]),
		FUSE_TEXTS: PackedInt32Array([KORATH_FUSE_TEXT, FUSE_TEXT]),
	}
