class_name GalaxyTexts
extends RefCounted
## The texts of a Galaxy episode's own files (Keen 4 and 5) that a language
## can translate, by their names, and the translation of each where the
## game shows it ([Lang]). A name starts with the episode's
## ([member GalaxyGameRules.text_names], "keen4"):
##   - [code]keen4.level.<map>[/code]: a map's name (the status window, the
##     box after a death, the status line);
##   - [code]keen4.enter.<map>[/code]: "Keen enters ..." while a map loads;
##   - [code]keen4.<run>.<index>[/code]: a text of one of the program's
##     runs ([member GalaxyGameRules.translated_runs]: the status window's
##     labels, the game's boxes, the cheat box, the story, Keen 4's council
##     and janitor, Keen 5's fuse messages);
##   - [code]keen4.text.<chunk>[/code]: a help topic or an end (EGAGRAPH's
##     text chunks, [GalaxyTextPages]), whole, with its commands.
## A translated text chunk keeps the commands of the player's own chunk
## (their pictures, places and colours belong to the player's version) and
## takes only the words between them from the translation, so it needs the
## same commands in the same order; otherwise the chunk stays English (an
## other release with other pages).
##
## The English texts are the player's own and never go into git; only the
## translations in `languages/` do (the user's exception, 26-10-2026).

const LEVEL := "level"
const ENTER := "enter"
const TEXT := "text"
## Commands of a text chunk that run to the end of their line (a page, a
## picture, a timed picture, a place, a bar), the end, and the colour (a
## caret, its letter and one hex digit).
const CARET := "^"
const LINE_COMMANDS := "PGTLB"
const END_COMMAND := "E"
const COLOR_COMMAND := "C"
const COLOR_LENGTH := 3
const COMMAND_LENGTH := 2


## The name of text [param index] of kind [param kind] (a run, or
## [constant LEVEL], [constant ENTER], [constant TEXT]) of the episode
## whose texts are named [param names].
static func id(names: String, kind: String, index: int) -> String:
	return "%s.%s.%d" % [names, kind, index]


## The name of map [param map] in the language in use.
static func level_name(names: String, map: int, english: String) -> String:
	return Lang.game(id(names, LEVEL, map), english)


## Every name of [param english] (by map) in the language in use.
static func level_names(names: String, english: PackedStringArray) -> PackedStringArray:
	var translated := PackedStringArray()
	for map in english.size():
		translated.append(level_name(names, map, english[map]))
	return translated


## The text while map [param map] loads in the language in use.
static func entry(names: String, map: int, english: String) -> String:
	return Lang.game(id(names, ENTER, map), english)


## Text [param index] of run [param run] in the language in use.
static func run_text(names: String, run: String, index: int, english: String) -> String:
	return Lang.game(id(names, run, index), english)


## Text chunk [param chunk] ([param english], the player's) in the
## language in use: the player's chunk with the translation's words.
static func pages(names: String, chunk: int, english: PackedByteArray) -> PackedByteArray:
	var name := id(names, TEXT, chunk)
	if not Lang.has_game(name):
		return english
	var merged := merge_pages(english, Lang.game(name, ""))
	return merged if not merged.is_empty() else english


## [param english]'s commands with the words of [param translated] between
## them; empty when the two do not have the same commands in the same
## order.
static func merge_pages(english: PackedByteArray, translated: String) -> PackedByteArray:
	var original := split_pages(english.get_string_from_ascii())
	var words := split_pages(translated)
	if kinds(original) != kinds(words):
		return PackedByteArray()
	var merged := ""
	for index in original.size():
		merged += words[index] if index % 2 == 0 else original[index]
	return merged.to_ascii_buffer()


## [param text] cut into its words and commands, in turn: words (perhaps
## empty), a command, words, ..., words; the end command takes the rest.
static func split_pages(text: String) -> PackedStringArray:
	var parts := PackedStringArray()
	var words_from := 0
	var at := 0
	while at < text.length() - 1:
		var length := _command_length(text, at)
		if length == 0:
			at += 1
			continue
		parts.append(text.substr(words_from, at - words_from))
		parts.append(text.substr(at, length))
		at += length
		words_from = at
	parts.append(text.substr(words_from))
	return parts


## The kind of every command of [param parts] ([method split_pages]): its
## letter in upper case.
static func kinds(parts: PackedStringArray) -> String:
	var letters := ""
	for index in range(1, parts.size(), 2):
		letters += parts[index][1].to_upper()
	return letters


## Name -> English of every text of the episode of [param rules] in the
## player's files; empty when they are missing.
static func catalog_of(rules: GalaxyGameRules) -> Dictionary[String, String]:
	var files: GameFiles = rules.locate_files.call()
	if files == null:
		return {}
	var data: GalaxyData = rules.load_data.call(files)
	if data == null:
		return {}
	return catalog(data, rules)


## Name -> English of every text of [param data] the game shows by
## [param rules].
static func catalog(data: GalaxyData, rules: GalaxyGameRules) -> Dictionary[String, String]:
	var texts: Dictionary[String, String] = {}
	var names := rules.text_names
	var levels := data.executable.level_names()
	var entries := data.executable.entry_texts()
	for map in levels.size():
		texts[id(names, LEVEL, map)] = levels[map]
	for map in entries.size():
		texts[id(names, ENTER, map)] = entries[map]
	for run in rules.translated_runs:
		var run_texts := (
			data.executable.messages(run)
			if data.episode.message_shapes.has(run)
			else data.executable.texts(run)
		)
		for index in rules.translated_runs[run]:
			if index < run_texts.size():
				texts[id(names, run, index)] = run_texts[index]
	for chunk in text_chunks(rules):
		var english := data.graphics.text(chunk).get_string_from_ascii()
		if not english.is_empty():
			texts[id(names, TEXT, chunk)] = english.replace("\r", "")
	return texts


## The text chunks the game shows by [param rules]: the help topics and
## the ends.
static func text_chunks(rules: GalaxyGameRules) -> PackedInt32Array:
	var chunks := PackedInt32Array()
	var shown := Array(rules.help_topic_texts) + [rules.end_text, rules.secret_end_text]
	for chunk: int in shown:
		if chunk >= 0 and not chunks.has(chunk):
			chunks.append(chunk)
	chunks.sort()
	return chunks


## How long the command at [param at] of [param text] is; 0 when none
## starts there.
static func _command_length(text: String, at: int) -> int:
	if text[at] != CARET:
		return 0
	var letter := text[at + 1].to_upper()
	if letter == END_COMMAND:
		return text.length() - at
	if LINE_COMMANDS.contains(letter):
		var end := text.find("\n", at)
		return (end + 1 if end >= 0 else text.length()) - at
	if letter == COLOR_COMMAND:
		return mini(COLOR_LENGTH, text.length() - at)
	return COMMAND_LENGTH
