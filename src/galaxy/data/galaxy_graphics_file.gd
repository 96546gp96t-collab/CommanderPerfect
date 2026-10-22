class_name GalaxyGraphicsFile
extends RefCounted
## The chunks of EGAGRAPH: where each starts (EGAHEAD) and how to expand it
## (EGADICT). Most chunks begin with their expanded length; the tile chunks
## do not, because their length follows from what they hold. See
## docs/keen4/file-formats.md, "EGAGRAPH.CK4: chunks".

const LENGTH_SIZE := 4

var data := PackedByteArray()
## The start of every chunk and, last, the size of the file; -1 = empty.
var offsets := PackedInt32Array()
var dictionary: GalaxyHuffman


static func create(
	file_data: PackedByteArray, chunk_offsets: PackedInt32Array, huffman: GalaxyHuffman
) -> GalaxyGraphicsFile:
	var file := GalaxyGraphicsFile.new()
	file.data = file_data
	file.offsets = chunk_offsets
	file.dictionary = huffman
	return file


func chunk_count() -> int:
	return maxi(0, offsets.size() - 1)


## Whether [param chunk] holds nothing (a tile that is never drawn).
func is_empty(chunk: int) -> bool:
	return chunk < 0 or chunk >= chunk_count() or offsets[chunk] < 0


## How many bytes [param chunk] takes in the file.
func stored_size(chunk: int) -> int:
	if is_empty(chunk):
		return 0
	return GalaxyHeaderSearch.chunk_end(offsets, chunk) - offsets[chunk]


## The expanded bytes of [param chunk], which starts with its length; empty
## for an empty chunk.
func expand(chunk: int) -> PackedByteArray:
	if is_empty(chunk) or stored_size(chunk) < LENGTH_SIZE:
		return PackedByteArray()
	var start := offsets[chunk]
	return dictionary.expand(data, start + LENGTH_SIZE, data.decode_u32(start))


## The first [param length] expanded bytes of [param chunk], which has no
## length of its own (a tile chunk); empty for an empty chunk.
func expand_fixed(chunk: int, length: int) -> PackedByteArray:
	if is_empty(chunk):
		return PackedByteArray()
	return dictionary.expand(data, offsets[chunk], length)


## Everything [param chunk] holds when it has no length of its own (may be a
## few bytes longer than what was packed; see [method GalaxyHuffman.expand_all]).
func expand_whole(chunk: int) -> PackedByteArray:
	if is_empty(chunk):
		return PackedByteArray()
	return dictionary.expand_all(data, offsets[chunk], offsets[chunk] + stored_size(chunk))


## The expanded length that [param chunk] says it has; 0 when empty.
func expanded_length(chunk: int) -> int:
	if is_empty(chunk) or stored_size(chunk) < LENGTH_SIZE:
		return 0
	return data.decode_u32(offsets[chunk])


## Whether [param chunk] (without a length of its own) holds at least
## [param length] bytes: expanding them must not read past its end.
func holds(chunk: int, length: int) -> bool:
	if is_empty(chunk):
		return false
	var needed := dictionary.bytes_needed(data, offsets[chunk], length)
	return needed >= 0 and needed <= stored_size(chunk)
