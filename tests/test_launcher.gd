extends "res://tests/test_case.gd"
## Tests for the start screen: where the picture, the bar and the icons go
## on screens of different shapes, the icon under the mouse, a game whose
## files are missing, the hand-over to the game and the way back from its
## menu.

const PICTURE := Vector2(1672, 941)


func test_picture_fills_the_width_of_a_16_by_10_screen() -> void:
	var screen := Vector2(1280, 800)
	var picture := LauncherLayout.picture_rect(screen, PICTURE)
	assert_true(picture.position.x < 1.0, "from the left edge")
	assert_true(picture.size.x > 1278.0, "as wide as the screen")
	assert_true(is_equal_approx(picture.size.x / picture.size.y, PICTURE.x / PICTURE.y), "whole")
	var bar := LauncherLayout.bar_rect(screen, picture)
	assert_true(bar.size.y >= screen.y * LauncherLayout.BAR_SHARE, "room for the icons below")
	assert_equal(bar.end.y, 800.0, "down to the bottom")


func test_bar_keeps_its_room_on_a_16_by_9_screen() -> void:
	var screen := Vector2(1920, 1080)
	var picture := LauncherLayout.picture_rect(screen, PICTURE)
	var bar := LauncherLayout.bar_rect(screen, picture)
	assert_true(is_equal_approx(bar.size.y, 1080.0 * LauncherLayout.BAR_SHARE), "the bar's share")
	assert_true(picture.position.x > 0.0, "the picture is a little narrower")
	assert_true(is_equal_approx(picture.position.x, screen.x - picture.end.x), "in the middle")


func test_icons_sit_in_the_bottom_left_corner() -> void:
	var bar := Rect2(0, 720, 1280, 80)
	var scale := LauncherLayout.icon_scale(bar.size.y)
	assert_equal(scale, 2, "whole icon pixels that fit the bar")
	var size := Vector2(GameIcon.BASE_SIZE * scale)
	var positions := LauncherLayout.icon_positions(bar, size, 2)
	assert_equal(positions.size(), 2, "one place per game")
	var gap := LauncherLayout.gap_in(bar)
	assert_equal(positions[0].x, gap, "the first game (Keen 1) on the far left")
	assert_true(positions[0].x + size.x < positions[1].x, "the next to its right")
	assert_true(positions[1].y >= bar.position.y, "in the bar")
	assert_true(positions[1].y + size.y <= bar.end.y, "not below the screen")


func test_icon_is_darker_under_the_mouse() -> void:
	var icon := GameIcon.new()
	assert_equal(icon.modulate, Color.WHITE, "normal")
	icon.mouse_entered.emit()
	assert_true(icon.is_darker(), "under the mouse")
	assert_equal(icon.modulate, GameIcon.DARKER, "a little darker")
	icon.mouse_exited.emit()
	assert_equal(icon.modulate, Color.WHITE, "normal again")
	icon.free()


func test_icon_without_files_is_gray() -> void:
	var icon := GameIcon.new()
	icon.available = false
	assert_equal(icon.modulate, GameIcon.UNAVAILABLE, "gray")
	icon.mouse_entered.emit()
	assert_equal(
		icon.modulate, GameIcon.UNAVAILABLE * GameIcon.DARKER, "and darker under the mouse"
	)
	icon.free()


func test_game_without_files_says_why() -> void:
	var launcher := Launcher.new()
	var game := GameCatalog.Game.new()
	game.title = "Keen 1"
	launcher._start(game)
	assert_true(launcher.message().contains("game_data/keen1"), "where the files go")
	assert_true(not GameLaunch.take_menu_request(), "nothing starts")
	launcher.free()


func test_keen_1_is_offered() -> void:
	var games := GameCatalog.games()
	assert_equal(games.size(), 1, "one game for now")
	assert_equal(games[0].title, "Keen 1", "no other name on the icon")
	assert_equal(games[0].scene, GameLaunch.KEEN_1_SCENE, "plays Keen 1")


func test_menu_request_is_taken_once() -> void:
	GameLaunch.request_menu()
	assert_true(GameLaunch.take_menu_request(), "the game opens its menu")
	assert_true(not GameLaunch.take_menu_request(), "only once")


func test_level_options_skip_the_start_screen() -> void:
	assert_true(GameLaunch.skips_launcher(["--level=1"]), "a level")
	assert_true(GameLaunch.skips_launcher(["--ending"]), "the ending")
	assert_true(not GameLaunch.skips_launcher([]), "nothing: the start screen")
	assert_true(not GameLaunch.skips_launcher(["--data-dir=/x"]), "other options")


func test_main_menu_goes_back_to_choose_a_game() -> void:
	var window := GameWindow.new()
	var menus := MenuController.new()
	menus.window = window
	var chosen := []
	menus.chosen.connect(func(id: StringName, value: int) -> void: chosen.append([id, value]))
	menus.open_main(false, false)
	var menu := menus._top()
	for index in menu.items.size():
		if menu.items[index].label == "Choose Game":
			menu.cursor = index
	var enter := InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.keycode = KEY_ENTER
	enter.pressed = true
	menus.handle_input(enter)
	assert_equal(chosen, [[MenuController.CHOICE_CHOOSE_GAME, 0]], "back to the start screen")
	menus.free()
	window.free()
