class_name Keen2MenuScreen
extends Keen2SpaceScreen
## The screens around a game of Keen 2 (milestone B7), as Keen 1 has them:
## the title over map 90, the high score table with the number of cities
## ([Keen2HighScores], drawn by [Keen2Screens]) and the main menu (the
## shared [MenuController]: new game, continue, save on the world map, the
## story, high scores, controls, options, quit to title, choose game, quit).
## The title and the high scores take turns until a key opens the main menu.
## GAME OVER and the end of the game lead to the high scores, which ask for a
## name when the score is good enough. Saved games and the high scores live in
## Keen 2's own folder ([constant SAVES_DIRECTORY]); the keys and the display
## settings are shared with Keen 1. The menus offer no online game, no second
## player and no extra levels (Keen 1's); co-op comes in milestone B9.
##
## [Keen2View], which extends this, plays the game; it starts one in
## [method _start_game].

## Seconds the title and the high scores stay before they swap (as Keen 1).
const ATTRACT_SECONDS := 8.0
const SAVES_DIRECTORY := "user://keen2/saves"
const SAVE_FAILED_MESSAGE := "The game could not be saved."
const LOAD_FAILED_LINES: PackedStringArray = ["That game could not be", "read.  Press a key"]

## The game being played; null when the files could not be read.
var play: Keen2LevelPlay
var _saves := SaveGames.in_directory(SAVES_DIRECTORY)
var _high_scores := Keen2HighScores.new()
var _screen_time_left := 0.0
## The place a good score takes while its name is typed; -1 otherwise.
var _pending_place := -1


## Starts a game: [param game] is a loaded one, or null for a new game.
func _start_game(_game: Keen2Progress) -> void:
	pass


## Connects the menus; call before the screen is shown.
func _set_up_menus() -> void:
	_menus.saves = _saves
	_menus.offers_online = false
	_menus.offers_second_player = false
	_menus.offers_extra_levels = false
	_menus.chosen.connect(_on_menu_chosen)
	_menus.settings_changed.connect(_on_settings_changed)
	_menus.settings_changed.connect(_apply_keen_2_sound)
	_menus.name_entered.connect(_on_name_entered)


## The story and the high scores, once [member Keen2SpaceScreen._texts] is
## read; and the layer that draws the title and the table.
func _set_up_texts() -> void:
	_pictures.set_textures(_textures)
	if not _texts.story.is_empty():
		_menus.story = TextDocument.layout(_texts.story, MenuController.TEXT_WIDTH)
	var score_texts := _texts.score_texts
	var names := score_texts.default_names if score_texts != null else PackedStringArray()
	_high_scores = Keen2HighScores.load_from(Keen2HighScores.DEFAULT_PATH, names)


## Shows the title over the mothership and the Earth.
func _show_title() -> void:
	if _show_screen(Mode.TITLE, Keen2Screens.TITLE_SCREEN):
		Keen2Screens.show_title(_pictures)


## Shows the high score table.
func _show_high_scores() -> void:
	if _show_screen(Mode.HIGH_SCORES, Keen2Screens.HIGH_SCORE_SCREEN):
		Keen2Screens.show_high_scores(_pictures, _high_scores)


## Shows the screen [param area] of map 90 and switches to [param mode].
## Returns false (and says why) when the map cannot be read.
func _show_screen(mode: Mode, area: Rect2i) -> bool:
	var file_name := files.level_file(Keen2Files.TITLE_LEVEL)
	var backdrops := LevelData.parse(files.read(file_name))
	if backdrops == null:
		_show_message("%s could not be read." % file_name)
		return false
	_clear_screen()
	_level = Backdrops.screen(backdrops, area)
	_level_number = Keen2Files.TITLE_LEVEL
	_level_map.show_level(_level, _properties)
	_mode = mode
	_screen_time_left = ATTRACT_SECONDS
	_frame_camera()
	_apply_backdrop()
	_follow(_camera_anchor)
	# The screens are a little taller than the view: show their top.
	var area_pixels := LevelMap.playable_pixels(_level)
	_camera_anchor.position = Vector2(
		area_pixels.get_center().x, area_pixels.position.y + _settings.game_size().y / 2.0
	)
	_camera.reset_smoothing()
	return true


## Takes away what a level, the map or the ending left on the screen.
func _clear_screen() -> void:
	_session = null
	_map_session = null
	_keen2_ending = null
	_doom = Doom.NONE
	_actor_layer.clear()
	_pictures.clear()
	_close_window()
	_show_picture(false)
	_darkness.set_dark(false)
	_level_map.visible = true
	_time_left = 0.0


## Counts down the title, the high scores and GAME OVER.
func _count_down_screen(delta: float) -> void:
	if _mode == Mode.GAME_OVER:
		_game_over_time_left -= delta
		if _game_over_time_left <= 0.0:
			_finish_game()
		return
	if _mode not in [Mode.TITLE, Mode.HIGH_SCORES]:
		return
	_screen_time_left -= delta
	if _screen_time_left > 0.0:
		return
	if _mode == Mode.TITLE:
		_show_high_scores()
	else:
		_show_title()


## A key on the title or the high scores opens the main menu; on GAME OVER
## it moves on.
func _on_screen_key() -> void:
	if _mode == Mode.GAME_OVER:
		_finish_game()
	else:
		_open_main_menu()


## The main menu; while a game runs it can go back to it, and on the world
## map save it.
func _open_main_menu() -> void:
	_close_window()
	_user_settings.fullscreen = _is_fullscreen()
	_menus.open_main(_mode in [Mode.MAP, Mode.LEVEL, Mode.ENDING], _can_save())


## Saving is only possible while Keen stands on the world map.
func _can_save() -> bool:
	return (
		_mode == Mode.MAP
		and play.map_session != null
		and play.map_session.outcome == MapSession.Outcome.PLAYING
	)


func _on_menu_chosen(id: StringName, slot: int) -> void:
	match id:
		MenuController.CHOICE_NEW_GAME:
			_start_game(null)
		MenuController.CHOICE_LOAD:
			_load_game(slot)
		MenuController.CHOICE_SAVE:
			play.progress.map_position = play.map_session.keen.position
			if not _saves.write(slot, play.progress):
				_show_message(SAVE_FAILED_MESSAGE)
		MenuController.CHOICE_HIGH_SCORES:
			_show_high_scores()
		MenuController.CHOICE_TITLE:
			_show_title()
		MenuController.CHOICE_QUIT:
			get_tree().quit()
		MenuController.CHOICE_CHOOSE_GAME:
			_leave()


func _load_game(slot: int) -> void:
	var game := _saves.read(slot)
	if game == null:
		_menus.show_message(LOAD_FAILED_LINES)
		return
	_start_game(Keen2Progress.from_game(game))


## The game is over (GAME OVER or the ending): the high scores, and a good
## score asks for a name first.
func _finish_game() -> void:
	_show_high_scores()
	_pending_place = _high_scores.place_for(play.inventory.score)
	if _pending_place < 0:
		return
	_sounds.play(Sound.Id.HIGH_SCORE)
	var score_texts := _texts.score_texts
	var words := score_texts.place_names if score_texts != null else PackedStringArray()
	_menus.ask_name(words[_pending_place] if _pending_place < words.size() else "a")


func _on_name_entered(player_name: String) -> void:
	if _pending_place < 0:
		return
	var score := play.inventory.score
	_high_scores.insert(_pending_place, player_name, score, play.progress.saved_city_count())
	_high_scores.save()
	_pending_place = -1
	_show_high_scores()


## Keen 2's own speaker (EARTHPOW) follows the sound setting too.
func _apply_keen_2_sound() -> void:
	_keen_2_sounds.enabled = _user_settings.sound_enabled
