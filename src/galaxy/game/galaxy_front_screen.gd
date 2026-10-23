class_name GalaxyFrontScreen
extends GalaxyFlowScreen
## What a Galaxy episode shows around its games, on top of
## [GalaxyFlowScreen] (made from Keen 4's [Keen4FrontScreen], milestone E7;
## docs/keen4/gameplay.md, "The title loop"; docs/keen5/gameplay.md, "The
## title loop"): the title loop ([GalaxyTitleLoop]: the intro credits and
## the title picture, the story, the demos, the high scores), the end
## pages ([GalaxyEnding]), a scene of the
## episode's own over the whole screen ([GalaxyScene]: Keen 5's exploding
## galaxy), the high-score table with the name typed in
## ([GalaxyHighScoreBoard]) and the original's two cheats ([GalaxyCheats]).
##
## The full-screen parts are drawn by a [GalaxyTitleLayer] over the game;
## the demos are played like a game, steered by their recorded input
## ([GalaxyDemo], [GalaxyTwoButtonFiring]) at 3 tics a frame from the
## start of the random table, on Normal, with the DEMO sign instead of the
## score box and no extra lives for points (Omni `ck_inter.c`:
## CK_PlayDemo; `ck_play.c`: CK_PlayLoop; `id_rf.c`: RFL_CalcTics).
## The episode's view calls [method _set_up_front] after
## [method GalaxyFlowScreen._set_up_flow] and passes its input through
## [method _front_input]. The control panel, the help and a new game are
## [GalaxyMenuScreen]'s (milestone E9), on top of this one.

enum Front { NONE, INTRO, STORY, DEMO, HELP, ENDING, NAME_ENTRY, SCENE }

## The DEMO sign at the top middle of the view (Omni CK_DemoSign: 128 and
## 8 pixels from its corner, plus the sprite's origin; Keen 4, D8.1).
const DEMO_SIGN_AT := Vector2(128, 8)

var _front := Front.NONE
## Whether the title loop runs (not a game).
var _in_title_loop := false
var _loop: GalaxyTitleLoop
var _title_layer := GalaxyTitleLayer.new()
var _intro: GalaxyIntroCredits
var _story: GalaxyStoryScroller
var _story_tics := 0
var _demo: GalaxyDemo
var _demo_frame := 0
var _firing := GalaxyTwoButtonFiring.new()
var _end_pages: GalaxyEnding
var _scene: GalaxyScene
## What follows the scene.
var _after_scene := Callable()
var _high_scores: GalaxyHighScores
var _board: GalaxyHighScoreBoard
var _board_sprite := Sprite2D.new()
var _demo_sign := Sprite2D.new()
## The original's palette fades over the whole picture (a scene's).
var _fade := ColorRect.new()
var _cheats := GalaxyCheats.new()
## Whether a key is held now (the keyboard; a test gives its own).
var _key_held: Callable = GalaxyCheats.is_key_held
## After a game the high scores are followed by the title picture.
var _after_game := false


## After [method GalaxyFlowScreen._set_up_flow]: the title layer under the
## boxes, the DEMO sign, the table's sprite on the map, the high scores.
func _set_up_front() -> void:
	_loop = GalaxyTitleLoop.create(rules.high_score_demo)
	var ui := _score_box.get_parent()
	ui.add_child(_title_layer)
	ui.move_child(_title_layer, _window_sprite.get_index())
	if not rules.intro_word_colors.is_empty():
		_title_layer.word_colors = rules.intro_word_colors
	_demo_sign.centered = false
	_demo_sign.visible = false
	# The sign, the boxes and the table keep the original pixels, also with
	# xBRZ (Keen 4, D11; as the score box).
	_demo_sign.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_board_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sign := _data.graphics.sprite(rules.demo_sign_sprite)
	if sign != null:
		_demo_sign.texture = ImageTexture.create_from_image(sign)
		var origin := _data.graphics.sprite_infos[rules.demo_sign_sprite].origin
		_demo_sign.offset = Vector2(origin / GalaxyUnits.PER_PIXEL)
	ui.add_child(_demo_sign)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.visible = false
	ui.add_child(_fade)
	_board_sprite.centered = false
	_board_sprite.visible = false
	_galaxy_map.add_sibling(_board_sprite)
	_high_scores = GalaxyHighScores.load_from(
		rules.high_scores_path(), GalaxyHighScoreBoard.defaults(_data, rules)
	)


## The high scores (kept in the episode's own user folder).
func high_scores() -> GalaxyHighScores:
	return _high_scores


## Whether the title loop runs.
func in_title_loop() -> bool:
	return _in_title_loop


## What the front shows now.
func front() -> Front:
	return _front


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
		GalaxyTitleLoop.Step.INTRO:
			_start_intro()
		GalaxyTitleLoop.Step.STORY:
			_start_story()
		GalaxyTitleLoop.Step.DEMO:
			_start_demo(_loop.demo(), false)
		GalaxyTitleLoop.Step.HIGH_SCORES:
			_start_demo(rules.high_score_demo, true)


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
	for credit in rules.credit_count:
		pictures.append(_data.graphics.picture(count - rules.first_credit_from_end + credit))
	_intro = GalaxyIntroCredits.create(
		GalaxyIntroBitmap.parse(_data.graphics.misc(rules.left_word_misc)),
		GalaxyIntroBitmap.parse(_data.graphics.misc(rules.right_word_misc)),
		pictures,
		_title_picture()
	)
	if not rules.intro_word_colors.is_empty():
		_intro.word_color = rules.intro_word_colors[0]
	_front = Front.INTRO
	_title_layer.show_scroll(_intro)


## Only the title picture, for its time (after a game).
func _show_title_picture() -> void:
	_start_intro()
	_intro.phase = GalaxyIntroCredits.Phase.TITLE
	_title_layer.show_picture(_title_picture())


func _start_story() -> void:
	var texts := _data.executable.messages(rules.story_messages)
	var count := _data.graphics.ranges.picture_count
	var picture := _data.graphics.picture(count - rules.story_from_end)
	var text := texts[0] if not texts.is_empty() else ""
	var font := _data.graphics.font(rules.story_font)
	if rules.story_colors.is_empty():
		_story = GalaxyStoryScroller.create(text, font, picture)
	else:
		_story = GalaxyStoryScroller.create(text, font, picture, rules.story_colors)
	_story_tics = 0
	_front = Front.STORY
	_title_layer.show_story(_story, 0)
	_play_map_song(rules.story_song)


## Demo [param index] after its box (the high scores: the high-score map
## behind the table, without the box).
func _start_demo(index: int, high_scores_shown: bool) -> void:
	_demo = GalaxyDemo.parse(_data.graphics.demo(index))
	if _demo == null:
		_next_title_step()
		return
	var screens: Array[Image] = []
	if not high_scores_shown:
		screens = _boxes.demo_entering()
	_queue.clear()
	_queue_loading(screens, _begin_demo.bind(high_scores_shown))
	_after_queue(Callable())


## The demo's map at the start of its play: a new game on Normal, the
## random table from its start.
func _begin_demo(high_scores_shown: bool) -> void:
	_title_layer.clear()
	_inventory = _new_inventory()
	_inventory.extra_lives_for_points = false
	_game_progress = _new_progress()
	_difficulty = GalaxyDifficulty.DEFAULT
	_map_number = _demo.map_number
	var map := _data.maps.load_map(_demo.map_number)
	var session := _new_session(map, _demo.map_number, 0) if map != null else null
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
	_demo_sign.visible = not high_scores_shown
	if high_scores_shown:
		_show_board(map)


## A new map: the table is part of the high-score map's picture (it stays
## under the next demo's box until that map is shown, seen in Keen 4).
func _show_map(map: GalaxyMap, sprites: PackedInt32Array) -> void:
	_board_sprite.visible = false
	super(map, sprites)


## The table over the high-score map's view.
func _show_board(map: GalaxyMap) -> void:
	_board = GalaxyHighScoreBoard.create(
		_data.graphics, rules, _high_scores, map, _galaxy_camera.view_pixels()
	)
	_board_sprite.position = Vector2(_galaxy_camera.view_pixels())
	_redraw_board()
	_board_sprite.visible = true


func _redraw_board() -> void:
	_board_sprite.texture = ImageTexture.create_from_image(_board.overlay())


## A demo's frame: its recorded input, through two-button firing.
func _frame_input(tics: int) -> KeenInput:
	if _front != Front.DEMO or _demo == null:
		return super(tics)
	var input := _firing.convert(_demo.controls_at(_demo_frame), tics)
	_demo_frame += 1
	return input


## A demo plays as recorded, in the original's view: in widescreen too
## objects wake up around the original's 320 pixels, or a creature woken
## earlier would change the demo.
func _wide_view_width() -> int:
	return 0 if _demo != null else super()


## After a frame: a demo goes on or ends; in a game the cheats, then the
## flow.
func _after_frame() -> bool:
	if _after_demo_frame():
		return not _queue.is_empty() or _played == null
	if _check_cheats():
		return true
	return super()


## Whether a demo is played; after its frame it may end (its input used
## up, or Keen out of the level): then the title loop goes on.
func _after_demo_frame() -> bool:
	if _front != Front.DEMO:
		return false
	if _demo_frame >= _demo.frame_count() or not _played.is_playing():
		_end_demo()
	return true


func _end_demo() -> void:
	var was_high_scores := _board_sprite.visible and _demo.map_number == rules.high_score_map
	_played = null
	_stop_music()
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
				_stop_music()
				_next_title_step()
		Front.ENDING:
			if _end_pages.advance(tics):
				_title_layer.show_picture(_end_pages.screen())
		Front.NAME_ENTRY:
			if _board.advance(tics):
				_redraw_board()
		Front.SCENE:
			_advance_scene(tics)
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
	var picture := _data.graphics.picture(
		_data.graphics.ranges.picture_count - rules.title_from_end
	)
	if picture != null and picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	return picture


## [param scene] over the whole screen; then [param then].
func _start_scene(scene: GalaxyScene, then: Callable) -> void:
	_played = null
	_on_map = null
	_score_box.visible = false
	_queue.clear()
	_show_step()
	scene.sound_player = _play_sound
	scene.song_player = _play_map_song
	_scene = scene
	_after_scene = then
	_front = Front.SCENE
	_show_scene()


func _advance_scene(tics: int) -> void:
	if _scene.advance(tics):
		_show_scene()
	if _scene.is_done():
		_end_scene()


func _show_scene() -> void:
	var image := _scene.screen()
	if image != null:
		_title_layer.show_picture(image)
	else:
		_title_layer.clear()
	var level := _scene.fade_level()
	_fade.visible = level < GalaxyEgaFade.WHOLE
	if _fade.visible:
		_fade.material = GalaxyEgaFade.material(level)


func _end_scene() -> void:
	_scene = null
	_front = Front.NONE
	_fade.visible = false
	var then := _after_scene
	_after_scene = Callable()
	if then.is_valid():
		then.call()


## The end pages of text [param text].
func _start_ending(text: int) -> void:
	_played = null
	_on_map = null
	_score_box.visible = false
	_end_pages = GalaxyEnding.create(_data.graphics, rules, text)
	_front = Front.ENDING
	_play_map_song(rules.ending_song)
	_title_layer.show_picture(_end_pages.screen())


## After a game: the name is typed in on the high-score map when the score
## made the table; then the high scores and the title picture; then the
## title loop goes on (Omni CK_SubmitHighScore, CK_DemoLoop).
func _game_ended() -> void:
	_played = null
	_on_map = null
	_after_game = true
	_stop_front()
	_stop_music()
	var place := _high_scores.place_for(_inventory.score, _high_score_count())
	if place < 0:
		_in_title_loop = true
		_title_layer.show_black()
		_start_demo(rules.high_score_demo, true)
		return
	_high_scores.insert(place, "", _inventory.score, _high_score_count())
	_queue.clear()
	var no_box: Array[Image] = []
	_queue_loading(no_box, _begin_name_entry.bind(place))
	_after_queue(Callable())


## The number the table keeps beside a game's score (Keen 4: the council
## members rescued; none by default).
func _high_score_count() -> int:
	return 0


func _begin_name_entry(place: int) -> void:
	_title_layer.clear()
	var map := _data.maps.load_map(rules.high_score_map)
	_map_number = rules.high_score_map
	_inventory = _new_inventory()
	var session := _new_session(map, map.number, 0)
	_play(session, map)
	# The original only loads the map here, it does not play it: no song.
	_stop_music()
	_score_box.visible = false
	# The original draws only the map's tiles behind the table here (seen
	# in Keen 4).
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
	_start_demo(rules.high_score_demo, true)


## The cheats while Keen plays (Omni CK_PlayLoop, CK_CheckKeys): E+N+D
## ([method _cheat_end]); B+A+T shows its box and gives the items. Returns
## whether one did something.
func _check_cheats() -> bool:
	if _in_title_loop:
		return false
	match _cheats.check(_key_held):
		GalaxyCheats.Cheat.END:
			_cheat_end()
			return true
		GalaxyCheats.Cheat.ITEMS:
			_show_screens([GalaxyCheats.items_box(_data, rules)], _give_items)
			return true
	return false


## E+N+D: the episode's end (none by default).
func _cheat_end() -> void:
	pass


## B+A+T's gifts (an episode adds its own: Keen 5's keycard).
func _give_items() -> void:
	GalaxyCheats.give_items(_inventory)
	_update_score_box()


## The keys of the front screens; returns whether [param event] was theirs.
func _front_input(event: InputEvent) -> bool:
	var key := event as InputEventKey
	match _front:
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
		Front.SCENE:
			if _is_new_press(event) and _scene.press():
				_advance_scene(0)
			return true
	if not _in_title_loop:
		return false
	if _is_new_press(event):
		_title_loop_key(event)
	return true


## A key in the title loop: Escape goes back to the start screen (the
## menu screen opens the control panel on any key, as the original).
func _title_loop_key(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_leave()


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
	_fade.size = Vector2(game_size)
	_demo_sign.position = (
		Vector2((game_size.x - GalaxyWindow.SCREEN_SIZE.x) / 2.0, 0) + DEMO_SIGN_AT
	)
