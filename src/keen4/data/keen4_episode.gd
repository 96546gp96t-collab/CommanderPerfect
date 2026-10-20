class_name Keen4Episode
extends RefCounted
## The numbers of Keen 4 that the shared Galaxy readers need
## ([GalaxyEpisode]), and the few that Keen 4's own code uses. Positions are
## raw offsets in the unpacked program; they are only tried first (the
## readers search by content). v1.0 is the user's (files), v1.4 from
## Commander Genius (CG). See docs/keen4/research.md §0-§1.

## The size of the program file per version: v1.0 is packed with LZEXE.
const EXECUTABLE_SIZES: Dictionary[String, int] = {"1.0": 102355, "1.4": 263488}
const AUDIOHED_V1_0 := 0x1FB80
const EGAHEAD_V1_0 := 0x1FE10
const EGAHEAD_V1_4 := 0x21080
const MAPHEAD_V1_0 := 0x235B0
const MAPHEAD_V1_4 := 0x24830
const AUDIODCT_V1_0 := 0x33FF6
const EGADICT_V1_0 := 0x343F6
const EGADICT_V1_4 := 0x358F6
## EGAGRAPH chunks no table counts (the same in v1.0 and v1.4).
const FONT_COUNT := 3
const MISC_COUNT := 4
const TEXT_COUNT := 7
const DEMO_COUNT := 5
## Maps 0-18 have a name and a "Keen enters ..." text; 19 (the high scores)
## has none.
const LEVEL_NAME_COUNT := 19
const LEVEL_NAMES_V1_0 := 0x1DD40
## The messages of the council members, Lindsey and Keen, found by their
## numbers of lines (files, v1.0): Lindsey's two hints, Keen's two thanks,
## "Princess Lindsey says:", the two wetsuit lines, Keen's eight answers to
## the council members, then the member's message under water and on land.
const COUNCIL_MESSAGES := "council"
const COUNCIL_SHAPE: PackedInt32Array = [4, 4, 1, 3, 1, 1, 2, 2, 2, 1, 3, 1, 3, 2, 4, 5, 5]
const COUNCIL_V1_0 := 0x2F5BC
## The janitor of level 14 and Keen's reply, right after the level texts.
const JANITOR_MESSAGES := "janitor"
const JANITOR_SHAPE: PackedInt32Array = [4, 3, 2, 2]
const JANITOR_V1_0 := 0x1E280
## The labels of the status window (files, v1.0), found by their lengths:
## location, score, extra, rescued, level, the three difficulties, keys,
## ammo, lives, drops, and the wetsuit or its absence.
const STATUS_TEXTS := "status"
const STATUS_LENGTHS: PackedInt32Array = [8, 5, 5, 7, 5, 4, 6, 4, 4, 4, 5, 5, 7, 3]
const STATUS_V1_0 := 0x2E115
## The run from "game over" to "one moment" (files, v1.0): game over, two
## memory errors, the demo texts, the three lines of the box after a
## death, two more memory errors and the box when Keen leaves the map.
const GAME_TEXTS := "game"
const GAME_LENGTHS: PackedInt32Array = [10, 31, 31, 4, 33, 22, 39, 23, 9, 19, 34, 48, 10]
const GAME_V1_0 := 0x2DD4C
## The story of the title loop (files, v1.0): one record of 30 lines.
const STORY_MESSAGES := "story"
const STORY_SHAPE: PackedInt32Array = [30]
const STORY_V1_0 := 0x1DB40
## The box of the B+A+T cheat, then "PAUSED" and the drive prompt (files,
## v1.0), found by their lengths.
const CHEAT_TEXTS := "cheat"
const CHEAT_LENGTHS: PackedInt32Array = [70, 6, 3]
const CHEAT_V1_0 := 0x2E0C3
## The original's high-score table (files, v1.0): 8 records of 64 bytes.
const HIGH_SCORE_COUNT := 8
const HIGH_SCORES_V1_0 := 0x31E9C
## Keen walking to the right (files, v1.0): the start screen's icon, as
## Keen 1-3 show him.
const KEEN_WALK_RIGHT_SPRITE := 7
## The font of the original's menus and windows (the first of three).
const MENU_FONT := 0
## Keen standing, facing right and left (Omni SPR_KEENSTANDR and
## SPR_KEENSTANDL, sprites 6 and 14 in v1.0 and v1.4).
const KEEN_STAND_RIGHT_SPRITE := 6
const KEEN_STAND_LEFT_SPRITE := 14
## The world map, the levels and the last map (the high scores).
const WORLD_MAP := 0
const FIRST_LEVEL := 1
const LAST_LEVEL := 17
const LAST_MAP := 19
## The map of the high scores (Omni CK_highScoreLevel).
const HIGH_SCORE_MAP := 19
## Info values (Omni `ck4_misc.c:CK4_ScanInfoLayer`, research.md §6): Keen
## facing right or left, Keen on the world map, Keen swimming (level 17).
const KEEN_RIGHT_INFO := 1
const KEEN_LEFT_INFO := 2
const MAP_KEEN_INFO := 3
const SWIMMING_KEEN_INFO := 42
## Scroll blocks: 25 is a row the view never scrolls over (Omni calls it a
## vertical block), 26 a column.
const ROW_BLOCK_INFO := 25
const COLUMN_BLOCK_INFO := 26
## The plain sky tiles (one colour, nothing on them; files, v1.0): light
## cyan 1085-1088, 1104 and 1105, and the light blue 478 (the sky of level
## 5, but also water in levels 8 and 10 and on the world map: a level's sky
## is the one in its top row; docs/keen4/gameplay.md).
const SKY_TILES: PackedInt32Array = [478, 1085, 1086, 1087, 1088, 1104, 1105]
## Keen 4's own pictures behind the levels (none yet; the player can add
## his own in game_data/keen4/backgrounds).
const BACKDROP_FOLDER := "res://assets/backgrounds/keen4"


## The numbers above as a [GalaxyEpisode].
static func create() -> GalaxyEpisode:
	var episode := GalaxyEpisode.new()
	episode.extension = Keen4Files.EXTENSION
	episode.executables = Keen4Files.EXECUTABLES
	episode.executable_sizes = EXECUTABLE_SIZES
	episode.known_offsets = {
		GalaxyEpisode.Header.AUDIOHED: PackedInt32Array([AUDIOHED_V1_0]),
		GalaxyEpisode.Header.EGAHEAD: PackedInt32Array([EGAHEAD_V1_0, EGAHEAD_V1_4]),
		GalaxyEpisode.Header.MAPHEAD: PackedInt32Array([MAPHEAD_V1_0, MAPHEAD_V1_4]),
		GalaxyEpisode.Header.AUDIODCT: PackedInt32Array([AUDIODCT_V1_0]),
		GalaxyEpisode.Header.EGADICT: PackedInt32Array([EGADICT_V1_0, EGADICT_V1_4]),
	}
	episode.font_count = FONT_COUNT
	episode.misc_count = MISC_COUNT
	episode.text_count = TEXT_COUNT
	episode.demo_count = DEMO_COUNT
	episode.level_name_count = LEVEL_NAME_COUNT
	episode.known_level_name_offsets = PackedInt32Array([LEVEL_NAMES_V1_0])
	episode.message_shapes = {
		COUNCIL_MESSAGES: COUNCIL_SHAPE,
		JANITOR_MESSAGES: JANITOR_SHAPE,
		STORY_MESSAGES: STORY_SHAPE,
	}
	episode.known_message_offsets = {
		COUNCIL_MESSAGES: PackedInt32Array([COUNCIL_V1_0]),
		JANITOR_MESSAGES: PackedInt32Array([JANITOR_V1_0]),
		STORY_MESSAGES: PackedInt32Array([STORY_V1_0]),
	}
	episode.text_lengths = {
		STATUS_TEXTS: STATUS_LENGTHS, GAME_TEXTS: GAME_LENGTHS, CHEAT_TEXTS: CHEAT_LENGTHS
	}
	episode.known_text_offsets = {
		STATUS_TEXTS: PackedInt32Array([STATUS_V1_0]),
		GAME_TEXTS: PackedInt32Array([GAME_V1_0]),
		CHEAT_TEXTS: PackedInt32Array([CHEAT_V1_0]),
	}
	return episode


## All of Keen 4 in [param files]; null when something is missing.
static func load_data(files: GameFiles) -> GalaxyData:
	return GalaxyData.load_from(files, create())
