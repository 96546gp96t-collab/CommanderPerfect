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
## Keen walking to the right (files, v1.0): the start screen's icon, as
## Keen 1-3 show him.
const KEEN_WALK_RIGHT_SPRITE := 7
## The font of the original's menus and windows (the first of three).
const MENU_FONT := 0


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
	episode.message_shapes = {COUNCIL_MESSAGES: COUNCIL_SHAPE, JANITOR_MESSAGES: JANITOR_SHAPE}
	episode.known_message_offsets = {
		COUNCIL_MESSAGES: PackedInt32Array([COUNCIL_V1_0]),
		JANITOR_MESSAGES: PackedInt32Array([JANITOR_V1_0]),
	}
	return episode


## All of Keen 4 in [param files]; null when something is missing.
static func load_data(files: GameFiles) -> GalaxyData:
	return GalaxyData.load_from(files, create())
