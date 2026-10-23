extends RefCounted
## Hand-made pieces where Keen 5's files differ from Keen 4's, built from
## the shared Galaxy fixtures (tests/galaxy_file_fixtures.gd): an EGAGRAPH
## whose texts come before its misc chunks, and whose last two rows of
## background tiles are empty, so the border between the tile sets cannot
## be seen in the file (Keen 5: 1512 background tiles, the last ones empty;
## docs/keen5/file-formats.md). None of it comes from the game.

const Fixtures := preload("res://tests/galaxy_fixtures.gd")
const FileFixtures := preload("res://tests/galaxy_file_fixtures.gd")

## Background tiles: two rows of 18, of which only the first 16 hold
## anything; then the shared fixtures' 4 foreground tiles (the first empty).
const BACK_TILES := 36
const DRAWN_BACK_TILES := 16
const FORE_TILES := Fixtures.FORE_TILES
## Where the shared fixtures' chunks are: the first background tile, the
## first foreground tile, and the misc, text and demo chunk at the end.
const FIRST_TILE_CHUNK := 11
const SHARED_FORE_START := FIRST_TILE_CHUNK + Fixtures.BACK_TILES
const SHARED_MISC := SHARED_FORE_START + Fixtures.FORE_TILES
const SHARED_TEXT := SHARED_MISC + 1
const SHARED_DEMO := SHARED_TEXT + 1
## Where the border falls when it is worked out: after the first whole row
## of 18 that holds the drawn tiles (as 1440 for Keen 5).
const WORKED_OUT_BACK_TILES := 18


## The expanded contents of every chunk (as
## [method FileFixtures.graphics_contents]): the shared tables, pictures,
## sprites and 8×8 tiles, [constant BACK_TILES] background tiles, the
## foreground tiles, then the text, the misc chunk and the demo.
static func graphics_contents() -> Array[Array]:
	var shared := FileFixtures.graphics_contents()
	var chunks: Array[Array] = shared.slice(0, FIRST_TILE_CHUNK)
	for tile in BACK_TILES:
		if tile < DRAWN_BACK_TILES:
			chunks.append(shared[FIRST_TILE_CHUNK + tile])
		else:
			chunks.append([PackedByteArray(), false])
	chunks.append_array(shared.slice(SHARED_FORE_START, SHARED_MISC))
	chunks.append(shared[SHARED_TEXT])
	chunks.append(shared[SHARED_MISC])
	chunks.append(shared[SHARED_DEMO])
	return chunks


## The EGAGRAPH of [method graphics_contents], ready to read.
static func graphics_file() -> GalaxyGraphicsFile:
	var tree := Fixtures.dictionary(FileFixtures.GRAPHICS_TREE_WEIGHT)
	var data := PackedByteArray()
	var offsets := PackedInt32Array()
	for content in graphics_contents():
		var bytes: PackedByteArray = content[0]
		if bytes.is_empty():
			offsets.append(-1)
			continue
		offsets.append(data.size())
		data.append_array(Fixtures.chunk(tree, bytes, content[1]))
	offsets.append(data.size())
	return GalaxyGraphicsFile.create(data, offsets, GalaxyHuffman.from_bytes(tree))


## The shared hand-made episode as Keen 5 sets it up: the number of
## background tiles given, the texts before the misc chunks.
static func episode() -> GalaxyEpisode:
	var result := Fixtures.episode()
	result.back_tile_count = BACK_TILES
	result.texts_before_misc = true
	return result
