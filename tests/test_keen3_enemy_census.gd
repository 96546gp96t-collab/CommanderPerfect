extends "res://tests/test_case.gd"
## Tests of Keen 3's enemies and objects with the player's own files
## (skipped without them): every level 1-16 spawns the enemies and the
## objects of C5 of its census (docs/keen3/research.md §5), and level 1 runs
## with its enemies awake.

## Per level: grunts, youths, mothers, Meeps, ninjas, Foobs (research §5).
const CENSUS: Dictionary[int, Array] = {
	1: [2, 4, 1, 0, 0, 3],
	2: [13, 0, 0, 0, 0, 2],
	3: [11, 0, 1, 0, 1, 3],
	4: [7, 5, 3, 1, 4, 6],
	5: [21, 7, 14, 0, 0, 0],
	6: [3, 5, 0, 0, 0, 0],
	7: [12, 5, 2, 0, 1, 0],
	8: [7, 2, 0, 0, 1, 0],
	9: [14, 4, 0, 0, 0, 0],
	10: [5, 2, 0, 0, 4, 0],
	11: [2, 5, 0, 0, 0, 0],
	12: [5, 0, 0, 6, 2, 1],
	13: [0, 7, 1, 0, 0, 18],
	14: [4, 0, 0, 3, 21, 1],
	15: [9, 0, 0, 0, 9, 8],
	16: [0, 0, 0, 2, 0, 0],
}
## Per level: balls, jacks, sideways and up-and-down platforms, guns firing
## right and down (research §5).
const OBJECT_CENSUS: Dictionary[int, Array] = {
	1: [0, 0, 0, 0, 0, 0],
	2: [0, 0, 0, 2, 0, 0],
	3: [1, 0, 0, 0, 0, 0],
	4: [0, 1, 0, 0, 1, 0],
	5: [0, 0, 0, 3, 0, 0],
	6: [3, 0, 0, 0, 0, 0],
	7: [0, 0, 0, 0, 0, 0],
	8: [2, 0, 2, 2, 0, 0],
	9: [6, 1, 4, 3, 11, 0],
	10: [0, 0, 2, 2, 3, 1],
	11: [0, 0, 1, 0, 4, 0],
	12: [0, 0, 3, 0, 2, 9],
	13: [0, 0, 0, 0, 0, 0],
	14: [0, 0, 1, 0, 1, 1],
	15: [13, 2, 0, 0, 0, 0],
	16: [0, 0, 0, 0, 0, 2],
}
const RUN_TICKS := 600

var _files: GameFiles
var _data: Keen3GameData
## The kinds in the order of [constant CENSUS].
var _kinds: Array[Script] = [Keen3Grunt, Keen3Youth, Keen3Mom, Keen3Meep, Keen3Ninja, Keen3Foob]


func run_all() -> void:
	_files = Keen3Files.locate()
	if _files == null:
		skip("no Keen 3 game data found")
		return
	_data = Keen3GameData.load_from(_files)
	super.run_all()


func test_every_level_spawns_its_census() -> void:
	var play := Keen3LevelPlay.create(_files, _data.properties)
	for number in CENSUS:
		assert_true(play.start(number), "level %d starts" % number)
		var counts := []
		counts.resize(_kinds.size())
		counts.fill(0)
		for enemy in play.session.enemies():
			var kind := _kinds.find(enemy.get_script())
			assert_true(kind >= 0 or _object_kind(enemy) >= 0, "known in level %d" % number)
			if kind >= 0:
				counts[kind] += 1
		assert_equal(counts, CENSUS[number], "the enemies of level %d" % number)


func test_every_level_spawns_its_objects() -> void:
	var play := Keen3LevelPlay.create(_files, _data.properties)
	for number in OBJECT_CENSUS:
		assert_true(play.start(number), "level %d starts" % number)
		var counts := []
		counts.resize(OBJECT_CENSUS[number].size())
		counts.fill(0)
		for enemy in play.session.enemies():
			var kind := _object_kind(enemy)
			if kind >= 0:
				counts[kind] += 1
		assert_equal(counts, OBJECT_CENSUS[number], "the objects of level %d" % number)


func test_level_1_runs_with_its_enemies() -> void:
	var play := Keen3LevelPlay.create(_files, _data.properties)
	assert_true(play.start(Keen3Files.FIRST_LEVEL), "level 1 starts")
	var session := play.session
	session.set_invincible(true)
	var woke := 0
	for tick in RUN_TICKS:
		session.step(KeenInput.new())
	for enemy in session.enemies():
		if enemy.is_active:
			woke += 1
	assert_true(woke > 0, "enemies near Keen woke up")
	assert_equal(session.inventory.score, 0, "no points from enemies")


## The column of [param enemy] in [constant OBJECT_CENSUS], or -1.
func _object_kind(enemy: Enemy) -> int:
	if enemy is Keen3Ball:
		return 0
	if enemy is Keen3Jack:
		return 1
	if enemy is Keen3Platform:
		return 3 if enemy.vertical else 2
	if enemy is Keen3WallGun:
		return 5 if enemy.downward else 4
	return -1
