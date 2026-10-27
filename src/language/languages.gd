class_name Languages
extends RefCounted
## Finds the languages the player can pick. A language is a folder named
## after its code ("nl") with one or more .txt files ([LanguageFile]) in a
## folder `languages`: the ones that come with the game inside the app, and
## the player's own in a folder `languages` next to `game_data` (next to the
## app). A player's folder with the code of a language that comes with the
## game adds to it and wins where both translate the same text.
##
## English is always there and needs no files: it is the game as it is.

const ENGLISH := "en"
const ENGLISH_NAME := "English"
const SUBFOLDER := "languages"
const BUILT_IN := "res://languages"
## Command line option for another folder of languages (tests, tools).
const FOLDER_OPTION := "--languages="
const FILE_EXTENSION := "txt"


## The folders searched, in order: the languages of the app first, so that
## the player's own win.
static func folders() -> PackedStringArray:
	var found := PackedStringArray([BUILT_IN])
	for folder in GameFiles.candidate_directories_in(SUBFOLDER, FOLDER_OPTION):
		var absolute := folder.simplify_path()
		if absolute != ProjectSettings.globalize_path(BUILT_IN).simplify_path():
			if not found.has(absolute):
				found.append(absolute)
	return found


## Every language that can be picked as code -> name, English first and the
## others in the order of their names.
static func available(search: PackedStringArray = folders()) -> Dictionary[String, String]:
	var names: Dictionary[String, String] = {}
	for code in _codes(search):
		var language := load_language(code, search)
		if language != null:
			names[code] = language.name if not language.name.is_empty() else code
	var codes := names.keys()
	codes.sort_custom(func(a: String, b: String) -> bool: return names[a] < names[b])
	var ordered: Dictionary[String, String] = {ENGLISH: ENGLISH_NAME}
	for code: String in codes:
		if code != ENGLISH:
			ordered[code] = names[code]
	return ordered


## All files of the language [param code] in [param search], merged; null
## when there are none (or for English, which needs none).
static func load_language(code: String, search: PackedStringArray = folders()) -> LanguageFile:
	if code.is_empty() or code == ENGLISH:
		return null
	var language: LanguageFile = null
	for folder in search:
		var path := folder.path_join(code)
		if not DirAccess.dir_exists_absolute(path):
			continue
		var files := Array(DirAccess.get_files_at(path))
		files.sort()
		for file_name: String in files:
			if file_name.get_extension().to_lower() != FILE_EXTENSION:
				continue
			var part := LanguageFile.load_from(path.path_join(file_name))
			if part == null:
				continue
			if language == null:
				language = part
			else:
				language.merge(part)
	return language


static func _codes(search: PackedStringArray) -> PackedStringArray:
	var codes := PackedStringArray()
	for folder in search:
		if not DirAccess.dir_exists_absolute(folder):
			continue
		for code in DirAccess.get_directories_at(folder):
			if not codes.has(code) and not code.begins_with("."):
				codes.append(code)
	return codes
