class_name Keen4View
extends Keen4OnlineScreen
## The Keen 4 game screen that the start screen opens (milestones D3-D10):
## the flow of a game on top of [Keen4MenuScreen] (docs/keen4/architecture.md,
## "The flow of Keen 4"; Omni `ck_game.c:CK_GameLoop`, facts only):
##   - it starts with the title loop (intro, story, demos, high scores); a
##     key opens the control panel (new game on Easy, Normal or Hard on the
##     world map, with the box "Keen enters the Shadowlands"; load, save,
##     configure, end game, choose game, quit; F1: the help);
##     [code]-- --game=4 --level=N[/code] opens map N at once (0 the world
##     map, 1-17 the levels, 18 the Megarocket, 19 the high-score map);
##   - on the world map jump, pogo or fire on an entrance: "One moment",
##     then the level's "Keen enters ..." box with Keen counting down, a
##     fade, and the level;
##   - walking out of a level, the Foot, a rescue or the wetsuit: the level
##     is done (rescue and wetsuit boxes first); back on the map with its
##     box, at the place he entered, the level's flag thrown (the Foot: he
##     flies);
##   - a death: one life less and the box "You didn't make it past …"
##     with Try Again (the level again) or Exit to Shadowlands (the map);
##     with no life left "Game Over!", then the high scores;
##   - after the eighth rescue (or the cheat E+N+D) the end pages, then the
##     name typed in on the high-score table, the high scores and the title
##     loop again; B+A+T gives the gems, 99 charges and a life.
##
## Keys: the shared ones (arrows, jump, pogo, fire); Enter the status
## window; F1 the help; Escape the control panel; Shift+N / Shift+P
## the next or previous map; Shift+G god mode; Shift+S the sound and
## Shift+M the music; Shift+F1 and F2-F6 as in
## Keen 1-3 (help line, widescreen, pixel shape, full screen, graphics:
## original or xBRZ, smooth motion).

const NOT_A_MAP_MESSAGE := "Keen 4 has no map %d"
## "One moment" when Keen leaves the world map (seen in the original, D7).
const ONE_MOMENT_TICS := 28
## "Game Over!" stays 4 seconds, or until a key (Omni CK_GameOver).
const GAME_OVER_TICS := 4 * GalaxyClock.TICS_PER_SECOND
## The choices after a death.
const TRY_AGAIN := 0
const EXIT_TO_MAP := 1

## The choice after a death, while the box is up; -1 otherwise.
var _choice := -1
var _choice_tic := 0
var _cheats := Keen4Cheats.new()


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; Keen 4 starts
	# with its title loop as the original (a key opens the menu), so the
	# request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	_set_up_play()
	_set_up_front()
	_set_up_panel()
	_set_up_coop()
	_set_up_online()
	var requested := _requested_map()
	if requested < 0:
		_start_title_loop()
	else:
		_show_level(requested)


func _unhandled_input(event: InputEvent) -> void:
	if _is_help_key(event):
		get_viewport().set_input_as_handled()
		_open_help()
		return
	if _handle_display_keys(event):
		get_viewport().set_input_as_handled()
		return
	if _data != null and _front_input(event):
		get_viewport().set_input_as_handled()
		return
	if _status_drop != null:
		if _is_new_press(event):
			get_viewport().set_input_as_handled()
			if _status_drop.stage == GalaxyStatusDrop.Stage.DOWN:
				_audio.play(&"status_up")
			_status_drop.release()
		return
	if _choice >= 0:
		_choose(event)
		return
	if not _queue.is_empty():
		if _is_new_press(event):
			get_viewport().set_input_as_handled()
			if _queue.press():
				_show_step()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_open_panel()
	elif event.is_action_pressed("status") and (_played != null or _on_map != null):
		get_viewport().set_input_as_handled()
		_open_status()
	elif _handle_map_keys(event):
		get_viewport().set_input_as_handled()


## Shows map [param number] at once: played when Keen is in it, otherwise
## with Keen standing still and the view on him.
func _show_level(number: int, random_start := -1) -> void:
	_map_number = number
	# A fresh copy: playing changes the map's tiles.
	var map := _data.maps.load_map(number) if _data.maps.has_map(number) else null
	if map == null:
		_show_message(NOT_A_MAP_MESSAGE % number)
		return
	_start = Keen4Start.find(map)
	_objects.clear()
	_keen_item = null
	if random_start < 0:
		random_start = randi() & GalaxyWorld.RANDOM_MASK
	if _start.is_world_map():
		var on_map := Keen4MapSession.start(_data, map, _game_progress, random_start)
		_game_progress.foot_flight = false
		_game_progress.last_finished = -1
		if on_map != null:
			_play_map(on_map)
			return
	var played := Keen4LevelSession.start(_data, map, _inventory, random_start, _difficulty, number)
	if played != null:
		_level_began(number, random_start)
		_play(played, map)
	else:
		_look_at(map)


## Map [param number] behind its "Keen enters ..." box, the count-down and
## a fade (Omni CK_LoadLevel's cache box; seen in the original, D7);
## [param from_map]: "One moment" first.
func _enter(number: int, from_map: bool) -> void:
	_queue.clear()
	if from_map:
		_queue.add(_boxes.one_moment(), ONE_MOMENT_TICS)
	_queue_loading(_boxes.entering(number), _show_level.bind(number))
	_after_queue(Callable())


## After a frame: what the level or the map asks for, and how it ended.
func _after_frame() -> bool:
	if _after_demo_frame():
		return not _queue.is_empty() or _played == null
	if _check_cheats():
		return true
	if _on_map != null:
		_after_map_frame()
	else:
		_after_level_frame()
	return not _queue.is_empty() or (_played == null and _on_map == null)


func _after_map_frame() -> void:
	if _on_map.take_conversation() == Keen4MapKeen.CANT_SWIM:
		_show_screens([_boxes.cant_swim()], Callable())
	var level := _on_map.entered()
	if level > 0:
		_game_progress.map_position = _on_map.keen.map_position
		_enter(level, true)


func _after_level_frame() -> void:
	var asked := _played.take_conversation()
	if asked == Keen4Lindsey.MESSAGE:
		# Her message stops the music; the map's song starts again after it
		# (Omni CK4_ShowPrincessMessage).
		_audio.stop_music()
		_show_screens(_messages.lindsey(_map_number), _audio.play_map_song.bind(_map_number))
	elif asked == Keen4Council.JANITOR:
		_audio.play_council_song()
		_show_screens(_messages.janitor(), _audio.play_map_song.bind(_map_number))
	if _played.is_done():
		_finish_level()
	elif _played.is_lost():
		_lose_level()


## The level is done (Omni CK_GameLoop): it is marked, its flag will be
## thrown; a rescue or the wetsuit shows its boxes first; then the map.
func _finish_level() -> void:
	var ending := _played.ending()
	_played = null
	_game_progress.mark_done(_map_number)
	_game_progress.last_finished = _map_number
	_game_progress.foot_flight = ending == Keen4Inchworm.FOOT_ENDING
	_audio.play(&"level_exit")
	match ending:
		Keen4Council.RESCUED:
			_audio.play_council_song()
			var before := _game_progress.rescue()
			_show_screens(_messages.council(_map_number, before), _after_rescue)
		Keen4Wetsuit.TAKEN:
			_game_progress.wetsuit = true
			_show_screens(_messages.wetsuit(), _back_to_map)
		_:
			_back_to_map()


func _after_rescue() -> void:
	if _game_progress.all_rescued():
		_start_ending()
	else:
		_back_to_map()


func _back_to_map() -> void:
	_enter(Keen4Episode.WORLD_MAP, false)


## Keen died (Omni CK_TryAgainMenu, CK_GameOver): a life less; the box with
## the choice, or "Game Over!" and the start screen.
func _lose_level() -> void:
	_played = null
	_game_progress.last_finished = -1
	_inventory.lives -= 1
	if _inventory.lives < 0:
		_queue.add(_boxes.game_over(), GAME_OVER_TICS)
		_after_queue(_game_ended)
		return
	_choice = TRY_AGAIN
	_choice_tic = 0
	_queue.add_box(_boxes.try_again(_map_number, _choice, _choice_tic))
	_show_step()


## The keys of the box after a death: up and down choose, jump, pogo,
## Enter or Space take the choice, Escape goes to the map.
func _choose(event: InputEvent) -> void:
	if not _is_new_press(event):
		return
	get_viewport().set_input_as_handled()
	var input := _choice_input()
	if event.is_action_pressed("ui_cancel"):
		_take_choice(EXIT_TO_MAP)
	elif input.jump or input.pogo or event.is_action_pressed("ui_accept"):
		_take_choice(_choice)
	elif input.vertical != 0:
		_choice = TRY_AGAIN if input.vertical < 0 else EXIT_TO_MAP
		_redraw_choice()


func _take_choice(choice: int) -> void:
	_choice = -1
	_queue.clear()
	_enter(_map_number if choice == TRY_AGAIN else Keen4Episode.WORLD_MAP, false)


## The choice's frame blinks while the box waits.
func _waiting(tics: int) -> void:
	super(tics)
	if _choice < 0:
		return
	var before := Keen4GameBoxes.blink_color(_choice_tic)
	_choice_tic += tics
	if Keen4GameBoxes.blink_color(_choice_tic) != before:
		_redraw_choice()


func _redraw_choice() -> void:
	var step := _queue.current()
	if step == null:
		return
	step.image = _boxes.try_again(_map_number, _choice, _choice_tic)
	_show_step()


## The cheats while Keen plays (Omni CK_PlayLoop, CK_CheckKeys): E+N+D
## ends the game as a rescue of the eighth council member here; B+A+T
## shows its box and gives the items. Returns whether one did something.
func _check_cheats() -> bool:
	match _cheats.check(Keen4Cheats.is_key_held):
		Keen4Cheats.Cheat.END:
			var map := _map_number
			_played = null
			_on_map = null
			_game_progress.rescued = Keen4Progress.COUNCIL_COUNT - 1
			if map >= Keen4Episode.FIRST_LEVEL and map <= Keen4Episode.LAST_LEVEL:
				_game_progress.mark_done(map)
			var before := _game_progress.rescue()
			_audio.play_council_song()
			_show_screens(_messages.council(map, before), _start_ending)
			return true
		Keen4Cheats.Cheat.ITEMS:
			_record_event(Keen4SavedGame.Event.ITEMS_CHEAT)
			_show_screens([Keen4Cheats.items_box(_data)], _give_items)
			return true
	return false


func _give_items() -> void:
	Keen4Cheats.give_items(_inventory)
	_update_score_box()


## F1 alone (Shift+F1 keeps Keen 1-3's help line); not over the end or
## the name being typed.
func _is_help_key(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.shift_pressed:
		return false
	if _data == null or _front in [Front.HELP, Front.ENDING, Front.NAME_ENTRY]:
		return false
	if _panel.is_open() and not _panel.allows_help():
		return false
	return event.is_action_pressed("toggle_help")


func _leave() -> void:
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


## Shift+N and Shift+P: the next or previous map; Shift+G: god mode, as
## the original's debug key F10+G (nothing kills Keen, D5); Shift+S the
## sound (AdLib, PC speaker, off) and Shift+M the music (until the menus
## of D10 have them).
func _handle_map_keys(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not key.shift_pressed:
		return false
	var step := 0
	match key.keycode:
		KEY_N:
			step = 1
		KEY_P:
			step = -1
		KEY_G:
			_god_mode = not _god_mode
			if _played != null:
				_played.player.god_mode = _god_mode
				_record_event(
					(
						Keen4SavedGame.Event.GOD_MODE_ON
						if _god_mode
						else Keen4SavedGame.Event.GOD_MODE_OFF
					)
				)
			return true
		KEY_S:
			_show_message(_audio.next_mode(_user_settings))
			_user_settings.save()
			return true
		KEY_M:
			_show_message(_audio.toggle_music(_user_settings))
			_user_settings.save()
			return true
		_:
			return false
	if _data != null:
		var count := Keen4Episode.LAST_MAP + 1
		_show_level(posmod(_map_number + step, count))
	return true


## The map asked for with --level=N, or -1 (a new game).
static func _requested_map() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(GameLaunch.LEVEL_OPTION):
			return argument.trim_prefix(GameLaunch.LEVEL_OPTION).to_int()
	return -1
