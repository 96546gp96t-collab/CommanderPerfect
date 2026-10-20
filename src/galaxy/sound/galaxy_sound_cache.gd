class_name GalaxySoundCache
extends RefCounted
## Rendered AdLib sounds and songs on disk, so the OPL2 synthesiser only
## runs once per installation: one file per rendered chunk, named by a
## hash of the chunk's bytes (another version of the game, with other
## bytes, renders again) and of [constant RENDER_VERSION] (raised when
## the synthesiser changes). The files are made from the player's own game
## files in the user folder and are never shipped.
##
## A file: two 32-bit numbers (the loop's first and last sample, -1 when
## the audio does not loop), then 16-bit audio at
## [constant GalaxyOpl.CHIP_RATE].

const DEFAULT_DIRECTORY := "user://keen4/cache"
## Raise this when the rendered sound changes, so old files are not used.
const RENDER_VERSION := "galaxy-opl-1"
const EXTENSION := ".pcm"
const HEADER_SIZE := 8

var directory := DEFAULT_DIRECTORY


func _init(folder := DEFAULT_DIRECTORY) -> void:
	directory = folder


## The name of the rendering of [param chunk].
static func key(chunk: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(RENDER_VERSION.to_utf8_buffer())
	context.update(chunk)
	return context.finish().hex_encode()


func path_for(name: String) -> String:
	return directory.path_join(name + EXTENSION)


func has(name: String) -> bool:
	return FileAccess.file_exists(path_for(name))


## The stored rendering: {"pcm": PackedByteArray, "loop_begin": int,
## "loop_end": int}; empty when there is none (or it cannot be read).
func load_entry(name: String) -> Dictionary:
	var path := path_for(name)
	if not FileAccess.file_exists(path):
		return {}
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < HEADER_SIZE:
		push_error("The sound cache file %s is damaged; it is rendered again." % path)
		return {}
	return {
		"pcm": bytes.slice(HEADER_SIZE),
		"loop_begin": bytes.decode_s32(0),
		"loop_end": bytes.decode_s32(4),
	}


## Stores a rendering; returns whether that worked. Written to a temporary
## file first, so a half-written file is never read.
func save_entry(name: String, pcm: PackedByteArray, loop_begin := -1, loop_end := -1) -> bool:
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("The sound cache folder %s could not be made." % directory)
		return false
	var path := path_for(name)
	var temporary := path + ".part"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s." % temporary)
		return false
	var header := PackedByteArray()
	header.resize(HEADER_SIZE)
	header.encode_s32(0, loop_begin)
	header.encode_s32(4, loop_end)
	file.store_buffer(header)
	file.store_buffer(pcm)
	file.close()
	return DirAccess.rename_absolute(temporary, path) == OK
