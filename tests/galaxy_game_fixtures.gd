extends RefCounted
## A small hand-made episode for the tests of the shared Galaxy game
## (milestone E3; [GalaxyGameRules], [GalaxyStart], [GalaxyLevelSession]):
## its rules (three levels, map 2 missing, row blocks at 25 and no column
## blocks, items at 57-68 and one more item at 70), and its data in memory
## (the tiles and sprite boxes of [code]galaxy_keen_fixtures.gd[/code], a
## program image that holds only the table of random numbers). The sprite
## names are Keen 4's table ([Keen4Sprites], code, not game data). None of
## it comes from a game.

const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const WORLD_MAP := 0
const FIRST_LEVEL := 1
const LAST_LEVEL := 4
const MISSING_MAP := 2
const LAST_MAP := 5
const ROW_BLOCK_INFO := 25
const FIRST_ITEM_INFO := 57
const LAST_ITEM_INFO := 68
const LOW_STUNNER_INFO := 69
## One more item beyond the range: info 70 is item 12 (as Keen 5's keycard).
const MORE_ITEM_INFO := 70
const MORE_ITEM := 12
const START_LIVES := 4
const START_SHOTS := 7
const FIRST_EXTRA_LIFE := 30000
const MAP_KEEN_SPRITE := 132
const NAME := "Fixture"
const DATA_FOLDER := "game_data/fixture"
const DATA_OPTION := "--data-dir-fixture="


## The rules of the hand-made episode; its files are never found.
static func rules() -> GalaxyGameRules:
	var game := GalaxyGameRules.new()
	game.name = NAME
	game.locate_files = func() -> GameFiles: return null
	game.load_data = func(_files: GameFiles) -> GalaxyData: return data()
	game.data_folder = DATA_FOLDER
	game.data_dir_option = DATA_OPTION
	game.user_folder = "user://fixture"
	game.world_map = WORLD_MAP
	game.first_level = FIRST_LEVEL
	game.last_level = LAST_LEVEL
	game.last_map = LAST_MAP
	game.missing_maps = PackedInt32Array([MISSING_MAP])
	game.row_block_info = ROW_BLOCK_INFO
	game.column_block_info = -1
	game.first_item_info = FIRST_ITEM_INFO
	game.last_item_info = LAST_ITEM_INFO
	game.more_item_infos = {MORE_ITEM_INFO: MORE_ITEM}
	game.low_stunner_info = LOW_STUNNER_INFO
	game.map_keen_sprite = MAP_KEEN_SPRITE
	game.sprites = Keen4Sprites.all()
	game.sprites[&"ITEM_12"] = Keen4Sprites.ITEM_FIRST_FRAMES[0]
	game.sprites[&"SHADOW_12"] = Keen4Sprites.ITEM_SHADOWS[0]
	game.start_lives = START_LIVES
	game.start_shots = START_SHOTS
	game.first_extra_life = FIRST_EXTRA_LIFE
	return game


## The episode's data in memory: tiles, sprite boxes, the random table.
static func data() -> GalaxyData:
	var episode := GalaxyData.new()
	episode.tile_info = Keen.tile_info()
	episode.graphics = GalaxyGraphics.new()
	episode.graphics.sprite_infos = Keen.sprite_infos()
	episode.executable = GalaxyExecutable.new()
	var table := GalaxyExecutable.RANDOM_TABLE_START.duplicate()
	table.resize(GalaxyExecutable.RANDOM_TABLE_SIZE)
	episode.executable.image = table
	return episode
