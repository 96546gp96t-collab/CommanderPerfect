extends "res://tests/test_case.gd"
## Checks the shared Galaxy game's world map and progress (milestone E6;
## [GalaxyMapSession], [GalaxyProgress]) with the hand-made episode of
## [code]galaxy_game_fixtures.gd[/code], so no game's files are needed:
## Keen's place in a new game and on the way back, the entrances, the done
## levels' gates and flags by the rules (thrown or waving only), the
## episode's hooks, and the levels done with their values in a saved game.

const Game := preload("res://tests/galaxy_game_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")
const MapFixtures := preload("res://tests/keen4_map_fixtures.gd")

const TILE := 256
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..........M...................",
	"..............................",
	"..............................",
	"..............................",
]
## The map Keen's cell, with the border.
const KEEN_CELL := Vector2i(12, 6)
const BELOW_KEEN := Vector2i(12, 7)
const LEVEL := 3
const OTHER_LEVEL := 4
const FLAG_HOLDER := Vector2i(20, 3)
const OTHER_HOLDER := Vector2i(24, 3)
const GATE := Vector2i(16, 3)
const FUSE_VALUE := 14
const RETURN_PLACE := Vector2i(0x700, 0x500)
const WALK_FRAMES := 4


## A map session whose episode runs some frames itself (as Keen 5's rides).
class OwnFrames:
	extends GalaxyMapSession
	var own := false
	var extras_for: GalaxyProgress

	func _place_extras(progress: GalaxyProgress) -> void:
		extras_for = progress

	func _runs_own_frame(_tics: int, _tic: int) -> bool:
		return own


## Progress that keeps one more thing in a saved game.
class MoreProgress:
	extends GalaxyProgress
	var stars := 0

	func _extra_to_dictionary() -> Dictionary:
		return {"stars": stars}

	func _extra_from_dictionary(saved: Dictionary) -> void:
		stars = int(saved.get("stars", 0))


func test_keen_starts_on_the_map_keen_info_or_where_he_entered() -> void:
	var on_map := _session(MapFixtures.map(FIELD))
	assert_true(on_map != null, "a world map")
	assert_true(on_map.keen is GalaxyMapKeen, "the map Keen")
	assert_equal(on_map.keen.position, KEEN_CELL * TILE, "on info 3 in a new game")
	assert_equal(on_map.world.map_number, Game.WORLD_MAP, "the rules' world map")
	var progress := GalaxyProgress.new()
	progress.map_position = RETURN_PLACE
	on_map = _session(MapFixtures.map(FIELD), progress)
	assert_equal(on_map.keen.position, RETURN_PLACE, "where he entered the last level")
	var level := Keen.level(PackedStringArray(["....K....", "#########"]))
	assert_true(_session(level) == null, "no map Keen: no world map")


func test_jump_on_an_entrance_enters_its_level() -> void:
	var level := MapFixtures.map(FIELD)
	_set_info(level, BELOW_KEEN, GalaxyMapKeen.ENTRY_BASE + LEVEL)
	var on_map := _session(level)
	_hold(on_map, 2, KeenInput.new())
	assert_equal(on_map.entered(), 0, "not without a button")
	_hold(on_map, 1, MapFixtures.jump())
	assert_equal(on_map.entered(), LEVEL, "0xC003 enters level 3")
	assert_equal(on_map.keen.map_position, on_map.keen.position, "where he stood")


func test_done_levels_open_gates_and_get_flags_by_the_rules() -> void:
	var progress := GalaxyProgress.new()
	progress.mark_done(LEVEL)
	progress.mark_done(OTHER_LEVEL, FUSE_VALUE)
	progress.last_finished = LEVEL
	var on_map := _session(_marked_map(), progress)
	var rules := Game.rules()
	assert_equal(on_map.world.fore_tile(GATE.x, GATE.y), 0, "the gate is gone")
	assert_equal(on_map.world.info_at(GATE.x, GATE.y), 0, "its word cleared")
	assert_equal(on_map.flags.size(), 2, "a flag for each done level, any value")
	assert_true(on_map.flags[0].is_thrown(), "the level just finished: thrown from Keen")
	assert_equal(
		on_map.flags[0].target, FLAG_HOLDER * TILE + rules.map_flag_throw_offset, "to its holder"
	)
	assert_equal(
		on_map.flags[1].position, OTHER_HOLDER * TILE + rules.map_flag_offset, "the other waves"
	)


func test_an_episode_without_thrown_flags_only_waves() -> void:
	var rules := Game.rules()
	rules.throws_map_flag = false
	rules.map_flag_offset = Vector2i(-0x50, -0x1E0)
	rules.sprites = _waving_only_sprites()
	var progress := GalaxyProgress.new()
	progress.mark_done(LEVEL)
	progress.last_finished = LEVEL
	var on_map := _session(_marked_map(), progress, rules)
	assert_equal(on_map.flags.size(), 1, "one flag")
	var flag := on_map.flags[0]
	assert_true(not flag.is_thrown(), "waving")
	assert_equal(flag.position, FLAG_HOLDER * TILE + Vector2i(-0x50, -0x1E0), "at the offset")
	assert_true(not flag._actions.has(&"throw"), "no flipping actions (no such sprites)")


func test_the_episode_hooks() -> void:
	var on_map := OwnFrames.new()
	var progress := GalaxyProgress.new()
	assert_true(_begin(on_map, MapFixtures.map(FIELD), progress, Game.rules()), "set up")
	assert_true(on_map.extras_for == progress, "its extras with the progress")
	on_map.own = true
	var start := on_map.keen.position
	_hold(on_map, WALK_FRAMES, MapFixtures.stick(Vector2i.RIGHT))
	assert_equal(on_map.keen.position, start, "a frame of its own: the world stands")
	on_map.own = false
	_hold(on_map, WALK_FRAMES, MapFixtures.stick(Vector2i.RIGHT))
	assert_true(on_map.keen.position.x > start.x, "the world's frames again")


func test_progress_keeps_levels_with_their_values() -> void:
	var progress := GalaxyProgress.new()
	progress.mark_done(OTHER_LEVEL, FUSE_VALUE)
	progress.mark_done(LEVEL)
	assert_true(progress.is_done(LEVEL) and progress.is_done(OTHER_LEVEL), "both done")
	assert_equal(progress.done_value(LEVEL), GalaxyProgress.DONE, "1 by default")
	assert_equal(progress.done_value(OTHER_LEVEL), FUSE_VALUE, "its own value")
	assert_equal(progress.done_value(1), 0, "0 when not done")
	assert_equal(progress.done_levels(), PackedInt32Array([LEVEL, OTHER_LEVEL]), "in order")
	progress.mark_done(LEVEL, 0)
	assert_true(not progress.is_done(LEVEL), "0 takes it back")
	progress.last_finished = OTHER_LEVEL
	progress.map_shown()
	assert_equal(progress.last_finished, -1, "the map was shown once")


func test_progress_in_a_saved_game() -> void:
	var progress := MoreProgress.new()
	progress.mark_done(LEVEL)
	progress.mark_done(OTHER_LEVEL, FUSE_VALUE)
	progress.map_position = RETURN_PLACE
	progress.stars = 7
	var saved := JSON.parse_string(JSON.stringify(progress.to_dictionary())) as Dictionary
	var loaded := MoreProgress.new()
	loaded.load_dictionary(saved)
	assert_equal(loaded.done_value(LEVEL), GalaxyProgress.DONE, "a level done")
	assert_equal(loaded.done_value(OTHER_LEVEL), FUSE_VALUE, "with its value")
	assert_equal(loaded.map_position, RETURN_PLACE, "the place on the map")
	assert_equal(loaded.stars, 7, "the episode's own")
	var empty := GalaxyProgress.new()
	empty.load_dictionary({})
	assert_equal(empty.done_levels().size(), 0, "nothing saved: a new game")


## The field with a gate (0xD003), the holders of levels 3 and 4 and an
## entrance of level 3.
func _marked_map() -> GalaxyMap:
	var level := MapFixtures.map(FIELD)
	MapFixtures.put_fore(level, GATE - Vector2i(2, 2), Keen.SOLID)
	_set_info(level, GATE, 0xD000 | LEVEL)
	_set_info(level, FLAG_HOLDER, 0xF000 | LEVEL)
	_set_info(level, OTHER_HOLDER, 0xF000 | OTHER_LEVEL)
	return level


## Keen 4's sprite names without the thrown flag's.
static func _waving_only_sprites() -> Dictionary[StringName, int]:
	var sprites := Game.rules().sprites.duplicate()
	for name: StringName in sprites.keys():
		if String(name).begins_with("FLAG_FLIP") or String(name).begins_with("FLAG_FALL"):
			sprites.erase(name)
	return sprites


func _session(
	level: GalaxyMap, progress := GalaxyProgress.new(), rules := Game.rules()
) -> GalaxyMapSession:
	var on_map := GalaxyMapSession.new()
	return on_map if _begin(on_map, level, progress, rules) else null


func _begin(
	on_map: GalaxyMapSession, level: GalaxyMap, progress: GalaxyProgress, rules: GalaxyGameRules
) -> bool:
	var made := on_map.begin(
		rules,
		level,
		MapFixtures.tile_info(),
		Keen.sprite_infos(),
		MapFixtures.Creatures.random_table(),
		progress
	)
	if made:
		on_map.run_frame(
			KeenInput.new(), MapFixtures.FIRST_FRAME_TICS, MapFixtures.FIRST_FRAME_TICS
		)
		on_map.set_meta(&"tic", MapFixtures.FIRST_FRAME_TICS)
	return made


static func _hold(on_map: GalaxyMapSession, frames: int, held: KeenInput) -> void:
	var tic: int = on_map.get_meta(&"tic", 0)
	for frame in frames:
		tic += MapFixtures.FRAME_TICS
		on_map.run_frame(held, MapFixtures.FRAME_TICS, tic)
	on_map.set_meta(&"tic", tic)


static func _set_info(level: GalaxyMap, cell: Vector2i, value: int) -> void:
	level.planes[GalaxyMap.Layer.INFO][cell.y * level.width + cell.x] = value
