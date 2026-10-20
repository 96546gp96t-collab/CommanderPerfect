class_name Keen4Episode
extends RefCounted
## The numbers of Keen 4 that the shared Galaxy readers need
## ([GalaxyEpisode]), and the few that Keen 4's own code uses. Positions are
## raw offsets in the unpacked program; they are only tried first (the
## readers search by content). v1.0 and the shareware v1.4 are the user's
## (files; D13 checked CG's v1.4 places in them). See
## docs/keen4/research.md §0-§1.

## The size of the program file per version: v1.0 is packed with LZEXE,
## CG's v1.4 is not (the shareware v1.4 is packed too: 105,108 bytes; its
## sign-on gives its version, so the size is not needed).
const EXECUTABLE_SIZES: Dictionary[String, int] = {"1.0": 102355, "1.4": 263488}
const AUDIOHED_V1_0 := 0x1FB80
const AUDIOHED_V1_4 := 0x20DF0
const EGAHEAD_V1_0 := 0x1FE10
const EGAHEAD_V1_4 := 0x21080
const MAPHEAD_V1_0 := 0x235B0
const MAPHEAD_V1_4 := 0x24830
const AUDIODCT_V1_0 := 0x33FF6
const AUDIODCT_V1_4 := 0x354F6
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
const LEVEL_NAMES_V1_4 := 0x1F040
## The messages of the council members, Lindsey and Keen, found by their
## numbers of lines (files, v1.0): Lindsey's two hints, Keen's two thanks,
## "Princess Lindsey says:", the two wetsuit lines, Keen's eight answers to
## the council members, then the member's message under water and on land.
const COUNCIL_MESSAGES := "council"
const COUNCIL_SHAPE: PackedInt32Array = [4, 4, 1, 3, 1, 1, 2, 2, 2, 1, 3, 1, 3, 2, 4, 5, 5]
const COUNCIL_V1_0 := 0x2F5BC
const COUNCIL_V1_4 := 0x3094C
## The janitor of level 14 and Keen's reply, right after the level texts.
const JANITOR_MESSAGES := "janitor"
const JANITOR_SHAPE: PackedInt32Array = [4, 3, 2, 2]
const JANITOR_V1_0 := 0x1E280
const JANITOR_V1_4 := 0x1F580
## The labels of the status window (files, v1.0), found by their lengths:
## location, score, extra, rescued, level, the three difficulties, keys,
## ammo, lives, drops, and the wetsuit or its absence.
const STATUS_TEXTS := "status"
const STATUS_LENGTHS: PackedInt32Array = [8, 5, 5, 7, 5, 4, 6, 4, 4, 4, 5, 5, 7, 3]
const STATUS_V1_0 := 0x2E115
const STATUS_V1_4 := 0x2F487
## The run from "game over" to "one moment" (files, v1.0): game over, two
## memory errors, the demo texts, the three lines of the box after a
## death, two more memory errors and the box when Keen leaves the map.
const GAME_TEXTS := "game"
const GAME_LENGTHS: PackedInt32Array = [10, 31, 31, 4, 33, 22, 39, 23, 9, 19, 34, 48, 10]
const GAME_V1_0 := 0x2DD4C
const GAME_V1_4 := 0x2F0BE
## The story of the title loop (files, v1.0): one record of 30 lines.
const STORY_MESSAGES := "story"
const STORY_SHAPE: PackedInt32Array = [30]
const STORY_V1_0 := 0x1DB40
const STORY_V1_4 := 0x1EE40
## The box of the B+A+T cheat, then "PAUSED" and the drive prompt (files,
## v1.0), found by their lengths.
const CHEAT_TEXTS := "cheat"
const CHEAT_LENGTHS: PackedInt32Array = [70, 6, 3]
const CHEAT_V1_0 := 0x2E0C3
const CHEAT_V1_4 := 0x2F435
## The original's high-score table (files, v1.0 and v1.4): 8 records of
## 64 bytes.
const HIGH_SCORE_COUNT := 8
const HIGH_SCORES_V1_0 := 0x31E9C
const HIGH_SCORES_V1_4 := 0x33234
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
## The control panel (D10): the cards' title pictures and the wrist watch,
## counted from the end of the picture range (the same in v1.0 and v1.4;
## Omni PIC_MENUCARD ... PIC_WRISTWATCH; seen in v1.0).
const MENU_CARDS_FROM_END: Dictionary[StringName, int] = {
	MenuController.MAIN: 33,
	GalaxyMenuController.NEW_GAME: 32,
	MenuController.SLOTS_LOAD: 31,
	MenuController.SLOTS_SAVE: 30,
	GalaxyMenuController.CONFIGURE: 29,
	GalaxyMenuController.SOUND_CARD: 28,
	GalaxyMenuController.MUSIC_CARD: 27,
	MenuController.KEY_SET: 24,
	MenuController.OPTIONS: 22,
}
const WATCH_FROM_END := 18
## Paddle War's title picture (Omni PIC_PADDLEWAR; D11).
const PADDLE_WAR_FROM_END := 21
## The text pages (help, end; D8, D13): v1.0 lays them out on light grey
## in dark grey; v1.4 on red in yellow, inside a frame of five pictures
## that start at picture 74 (Omni PIC_BORDERTOP, chunk 80; seen in v1.4).
## v1.0 has other pictures there, so the frame is found by its sizes.
const PAGE_BACKGROUND := 7
const PAGE_TEXT_COLOR := 8
const FRAMED_PAGE_BACKGROUND := 4
const FRAMED_PAGE_TEXT_COLOR := 14
const PAGE_FRAME_PICTURE := 74


## The numbers above as a [GalaxyEpisode].
static func create() -> GalaxyEpisode:
	var episode := GalaxyEpisode.new()
	episode.extension = Keen4Files.EXTENSION
	episode.executables = Keen4Files.EXECUTABLES
	episode.executable_sizes = EXECUTABLE_SIZES
	episode.known_offsets = {
		GalaxyEpisode.Header.AUDIOHED: PackedInt32Array([AUDIOHED_V1_0, AUDIOHED_V1_4]),
		GalaxyEpisode.Header.EGAHEAD: PackedInt32Array([EGAHEAD_V1_0, EGAHEAD_V1_4]),
		GalaxyEpisode.Header.MAPHEAD: PackedInt32Array([MAPHEAD_V1_0, MAPHEAD_V1_4]),
		GalaxyEpisode.Header.AUDIODCT: PackedInt32Array([AUDIODCT_V1_0, AUDIODCT_V1_4]),
		GalaxyEpisode.Header.EGADICT: PackedInt32Array([EGADICT_V1_0, EGADICT_V1_4]),
	}
	episode.font_count = FONT_COUNT
	episode.misc_count = MISC_COUNT
	episode.text_count = TEXT_COUNT
	episode.demo_count = DEMO_COUNT
	episode.level_name_count = LEVEL_NAME_COUNT
	episode.known_level_name_offsets = PackedInt32Array([LEVEL_NAMES_V1_0, LEVEL_NAMES_V1_4])
	episode.message_shapes = {
		COUNCIL_MESSAGES: COUNCIL_SHAPE,
		JANITOR_MESSAGES: JANITOR_SHAPE,
		STORY_MESSAGES: STORY_SHAPE,
	}
	episode.known_message_offsets = {
		COUNCIL_MESSAGES: PackedInt32Array([COUNCIL_V1_0, COUNCIL_V1_4]),
		JANITOR_MESSAGES: PackedInt32Array([JANITOR_V1_0, JANITOR_V1_4]),
		STORY_MESSAGES: PackedInt32Array([STORY_V1_0, STORY_V1_4]),
	}
	episode.text_lengths = {
		STATUS_TEXTS: STATUS_LENGTHS, GAME_TEXTS: GAME_LENGTHS, CHEAT_TEXTS: CHEAT_LENGTHS
	}
	episode.known_text_offsets = {
		STATUS_TEXTS: PackedInt32Array([STATUS_V1_0, STATUS_V1_4]),
		GAME_TEXTS: PackedInt32Array([GAME_V1_0, GAME_V1_4]),
		CHEAT_TEXTS: PackedInt32Array([CHEAT_V1_0, CHEAT_V1_4]),
	}
	return episode


## Where the original's high-score table may be, in the known versions.
static func high_score_offsets() -> PackedInt32Array:
	return PackedInt32Array([HIGH_SCORES_V1_0, HIGH_SCORES_V1_4])


## The control panel's pictures in a picture range of [param picture_count].
static func menu_cards(picture_count: int) -> GalaxyMenuCards:
	var pictures: Dictionary[StringName, int] = {}
	for kind in MENU_CARDS_FROM_END:
		pictures[kind] = picture_count - MENU_CARDS_FROM_END[kind]
	var cards := GalaxyMenuCards.create(picture_count - WATCH_FROM_END, pictures)
	cards.paddle_war_picture = picture_count - PADDLE_WAR_FROM_END
	return cards


## A layout for the text pages of [param graphics] in the menu font, in
## the colours and with the frame of its version.
static func page_layout(graphics: GalaxyGraphics) -> GalaxyPageLayout:
	var layout := GalaxyPageLayout.create(graphics, MENU_FONT)
	layout.frame = GalaxyPageFrame.find(graphics, PAGE_FRAME_PICTURE)
	var framed := layout.frame != null
	layout.background = FRAMED_PAGE_BACKGROUND if framed else PAGE_BACKGROUND
	layout.default_color = FRAMED_PAGE_TEXT_COLOR if framed else PAGE_TEXT_COLOR
	return layout


## All of Keen 4 in [param files]; null when something is missing.
static func load_data(files: GameFiles) -> GalaxyData:
	return GalaxyData.load_from(files, create())
