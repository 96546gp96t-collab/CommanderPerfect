class_name Keen5Files
extends RefCounted
## Finds the player's own Keen 5 files, the way [Keen4Files] finds Keen 4's:
##   1. the folder given with the command-line option --data-dir-keen5=PATH
##   2. game_data/keen5 inside the project folder (handy while developing)
##   3. game_data/keen5 next to the exported game executable
##   4. game_data/keen5 next to a macOS app
##
## The folder must hold EGAGRAPH.CK5, GAMEMAPS.CK5, AUDIO.CK5 and the
## program, KEEN5E.EXE (v1.4, the user's) or KEEN5.EXE. The program holds
## the headers of the other files ([GalaxyHeaders]). See
## docs/keen5/file-formats.md and game_data/README.md.

const DATA_DIR_OPTION := "--data-dir-keen5="
const SUBFOLDER := "game_data/keen5"
const EXTENSION := "CK5"
const EXECUTABLES: PackedStringArray = ["KEEN5E.EXE", "KEEN5.EXE"]
const REQUIRED_FILES: PackedStringArray = ["EGAGRAPH.CK5", "GAMEMAPS.CK5", "AUDIO.CK5"]
## Keen 5's id online. Not yet in [constant OnlineProtocol.GAME_IDS]: Keen 5
## goes online in milestone E11.
const GAME_ID := "commanderperfect-keen5"


## The Keen 5 files in the first folder that holds all of them, or null.
static func locate() -> GameFiles:
	return find_in(candidate_directories())


## Folders that are searched by [method locate], in order.
static func candidate_directories() -> PackedStringArray:
	return GameFiles.candidate_directories_in(SUBFOLDER, DATA_DIR_OPTION)


## The first of [param candidates] with all Keen 5 files; null when none.
static func find_in(candidates: PackedStringArray) -> GameFiles:
	for candidate in candidates:
		var files := open(candidate)
		if files != null and is_complete(files):
			return files
	return null


## Opens [param path] as a Keen 5 folder; null when it does not exist.
static func open(path: String) -> GameFiles:
	return GameFiles.open(path, EXTENSION, REQUIRED_FILES)


## Whether [param files] holds the data files and one of the programs.
static func is_complete(files: GameFiles) -> bool:
	return files.has_required_files() and not executable_in(files).is_empty()


## The program in [param files] ("" when there is none).
static func executable_in(files: GameFiles) -> String:
	for name in EXECUTABLES:
		if files.has_file(name):
			return name
	return ""
