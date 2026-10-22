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
## Keen 5's own pictures behind the levels: none yet (milestone E10), and
## no sky tiles named, so no level shows one.
const BACKDROP_FOLDER := "res://assets/backgrounds/keen5"
const SKY_TILES: PackedInt32Array = []
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


## The numbers of Keen 5 that the shared Galaxy game needs.
static func game_rules() -> GalaxyGameRules:
	var rules := GalaxyGameRules.new()
	rules.name = NAME
	rules.locate_files = Keen5Files.locate
	rules.load_data = load_data
	rules.data_folder = Keen5Files.SUBFOLDER
	rules.data_dir_option = Keen5Files.DATA_DIR_OPTION
	rules.user_folder = USER_FOLDER
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
	return rules


## Where the original's high-score table may be, in the known versions.
static func high_score_offsets() -> PackedInt32Array:
	return PackedInt32Array([HIGH_SCORES_V1_4])


## All of Keen 5 in [param files]; null when something is missing.
static func load_data(files: GameFiles) -> GalaxyData:
	return GalaxyData.load_from(files, create())
