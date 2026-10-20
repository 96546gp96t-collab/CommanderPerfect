class_name Keen4FrontScreen
extends Keen4PlayScreen
## What Keen 4 shows around its games, on top of [Keen4PlayScreen]
## ([Keen4View] adds the game's flow): the title loop ([Keen4TitleLoop]:
## the intro credits and the title picture, the story, the demos, the high
## scores), the help (F1), the end pages after the eighth rescue and the
## high-score table with the name typed in (docs/keen4/gameplay.md, "The
## title loop").
##
## The full-screen parts are drawn by a [GalaxyTitleLayer] over the game;
## the demos are played like a game, steered by their recorded input
## ([GalaxyDemo], [GalaxyTwoButtonFiring]) at 3 tics a frame from the
## start of the random table, with the DEMO sign instead of the score box
## and no extra lives for points (Omni `ck_inter.c`: CK_PlayDemo;
## `ck_play.c`: CK_PlayLoop; `id_rf.c`: RFL_CalcTics).

enum Front { NONE, INTRO, STORY, DEMO, HELP, ENDING, NAME_ENTRY }

## The box while a map "loads" (seen in the original, D7): the box with
## the whole count-down picture, each finger, the last one; then the fade
## to the next map and back (steps of 6 tics, about 19 tics black).
const BOX_TICS := 21
const FINGER_TICS := 20
const LAST_FINGER_TICS := 28
const FADE_STEPS: PackedFloat32Array = [0.75, 0.5, 0.25]
const FADE_STEP_TICS := 6
const BLACK_TICS := 19
## Pictures counted from the end of the picture range (the same in v1.0
## and v1.4): the title, the story's picture, the first of four credits.
const TITLE_FROM_END := 12
const STORY_FROM_END := 13
const FIRST_CREDIT_FROM_END := 17
const CREDIT_COUNT := 4
## The misc chunks with the two words of the intro.
const LEFT_WORD_MISC := 1
const RIGHT_WORD_MISC := 2
## The story's font: the large one.
const STORY_FONT := 2
## The DEMO sign (sprite 5) at the top middle of the view (Omni
## CK_DemoSign: 128 and 8 pixels from its corner).
const DEMO_SIGN_SPRITE := 5
const DEMO_SIGN_AT := Vector2(128, 8)
const HIGH_SCORES_PATH := "user://keen4/high_scores.json"

var _front := Front.NONE
## Whether the title loop runs (not a game).
var _in_title_loop := false
var _loop := Keen4TitleLoop.new()
var _title_layer := GalaxyTitleLayer.new()
var _intro: GalaxyIntroCredits
var _story: GalaxyStoryScroller
var _story_tics := 0
var _demo: GalaxyDemo
var _demo_frame := 0
var _firing := GalaxyTwoButtonFiring.new()
var _help: Keen4Help
var _end_pages: Keen4Ending
var _high_scores: GalaxyHighScores
var _board: Keen4HighScoreBoard
var _board_sprite := Sprite2D.new()
var _demo_sign := Sprite2D.new()
## After a game the high scores are followed by the title picture.
var _after_game := false


## After [method Keen4PlayScreen._set_up_play]: the title layer under the
## boxes, the DEMO sign, the table's sprite on the map, the high scores.
func _set_up_front() -> void:
	var ui := _score_box.get_parent()
	ui.add_child(_title_layer)
	ui.move_child(_title_layer, _window_sprite.get_index())
	_demo_sign.centered = false
	_demo_sign.visible = false
	_demo_sign.texture = ImageTexture.create_from_image(_data.graphics.sprite(DEMO_SIGN_SPRITE))
	ui.add_child(_demo_sign)
	_board_sprite.centered = false
	_board_sprite.visible = false
	_galaxy_map.add_sibling(_board_sprite)
	_high_scores = GalaxyHighScores.load_from(HIGH_SCORES_PATH, default_high_scores(_data))


## The original's table from the player's program.
static func default_high_scores(data: GalaxyData) -> Array[GalaxyHighScores.Entry]:
	var image := data.executable.image
	var start := GalaxyHighScores.find_defaults(
		image, Keen4Episode.HIGH_SCORE_COUNT, PackedInt32Array([Keen4Episode.HIGH_SCORES_V1_0])
	)
	if start < 0:
		push_error("The high-score table was not found in the program.")
		var empty: Array[GalaxyHighScores.Entry] = []
		for place in Keen4Episode.HIGH_SCORE_COUNT:
			empty.append(GalaxyHighScores.Entry.new())
		return empty
	return GalaxyHighScores.defaults_at(image, start, Keen4Episode.HIGH_SCORE_COUNT)


## The title loop, from its next step.
func _start_title_loop() -> void:
	_in_title_loop = true
	_next_title_step()


## The next step of the title loop. A full screen (intro, story, help)
## leaves black behind, as the original clears the screen: the next demo's
## box shows over black.
func _next_title_step() -> void:
	_stop_front()
	if _title_layer.visible:
		_title_layer.show_black()
	match _loop.next():
		Keen4TitleLoop.Step.INTRO:
			_start_intro()
		Keen4TitleLoop.Step.STORY:
			_start_story()
		Keen4TitleLoop.Step.DEMO:
			_start_demo(_loop.demo(), false)
		Keen4TitleLoop.Step.HIGH_SCORES:
			_start_demo(Keen4TitleLoop.HIGH_SCORE_DEMO, true)


## Whatever the front shows stops (not the title loop itself).
func _stop_front() -> void:
	_front = Front.NONE
	_demo = null
	_demo_sign.visible = false
	_clock.tics_per_frame = GalaxyClock.NORMAL_TICS
	_objects.visible = true


func _start_intro() -> void:
	var pictures: Array[Image] = []
	var count := _data.graphics.ranges.picture_count
	for credit in CREDIT_COUNT:
		pictures.append(_data.graphics.picture(count - FIRST_CREDIT_FROM_END + credit))
	_intro = GalaxyIntroCredits.create(
		GalaxyIntroBitmap.parse(_data.graphics.misc(LEFT_WORD_MISC)),
		GalaxyIntroBitmap.parse(_data.graphics.misc(RIGHT_WORD_MISC)),
		pictures,
		_title_picture()
	)
	_front = Front.INTRO
	_title_layer.show_scroll(_intro)


## Only the title picture, for its time (after a game).
func _show_title_picture() -> void:
	_start_intro()
	_intro.phase = GalaxyIntroCredits.Phase.TITLE
	_title_layer.show_picture(_title_picture())


func _start_story() -> void:
	var texts := _data.executable.messages(Keen4Episode.STORY_MESSAGES)
	var count := _data.graphics.ranges.picture_count
	_story = GalaxyStoryScroller.create(
		texts[0] if not texts.is_empty() else "",
		_data.graphics.font(STORY_FONT),
		_data.graphics.picture(count - STORY_FROM_END)
	)
	_story_tics = 0
	_front = Front.STORY
	_title_layer.show_story(_story, 0)
	_audio.play_story_song()


## Demo [param index] after its box (the high scores: map 19 behind the
## table, without the box).
func _start_demo(index: int, high_scores: bool) -> void:
	_demo = GalaxyDemo.parse(_data.graphics.demo(index))
	if _demo == null:
		_next_title_step()
		return
	var screens: Array[Image] = []
	if not high_scores:
		screens = _boxes.demo_entering()
	_queue.clear()
	_queue_loading(screens, _begin_demo.bind(high_scores))
	_after_queue(Callable())


## The demo's map at the start of its play: a new game on Normal, the
## random table from its start.
func _begin_demo(high_scores: bool) -> void:
	_title_layer.clear()
	_inventory = Keen4Inventory.new_game()
	_inventory.extra_lives_for_points = false
	_game_progress = Keen4Progress.new()
	_map_number = _demo.map_number
	var map := _data.maps.load_map(_demo.map_number)
	var session := Keen4LevelSession.start(
		_data, map, _inventory, 0, GalaxyDifficulty.DEFAULT, _demo.map_number
	)
	if session == null:
		_next_title_step()
		return
	session.world.random_index = 0
	_play(session, map)
	_clock.tics_per_frame = GalaxyClock.DEMO_TICS
	_firing = GalaxyTwoButtonFiring.new()
	_demo_frame = 0
	_front = Front.DEMO
	_score_box.visible = false
	_demo_sign.visible = not high_scores
	if high_scores:
		_show_board(map)


## A new map: the table is part of map 19's picture (it stays under the
## next demo's box until that map is shown, seen in the original).
func _show_map(map: GalaxyMap, sprites: PackedInt32Array) -> void:
	_board_sprite.visible = false
	super(map, sprites)


## The table over map 19's view.
func _show_board(map: GalaxyMap) -> void:
	_board = Keen4HighScoreBoard.create(
		_data.graphics, _high_scores, map, _galaxy_camera.view_pixels()
	)
	_board_sprite.position = Vector2(_galaxy_camera.view_pixels())
	_redraw_board()
	_board_sprite.visible = true


func _redraw_board() -> void:
	_board_sprite.texture = ImageTexture.create_from_image(_board.overlay())


## Adds to the queue the box of [param screens] (none: only the fade),
## the fade to black, [param start] in the black, and the fade back (seen
## in the original, D7).
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


## A demo's frame: its recorded input, through two-button firing.
func _frame_input(tics: int) -> KeenInput:
	if _front != Front.DEMO or _demo == null:
		return super(tics)
	var input := _firing.convert(_demo.controls_at(_demo_frame), tics)
	_demo_frame += 1
	return input


## Whether a demo is played; after its frame it may end (its input used
## up, or Keen out of the level): then the title loop goes on.
func _after_demo_frame() -> bool:
	if _front != Front.DEMO:
		return false
	if _demo_frame >= _demo.frame_count() or not _played.is_playing():
		_end_demo()
	return true


func _end_demo() -> void:
	var was_high_scores := _board_sprite.visible and _demo.map_number == Keen4Episode.HIGH_SCORE_MAP
	_played = null
	_stop_front()
	if _after_game and was_high_scores:
		_after_game = false
		_show_title_picture()
	else:
		_next_title_step()


## Front screens run on the clock instead of the game.
func _run_frame(tics: int) -> bool:
	match _front:
		Front.INTRO:
			_advance_intro(tics)
		Front.STORY:
			_story_tics += tics
			_title_layer.show_story(_story, GalaxyStoryScroller.distance_after(_story_tics))
			if _story_tics >= _story.total_tics():
				_audio.stop_music()
				_next_title_step()
		Front.ENDING:
			if _end_pages.advance(tics):
				_title_layer.show_picture(_end_pages.screen())
		Front.NAME_ENTRY:
			if _board.advance(tics):
				_redraw_board()
		Front.HELP:
			pass
		_:
			return super(tics)
	return false


func _advance_intro(tics: int) -> void:
	var before := _intro.phase
	_intro.advance(tics)
	match _intro.phase:
		GalaxyIntroCredits.Phase.SCROLL:
			_title_layer.show_scroll(_intro)
		GalaxyIntroCredits.Phase.ZOOM:
			_title_layer.show_picture(_intro.zoom_image(_intro.elapsed))
		GalaxyIntroCredits.Phase.FIZZLE:
			_title_layer.show_picture(_intro.fizzle)
		GalaxyIntroCredits.Phase.TITLE:
			if before != GalaxyIntroCredits.Phase.TITLE:
				_title_layer.show_picture(_intro.title)
		GalaxyIntroCredits.Phase.DONE:
			_next_title_step()


func _title_picture() -> Image:
	var picture := _data.graphics.picture(_data.graphics.ranges.picture_count - TITLE_FROM_END)
	if picture != null and picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	return picture


## F1: the help, over the title loop or the game (which waits).
func _open_help() -> void:
	if _help == null:
		_help = Keen4Help.create(_data.graphics)
	if _in_title_loop:
		_queue.clear()
		_played = null
		_stop_front()
	_front = Front.HELP
	_title_layer.show_picture(_help.screen())
	_audio.stop_music()


func _close_help() -> void:
	if _in_title_loop:
		_next_title_step()
	else:
		_title_layer.clear()
		_front = Front.NONE
		_audio.play_map_song(_map_number)


## The end pages (after the eighth rescue).
func _start_ending() -> void:
	_played = null
	_on_map = null
	_score_box.visible = false
	_end_pages = Keen4Ending.create(_data.graphics)
	_front = Front.ENDING
	_audio.play_ending_song()
	_title_layer.show_picture(_end_pages.screen())


## After a game: the name is typed in on map 19 when the score made the
## table; then the high scores and the title picture; then the title loop
## goes on.
func _game_ended() -> void:
	_played = null
	_on_map = null
	_after_game = true
	_stop_front()
	var place := _high_scores.place_for(_inventory.score, _game_progress.rescued)
	if place < 0:
		_in_title_loop = true
		_title_layer.show_black()
		_start_demo(Keen4TitleLoop.HIGH_SCORE_DEMO, true)
		return
	_high_scores.insert(place, "", _inventory.score, _game_progress.rescued)
	_queue.clear()
	var no_box: Array[Image] = []
	_queue_loading(no_box, _begin_name_entry.bind(place))
	_after_queue(Callable())


func _begin_name_entry(place: int) -> void:
	_title_layer.clear()
	var map := _data.maps.load_map(Keen4Episode.HIGH_SCORE_MAP)
	var session := Keen4LevelSession.start(
		_data, map, Keen4Inventory.new_game(), 0, GalaxyDifficulty.DEFAULT, map.number
	)
	_play(session, map)
	_score_box.visible = false
	# The original draws only the map's tiles behind the table here (seen).
	_objects.visible = false
	_show_board(map)
	_board.start_typing(place)
	_front = Front.NAME_ENTRY


func _finish_name_entry(keep: bool) -> void:
	_board.finish(keep)
	_high_scores.save()
	_in_title_loop = true
	_played = null
	_stop_front()
	_start_demo(Keen4TitleLoop.HIGH_SCORE_DEMO, true)


## The keys of the front screens; returns whether [param event] was theirs.
func _front_input(event: InputEvent) -> bool:
	var key := event as InputEventKey
	match _front:
		Front.HELP:
			if _is_new_press(event):
				_help_key(event)
			return true
		Front.ENDING:
			if _is_new_press(event) and _end_pages.press():
				if _end_pages.is_done():
					_game_ended()
				else:
					_title_layer.show_picture(_end_pages.screen())
			return true
		Front.NAME_ENTRY:
			if key != null and _is_new_press(event):
				_name_key(key)
			return true
	if not _in_title_loop:
		return false
	if _is_new_press(event):
		if event.is_action_pressed("ui_cancel"):
			_leave()
		else:
			_new_game()
	return true


func _help_key(event: InputEvent) -> void:
	var input := KeenInput.from_actions()
	var action := -1
	if event.is_action_pressed("ui_cancel"):
		action = Keen4Help.Action.ESCAPE
	elif event.is_action_pressed("ui_accept") or input.jump or input.pogo:
		action = Keen4Help.Action.OPEN
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_page_up"):
		action = Keen4Help.Action.UP
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_page_down"):
		action = Keen4Help.Action.DOWN
	elif event.is_action_pressed("ui_left"):
		action = Keen4Help.Action.BACK_PAGE
	elif event.is_action_pressed("ui_right"):
		action = Keen4Help.Action.NEXT_PAGE
	if action < 0:
		return
	if _help.act(action):
		_title_layer.show_picture(_help.screen())
	else:
		_close_help()


func _name_key(key: InputEventKey) -> void:
	match key.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_finish_name_entry(true)
			return
		KEY_ESCAPE:
			_finish_name_entry(false)
			return
		KEY_BACKSPACE, KEY_DELETE, KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END:
			_board.edit(key.keycode)
		_:
			if key.unicode > 0:
				_board.type_character(String.chr(key.unicode))
	_redraw_board()


## The title layer and the DEMO sign follow the picture's width.
func _place_overlays() -> void:
	super()
	var game_size := _settings.game_size()
	_title_layer.fit(game_size)
	_demo_sign.position = (
		Vector2((game_size.x - GalaxyWindow.SCREEN_SIZE.x) / 2.0, 0) + DEMO_SIGN_AT
	)


## A new game from the title loop ([Keen4View]).
func _new_game() -> void:
	pass


## Back to the start screen ([Keen4View]).
func _leave() -> void:
	pass
