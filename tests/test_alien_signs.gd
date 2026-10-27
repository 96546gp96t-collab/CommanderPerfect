extends "res://tests/test_case.gd"
## Tests for the translations of the signs in the alien alphabet: finding
## the signs (whole-word tiles and words of letter tiles), the signs found
## in the real levels of each game whose files are there, the plates that
## show only near Keen and only with the option on, in the language in use,
## and the plate in Keen 1's level 1. Needs a running scene tree for the
## last; settings go to a folder of their own, removed afterwards.

const TEST_DIRECTORY := "user://test_alien_signs"
const FRAME_SECONDS := 1.0 / 60.0
const FADE_FRAMES := 30

var _tree: SceneTree


func _init() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func run_all() -> void:
	super.run_all()
	Lang.use(Languages.ENGLISH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY.path_join("s.cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_touching_tiles_of_a_group_are_one_sign() -> void:
	var grid := [
		[0, 0, 0, 0, 0, 0],
		[0, 7, 8, 0, 9, 0],
		[0, 7, 8, 0, 0, 0],
		[0, 0, 0, 0, 7, 0],
	]
	var groups: Array[AlienSigns.Group] = [
		AlienSigns.Group.create([7, 8], "BIG"), AlienSigns.Group.create([9], "SMALL")
	]
	var signs := AlienSigns.find(Vector2i(6, 4), _tile_at.bind(grid), groups)
	assert_equal(signs.size(), 3, "three signs")
	assert_equal(signs[0].cells, Rect2i(1, 1, 2, 2), "the big sign's cells")
	assert_equal(signs[0].text, "BIG", "its text")
	assert_equal(signs[1].text, "SMALL", "another group")
	assert_equal(signs[2].cells, Rect2i(4, 3, 1, 1), "apart: a sign of its own")


func test_letter_tiles_spell_words() -> void:
	var letters: Dictionary[int, String] = {}
	for index in AlienSignTables.ALPHABET.length():
		letters[100 + index] = AlienSignTables.ALPHABET[index]
	var rows := ["..LOWER......W..", "VORTIVILLE...A..", "................", "HOME.B...KILL..KEEN"]
	var grid := []
	for row: String in rows:
		var cells := []
		for character in row.rpad(20, "."):
			cells.append(0 if character == "." else 100 + AlienSignTables.ALPHABET.find(character))
		grid.append(cells)
	var signs := AlienSigns.find(Vector2i(20, 4), _tile_at.bind(grid), [], letters)
	var texts := PackedStringArray()
	for sign in signs:
		texts.append(sign.text)
	assert_equal(
		texts,
		PackedStringArray(["LOWER VORTIVILLE", "WA", "HOME B", "KILL KEEN"]),
		"words, lines under each other, letters stacked, gaps"
	)
	assert_equal(signs[0].cells, Rect2i(0, 0, 10, 2), "the cells of both lines")


func test_long_translations_are_wrapped() -> void:
	assert_equal(
		AlienSignLabels.wrap_lines("AANSCHOUW DE HEILIGE POGOSTICK"),
		PackedStringArray(["AANSCHOUW DE", "HEILIGE POGOSTICK"]),
		"between words"
	)
	assert_equal(
		AlienSignLabels.wrap_lines("A\nB"), PackedStringArray(["A", "B"]), "new lines kept"
	)


func test_the_signs_of_keen_1() -> void:
	var files := GameFiles.locate()
	if files == null:
		return
	var table := AlienSignTables.keen1()
	var texts := _texts_of(_level_signs(files, 1, table))
	assert_true(texts.has("THIS IS NEAT"), "next to the raygun")
	assert_true(texts.has("DIE"), "next to danger")
	assert_true(texts.has("EXIT"), "the exit")
	var shrine := _level_signs(files, 5, table)
	var found := false
	for sign in shrine:
		if sign.text == "BEHOLD THE HOLY POGO STICK":
			found = sign.cells == Rect2i(18, 28, 2, 2)
	assert_true(found, "the Pogo Shrine's sign of 2x2 tiles")


func test_the_signs_of_keen_2_and_3() -> void:
	var keen2 := Keen2Files.locate()
	if keen2 != null:
		var texts := _texts_of(_level_signs(keen2, 4, AlienSignTables.keen2()))
		assert_true(texts.has("TANTALUS LONDON"), "Keen 2: the city under the ray")
		texts = _texts_of(_level_signs(keen2, GameFiles.WORLD_MAP_LEVEL, AlienSignTables.keen2()))
		assert_true(texts.has("BLUEPRINT ASME"), "Keen 2: the map's title")
		assert_true(texts.has("NEW YORK"), "Keen 2: a city on the map")
	var keen3 := Keen3Files.locate()
	if keen3 != null:
		var texts := _texts_of(_level_signs(keen3, 2, AlienSignTables.keen3()))
		assert_true(texts.has("LOWER VORTIVILLE"), "Keen 3: the name of the town")
		texts = _texts_of(_level_signs(keen3, 7, AlienSignTables.keen3()))
		assert_true(texts.has("KILL KEEN"), "Keen 3: the school's lesson")


func test_the_signs_of_keen_4_and_5() -> void:
	var keen4_files := Keen4Files.locate()
	if keen4_files != null:
		var data := GalaxyData.load_from(keen4_files, Keen4Episode.create())
		var tables := [AlienSignTables.Table.new(), AlienSignTables.keen4_foreground()]
		assert_true(_map_texts(data, 3, tables).has("WATCH OUT"), "Keen 4: Perilous Pit")
		assert_true(_map_texts(data, 3, tables).has("HIGH LOW"), "Keen 4: high and low")
		assert_true(_map_texts(data, 5, tables).has("EXIT"), "Keen 4: the hidden exit")
	var keen5_files := Keen5Files.locate()
	if keen5_files != null:
		var data := GalaxyData.load_from(keen5_files, Keen5Episode.create())
		var tables := [AlienSignTables.keen5_background(), AlienSignTables.keen5_foreground()]
		assert_true(
			_map_texts(data, 4, tables).has("WARNING: FUSE STRUCTURE FRAGILE"), "Keen 5: the fuse"
		)
		assert_true(_map_texts(data, 11, tables).has("JUMP DOWN AT ARCH"), "Keen 5: the screen")


func test_a_plate_shows_only_near_keen_with_the_option_on() -> void:
	var labels := AlienSignLabels.new()
	_tree.root.add_child(labels)
	var on := [false]
	var keen := [Vector2(1000, 1000)]
	var level := RefCounted.new()
	var plates: Array[String] = []
	labels.is_on = func() -> bool: return on[0]
	labels.level = func() -> Object: return level
	labels.find_signs = func() -> Array[AlienSigns.Sign]:
		return [AlienSigns.Sign.create(Rect2i(10, 10, 2, 1), "THIS IS NEAT")]
	labels.readers = func() -> Array[Vector2]: return [keen[0]]
	labels.make_plate = func(lines: PackedStringArray) -> Image:
		plates.append("\n".join(lines))
		return Image.create_empty(40, 16, false, Image.FORMAT_RGBA8)
	_frames(labels)
	assert_true(labels.signs().is_empty(), "off: no signs")
	on[0] = true
	_frames(labels)
	assert_equal(labels.signs().size(), 1, "on: the sign")
	assert_true(not labels.is_showing(0), "Keen far away: hidden")
	keen[0] = Vector2(176, 150)
	_frames(labels)
	assert_true(labels.is_showing(0), "Keen close: shown")
	assert_equal(plates[-1], "THIS IS NEAT", "in English")
	Lang.use("nl")
	_frames(labels)
	assert_equal(plates[-1], "DIT IS TOF", "in Dutch once the language changes")
	Lang.use(Languages.ENGLISH)
	keen[0] = Vector2(1000, 1000)
	_frames(labels)
	assert_true(not labels.is_showing(0), "Keen walked on: hidden again")
	on[0] = false
	_frames(labels)
	assert_true(labels.signs().is_empty(), "off again: gone")
	labels.free()


func test_the_plate_in_keen_1_level_1() -> void:
	if GameFiles.locate() == null:
		return
	var scene := load("res://src/game/level_view.tscn") as PackedScene
	var view := scene.instantiate() as GameScreen
	_tree.root.add_child(view)
	view._user_settings.path = TEST_DIRECTORY.path_join("s.cfg")
	view._user_settings.alien_text = true
	view.call(&"_enter_level", 1)
	var labels := view._alien_labels
	_frames(labels)
	var neat := -1
	for index in labels.signs().size():
		if labels.signs()[index].text == "THIS IS NEAT":
			neat = index
	assert_true(neat >= 0, "the sign next to the raygun is found")
	assert_true(labels.get_parent() == view._world, "drawn in the level")
	if neat >= 0:
		assert_true(not labels.is_showing(neat), "not at the start")
		var cells := labels.signs()[neat].cells
		var near := Vector2(cells.position * AlienSignLabels.CELL)
		view._session.keen.position = near - KeenPhysics.SPRITE_SIZE / 2.0
		view._process(FRAME_SECONDS)
		_frames(labels)
		assert_true(labels.is_showing(neat), "shown when Keen stands by it")
	view.get_parent().remove_child(view)
	view.free()


func _frames(labels: AlienSignLabels) -> void:
	for frame in FADE_FRAMES:
		labels._process(FRAME_SECONDS)


func _level_signs(files: GameFiles, number: int, table: AlienSignTables.Table) -> Array:
	var level := LevelData.parse(files.read(files.level_file(number)))
	return AlienSigns.find(
		Vector2i(level.width, level.height), level.tile_at, table.groups, table.letters
	)


func _map_texts(data: GalaxyData, number: int, tables: Array) -> PackedStringArray:
	var map := data.maps.load_map(number)
	var texts := PackedStringArray()
	for layer: int in [GalaxyMap.Layer.BACKGROUND, GalaxyMap.Layer.FOREGROUND]:
		var table: AlienSignTables.Table = tables[layer]
		var signs := AlienSigns.find(
			Vector2i(map.width, map.height),
			func(cell: Vector2i) -> int: return map.tile(layer, cell.x, cell.y),
			table.groups,
			table.letters
		)
		texts.append_array(_texts_of(signs))
	return texts


static func _texts_of(signs: Array) -> PackedStringArray:
	var texts := PackedStringArray()
	for sign: AlienSigns.Sign in signs:
		texts.append(sign.text)
	return texts


static func _tile_at(cell: Vector2i, grid: Array) -> int:
	return grid[cell.y][cell.x]
