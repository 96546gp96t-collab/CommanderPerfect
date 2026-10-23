class_name GalaxyMenuScreen
extends GalaxyFrontScreen
## The control panel of a Galaxy episode, between [GalaxyFrontScreen] and
## the episode's view (made from Keen 4's [Keen4MenuScreen], milestone E9;
## docs/keen4/gameplay.md, "The control panel"; docs/keen5/gameplay.md,
## "The control panel"): the wrist-watch menu ([GalaxyMenuController]
## drawn by [GalaxyMenuView] on the title layer, with the episode's
## pictures from [method GalaxyGameRules.menu_cards]) that a key in the
## title loop and Escape in a game open (Omni `ck_play.c`, CK_PlayLoop;
## `ck_inter.c`, the demo loop), and what its choices do:
##   - New Game on Easy, Normal or Hard; Load Game (black, the game, the
##     "PAUSED" box until a key); Save Game, anywhere in a game
##     ([GalaxySavedGame]: on the map the place, in a level its start and
##     every frame since, played again when loaded), in the episode's own
##     folder ([method GalaxyGameRules.saves_folder]);
##   - Return to Game (or to the demos), End Game (the high scores, the
##     title loop), Paddle War (its tics run on the screen's time, its
##     sounds are [GalaxyAudio]'s), Quit (or, ours, another game: the start
##     screen);
##   - Configure: Sound and Music (at once, stored in the shared settings;
##     the quiet AdLib sounds in [GalaxySettings]), the score box (the
##     episode's own setting), the shared display settings and keys;
##   - F1 opens the help ([GalaxyHelp]) over the title loop, a game or a
##     card of the panel; leaving it shows what was there.
## While the panel is open the game and the title loop stand still and the
## music stops; Return to Game starts the map's song from its beginning
## (Omni CK_PlayLoop: StopMusic, US_RunCards, StartMusic), Return to Demo
## goes on with the title loop's next step and its song.
## The episode's view calls [method _set_up_panel] after
## [method GalaxyFrontScreen._set_up_front].

const PRESS_ANY_KEY := GalaxyMenuController.PRESS_ANY_KEY
const SAVE_FAILED_LINES: PackedStringArray = ["The game could not be saved", PRESS_ANY_KEY]
const LOAD_FAILED_LINES: PackedStringArray = ["That game could not be read", PRESS_ANY_KEY]
## A loaded level's frames are played again this long per screen frame.
const REPLAY_MILLISECONDS := 50
## The Sound card's choices as the settings name them.
const SOUND_DEVICES: Array[String] = ["off", "pc", "adlib", "adlib"]

var _panel: GalaxyMenuController
var _panel_view: GalaxyMenuView
var _saves: GalaxySaveSlots
## The level being played as it began, and its frames since (null on the
## world map, in a demo, out of a game).
var _recording: GalaxySavedGame
## A loaded level's frames being played again, and the game loaded.
var _replay: GalaxySavedGame.Replay
var _loaded: GalaxySavedGame
var _help: GalaxyHelp
## The help was opened from the panel (F1): leaving it shows the panel.
var _help_over_panel := false
## Paddle War's time not yet run as tics, and its place in the random
## table (its own: the game's must not change).
var _paddle_seconds := 0.0
var _paddle_random_index := 0
var _random_table := PackedByteArray()


## After [method GalaxyFrontScreen._set_up_front]: the panel, its pictures
## and the saved games.
func _set_up_panel() -> void:
	_saves = GalaxySaveSlots.in_directory(rules.saves_folder(), rules.save_slot_count)
	_panel = _new_panel()
	_panel.settings = _user_settings
	_panel.slots = _saves
	_panel.score_box = _galaxy_settings.score_box
	_panel.random = _paddle_random
	_random_table = _data.executable.random_table()
	add_child(_panel)
	_panel_view = GalaxyMenuView.create(
		_data.graphics, rules.menu_cards(_data.graphics.ranges.picture_count)
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


## The panel's controller (the co-op screen gives one with its own cards).
func _new_panel() -> GalaxyMenuController:
	return GalaxyMenuController.new()


## A saved game of the episode (one with more to keep gives its own:
## [Keen5SavedGame]).
func _new_saved_game() -> GalaxySavedGame:
	return GalaxySavedGame.new(rules)


## Whether the game is in a moment the panel cannot save (none by default;
## Keen 5's rides on the world map); Escape waits until it is over.
func _panel_waits() -> bool:
	return false


## Escape in a game: the panel.
func _escape() -> void:
	if not _panel_waits():
		_open_panel()


## Opens the main card; out of a game the title loop stops behind it.
func _open_panel() -> void:
	var playing := in_game()
	if not playing:
		_queue.clear()
		_played = null
		_on_map = null
		_stop_front()
		_show_step()
	# The music stops, in a game and in the title loop (heard in Keen 4).
	_stop_music()
	# The player can also switch with F4 and Shift+S/M: the cards show what
	# is so.
	_user_settings.fullscreen = _is_fullscreen()
	_panel.sound_choice = _sound_choice()
	_panel.music_on = _user_settings.music_enabled
	_panel.score_box = _galaxy_settings.score_box
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
			if _in_title_loop or not in_game():
				_in_title_loop = true
				_next_title_step()
			else:
				_play_map_song(_map_number)
		MenuController.CHOICE_NEW_GAME:
			_new_game(value as GalaxyDifficulty.Level)
		MenuController.CHOICE_LOAD:
			_load_game(value)
		MenuController.CHOICE_SAVE:
			_save_game(value)
		GalaxyMenuController.CHOICE_END_GAME:
			_end_game()
		GalaxyMenuController.CHOICE_SCORE_BOX:
			_galaxy_settings.score_box = value != 0
			_galaxy_settings.save()
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
## closes; the user wished it at once, Keen 4 D11).
func _choose_sound(choice: GalaxyMenuController.SoundChoice) -> void:
	_user_settings.sound_device = SOUND_DEVICES[choice]
	_user_settings.save()
	_galaxy_settings.quiet_adlib = choice == GalaxyMenuController.SoundChoice.QUIET_ADLIB
	_galaxy_settings.save()
	_audio.quiet_adlib = _galaxy_settings.quiet_adlib
	_audio.apply_settings(_user_settings)


## The Sound card's choice the settings give.
func _sound_choice() -> GalaxyMenuController.SoundChoice:
	match GalaxySoundPlayer.mode_named(_user_settings.sound_device):
		GalaxySoundPlayer.Mode.OFF:
			return GalaxyMenuController.SoundChoice.OFF
		GalaxySoundPlayer.Mode.PC:
			return GalaxyMenuController.SoundChoice.PC
	if _galaxy_settings.quiet_adlib:
		return GalaxyMenuController.SoundChoice.QUIET_ADLIB
	return GalaxyMenuController.SoundChoice.ADLIB


## Paddle War's random numbers: the original's table, from its own place.
func _paddle_random() -> int:
	if _random_table.is_empty():
		return randi() & GalaxyWorld.RANDOM_MASK
	_paddle_random_index = (_paddle_random_index + 1) & GalaxyWorld.RANDOM_MASK
	return _random_table[_paddle_random_index % _random_table.size()]


## F1: the help, over the title loop, the game (which waits) or a card of
## the panel (Omni US_RunCards).
func _open_help() -> void:
	if _help == null:
		_help = GalaxyHelp.create(_data.graphics, rules)
	_help_over_panel = _panel.is_open()
	if _in_title_loop and not _help_over_panel:
		_queue.clear()
		_played = null
		_stop_front()
	_front = Front.HELP
	_title_layer.show_picture(_help.screen())
	_stop_music()
	_play_map_song(rules.help_song)


## Leaving the help: the panel as it was, the title loop's next step, or
## the game with its song.
func _close_help() -> void:
	_stop_music()
	_front = Front.NONE
	if _help_over_panel:
		_help_over_panel = false
		_show_panel()
	elif _in_title_loop:
		_next_title_step()
	else:
		_title_layer.clear()
		_play_map_song(_map_number)


func _help_key(event: InputEvent) -> void:
	var input := KeenInput.from_actions()
	var action := -1
	if event.is_action_pressed("ui_cancel"):
		action = GalaxyHelp.Action.ESCAPE
	elif event.is_action_pressed("ui_accept") or input.jump or input.pogo:
		action = GalaxyHelp.Action.OPEN
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_page_up"):
		action = GalaxyHelp.Action.UP
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_page_down"):
		action = GalaxyHelp.Action.DOWN
	elif event.is_action_pressed("ui_left"):
		action = GalaxyHelp.Action.BACK_PAGE
	elif event.is_action_pressed("ui_right"):
		action = GalaxyHelp.Action.NEXT_PAGE
	if action < 0:
		return
	if _help.act(action):
		_title_layer.show_picture(_help.screen())
	else:
		_close_help()


## F1 alone (Shift+F1 keeps Keen 1-3's help line); not over the end, a
## scene, the name being typed, or a dialog, a name, a key or Paddle War
## in the panel.
func _is_help_key(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.shift_pressed:
		return false
	if _data == null or _front in [Front.HELP, Front.ENDING, Front.NAME_ENTRY, Front.SCENE]:
		return false
	if _panel.is_open() and not _panel.allows_help():
		return false
	return event.is_action_pressed("toggle_help")


## Whether a box, the status window or the choice after a death waits in a
## game: the original reads F1 only while Keen plays, so then F1 is just a
## key for what waits (Keen 4, D13).
func _box_waits() -> bool:
	if _panel.is_open() or _in_title_loop:
		return false
	return not _queue.is_empty() or _status_drop != null or _choice >= 0


## A display setting changed in the options: the picture follows.
func _on_display_changed() -> void:
	_apply_window_mode()
	_apply_graphics()
	_apply_display_settings()
	_show_panel()


## The score box shows while a game is played, unless it is switched off.
func _apply_score_box() -> void:
	if in_game():
		_score_box.visible = _galaxy_settings.score_box


func _play(session: GalaxyLevelSession, map: GalaxyMap) -> void:
	super(session, map)
	_apply_score_box()


func _play_map(session: GalaxyMapSession) -> void:
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


## The keys go to the help, or to the panel while it is open.
func _front_input(event: InputEvent) -> bool:
	if _front == Front.HELP:
		if _is_new_press(event):
			_help_key(event)
		return true
	if _panel.is_open():
		if event.is_pressed() or _is_new_press(event):
			_panel.handle_input(event)
		return true
	return super(event)


## In the title loop (intro, story, demos) any key opens the panel, as in
## the original.
func _title_loop_key(_event: InputEvent) -> void:
	_open_panel()


## Every frame of a level in a game is kept for a save.
func _frame_input(tics: int) -> KeenInput:
	var input := super(tics)
	if _recording != null and _played != null and _front == Front.NONE:
		GalaxySavedGame.record_frame(_recording.frames, input, tics)
	return input


## A level of a game began: from here its frames are kept.
func _level_began(number: int, random_start: int) -> void:
	if _in_title_loop or _front != Front.NONE:
		_recording = null
		return
	_recording = _snapshot()
	_recording.map_number = number
	_recording.random_start = random_start
	if _god_mode:
		GalaxySavedGame.record_event(_recording.frames, GalaxySavedGame.Event.GOD_MODE_ON)


## The game as it is now (copies of what Keen carries and the progress).
func _snapshot() -> GalaxySavedGame:
	var game := _new_saved_game()
	game.difficulty = _difficulty
	game.inventory = game.copy_inventory(_inventory)
	game.progress.load_dictionary(_game_progress.to_dictionary())
	return game


## The view's width is kept among the frames: objects wake up around what
## it shows, so the frames played again need it.
func _wide_view_changed(width: int) -> void:
	if _recording != null and _played != null:
		GalaxySavedGame.record_view_width(_recording.frames, width)


## Something between the frames that changes the level (a cheat, god mode).
func _record_event(event: GalaxySavedGame.Event) -> void:
	if _recording != null and _played != null:
		GalaxySavedGame.record_event(_recording.frames, event)


## B+A+T's gifts are kept among a saved level's frames.
func _give_items() -> void:
	_record_event(GalaxySavedGame.Event.ITEMS_CHEAT)
	super()


## A new game on [param level]: the world map behind its box.
func _new_game(level := GalaxyDifficulty.DEFAULT) -> void:
	_begin_game()
	_difficulty = level
	_inventory = _new_inventory()
	_game_progress = _new_progress()
	_enter(rules.world_map, false)


## Whatever ran (the title loop, a game) stops for a new or loaded game.
func _begin_game() -> void:
	_in_title_loop = false
	_after_game = false
	_queue.clear()
	_played = null
	_on_map = null
	_recording = null
	_stop_front()
	_stop_music()
	_title_layer.clear()


## The game in [param slot]: black, the game as it was, "PAUSED" until a
## key (seen in Keen 4 v1.0 and Keen 5 v1.4).
func _load_game(slot: int) -> void:
	var game := _new_saved_game()
	if not game.load_dictionary(_saves.read(slot)):
		_open_panel()
		_panel.show_message(LOAD_FAILED_LINES)
		return
	_begin_game()
	_replay = null
	_inventory = game.copy_inventory(game.inventory)
	_game_progress = game.progress
	_difficulty = game.difficulty
	_queue.add(null, BLACK_TICS, 0.0, _resume.bind(game))
	_queue.add_box(_boxes.paused())
	_after_queue(Callable())


## Puts [param game] on the screen: the map, or its level, whose frames
## are then played again behind the black ([method _finish_replay]),
## silently, without the god mode of now.
func _resume(game: GalaxySavedGame) -> void:
	_show_level(game.map_number, game.random_start)
	if not game.in_level() or _played == null:
		return
	_loaded = game
	_played.set_wide_width(0)
	_played.player.god_mode = false
	_played.world.sound_player = Callable()
	_replay = game.begin_replay(_played, game.frames, _galaxy_map.animate)


func _process(delta: float) -> void:
	if _panel != null and _panel.paddle_war() != null:
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
		_inventory = game.copy_inventory(game.inventory)
		_show_level(game.map_number, game.random_start)
		return
	_played.world.sound_player = _play_sound
	_god_mode = _played.player.god_mode
	_recording.frames = game.frames.duplicate()
	_apply_wide_view()
	_clock.resume_at(tic)
	_objects.show_objects(_played.world.objects)
	_frame_view()
	_view_motion.move_to(Vector2(_camera_anchor.position))
	_view_motion.snap()
	_update_score_box()


## Saves the game in [param slot] under the name typed in the panel.
func _save_game(slot: int) -> void:
	var game: GalaxySavedGame
	if _played != null and _recording != null:
		game = _recording
	elif _on_map != null:
		game = _snapshot()
		game.progress.map_position = _on_map.keen.position
	if game == null or not _saves.write(slot, _panel.typed_save_name, game.to_dictionary()):
		_panel.show_message(SAVE_FAILED_LINES)


## End Game: the game stops; the high scores and the title loop (seen in
## Keen 4 v1.0 and Keen 5 v1.4; nothing goes in the table).
func _end_game() -> void:
	_played = null
	_on_map = null
	_recording = null
	_in_title_loop = true
	_after_game = false
	_start_demo(rules.high_score_demo, true)
