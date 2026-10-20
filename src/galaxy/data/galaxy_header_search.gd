class_name GalaxyHeaderSearch
extends RefCounted
## Finds the headers of the Galaxy data files inside the unpacked program
## by their content (docs/keen4/file-formats.md, "Inside KEEN4E.EXE"). Only
## data is looked at, never program code. Each search first tries the
## places where a known version keeps the piece, and uses one only when the
## content passes the same check as the search; then it searches the whole
## image.
##
## - An offset table (AUDIOHED, EGAHEAD): one offset per chunk, starting at
##   0 and ending at the size of its data file.
## - MAPHEAD: the RLEW tag, then the offset of every map's header in
##   GAMEMAPS (0 = no map); each header carries the signature "!ID!".
## - A dictionary (AUDIODCT, EGADICT): see [method GalaxyHuffman.is_tree_at].

## A 3-byte offset with this value is an empty chunk.
const EMPTY_3 := 0xFFFFFF
## A real table has at least this many entries.
const MIN_TABLE_ENTRIES := 8
const MAP_SLOTS := 100
const TAG_SIZE := 2
const MAP_HEAD_SIZE := TAG_SIZE + MAP_SLOTS * 4
## Where a map header in GAMEMAPS carries its signature: after the three
## plane offsets and lengths, the size and the 16-byte name.
const MAP_SIGNATURE_OFFSET := 38
const MAP_SIGNATURE := "!ID!"
## A chunk is at most this many bytes longer than its Huffman data needs
## (seen: 0, 1, 4 or 5 in Keen 4 v1.0).
const MAX_SLACK := 8
const CHUNK_LENGTH_SIZE := 4
## A node value must stay below this (see [method GalaxyHuffman.is_tree_at]).
const NODE_VALUE_LIMIT := GalaxyHuffman.BYTE_VALUES + GalaxyHuffman.ROOT


## The start of an offset table with [param entry_size]-byte entries that
## ends at [param file_size], or -1. [param known] places are tried first.
static func find_offset_table(
	data: PackedByteArray, entry_size: int, file_size: int, known: PackedInt32Array
) -> int:
	for offset in known:
		if is_offset_table(data, offset, entry_size, file_size):
			return offset
	var needle := PackedByteArray()
	needle.resize(entry_size)
	for index in entry_size:
		needle[index] = (file_size >> (index * 8)) & 0xFF
	var last := ExeStrings.find(data, needle)
	while last >= 0:
		var start := _walk_back_to_zero(data, last, entry_size, file_size)
		if start >= 0 and is_offset_table(data, start, entry_size, file_size):
			return start
		last = ExeStrings.find(data, needle, last + 1)
	return -1


## Whether an offset table starts at [param start]: 0 first, every entry at
## most [param file_size] (or empty), [param file_size] last. Offsets never
## go down, except for one block of equal entries that are larger than the
## ones after them (the absent digitised sounds of AUDIOHED in Keen 4 v1.0).
static func is_offset_table(
	data: PackedByteArray, start: int, entry_size: int, file_size: int
) -> bool:
	var entries := offset_table(data, start, entry_size, file_size)
	if entries.size() < MIN_TABLE_ENTRIES:
		return false
	var bogus := -1
	var lowest := file_size
	for index in range(entries.size() - 1, -1, -1):
		var value := entries[index]
		if value < 0:
			continue
		if value <= lowest:
			lowest = value
		elif bogus < 0 or bogus == value:
			bogus = value
		else:
			return false
	return true


## [param entries] with every entry that is larger than one after it (the
## block that [method is_offset_table] allows) turned into -1, an empty
## chunk. Every other chunk then ends where the next non-empty one starts.
static func without_bogus(entries: PackedInt32Array) -> PackedInt32Array:
	var result := entries.duplicate()
	var lowest := 0x7FFFFFFF
	for index in range(result.size() - 1, -1, -1):
		if result[index] < 0:
			continue
		if result[index] > lowest:
			result[index] = -1
		else:
			lowest = result[index]
	return result


## Where chunk [param index] of [param offsets] (as from
## [method without_bogus]) ends: at the next offset that is not empty; -1
## when there is none.
static func chunk_end(offsets: PackedInt32Array, index: int) -> int:
	for next in range(index + 1, offsets.size()):
		if offsets[next] >= 0:
			return offsets[next]
	return -1


## The entries of the table at [param start] up to and including the one
## equal to [param file_size]; -1 for an empty chunk. Empty when no such
## table starts there.
static func offset_table(
	data: PackedByteArray, start: int, entry_size: int, file_size: int
) -> PackedInt32Array:
	var entries := PackedInt32Array()
	if start < 0 or start + entry_size > data.size() or _entry(data, start, entry_size) != 0:
		return entries
	var position := start
	while position + entry_size <= data.size():
		var value := _entry(data, position, entry_size)
		if entry_size == 3 and value == EMPTY_3:
			entries.append(-1)
		elif value > file_size:
			return PackedInt32Array()
		else:
			entries.append(value)
			if value == file_size:
				return entries
		position += entry_size
	return PackedInt32Array()


## The start of MAPHEAD for the GAMEMAPS bytes [param maps], or -1.
static func find_map_head(
	data: PackedByteArray, maps: PackedByteArray, known: PackedInt32Array
) -> int:
	for offset in known:
		if is_map_head(data, offset, maps):
			return offset
	# The first map's header is usually the first one in the file.
	var signature := ExeStrings.find(maps, MAP_SIGNATURE.to_ascii_buffer())
	if signature < MAP_SIGNATURE_OFFSET:
		return -1
	var needle := PackedByteArray()
	needle.resize(4)
	needle.encode_u32(0, signature - MAP_SIGNATURE_OFFSET)
	var slot := ExeStrings.find(data, needle)
	while slot >= 0:
		if is_map_head(data, slot - TAG_SIZE, maps):
			return slot - TAG_SIZE
		slot = ExeStrings.find(data, needle, slot + 1)
	return -1


## Whether MAPHEAD starts at [param start]: a tag and [constant MAP_SLOTS]
## offsets, each 0 or the start of a map header in [param maps], the first
## not 0.
static func is_map_head(data: PackedByteArray, start: int, maps: PackedByteArray) -> bool:
	if start < 0 or start + MAP_HEAD_SIZE > data.size():
		return false
	for slot in MAP_SLOTS:
		var offset := data.decode_u32(start + TAG_SIZE + slot * 4)
		if offset == 0 and slot > 0:
			continue
		if not _is_map_header(maps, offset):
			return false
	return true


## The [param known] places in [param data] that hold a dictionary.
static func known_dictionaries(data: PackedByteArray, known: PackedInt32Array) -> PackedInt32Array:
	var found := PackedInt32Array()
	for offset in known:
		if GalaxyHuffman.is_tree_at(data, offset) and not found.has(offset):
			found.append(offset)
	return found


## Every place in [param data] that holds a dictionary (a fraction of a
## second for a whole program).
static func find_dictionaries(data: PackedByteArray) -> PackedInt32Array:
	var found := PackedInt32Array()
	var limit := NODE_VALUE_LIMIT
	for offset in data.size() - GalaxyHuffman.SIZE + 1:
		# A quick look at the first node before the whole check.
		if data.decode_u16(offset) < limit and data.decode_u16(offset + 2) < limit:
			if GalaxyHuffman.is_tree_at(data, offset):
				found.append(offset)
	return found


## Whether [param dictionary] expands the chunk at [param start] of
## [param file] (a 32-bit length, then the Huffman data, up to
## [param end]) to exactly its length, reading about all of its bytes.
static func fits_chunk(
	dictionary: GalaxyHuffman, file: PackedByteArray, start: int, end: int
) -> bool:
	if start < 0 or start + CHUNK_LENGTH_SIZE > end or end > file.size():
		return false
	var length := file.decode_u32(start)
	var needed := dictionary.bytes_needed(file, start + CHUNK_LENGTH_SIZE, length)
	var stored := end - start - CHUNK_LENGTH_SIZE
	return needed >= 0 and needed <= stored and stored - needed <= MAX_SLACK


static func _walk_back_to_zero(
	data: PackedByteArray, last: int, entry_size: int, file_size: int
) -> int:
	var position := last - entry_size
	while position >= 0:
		var value := _entry(data, position, entry_size)
		if value == 0:
			return position
		if value > file_size and not (entry_size == 3 and value == EMPTY_3):
			return -1
		position -= entry_size
	return -1


static func _entry(data: PackedByteArray, position: int, entry_size: int) -> int:
	if entry_size == 3:
		return data.decode_u16(position) | (data[position + 2] << 16)
	return data.decode_u32(position)


static func _is_map_header(maps: PackedByteArray, offset: int) -> bool:
	var signature := offset + MAP_SIGNATURE_OFFSET
	if offset <= 0 or signature + MAP_SIGNATURE.length() > maps.size():
		return false
	return (
		maps.slice(signature, signature + MAP_SIGNATURE.length()).get_string_from_ascii()
		== MAP_SIGNATURE
	)
