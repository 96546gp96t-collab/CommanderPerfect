class_name GalaxyExecutable
extends RefCounted
## The program of a Galaxy episode (KEEN4E.EXE for Keen 4): unpacked with
## [DosExecutable], its version, the fixed table of random numbers and the
## texts the game shows (level names, "Keen enters ...", messages). The
## headers of the data files are found by [GalaxyHeaders]. Only data is read;
## the program code is never looked at. See docs/keen4/file-formats.md.

## The text-mode sign-on screen says "(v1.0)" or "(v1.4)": a character and
## its colour byte in turn, so the letters are two bytes apart.
const SIGN_ON_STRIDES: PackedInt32Array = [2, 1]
const VERSION_OPEN := "(v"
const VERSION_CLOSE := ")"
## A version is at most this many characters ("1.4").
const MAX_VERSION_LENGTH := 5
const UNKNOWN_VERSION := "unknown"
## The table of random numbers of id's engines starts with these bytes
## (Omni, [code]id_us_1.c:US_RndT[/code]); the search looks for them
## after the first one, which is a 0 like so many bytes.
const RANDOM_TABLE_START: PackedByteArray = [0, 8, 109, 220, 222, 241, 149]
const RANDOM_TABLE_SIZE := 256

## The unpacked program image.
var image := PackedByteArray()
## "1.0", "1.4", ... or [constant UNKNOWN_VERSION].
var version := UNKNOWN_VERSION
var _episode: GalaxyEpisode
var _level_texts_start := -2


## Reads and unpacks the program in [param files]. Returns null when it is
## missing or cannot be unpacked.
static func load_from(files: GameFiles, episode: GalaxyEpisode) -> GalaxyExecutable:
	var name := episode.executable_in(files)
	if name.is_empty():
		push_error("The program (%s) is missing." % " or ".join(episode.executables))
		return null
	var exe := files.read(name)
	var unpacked := DosExecutable.load_image(exe)
	if unpacked.is_empty():
		push_error("%s could not be unpacked." % name)
		return null
	return from_image(unpacked, episode, exe.size())


## Wraps an already unpacked [param program_image]; [param exe_size] is the
## size of the program file, when known.
static func from_image(
	program_image: PackedByteArray, episode: GalaxyEpisode, exe_size := 0
) -> GalaxyExecutable:
	var executable := GalaxyExecutable.new()
	executable.image = program_image
	executable._episode = episode
	executable.version = sign_on_version(program_image)
	if executable.version == UNKNOWN_VERSION:
		for label in episode.executable_sizes:
			if episode.executable_sizes[label] == exe_size:
				executable.version = label
	return executable


## The version in the sign-on text of [param data], such as "1.0", or
## [constant UNKNOWN_VERSION].
static func sign_on_version(data: PackedByteArray) -> String:
	var open := VERSION_OPEN.unicode_at(0)
	var position := data.find(open)
	while position >= 0:
		for stride in SIGN_ON_STRIDES:
			var found := _version_at(data, position, stride)
			if not found.is_empty():
				return found
		position = data.find(open, position + 1)
	return UNKNOWN_VERSION


## Where the table of random numbers starts, or -1.
static func find_random_table(data: PackedByteArray) -> int:
	var rest := RANDOM_TABLE_START.slice(1)
	var position := ExeStrings.find(data, rest, 1)
	while position >= 0:
		var start := position - 1
		if data[start] == RANDOM_TABLE_START[0] and start + RANDOM_TABLE_SIZE <= data.size():
			return start
		position = ExeStrings.find(data, rest, position + 1)
	return -1


## The 256 random numbers the game reads in turn (demos depend on them);
## empty when the table is not found.
func random_table() -> PackedByteArray:
	var start := find_random_table(image)
	if start < 0:
		push_error("The table of random numbers was not found.")
		return PackedByteArray()
	return image.slice(start, start + RANDOM_TABLE_SIZE)


## The name of every map that has one, by map number (the world map first);
## empty when they are not found.
func level_names() -> PackedStringArray:
	return _level_texts().slice(0, _episode.level_name_count)


## The text shown when Keen enters each map ("Keen enters ..."), by map
## number; empty when they are not found.
func entry_texts() -> PackedStringArray:
	return _level_texts().slice(_episode.level_name_count)


## The run of messages named [param shape_name] in
## [member GalaxyEpisode.message_shapes], one string per message (lines
## split by newlines); empty when it is not found.
func messages(shape_name: String) -> PackedStringArray:
	var shape: PackedInt32Array = _episode.message_shapes.get(shape_name, PackedInt32Array())
	var known: PackedInt32Array = _episode.known_message_offsets.get(shape_name, PackedInt32Array())
	var start := GalaxyExeTexts.find_messages(image, shape, known)
	if start < 0:
		push_error('The messages "%s" were not found.' % shape_name)
		return PackedStringArray()
	return GalaxyExeTexts.records_from(image, start, shape.size())


## The run of short texts named [param run_name] in
## [member GalaxyEpisode.text_lengths]; empty when it is not found.
func texts(run_name: String) -> PackedStringArray:
	var lengths: PackedInt32Array = _episode.text_lengths.get(run_name, PackedInt32Array())
	var known: PackedInt32Array = _episode.known_text_offsets.get(run_name, PackedInt32Array())
	var start := GalaxyExeTexts.find_by_lengths(image, lengths, known)
	if start < 0:
		push_error('The texts "%s" were not found.' % run_name)
		return PackedStringArray()
	return GalaxyExeTexts.records_from(image, start, lengths.size())


## Where the level names start, or -1.
func level_texts_start() -> int:
	if _level_texts_start == -2:
		_level_texts_start = GalaxyExeTexts.find_level_texts(
			image, _episode.level_name_count, _episode.known_level_name_offsets
		)
	return _level_texts_start


func _level_texts() -> PackedStringArray:
	var start := level_texts_start()
	if start < 0:
		push_error("The level names were not found.")
		return PackedStringArray()
	return GalaxyExeTexts.records_from(image, start, _episode.level_name_count * 2)


static func _version_at(data: PackedByteArray, start: int, stride: int) -> String:
	if start + stride >= data.size() or data[start + stride] != VERSION_OPEN.unicode_at(1):
		return ""
	var found := ""
	var position := start + stride * 2
	while position < data.size() and found.length() <= MAX_VERSION_LENGTH:
		var character := String.chr(data[position])
		if character == VERSION_CLOSE:
			return found if found.length() >= 3 and found[1] == "." else ""
		if not (character.is_valid_int() or character == "."):
			return ""
		found += character
		position += stride
	return ""
