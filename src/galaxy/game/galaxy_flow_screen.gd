class_name GalaxyFlowScreen
extends GalaxyPlayScreen
## The flow of a game of a Galaxy episode between its maps, on top of
## [GalaxyPlayScreen] (made from Keen 4's [Keen4View] and the status window
## of [Keen4PlayScreen], milestone E6; Omni `ck_game.c`: CK_GameLoop,
## CK_LoadLevel, CK_TryAgainMenu; `ck_play.c`: CK_ShowStatusWindow; facts
## only; docs/keen4/gameplay.md, "Between the levels"):
##   - map N is shown at once ([method _show_level]): the world map is
##     played ([GalaxyMapSession]), a level is played, any other map only
##     looked at;
##   - on the world map jump, pogo or fire on an entrance: "One moment",
##     then the level's "Keen enters ..." box with Keen counting down, a
##     fade, and the level ([method _enter]);
##   - a level done: it is marked in the game's progress
##     ([GalaxyProgress]) with the value the episode gives
##     ([method _done_value]); what follows is the episode's
##     ([method _after_level_done]: by default the exit sound and back to
##     the map, with its box, at the place he entered);
##   - a death: one life less and the box "You didn't make it past …"
##     with Try Again (the level again) or the exit to the map; with no
##     life left the game is over ([method _game_over]);
##   - the status key drops the status window ([GalaxyStatusWindow]) over
##     the level or the map; a key lifts it again ([GalaxyStatusDrop]);
##   - the music stops whenever the play of a map ends (Omni CK_PlayLoop
##     ends with StopMusic): the boxes between the maps are silent, the
##     next map starts its own song.
## The episode's view calls [method _set_up_flow] after
## [method GalaxyPlayScreen._set_up_play] and passes its input through
## [method _flow_input].

## The pictures of the status window: the window, the arm, the strap.
enum StatusPart { WINDOW, ARM, STRAP }

const NOT_A_MAP_MESSAGE := "%s has no map %d"
## "One moment" when Keen leaves the world map (seen in the original, D7).
const ONE_MOMENT_TICS := 28
## "Game Over!" stays 4.76 seconds, or until a key (seen in Keen 4, D13).
const GAME_OVER_TICS := 333
## The box while a map "loads" (seen in the original, D7): the box with
## the whole count-down picture, each finger, the last one; then the fade
## to the next map and back (steps of 6 tics, about 19 tics black).
const BOX_TICS := 21
const FINGER_TICS := 20
const LAST_FINGER_TICS := 28
const FADE_STEPS: PackedFloat32Array = [0.75, 0.5, 0.25]
const FADE_STEP_TICS := 6
const BLACK_TICS := 19
## The choices after a death.
const TRY_AGAIN := 0
const EXIT_TO_MAP := 1

## The levels done, the place on the map, the episode's own.
var _game_progress: GalaxyProgress
var _boxes: GalaxyGameBoxes
var _status: GalaxyStatusWindow
var _status_drop: GalaxyStatusDrop
var _status_sprites: Array[Sprite2D] = []
## The choice after a death, while the box is up; -1 otherwise.
var _choice := -1
var _choice_tic := 0


## After [method GalaxyPlayScreen._set_up_play]: the progress of a new game,
## the boxes, the status window and its sprites.
func _set_up_flow() -> void:
	_game_progress = _new_progress()
	_boxes = GalaxyGameBoxes.create(_data, rules)
	_status = _new_status_window()
	for part in StatusPart.size():
		var sprite := Sprite2D.new()
		sprite.centered = false
		# The window keeps the original pixels, also with xBRZ (Keen 4, D11).
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = false
		_score_box.get_parent().add_child(sprite)
		_status_sprites.append(sprite)


func progress() -> GalaxyProgress:
	return _game_progress


## Whether the status window is on the screen.
func shows_status() -> bool:
	return _status_drop != null


## The progress of a new game (an episode with more to keep gives its
## own: Keen 5's [Keen5Progress]).
func _new_progress() -> GalaxyProgress:
	return GalaxyProgress.new()


## The status window (an episode's own row: Keen 5's [Keen5StatusWindow]).
func _new_status_window() -> GalaxyStatusWindow:
	return GalaxyStatusWindow.create(_data, rules)


## The world map [param map] for the game's progress, or null without a
## map Keen (an episode's own: Keen 5's [Keen5MapSession]).
func _new_map_session(map: GalaxyMap, random_start: int) -> GalaxyMapSession:
	return GalaxyMapSession.start_map(_data, rules, map, _game_progress, random_start)


## Shows map [param number] at once: the world map or a level played when
## Keen is in it, otherwise with Keen standing still and the view on him.
func _show_level(number: int, random_start := -1) -> void:
	_map_number = number
	# A fresh copy: playing changes the map's tiles.
	var map := _data.maps.load_map(number) if _data.maps.has_map(number) else null
	if map == null:
		_show_message(NOT_A_MAP_MESSAGE % [rules.name, number])
		return
	_start = GalaxyStart.find(map, rules)
	_objects.clear()
	_keen_item = null
	if random_start < 0:
		random_start = randi() & GalaxyWorld.RANDOM_MASK
	if _start.is_world_map():
		var on_map := _new_map_session(map, random_start)
		_game_progress.map_shown()
		if on_map != null:
			_play_map(on_map)
			return
	var played := _new_session(map, number, random_start)
	if played != null:
		_level_began(number, random_start)
		_play(played, map)
	else:
		_look_at(map)


## Level [param _number] begins with its random table at
## [param _random_start] (the menu screen keeps its frames for a save).
func _level_began(_number: int, _random_start: int) -> void:
	pass


## Map [param number] behind its loading box, the count-down and a fade
## (Omni CK_LoadLevel's cache box; seen in the original, D7);
## [param from_map]: "One moment" first.
func _enter(number: int, from_map: bool) -> void:
	_queue.clear()
	if from_map:
		_queue.add(_boxes.one_moment(), ONE_MOMENT_TICS)
	_queue_loading(_loading_box(number), _show_level.bind(number))
	_after_queue(Callable())


## The box while map [param number] loads: its "Keen enters ..." text (an
## episode may say something else: Keen 5's arrival on Korath III).
func _loading_box(number: int) -> Array[Image]:
	return _boxes.entering(number)


## The loading box ([param screens]: the box, then each finger), the fade
## out; [param start] while it is black; the fade in.
func _queue_loading(screens: Array[Image], start: Callable) -> void:
	if not screens.is_empty():
		_queue.add(screens[0], BOX_TICS)
		for finger in range(1, screens.size()):
			var last := finger == screens.size() - 1
			_queue.add(screens[finger], LAST_FINGER_TICS if last else FINGER_TICS)
	var shown: Image = screens[-1] if not screens.is_empty() else null
	for brightness in FADE_STEPS:
		_queue.add(shown, FADE_STEP_TICS, brightness)
	_queue.add(null, BLACK_TICS, 0.0, start)
	for step in range(FADE_STEPS.size() - 1, -1, -1):
		_queue.add(null, FADE_STEP_TICS, FADE_STEPS[step])


## After a frame: what the level or the map asks for, and how it ended.
func _after_frame() -> bool:
	if _on_map != null:
		_after_map_frame()
	elif _played != null:
		_after_level_frame()
	return not _queue.is_empty() or (_played == null and _on_map == null)


## An entrance taken: the level, from where Keen stood.
func _after_map_frame() -> void:
	var level := _on_map.entered()
	if level > 0:
		_stop_music_between_maps()
		_game_progress.map_position = _on_map.keen.map_position
		_enter(level, true)


func _after_level_frame() -> void:
	if _played.is_done():
		_finish_level()
	elif _played.is_lost():
		_lose_level()


## The level is done (Omni CK_GameLoop): it is marked with its value;
## then what the episode does after it.
func _finish_level() -> void:
	var finished := _played
	_played = null
	_stop_music_between_maps()
	_game_progress.mark_done(_map_number, _done_value(finished))
	_game_progress.last_finished = _map_number
	_after_level_done(finished)


## The value level [param _finished] is done with (1; Keen 5's fuse
## levels 14).
func _done_value(_finished: GalaxyLevelSession) -> int:
	return GalaxyProgress.DONE


## What follows a level done: by default the exit sound and the map.
func _after_level_done(_finished: GalaxyLevelSession) -> void:
	_exit_to_map()


## The exit sound, then the map.
func _exit_to_map() -> void:
	_play_sound(&"level_exit")
	_back_to_map()


func _back_to_map() -> void:
	_enter(rules.world_map, false)


## Keen died (Omni CK_TryAgainMenu): a life less; the box with the choice,
## or the game is over.
func _lose_level() -> void:
	_played = null
	_stop_music_between_maps()
	_game_progress.last_finished = -1
	_inventory.lives -= 1
	if _inventory.lives < 0:
		_game_over()
		return
	_choice = TRY_AGAIN
	_choice_tic = 0
	_queue.add_box(_boxes.try_again(_map_number, _choice, _choice_tic))
	_show_step()


## No life left (Omni CK_GameOver): "Game Over!" when the episode has the
## box, then [method _game_ended].
func _game_over() -> void:
	var box := _boxes.game_over()
	if box == null:
		_game_ended()
		return
	_queue.add(box, GAME_OVER_TICS)
	_after_queue(_game_ended)


## The game is over: back to the start screen (the episode's title loop
## and high scores come later).
func _game_ended() -> void:
	_leave()


func _leave() -> void:
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


## What the flow takes of [param event]: lifting the status window, the
## choice after a death, a key for a box, the status key. Returns whether
## it took it.
func _flow_input(event: InputEvent) -> bool:
	if _status_drop != null:
		if _is_new_press(event):
			get_viewport().set_input_as_handled()
			if _status_drop.stage == GalaxyStatusDrop.Stage.DOWN:
				_play_sound(&"status_up")
			_status_drop.release()
		return true
	if _choice >= 0:
		_choose(event)
		return true
	if not _queue.is_empty():
		if _is_new_press(event):
			get_viewport().set_input_as_handled()
			if _queue.press():
				_show_step()
		return true
	if event.is_action_pressed("status") and (_played != null or _on_map != null):
		get_viewport().set_input_as_handled()
		_open_status()
		return true
	return false


## The keys that make the choice after a death.
func _choice_input() -> KeenInput:
	return KeenInput.from_actions()


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
	_enter(_map_number if choice == TRY_AGAIN else rules.world_map, false)


## The choice's frame blinks while the box waits.
func _waiting(tics: int) -> void:
	super(tics)
	if _choice < 0:
		return
	var before := GalaxyGameBoxes.blink_color(_choice_tic)
	_choice_tic += tics
	if GalaxyGameBoxes.blink_color(_choice_tic) != before:
		_redraw_choice()


func _redraw_choice() -> void:
	var step := _queue.current()
	if step == null:
		return
	step.image = _boxes.try_again(_map_number, _choice, _choice_tic)
	_show_step()


## The status window holds the game while it is on the screen.
func _hold_frame(tics: int) -> bool:
	if _status_drop == null:
		return false
	_advance_status(tics)
	return true


## The status window drops down.
func _open_status() -> void:
	if _status == null:
		return
	var level := _played.difficulty if _played != null else _difficulty
	var pictures: Array[Image] = [
		_status.window(_status_map(), _inventory, _game_progress, level),
		_status.arm(),
		_status.strap(),
	]
	for part in pictures.size():
		var picture := pictures[part]
		_status_sprites[part].texture = (
			ImageTexture.create_from_image(picture) if picture != null else null
		)
	_status_drop = GalaxyStatusDrop.new()
	_play_sound(&"status_down")
	_place_overlays()


## The map whose name the status window shows: the one played (Keen 5
## names Korath III's base while Keen is there on the world map).
func _status_map() -> int:
	return _map_number


func _advance_status(tics: int) -> void:
	_status_drop.advance(tics)
	if _status_drop.is_gone():
		_status_drop = null
	_place_overlays()


## The boxes and the status window in the middle of the picture, also
## after F2.
func _place_overlays() -> void:
	super()
	var dropping := _status_drop != null
	for part in _status_sprites.size():
		_status_sprites[part].visible = dropping
	if not dropping:
		return
	var left := (_settings.game_size().x - GalaxyWindow.SCREEN_SIZE.x) / 2.0
	var shift := Vector2(left, _status_drop.shift())
	# The window is drawn on a whole screen; the arm and the strap are only
	# their own pictures.
	_status_sprites[StatusPart.WINDOW].position = shift
	_status_sprites[StatusPart.ARM].position = Vector2(GalaxyStatusWindow.ARM_AT) + shift
	_status_sprites[StatusPart.STRAP].position = Vector2(GalaxyStatusWindow.STRAP_AT) + shift
	_status_sprites[StatusPart.ARM].visible = _status_drop.shows_arm()
	_status_sprites[StatusPart.STRAP].visible = _status_drop.shows_strap()
