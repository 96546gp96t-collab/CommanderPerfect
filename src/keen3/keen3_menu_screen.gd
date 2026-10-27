class_name Keen3MenuScreen
extends Keen3EndingScreen
## The screens around a game of Keen 3 (milestone C8), as Keen 2 has them
## (B7, B10): the title over map 90, the high score table with names and
## scores ([Keen2HighScores] in Keen 3's own file, drawn by [Keen3Screens])
## and the shared main menu ([MenuController]: new game, continue, save on
## the world map, the story from KEEN3.EXE, high scores, controls, options,
## quit to title, choose game, quit).
##   attract    the title and the high scores take turns, 2400 clock ticks
##              each (Choco `CVort_game_over`, the title loop), until a key
##              opens the main menu
##   game over  GAME OVER (after the last life, and after the ending) leads
##              to the high scores; a score that gets in first asks for a
##              name (the shared name box; the original plays no HISCORESND)
##   saving     on the world map only, not while a teleporter runs; nine
##              slots in Keen 3's own folder ([Keen3SaveGames])
## The keys, the display settings and the sound setting are shared with Keen
## 1 and 2. Since milestone C10 the menus offer adding or removing player 2
## during a game and playing online ([Keen3OnlineScreen]), as Keen 2's do;
## never Keen 1's extra levels. A player who joined an online game waits at
## his title after GAME OVER and the ending: the high scores are the host's.
##
## [Keen3View], which extends this, plays the game; it starts one in
## [method _start_game].

## The game's clock (the timer interrupt that also plays the sounds).
const CLOCK_TICKS_PER_SECOND := SoundFile.STEPS_PER_SECOND
## The title and the high scores stay 2400 clock ticks, 16.5 s (Choco; seen
## in the original, C11: the title 16.5 s, the high scores 16.4 s).
const ATTRACT_SECONDS := 2400.0 / CLOCK_TICKS_PER_SECOND
const HIGH_SCORES_PATH := "user://keen3/high_scores.json"
const SAVE_FAILED_MESSAGE := "The game could not be saved."
const LOAD_FAILED_LINES: PackedStringArray = ["That game could not be", "read.  Press a key"]

## The game being played; null when the files could not be read.
var play: Keen3LevelPlay
## Whether a second player plays along on the keyboard (not saved with a
## game, as in Keen 1 and 2).
var _two_players := false
var _saves := Keen3SaveGames.in_folder()
var _high_scores := Keen2HighScores.new()
var _screen_time_left := 0.0
## The place a good score takes while its name is typed; -1 otherwise.
var _pending_place := -1


## Starts a game: [param game] is a loaded one, or null for a new game.
func _start_game(_game: Keen3Progress) -> void:
	pass


## A second player joins, or leaves (F7 or the menu).
func _toggle_second_player() -> void:
	pass


## Connects the menus; call before the screen is shown.
func _set_up_menus() -> void:
	_menus.saves = _saves
	_menus.offers_extra_levels = false
	_menus.chosen.connect(_on_menu_chosen)
	_menus.settings_changed.connect(_on_settings_changed)
	_menus.settings_changed.connect(_apply_keen_3_sound)
	_menus.name_entered.connect(_on_name_entered)
	_menus.closed.connect(_on_menus_closed)


## The story and the high scores, once [member Keen3EndingScreen._data] is
## read; and the layer that draws the title and the table.
func _set_up_texts() -> void:
	_pictures.set_textures(_textures)
	if not _data.story.is_empty():
		_menus.set_story(Keen3Texts.STORY, _data.story)
	var score_texts := _data.score_texts
	var names := score_texts.default_names if score_texts != null else PackedStringArray()
	names = GameTexts.score_names(Keen3Texts.PREFIX, names)
	_high_scores = Keen2HighScores.load_from(HIGH_SCORES_PATH, Keen3Screens.default_names(names))


## Shows the title over the first screen of map 90, as the original does.
func _show_title() -> void:
	if _show_screen(Mode.TITLE, Keen3Screens.TITLE_SCREEN):
		Keen3Screens.show_title(_pictures)


## Shows the high score table.
func _show_high_scores() -> void:
	if _show_screen(Mode.HIGH_SCORES, Keen3Screens.HIGH_SCORE_SCREEN):
		Keen3Screens.show_high_scores(_pictures, _high_scores)


## Shows the screen [param area] of map 90 and switches to [param mode].
## Returns false (and says why) when the map cannot be read.
func _show_screen(mode: Mode, area: Rect2i) -> bool:
	var file_name := files.level_file(Keen3Files.TITLE_LEVEL)
	var backdrops := LevelData.parse(files.read(file_name))
	if backdrops == null:
		_show_message("%s could not be read." % file_name)
		return false
	_clear_screen()
	_level = Backdrops.screen(backdrops, area)
	_level_number = Keen3Files.TITLE_LEVEL
	_level_map.show_level(_level, _properties)
	_mode = mode
	_screen_time_left = ATTRACT_SECONDS
	_frame_camera()
	_apply_backdrop()
	_follow(_camera_anchor)
	_camera.follow_exactly(false)
	# The screens are a little taller than the view: show their top (map row
	# 2 at the top of the picture, as the original).
	var area_pixels := LevelMap.playable_pixels(_level)
	_camera_anchor.position = Vector2(
		area_pixels.get_center().x, area_pixels.position.y + _settings.game_size().y / 2.0
	)
	_camera.reset_smoothing()
	return true


## Takes away what the title, a level, the map or the ending left on the
## screen.
func _clear_screen() -> void:
	if _second_player != null:
		_second_player.stop()
	_session = null
	_map_session = null
	_mortimer = null
	_keen3_ending = null
	_mortimer_sound_in = -1.0
	_actor_layer.clear()
	_pictures.clear()
	_shown_box = null
	_shown_letters = -1
	_close_window()
	_show_picture(false)
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
	var in_game := _mode in [Mode.MAP, Mode.LEVEL, Mode.ENDING]
	_menus.open_main(in_game, _can_save(), _two_players)


## Saving is only possible while Keen stands on the world map, not while a
## teleporter carries him.
func _can_save() -> bool:
	if _mode != Mode.MAP or play == null or play.map_session == null:
		return false
	var map := play.map_session
	return map.outcome == MapSession.Outcome.PLAYING and not map.is_teleporting()


func _on_menu_chosen(id: StringName, slot: int) -> void:
	match id:
		MenuController.CHOICE_NEW_GAME:
			_start_game(null)
		MenuController.CHOICE_SECOND_PLAYER:
			_toggle_second_player()
		MenuController.CHOICE_LOAD:
			_load_game(slot)
		MenuController.CHOICE_SAVE:
			_save_game(slot)
		MenuController.CHOICE_HIGH_SCORES:
			_show_high_scores()
		MenuController.CHOICE_TITLE:
			_show_title()
		MenuController.CHOICE_QUIT:
			get_tree().quit()
		MenuController.CHOICE_CHOOSE_GAME:
			_leave()


func _save_game(slot: int) -> void:
	if not _can_save():
		return
	play.map_session.remember_place()
	if not _saves.write(slot, play.progress):
		_show_message(SAVE_FAILED_MESSAGE)


func _load_game(slot: int) -> void:
	var game := _saves.read(slot) as Keen3Progress
	if game == null:
		_menus.show_message(LOAD_FAILED_LINES)
		return
	_start_game(game)


## The menus are closed: in the ending its box or text comes back (the menu
## used the same window).
func _on_menus_closed() -> void:
	if _mode != Mode.ENDING or _keen3_ending == null:
		return
	_shown_box = null
	_shown_letters = -1
	_on_ending_changed()


## The game is over (GAME OVER, after the last life or the ending): the
## high scores, and a good score asks for a name first.
func _finish_game() -> void:
	if _joined_online:
		# The high score table is the host's: wait for his next game.
		_show_title()
		return
	_show_high_scores()
	_pending_place = _high_scores.place_for(play.inventory.score) if play != null else -1
	if _pending_place < 0:
		return
	var place := _pending_place
	_menus.ask_name(GameTexts.place_word(Keen3Texts.PREFIX, _data.score_texts, place, "a"))


func _on_name_entered(player_name: String) -> void:
	if _pending_place < 0:
		return
	_high_scores.insert(_pending_place, player_name, play.inventory.score, 0)
	_high_scores.save()
	_pending_place = -1
	_show_high_scores()


## Keen 3's own speaker follows the sound setting too.
func _apply_keen_3_sound() -> void:
	_keen_3_sounds.enabled = _user_settings.sound_enabled
	if not _keen_3_sounds.enabled:
		_keen_3_sounds.stop()
