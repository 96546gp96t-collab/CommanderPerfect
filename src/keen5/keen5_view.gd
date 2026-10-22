class_name Keen5View
extends GalaxyPlayScreen
## The Keen 5 game screen that the start screen opens (milestone E3): the
## shared Galaxy game ([GalaxyPlayScreen], with Keen 5's numbers from
## [method Keen5Episode.game_rules]) and, for now, the simple flow of a
## game that Keen 4 had in its D4 (docs/keen5/gameplay.md, "The flow for
## now"):
##   - it starts in level 1, or in map N with [code]-- --game=5 --level=N[/code]
##     (0 the world map and 15 the high-score map are only shown, Keen
##     standing; 14 does not exist);
##   - the exit door, the door to Korath III, the last fuse broken, the QED
##     destroyed or walking out of a level: the next level (13 is followed
##     by 1); after a fuse first the fuse message ([Keen5Messages]), each
##     of its two screens 30 tics and then until a key; what each level
##     counts as is kept in [member levels_done] (1, or 14 by its fuse);
##   - a death: one life less and the level again; with no life left, the
##     start screen.
## The world map (E6), the other boxes, title and ending (E7), sound (E8)
## and menus (E9) come later (docs/keen5/roadmap.md).
##
## Keys: the shared ones (arrows, jump, pogo, fire); Escape the start
## screen; Shift+N / Shift+P the next or previous map; Shift+G god mode and
## Shift+I all four gems, the keycard and 99 charges (Keen 1-4's testing
## cheats); F1 the help line; F2-F6 as in Keen 1-4 (widescreen, pixel
## shape, full screen, graphics: original or xBRZ, smooth motion).

const NOT_A_MAP_MESSAGE := "Keen 5 has no map %d"
## The testing cheats' messages, worded as in Keen 1-4.
const GOD_MODE_MESSAGE := "Cheat: god mode %s"
const EVERYTHING_MESSAGE := "Cheat: all four gems, the keycard and 99 stunner charges"
## Shift+I gives at least this many charges (as Keen 4's).
const CHEAT_SHOTS := 99

## What each level counts as once done, by map (Omni levelsDone: 1, or
## 14 when its fuse ended it; [method Keen5LevelSession.result]), for the
## world map (E6).
var levels_done: Dictionary[int, int] = {}
var _messages: Keen5Messages


func _init() -> void:
	rules = Keen5Episode.game_rules()


func _ready() -> void:
	# Picking the game on the start screen asks for its menu; Keen 5 has
	# none yet, so the request is taken here and not left for the next game.
	GameLaunch.take_menu_request()
	_set_up_screen()
	if not _load_data():
		return
	_messages = Keen5Messages.create(_data)
	_set_up_play()
	var requested := requested_map(OS.get_cmdline_user_args())
	_show_level(requested if requested >= 0 else rules.first_level)


func _unhandled_input(event: InputEvent) -> void:
	if _handle_display_keys(event):
		get_viewport().set_input_as_handled()
	elif not _queue.is_empty():
		if _is_new_press(event):
			get_viewport().set_input_as_handled()
			if _queue.press():
				_show_step()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
	elif _handle_map_keys(event):
		get_viewport().set_input_as_handled()


## The map that [param arguments] ask for with --level=N, or -1.
static func requested_map(arguments: PackedStringArray) -> int:
	for argument in arguments:
		if argument.begins_with(GameLaunch.LEVEL_OPTION):
			return argument.trim_prefix(GameLaunch.LEVEL_OPTION).to_int()
	return -1


## Shows map [param number] at once: played when Keen stands in it,
## otherwise with Keen standing still and the view on him.
func _show_level(number: int, random_start := -1) -> void:
	_map_number = number
	# A fresh copy: playing changes the map's tiles.
	var map := _data.maps.load_map(number) if _data.maps.has_map(number) else null
	if map == null:
		_show_message(NOT_A_MAP_MESSAGE % number)
		return
	_start = GalaxyStart.find(map, rules)
	_objects.clear()
	_keen_item = null
	if random_start < 0:
		random_start = randi() & GalaxyWorld.RANDOM_MASK
	var played := _new_session(map, number, random_start)
	if played != null:
		_play(played, map)
	else:
		_look_at(map)


func _new_inventory() -> GalaxyInventory:
	return Keen5Inventory.new_game()


func _new_session(map: GalaxyMap, number: int, random_start: int) -> GalaxyLevelSession:
	return Keen5LevelSession.start_level(
		_data, rules, map, _inventory, random_start, _difficulty, number
	)


## After a frame: a level done goes on to the next, a death starts it
## again (or ends the game). Returns whether the frames stop.
func _after_frame() -> bool:
	if _played.is_done():
		_finish_level()
		return true
	if _played.is_lost():
		_lose_level()
		return true
	return super()


## The level is done (the exit door, the door to Korath III, its fuse,
## the QED or walking out): it is marked; after its fuse the fuse message;
## then the next level (Omni CK_GameLoop; the QED's end pages come in E7).
func _finish_level() -> void:
	var done := (_played as Keen5LevelSession).result()
	_played = null
	levels_done[_map_number] = done
	var next := _show_level.bind(rules.next_level(_map_number))
	if done == Keen5LevelSession.DONE_BY_FUSE:
		_show_fuse_message(next)
	else:
		next.call()


## The two screens after a fuse, each 30 tics before a key counts (Omni
## CK5_FuseMessage); then [param then].
func _show_fuse_message(then: Callable) -> void:
	for screen in _messages.fuse(_map_number):
		_queue.add(screen, Keen5Messages.KEY_WAIT_TICS)
		_queue.add_box(screen)
	_after_queue(then)


## Keen died: a life less and the level again; with none left the game is
## over and the start screen comes back.
func _lose_level() -> void:
	_played = null
	_inventory.lives -= 1
	if _inventory.lives < 0:
		_leave()
		return
	_show_level(_map_number)


func _leave() -> void:
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


## Shift+N and Shift+P: the next or previous map (over the missing one);
## Shift+G and Shift+I: the testing cheats. Returns whether it was one.
func _handle_map_keys(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not key.shift_pressed:
		return false
	if event.is_action_pressed("cheat_god"):
		_toggle_god_mode()
		return true
	if event.is_action_pressed("cheat_items") and _played != null:
		_give_everything()
		return true
	var step := 0
	match key.keycode:
		KEY_N:
			step = 1
		KEY_P:
			step = -1
		_:
			return false
	if _data != null:
		_show_level(_next_map(_map_number, step))
	return true


## The map [param step] (1 or -1) from [param number] that exists, round
## from the last to the world map.
func _next_map(number: int, step: int) -> int:
	var count := rules.last_map + 1
	var next := posmod(number + step, count)
	while not _data.maps.has_map(next) and next != number:
		next = posmod(next + step, count)
	return next


## Shift+G: god mode, as the original's debug key F10+G (nothing kills Keen
## but falling out of the level).
func _toggle_god_mode() -> void:
	_god_mode = not _god_mode
	if _played != null:
		_played.player.god_mode = _god_mode
	_show_message(GOD_MODE_MESSAGE % ("on" if _god_mode else "off"))


## Shift+I in a level: all four gems, the keycard and at least 99 charges.
func _give_everything() -> void:
	_inventory.shots = maxi(_inventory.shots, CHEAT_SHOTS)
	_inventory.gems = PackedInt32Array([1, 1, 1, 1])
	(_inventory as Keen5Inventory).keycard = true
	_update_score_box()
	_show_message(EVERYTHING_MESSAGE)
