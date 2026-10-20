class_name Keen3Files
extends RefCounted
## Finds the player's own Keen 3 files, the way [Keen2Files] finds Keen 2's:
##   1. the folder given with the command-line option --data-dir-keen3=PATH
##   2. game_data/keen3 inside the project folder (handy while developing)
##   3. game_data/keen3 next to the exported game executable
##   4. game_data/keen3 next to a macOS app
##
## The result is an ordinary [GameFiles] set up for Keen 3 (extension CK3,
## Keen 3's required files), so every shared decoder reads it. Keen 3 has no
## SOUNDS, story, help, previews or end text file: those are inside KEEN3.EXE
## (see [Keen3Executable] and docs/keen3/file-formats.md).

const DATA_DIR_OPTION := "--data-dir-keen3="
const SUBFOLDER := "game_data/keen3"
const EXTENSION := "CK3"
const EXECUTABLE := "KEEN3.EXE"
const HEADER := "EGAHEAD.CK3"
const FINALE := "FINALE.CK3"
const REQUIRED_FILES: PackedStringArray = [HEADER, "EGALATCH.CK3", "EGASPRIT.CK3", EXECUTABLE]
const FIRST_LEVEL := 1
const LAST_LEVEL := 16
const WORLD_MAP_LEVEL := 80
## The hall where Keen gets the Big V in the ending.
const ENDING_LEVEL := 81
## The title screen, the id page, the ordering page and the high scores.
const TITLE_LEVEL := 90


## The Keen 3 files in the first folder that holds all required files, or
## null when there is none.
static func locate() -> GameFiles:
	return GameFiles.locate_in(SUBFOLDER, REQUIRED_FILES, DATA_DIR_OPTION, EXTENSION)


## Folders that are searched by [method locate], in order.
static func candidate_directories() -> PackedStringArray:
	return GameFiles.candidate_directories_in(SUBFOLDER, DATA_DIR_OPTION)


## The first of [param candidates] with all Keen 3 files; null when none.
static func find_in(candidates: PackedStringArray) -> GameFiles:
	return GameFiles.first_complete(candidates, REQUIRED_FILES, EXTENSION)


## Opens [param path] as a Keen 3 folder; null when it does not exist.
static func open(path: String) -> GameFiles:
	return GameFiles.open(path, EXTENSION, REQUIRED_FILES)


## Every map the game has: levels 1-16, the world map, the ending and the
## title.
static func expected_level_numbers() -> PackedInt32Array:
	var numbers := PackedInt32Array(range(FIRST_LEVEL, LAST_LEVEL + 1))
	numbers.append_array([WORLD_MAP_LEVEL, ENDING_LEVEL, TITLE_LEVEL])
	return numbers
