class_name LanguageFile
extends RefCounted
## One language as read from its text files: its name, the translations of
## the engine's own English texts, of the alien signs, and of the texts from
## the game files (by a name such as "keen1.hint.2").
##
## The format is plain UTF-8 text, made to be written by hand:
##   # a comment
##   @name Nederlands             the name shown in the list of languages
##   New Game = Nieuw spel        an engine text: English = translation
##   @alien THIS IS NEAT = DIT IS TOF
##   @text keen1.hint.2 = ...     a text from the game files on one line
##   @text keen1.story            or on the lines up to @end, kept exactly
##   ...
##   @end
## In a one-line value "\n" starts a new line. A language can be spread over
## several files; [method merge] adds one to another.

const COMMENT := "#"
const NAME := "@name"
const ALIEN := "@alien"
const TEXT := "@text"
const END := "@end"
const SEPARATOR := " = "
const NEW_LINE_ESCAPE := "\\n"

## The name shown in the list; empty when no file gave one.
var name := ""
## English engine text -> translation.
var texts: Dictionary[String, String] = {}
## English alien sign text -> translation.
var alien: Dictionary[String, String] = {}
## Name of a text from the game files -> translation.
var game: Dictionary[String, String] = {}


## The language in [param source]; lines it does not understand are
## reported with [param origin] and skipped.
static func parse(source: String, origin := "") -> LanguageFile:
	var language := LanguageFile.new()
	language.add(source, origin)
	return language


## Reads the language from the file at [param path]; null when it cannot be
## read.
static func load_from(path: String) -> LanguageFile:
	var source := FileAccess.get_file_as_string(path)
	if source.is_empty() and FileAccess.get_open_error() != OK:
		push_error("Could not read the language file %s." % path)
		return null
	return parse(source, path)


## Adds the lines of [param source]; later lines win over earlier ones.
func add(source: String, origin := "") -> void:
	var lines := source.replace("\r", "").split("\n")
	var index := 0
	while index < lines.size():
		var line := lines[index]
		var stripped := line.strip_edges()
		index += 1
		if stripped.is_empty() or stripped.begins_with(COMMENT):
			continue
		if stripped.begins_with(NAME + " "):
			name = stripped.trim_prefix(NAME).strip_edges()
		elif stripped.begins_with(ALIEN + " "):
			_add_pair(alien, stripped.trim_prefix(ALIEN), origin, index)
		elif stripped.begins_with(TEXT + " "):
			var rest := stripped.trim_prefix(TEXT).strip_edges()
			if rest.contains(SEPARATOR):
				_add_pair(game, rest, origin, index)
				continue
			var block := PackedStringArray()
			while index < lines.size() and lines[index].strip_edges() != END:
				block.append(lines[index])
				index += 1
			if index >= lines.size():
				push_error("%s:%d: @text %s has no @end." % [origin, index, rest])
			index += 1
			game[rest] = "\n".join(block)
		elif stripped.contains(SEPARATOR):
			_add_pair(texts, stripped, origin, index)
		else:
			push_error("%s:%d: not understood: %s" % [origin, index, stripped])


## Adds everything of [param other]; its translations win.
func merge(other: LanguageFile) -> void:
	if not other.name.is_empty():
		name = other.name
	texts.merge(other.texts, true)
	alien.merge(other.alien, true)
	game.merge(other.game, true)


static func _add_pair(
	into: Dictionary[String, String], line: String, origin: String, line_number: int
) -> void:
	var at := line.find(SEPARATOR)
	if at < 0:
		push_error('%s:%d: no " = " in: %s' % [origin, line_number, line])
		return
	var key := line.left(at).strip_edges()
	into[key] = line.substr(at + SEPARATOR.length()).strip_edges().replace(NEW_LINE_ESCAPE, "\n")
