class_name Keen2Files
extends RefCounted
## Finds the player's own Keen 2 files, the way [GameFiles] finds Keen 1's:
##   1. the folder given with the command-line option --data-dir-keen2=PATH
##   2. game_data/keen2 inside the project folder (handy while developing)
##   3. game_data/keen2 next to the exported game executable
##   4. game_data/keen2 next to a macOS app
##
## The result is an ordinary [GameFiles] set up for Keen 2 (extension CK2,
## Keen 2's required files), so every shared decoder reads it. Keen 2 has no
## SOUNDS, story, help or end text file: those are inside KEEN2.EXE (see
## [Keen2Executable] and docs/keen2/file-formats.md).

const DATA_DIR_OPTION := "--data-dir-keen2="
const SUBFOLDER := "game_data/keen2"
const EXTENSION := "CK2"
const EXECUTABLE := "KEEN2.EXE"
const FINALE := "FINALE.CK2"
const REQUIRED_FILES: PackedStringArray = [
	"EGAHEAD.CK2", "EGALATCH.CK2", "EGASPRIT.CK2", EXECUTABLE
]
const FIRST_LEVEL := 1
const LAST_LEVEL := 16
const WORLD_MAP_LEVEL := 80
## Space scenes: the ending and the Earth exploding.
const SPACE_LEVEL := 81
## The title screen, the story and the high scores.
const TITLE_LEVEL := 90


## The Keen 2 files in the first folder that holds all required files, or
## null when there is none.
static func locate() -> GameFiles:
	return GameFiles.locate_in(SUBFOLDER, REQUIRED_FILES, DATA_DIR_OPTION, EXTENSION)


## Folders that are searched by [method locate], in order.
static func candidate_directories() -> PackedStringArray:
	return GameFiles.candidate_directories_in(SUBFOLDER, DATA_DIR_OPTION)


## The first of [param candidates] with all Keen 2 files; null when none.
static func find_in(candidates: PackedStringArray) -> GameFiles:
	return GameFiles.first_complete(candidates, REQUIRED_FILES, EXTENSION)


## Opens [param path] as a Keen 2 folder; null when it does not exist.
static func open(path: String) -> GameFiles:
	return GameFiles.open(path, EXTENSION, REQUIRED_FILES)


## Every map the game has: levels 1-16, the world map, space and the title.
static func expected_level_numbers() -> PackedInt32Array:
	var numbers := PackedInt32Array(range(FIRST_LEVEL, LAST_LEVEL + 1))
	numbers.append_array([WORLD_MAP_LEVEL, SPACE_LEVEL, TITLE_LEVEL])
	return numbers
