class_name Keen4Files
extends RefCounted
## Finds the player's own Keen 4 files, the way [Keen3Files] finds Keen 3's:
##   1. the folder given with the command-line option --data-dir-keen4=PATH
##   2. game_data/keen4 inside the project folder (handy while developing)
##   3. game_data/keen4 next to the exported game executable
##   4. game_data/keen4 next to a macOS app
##
## The folder must hold EGAGRAPH.CK4, GAMEMAPS.CK4, AUDIO.CK4 and the
## program, KEEN4E.EXE (v1.0, the user's) or KEEN4.EXE. The program holds
## the headers of the other files ([GalaxyHeaders]). See
## docs/keen4/file-formats.md and game_data/README.md.

const DATA_DIR_OPTION := "--data-dir-keen4="
const SUBFOLDER := "game_data/keen4"
const EXTENSION := "CK4"
const EXECUTABLES: PackedStringArray = ["KEEN4E.EXE", "KEEN4.EXE"]
const REQUIRED_FILES: PackedStringArray = ["EGAGRAPH.CK4", "GAMEMAPS.CK4", "AUDIO.CK4"]
## Keen 4's id online. Keen 4 cannot be played online yet (D12), so this
## is not in [constant OnlineProtocol.GAME_IDS] and no host matches it.
const GAME_ID := "commanderperfect-keen4"


## The Keen 4 files in the first folder that holds all of them, or null.
static func locate() -> GameFiles:
	return find_in(candidate_directories())


## Folders that are searched by [method locate], in order.
static func candidate_directories() -> PackedStringArray:
	return GameFiles.candidate_directories_in(SUBFOLDER, DATA_DIR_OPTION)


## The first of [param candidates] with all Keen 4 files; null when none.
static func find_in(candidates: PackedStringArray) -> GameFiles:
	for candidate in candidates:
		var files := open(candidate)
		if files != null and is_complete(files):
			return files
	return null


## Opens [param path] as a Keen 4 folder; null when it does not exist.
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
