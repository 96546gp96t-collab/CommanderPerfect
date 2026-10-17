extends "res://tests/test_case.gd"
## Tests for milestone B10: what was measured in the original. A new game
## has 3 raygun charges; the status screen puts its numbers where the
## original does; the title goes over the first screen of map 90, not over
## Keen 1's space screen; GAME OVER is a bare bitmap, while every other
## window (and all of Keen 1's) keeps its frame.


func test_a_new_game_has_three_charges() -> void:
	assert_equal(Keen2Inventory.new().charges, 3, "as the original's status screen shows")


func test_status_screen_numbers_stand_where_the_original_has_them() -> void:
	var progress := Keen2Progress.new()
	progress.inventory.score = 1234
	progress.inventory.charges = 7
	var window := GameWindow.new()
	Keen2StatusScreen.fill(window, progress, PackedStringArray(), PackedStringArray())
	var cells := {}
	for item: Dictionary in window._texts:
		cells[item.text] = item.cell
	assert_equal(cells["1234"], Vector2i(Keen2StatusScreen.SCORE_END - 4, 1), "score ends at 10")
	assert_equal(cells["7"], Keen2StatusScreen.CHARGES_CELL, "charges from column 24")
	assert_equal(window._tile_items[0].cell, Keen2StatusScreen.RAYGUN_CELL, "the raygun")
	window.free()


func test_title_goes_over_the_first_screen() -> void:
	assert_true(Keen2Screens.TITLE_SCREEN != Backdrops.TITLE_SCREEN, "not Keen 1's screen")
	assert_equal(Keen2Screens.TITLE_SCREEN.position, Vector2i(2, 2), "the first screen")
	var layer := PictureLayer.new()
	Keen2Screens.show_title(layer)
	var origin := Vector2(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
	assert_equal(layer._bitmaps.size(), 2, "two bitmaps")
	assert_equal(layer._bitmaps[0].name, "TITLE", "the title")
	assert_equal(layer._bitmaps[0].at, origin + Keen2Screens.TITLE_POSITION, "where it was seen")
	assert_equal(layer._bitmaps[1].name, "F1HELP", "PRESS F1 FOR HELP")
	assert_equal(layer._bitmaps[1].at, origin + Keen2Screens.HELP_POSITION, "below the fires")
	layer.free()


func test_only_game_over_is_unframed() -> void:
	var window := GameWindow.new()
	assert_true(window.framed, "framed by default, as in Keen 1")
	window.open(Keen2SpaceScreen.GAME_OVER_CELLS)
	window.framed = false
	window.open(Vector2i(4, 1))
	assert_true(window.framed, "the next window has its frame again")
	window.free()
