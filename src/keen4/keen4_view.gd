class_name Keen4View
extends Keen4PlayScreen
## The Keen 4 game screen that the start screen opens (milestones D3-D7):
## the flow of a game on top of [Keen4PlayScreen] (docs/keen4/architecture.md,
## "The flow of Keen 4"; Omni `ck_game.c:CK_GameLoop`, facts only):
##   - a new game starts on the world map, with the box "Keen enters the
##     Shadowlands"; [code]-- --game=4 --level=N[/code] opens map N at once
##     (0 the world map, 1-17 the levels, 18 the Megarocket, 19 the
##     high-score map);
##   - on the world map jump, pogo or fire on an entrance: "One moment",
##     then the level's "Keen enters ..." box with Keen counting down, a
##     fade, and the level;
##   - walking out of a level, the Foot, a rescue or the wetsuit: the level
##     is done (rescue and wetsuit boxes first); back on the map with its
##     box, at the place he entered, the level's flag thrown (the Foot: he
##     flies);
##   - a death: one life less and the box "You didn't make it past …"
##     with Try Again (the level again) or Exit to Shadowlands (the map);
##     with no life left "Game Over!" and the start screen (the high scores
##     come in D8);
##   - after the eighth rescue (the end is D8's) the status line says so
##     and the map follows.
##
## Keys: the shared ones (arrows, jump, pogo, fire); Enter the status
## window; Escape back to the start screen; Shift+N / Shift+P the next or
## previous map; Shift+G god mode; F1-F6 as in Keen 1-3 (help line,
## widescreen, pixel shape, full screen, graphics: original or xBRZ,
## smooth motion).

const NOT_A_MAP_MESSAGE := "Keen 4 has no map %d"
## After the eighth rescue (the end comes in D8).
const ALL_RESCUED_MESSAGE := "All eight council members are rescued"
## The box when a map "loads" (seen in the original, D7; the original's
## times depend on how fast it reads the files): "One moment" when Keen
## leaves the world map, the box with the whole count-down picture, each
## finger, the last one before the fade.
const ONE_MOMENT_TICS := 28
const BOX_TICS := 21
const FINGER_TICS := 20
const LAST_FINGER_TICS := 28
## The fade to the next map and back (seen: steps of 6 tics, about 19
## tics black in between).
const FADE_STEPS: PackedFloat32Array = [0.75, 0.5, 0.25]
const FADE_STEP_TICS := 6
const BLACK_TICS := 19
## "Game Over!" stays 4 seconds, or until a key (Omni CK_GameOver).
const GAME_OVER_TICS := 4 * GalaxyClock.TICS_PER_SECOND
## The choices after a death.
const TRY_AGAIN := 0
const EXIT_TO_MAP := 1

## The choice after a death, while the box is up; -1 otherwise.
var _choice := -1
var _choice_tic := 0


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; there is none
	# yet (D10), so the request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	_set_up_play()
	var requested := _requested_map()
	if requested < 0:
		_enter(Keen4Episode.WORLD_MAP, false)
	else:
		_show_level(requested)


func _unhandled_input(event: InputEvent) -> void:
	if _handle_display_keys(event):
		get_viewport().set_input_as_handled()
		return
	if _status_drop != null:
		if _is_new_press(event):
			get_viewport().set_input_as_handled()
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
		_leave()
	elif event.is_action_pressed("status") and (_played != null or _on_map != null):
		get_viewport().set_input_as_handled()
		_open_status()
	elif _handle_map_keys(event):
		get_viewport().set_input_as_handled()


## Shows map [param number] at once: played when Keen is in it, otherwise
## with Keen standing still and the view on him.
func _show_level(number: int) -> void:
	_map_number = number
	# A fresh copy: playing changes the map's tiles.
	var map := _data.maps.load_map(number) if _data.maps.has_map(number) else null
	if map == null:
		_show_message(NOT_A_MAP_MESSAGE % number)
		return
	_start = Keen4Start.find(map)
	_objects.clear()
	_keen_item = null
	var random_start := randi() & GalaxyWorld.RANDOM_MASK
	if _start.is_world_map():
		var on_map := Keen4MapSession.start(_data, map, _game_progress, random_start)
		_game_progress.foot_flight = false
		_game_progress.last_finished = -1
		if on_map != null:
			_play_map(on_map)
			return
	var played := Keen4LevelSession.start(_data, map, _inventory, random_start, _difficulty, number)
	if played != null:
		_play(played, map)
	else:
		_look_at(map)


## Map [param number] behind its "Keen enters ..." box, the count-down and
## a fade (Omni CK_LoadLevel's cache box; seen in the original, D7);
## [param from_map]: "One moment" first.
func _enter(number: int, from_map: bool) -> void:
	_queue.clear()
	var screens := _boxes.entering(number)
	if from_map:
		_queue.add(_boxes.one_moment(), ONE_MOMENT_TICS)
	_queue.add(screens[0], BOX_TICS)
	for finger in range(1, screens.size()):
		var last := finger == screens.size() - 1
		_queue.add(screens[finger], LAST_FINGER_TICS if last else FINGER_TICS)
	for brightness in FADE_STEPS:
		_queue.add(screens[-1], FADE_STEP_TICS, brightness)
	_queue.add(null, BLACK_TICS, 0.0, _show_level.bind(number))
	for step in range(FADE_STEPS.size() - 1, -1, -1):
		_queue.add(null, FADE_STEP_TICS, FADE_STEPS[step])
	_after_queue(Callable())


## After a frame: what the level or the map asks for, and how it ended.
func _after_frame() -> bool:
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
		_show_screens(_messages.lindsey(_map_number), Callable())
	elif asked == Keen4Council.JANITOR:
		_show_screens(_messages.janitor(), Callable())
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
	match ending:
		Keen4Council.RESCUED:
			var before := _game_progress.rescue()
			_show_screens(_messages.council(_map_number, before), _after_rescue)
		Keen4Wetsuit.TAKEN:
			_game_progress.wetsuit = true
			_show_screens(_messages.wetsuit(), _back_to_map)
		_:
			_back_to_map()


func _after_rescue() -> void:
	if _game_progress.all_rescued():
		_show_message(ALL_RESCUED_MESSAGE)
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
		_after_queue(_leave)
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
	var input := KeenInput.from_actions()
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


func _leave() -> void:
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


## Shift+N and Shift+P: the next or previous map; Shift+G: god mode, as
## the original's debug key F10+G (nothing kills Keen, D5).
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
