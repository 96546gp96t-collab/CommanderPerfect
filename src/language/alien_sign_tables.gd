class_name AlienSignTables
extends RefCounted
## Which tiles of each game are signs in the alien alphabet, and what they
## say: read by eye from the tile sheets of the user's files (exported with
## tools/export_graphics.gd) with the letter tiles of Keen 3 as the key, and
## checked against the decodings on KeenWiki and cc314's pages. See
## docs/language/research.md, "The alien alphabet in the five games".
##
## A table holds groups of whole-word tiles ([AlienSigns.Group]) and, for
## the games that have them, the tiles of the letters A-Z.


## The signs of one game (of one layer, in Keen 4 and 5).
class Table:
	extends RefCounted
	var groups: Array[AlienSigns.Group] = []
	var letters: Dictionary[int, String] = {}


## The first of the 26 letter tiles, A to Z in order.
const KEEN2_FIRST_LETTER := 507
const KEEN3_FIRST_LETTER := 351
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

## Keen 1, 2 and 3 share these tiles.
const EXIT_DISPLAY: PackedInt32Array = [167, 168]
const THIS_IS_NEAT: PackedInt32Array = [206, 207]
const DIE: PackedInt32Array = [260, 440]
## Keen 5's fuse warning: four rows of five background tiles.
const FUSE_SIGN_ROWS: PackedInt32Array = [656, 674, 692, 710]
const FUSE_SIGN_WIDTH := 5


static func keen1() -> Table:
	return _table(
		[
			[EXIT_DISPLAY, "EXIT"],
			[THIS_IS_NEAT, "THIS IS NEAT"],
			[DIE, "DIE"],
			# The Pogo Shrine of level 5; "POGO" is in our own letters.
			[[263, 264, 276, 277], "BEHOLD THE HOLY POGO STICK"],
		]
	)


static func keen2() -> Table:
	var table := _table(
		[
			[EXIT_DISPLAY, "EXIT"],
			[THIS_IS_NEAT, "THIS IS NEAT"],
			[DIE, "DIE"],
			[[249], "GO UP"],
			# On the machine of every Tantalus Ray level.
			[[284], "ON"],
			# The world map is the Mothership's blueprint.
			[[16, 17, 29, 30], "BLUEPRINT ASME"],
		]
	)
	table.letters = _letters(KEEN2_FIRST_LETTER)
	return table


static func keen3() -> Table:
	var table := _table(
		[
			[[283, 284], "EXIT"],
			[[251, 252], "THIS IS NEAT"],
			[[253, 254], "HI HI"],
			[[118], "GO UP"],
			# Mortimer McMire's initials, in his castle.
			[[285], "MM"],
		]
	)
	table.letters = _letters(KEEN3_FIRST_LETTER)
	return table


## Keen 4's foreground; its background has no signs in the alien alphabet.
static func keen4_foreground() -> Table:
	return _table(
		[
			[[1062, 1063], "EXIT"],
			# The hidden exit of the Chasm of Chills.
			[[1700, 1701], "EXIT"],
			[[1080, 1081], "WATCH OUT"],
			[[1021, 1022], "HIGH LOW"],
			[[1023], "HI"],
		]
	)


static func keen5_foreground() -> Table:
	return _table(
		[
			[[1620, 1621, 1638, 1639], "EXIT"],
			[[1634, 1635, 1652, 1653], "EXIT"],
			[[2139, 2140, 2157, 2158], "JUMP DOWN AT ARCH"],
		]
	)


static func keen5_background() -> Table:
	return _table(
		[
			# The fuses (some versions spell it "STRCTURE").
			[_block(FUSE_SIGN_ROWS), "WARNING: FUSE STRUCTURE FRAGILE"],
			[[516, 517], "OK"],
		]
	)


## The tiles of rows that each start at one of [param row_starts] and are
## [constant FUSE_SIGN_WIDTH] tiles wide.
static func _block(row_starts: PackedInt32Array) -> PackedInt32Array:
	var tiles := PackedInt32Array()
	for start in row_starts:
		for offset in FUSE_SIGN_WIDTH:
			tiles.append(start + offset)
	return tiles


static func _table(entries: Array) -> Table:
	var table := Table.new()
	for entry: Array in entries:
		table.groups.append(AlienSigns.Group.create(PackedInt32Array(entry[0]), entry[1]))
	return table


static func _letters(first: int) -> Dictionary[int, String]:
	var letters: Dictionary[int, String] = {}
	for index in ALPHABET.length():
		letters[first + index] = ALPHABET[index]
	return letters
