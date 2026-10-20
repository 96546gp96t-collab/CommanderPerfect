class_name Keen4MenuScreen
extends Keen4FrontScreen
## Keen 4's control panel (milestone D10), between [Keen4FrontScreen] and
## [Keen4View]: the wrist-watch menu ([GalaxyMenuController] drawn by
## [GalaxyMenuView] on the title layer) that a key in the title loop and
## Escape in a game open (Omni `ck_play.c`, CK_PlayLoop; `ck_inter.c`, the
## demo loop), and what its choices do:
##   - New Game on Easy, Normal or Hard; Load Game (black, the game, the
##     "PAUSED" box until a key; seen in v1.0); Save Game, anywhere in a
##     game ([Keen4SavedGame]: on the map the place, in a level its start
##     and every frame since, played again when loaded);
##   - Return to Game (or to the demos), End Game (the map fades, the high
##     scores, the title loop; seen in v1.0), Paddle War (its tics run on
##     the screen's time, its sounds are [Keen4Audio]'s), Quit (or, ours,
##     another game: the start screen);
##   - Configure: Sound and Music (at once, stored in the shared settings;
##     the quiet AdLib sounds in [Keen4Settings]), the score box (Keen 4's
##     own setting), the shared display settings and keys;
##   - F1 on a card opens the help; leaving it shows the panel again.
## While the panel is open the game and the title loop stand still and the
## music stops; Return to Game starts the map's song from its beginning
## (Omni CK_PlayLoop: StopMusic, US_RunCards, StartMusic; heard in v1.0),
## Return to Demo goes on with the title loop's next step and its song.

const PRESS_ANY_KEY := GalaxyMenuController.PRESS_ANY_KEY
const SAVE_FAILED_LINES: PackedStringArray = ["The game could not be saved", PRESS_ANY_KEY]
const LOAD_FAILED_LINES: PackedStringArray = ["That game could not be read", PRESS_ANY_KEY]
## A loaded level's frames are played again this long per screen frame.
const REPLAY_MILLISECONDS := 50
## The Sound card's choices as the settings name them.
const SOUND_DEVICES: Array[String] = ["off", "pc", "adlib", "adlib"]

var _panel := GalaxyCoopMenuController.new()
var _panel_view: GalaxyMenuView
var _saves := GalaxySaveSlots.new()
var _keen4_settings := Keen4Settings.load_from()
## The level being played as it began, and its frames since (null on the
## world map, in a demo, out of a game).
var _recording: Keen4SavedGame
## A loaded level's frames being played again, and the game loaded.
var _replay: Keen4SavedGame.Replay
var _loaded: Keen4SavedGame
## The help was opened from the panel (F1): leaving it shows the panel.
var _help_over_panel := false
## Paddle War's time not yet run as tics, and its place in the random
## table (its own: the game's must not change).
var _paddle_seconds := 0.0
var _paddle_random_index := 0
var _random_table := PackedByteArray()


## After [method Keen4FrontScreen._set_up_front]: the panel and its
## pictures.
func _set_up_panel() -> void:
	_panel.settings = _user_settings
	_panel.slots = _saves
	_panel.score_box = _keen4_settings.score_box
	_panel.random = _paddle_random
	_random_table = _data.executable.random_table()
	_audio.quiet_adlib = _keen4_settings.quiet_adlib
	add_child(_panel)
	_panel_view = GalaxyMenuView.create(
		_data.graphics, Keen4Episode.menu_cards(_data.graphics.ranges.picture_count)
	)
	_panel.redrawn.connect(_show_panel)
	_panel.closed.connect(_on_panel_closed)
	_panel.chosen.connect(_on_panel_chosen)
	_panel.settings_changed.connect(_on_display_changed)
	_panel.sound_requested.connect(_audio.play)


## The control panel (tests drive it).
func menus() -> GalaxyMenuController:
	return _panel


## The saved games.
func saves() -> GalaxySaveSlots:
	return _saves


## Whether a game is being played (not the title loop, a demo, the end).
func in_game() -> bool:
	return not _in_title_loop and _front == Front.NONE and (_played != null or _on_map != null)


## Opens the main card; out of a game the title loop stops behind it.
func _open_panel() -> void:
	var playing := in_game()
	if not playing:
		_queue.clear()
		_played = null
		_on_map = null
		_stop_front()
		_show_step()
	# The music stops, in a game and in the title loop (heard in v1.0).
	_audio.stop_music()
	# The player can also switch with F4 and Shift+S/M: the cards show what
	# is so.
	_user_settings.fullscreen = _is_fullscreen()
	_panel.sound_choice = _sound_choice()
	_panel.music_on = _user_settings.music_enabled
	_panel.open_main(playing)


func _show_panel() -> void:
	if _panel.is_open() and _panel_view != null and _front != Front.HELP:
		_title_layer.show_picture(_panel_view.draw(_panel))


func _on_panel_closed() -> void:
	if _in_title_loop:
		_title_layer.show_black()
	else:
		_title_layer.clear()
		_apply_score_box()


func _on_panel_chosen(id: StringName, value: int) -> void:
	match id:
		MenuController.CHOICE_RESUME:
			if _in_title_loop:
				_next_title_step()
			else:
				_audio.play_map_song(_map_number)
		MenuController.CHOICE_NEW_GAME:
			_new_game(value as GalaxyDifficulty.Level)
		MenuController.CHOICE_LOAD:
			_load_game(value)
		MenuController.CHOICE_SAVE:
			_save_game(value)
		GalaxyMenuController.CHOICE_END_GAME:
			_end_game()
		GalaxyMenuController.CHOICE_SCORE_BOX:
			_keen4_settings.score_box = value != 0
			_keen4_settings.save()
		GalaxyMenuController.CHOICE_SOUND:
			_choose_sound(value as GalaxyMenuController.SoundChoice)
		GalaxyMenuController.CHOICE_MUSIC:
			_user_settings.music_enabled = value != 0
			_user_settings.save()
			_audio.set_music(_user_settings.music_enabled)
		MenuController.CHOICE_CHOOSE_GAME:
			_leave()
		MenuController.CHOICE_QUIT:
			get_tree().quit()


## The Sound card's choice, at once (the original switches when the panel
## closes; the user wished it at once).
func _choose_sound(choice: GalaxyMenuController.SoundChoice) -> void:
	_user_settings.sound_device = SOUND_DEVICES[choice]
	_user_settings.save()
	_keen4_settings.quiet_adlib = choice == GalaxyMenuController.SoundChoice.QUIET_ADLIB
	_keen4_settings.save()
	_audio.quiet_adlib = _keen4_settings.quiet_adlib
	_audio.apply_settings(_user_settings)


## The Sound card's choice the settings give.
func _sound_choice() -> GalaxyMenuController.SoundChoice:
	match GalaxySoundPlayer.mode_named(_user_settings.sound_device):
		GalaxySoundPlayer.Mode.OFF:
			return GalaxyMenuController.SoundChoice.OFF
		GalaxySoundPlayer.Mode.PC:
			return GalaxyMenuController.SoundChoice.PC
	if _keen4_settings.quiet_adlib:
		return GalaxyMenuController.SoundChoice.QUIET_ADLIB
	return GalaxyMenuController.SoundChoice.ADLIB


## Paddle War's random numbers: the original's table, from its own place.
func _paddle_random() -> int:
	if _random_table.is_empty():
		return randi() & GalaxyWorld.RANDOM_MASK
	_paddle_random_index = (_paddle_random_index + 1) & GalaxyWorld.RANDOM_MASK
	return _random_table[_paddle_random_index % _random_table.size()]


## F1 on a card of the panel: the help over it (Omni US_RunCards).
func _open_help() -> void:
	_help_over_panel = _panel.is_open()
	if not _help_over_panel:
		super()
		return
	if _help == null:
		_help = Keen4Help.create(_data.graphics)
	_front = Front.HELP
	_title_layer.show_picture(_help.screen())
	_audio.stop_music()


## Leaving the help opened from the panel: the panel as it was.
func _close_help() -> void:
	if not _help_over_panel:
		super()
		return
	_help_over_panel = false
	_front = Front.NONE
	_show_panel()


## A display setting changed in the options: the picture follows.
func _on_display_changed() -> void:
	_apply_window_mode()
	_apply_graphics()
	_apply_display_settings()
	_show_panel()


## The score box shows while a game is played, unless it is switched off.
func _apply_score_box() -> void:
	if in_game():
		_score_box.visible = _keen4_settings.score_box


func _play(session: Keen4LevelSession, map: GalaxyMap) -> void:
	super(session, map)
	_apply_score_box()


func _play_map(session: Keen4MapSession) -> void:
	super(session)
	_recording = null
	_apply_score_box()


## While the panel is open the frames stand still; its cursor blinks.
func _run_frame(tics: int) -> bool:
	if _panel.is_open():
		if _front != Front.HELP:
			_panel.advance(tics)
		return true
	return super(tics)


## The keys go to the panel while it is open; in the title loop (intro,
## story, demos) any key opens it, as in the original.
func _front_input(event: InputEvent) -> bool:
	if _panel.is_open() and _front != Front.HELP:
		if event.is_pressed() or _is_new_press(event):
			_panel.handle_input(event)
		return true
	if _in_title_loop and _front in [Front.NONE, Front.INTRO, Front.STORY, Front.DEMO]:
		if _is_new_press(event):
			_open_panel()
		return true
	return super(event)


## Every frame of a level in a game is kept for a save.
func _frame_input(tics: int) -> KeenInput:
	var input := super(tics)
	if _recording != null and _played != null and _front == Front.NONE:
		Keen4SavedGame.record_frame(_recording.frames, input, tics)
	return input


## A level of a game began ([Keen4View]): from here its frames are kept.
func _level_began(number: int, random_start: int) -> void:
	if _in_title_loop or _front != Front.NONE:
		_recording = null
		return
	_recording = Keen4SavedGame.new()
	_recording.difficulty = _difficulty
	_recording.inventory = _copy_inventory(_inventory)
	_recording.progress = Keen4Progress.from_dictionary(_game_progress.to_dictionary())
	_recording.map_number = number
	_recording.random_start = random_start
	if _god_mode:
		Keen4SavedGame.record_event(_recording.frames, Keen4SavedGame.Event.GOD_MODE_ON)


## Something between the frames that changes the level (a cheat, god mode).
func _record_event(event: Keen4SavedGame.Event) -> void:
	if _recording != null and _played != null:
		Keen4SavedGame.record_event(_recording.frames, event)


## A new game on [param level] from the world map, with its box.
func _new_game(level := GalaxyDifficulty.DEFAULT) -> void:
	_begin_game()
	_inventory = Keen4Inventory.new_game()
	_game_progress = Keen4Progress.new()
	_difficulty = level
	_enter(Keen4Episode.WORLD_MAP, false)


## Whatever ran (the title loop, a game) stops for a new or loaded game.
func _begin_game() -> void:
	_in_title_loop = false
	_after_game = false
	_queue.clear()
	_played = null
	_on_map = null
	_recording = null
	_stop_front()
	_title_layer.clear()


## The game in [param slot]: black, the game as it was, "PAUSED" until a
## key (seen in v1.0).
func _load_game(slot: int) -> void:
	var game := Keen4SavedGame.from_dictionary(_saves.read(slot))
	if game == null:
		_open_panel()
		_panel.show_message(LOAD_FAILED_LINES)
		return
	_begin_game()
	_replay = null
	_inventory = _copy_inventory(game.inventory)
	_game_progress = game.progress
	_difficulty = game.difficulty
	_queue.add(null, BLACK_TICS, 0.0, _resume.bind(game))
	_queue.add_box(_boxes.paused())
	_after_queue(Callable())


## Puts [param game] on the screen: the map, or its level, whose frames
## are then played again behind the black ([method _continue_replay]).
func _resume(game: Keen4SavedGame) -> void:
	_show_level(game.map_number, game.random_start)
	if not game.in_level() or _played == null:
		return
	_loaded = game
	_replay = Keen4SavedGame.replay_on(_played, game.frames, _galaxy_map.animate)


func _process(delta: float) -> void:
	if _panel.paddle_war() != null:
		_run_paddle_war(delta)
	elif _replay == null:
		_paddle_seconds = 0.0
		super(delta)
	elif _replay.play(REPLAY_MILLISECONDS):
		_finish_replay()


## Paddle War runs on tics of its own (the original's 70 a second, every
## one drawn), with the paddle on the held left and right keys.
func _run_paddle_war(delta: float) -> void:
	_paddle_seconds += delta
	var tics := floori(_paddle_seconds * GalaxyClock.TICS_PER_SECOND)
	if tics <= 0:
		return
	_paddle_seconds -= float(tics) / GalaxyClock.TICS_PER_SECOND
	var left := Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_LEFT)
	var right := Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_RIGHT)
	_panel.run_paddle_war(tics, left, right)


## The loaded level is where it was saved: the game goes on from there.
func _finish_replay() -> void:
	var game := _loaded
	var tic := _replay.tic
	_replay = null
	_loaded = null
	if _played == null or not _played.is_playing():
		# The frames no longer give the same level (another version of the
		# engine): the level from its start.
		push_error("The saved level could not be played again; it starts anew.")
		_inventory = _copy_inventory(game.inventory)
		_show_level(game.map_number, game.random_start)
		return
	_recording.frames = game.frames.duplicate()
	_clock.resume_at(tic)
	_objects.show_objects(_played.world.objects)
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_view_motion.snap()
	_update_score_box()


## Saves the game in [param slot] under the name typed in the panel.
func _save_game(slot: int) -> void:
	var game: Keen4SavedGame
	if _played != null and _recording != null:
		game = _recording
	elif _on_map != null:
		game = Keen4SavedGame.new()
		game.difficulty = _difficulty
		game.inventory = _copy_inventory(_inventory)
		game.progress = Keen4Progress.from_dictionary(_game_progress.to_dictionary())
		game.progress.map_position = _on_map.keen.position
	if game == null or not _saves.write(slot, _panel.typed_save_name, game.to_dictionary()):
		_panel.show_message(SAVE_FAILED_LINES)


## End Game: the game stops, the map fades, the high scores and the title
## loop (seen in v1.0; nothing goes in the table).
func _end_game() -> void:
	_played = null
	_on_map = null
	_recording = null
	_in_title_loop = true
	_after_game = false
	_start_demo(Keen4TitleLoop.HIGH_SCORE_DEMO, true)


static func _copy_inventory(carried: GalaxyInventory) -> Keen4Inventory:
	return Keen4SavedGame.inventory_from_dictionary(Keen4SavedGame.inventory_to_dictionary(carried))


## Shows map [param _number] ([Keen4View]); [param _random_start] -1: a
## new place in the random table.
func _show_level(_number: int, _random_start := -1) -> void:
	pass


## Map [param _number] behind its box ([Keen4View]).
func _enter(_number: int, _from_map: bool) -> void:
	pass
