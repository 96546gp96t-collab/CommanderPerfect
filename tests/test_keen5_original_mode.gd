extends "res://tests/test_case.gd"
## Tests for milestone E12: with every option of Keen 5 off (4:3, no
## pictures behind the levels, the original graphics instead of xBRZ, no
## smooth motion) Keen 5 shows what the original v1.4 shows (the user's
## demand; docs/keen5/research.md, "Watched in E12"). Without files: which
## extras are on by default (only the two the user decided: widescreen and
## the pictures) and that the original's are the defaults otherwise. With
## the player's files, Keen 5's real screen on the world map and levels 1,
## 4, 11, 12 and 13: a 320 × 200 view on the original's view, no picture,
## no colour cleared from the tiles and nothing painted over them, no xBRZ
## textures, every sprite on the original's pixel (the x steps of its
## shifted copies), the score box 4 pixels from the view's corner; the
## broken QED paints nothing either. The pixels themselves are compared
## with the original's recordings in the scratchpad (the demos frame for
## frame, the status window, the panel, the death box, the end pages);
## this suite guards the switches. It needs a running scene tree; settings
## go to a folder of their own, removed afterwards.

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_original_mode"
const FRAME_SECONDS := 1.0 / 35.0
const QUEUE_FRAMES := 400
## Frames played on each map before looking at the sprites.
const PLAY_FRAMES := 40
const ORIGINAL_VIEW := Vector2i(320, 200)
## The world map and the levels with open space or sky (the maps that get
## a picture in widescreen), and level 12 with the QED.
const MAPS: PackedInt32Array = [0, 1, 4, 11, 12, 13]
const QED_LEVEL := 12

var _data: GalaxyData
var _view: Keen5View
var _tree: SceneTree


func _init() -> void:
	var files := Keen5Files.locate()
	if files != null:
		_data = Keen5Episode.load_data(files)
	_tree = Engine.get_main_loop() as SceneTree


func run_all() -> void:
	KeyBindings.reset()
	super.run_all()
	_free_view()
	var path := ProjectSettings.globalize_path(TEST_DIRECTORY.path_join("settings.cfg"))
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_only_the_decided_extras_are_on_by_default() -> void:
	var display := DisplaySettings.new()
	assert_equal(display.graphics, DisplaySettings.Graphics.ORIGINAL, "the original graphics")
	assert_true(not display.smooth_motion, "no smooth motion")
	assert_equal(display.aspect, DisplaySettings.Aspect.WIDESCREEN, "widescreen (decided)")
	assert_true(display.backgrounds, "the pictures (decided, widescreen only)")
	assert_true(GalaxySettings.new().score_box, "the score box, as the original")


func test_all_options_off_shows_the_original_view() -> void:
	if not _can_show():
		return
	_create_original_view()
	for number in MAPS:
		_view._show_level(number)
		_run_queue()
		_play(PLAY_FRAMES)
		_assert_original("map %d" % number)


func test_the_broken_qed_paints_nothing_with_all_options_off() -> void:
	if not _can_show():
		return
	_create_original_view()
	_view._show_level(QED_LEVEL)
	_run_queue()
	for object in _view._played.world.objects:
		if object is Keen5Qed:
			(object as Keen5Qed).hit_by_piece(null)
	_play(2)
	_assert_original("the QED broken")


func test_switching_the_options_off_takes_the_extras_away() -> void:
	if not _can_show():
		return
	_create_view()
	_view._settings.smooth_motion = true
	_view._apply_display_settings()
	_view._show_level(1)
	_run_queue()
	assert_true(_view._backdrop_picture != null, "on: the picture behind level 1")
	assert_equal(_view._settings.game_size().y, ORIGINAL_VIEW.y, "200 lines in widescreen too")
	assert_true(_view._settings.game_size().x > ORIGINAL_VIEW.x, "on: wider")
	_off()
	_play(PLAY_FRAMES)
	_assert_original("switched off while playing")


## Every check of the original's look on the map shown now.
func _assert_original(what: String) -> void:
	assert_equal(_view._settings.game_size(), ORIGINAL_VIEW, "%s: a 320 × 200 view" % what)
	assert_equal(Vector2i(_view._world.size), ORIGINAL_VIEW, "%s: the viewport" % what)
	assert_true(_view._backdrop_picture == null, "%s: no picture" % what)
	assert_true(_view._sky_color.a == 0.0, "%s: no colour cleared from the tiles" % what)
	assert_true(not _view._sky_patch.visible, "%s: nothing painted over them" % what)
	assert_true(not _view._showing_scaled, "%s: no xBRZ tiles" % what)
	assert_true(_view._objects._scaled == null, "%s: no xBRZ sprites" % what)
	var camera := _view._galaxy_camera
	var middle := Vector2(camera.view_pixels()) + Vector2(ORIGINAL_VIEW) / 2.0
	assert_equal(_view._camera_anchor.position, middle, "%s: the original's view" % what)
	assert_true(_view._score_box.visible, "%s: the score box" % what)
	assert_equal(_view._score_box.position, GalaxyScoreBox.SCREEN_OFFSET, "%s: 4 pixels in" % what)
	_assert_sprites_on_original_pixels(what)


func _assert_sprites_on_original_pixels(what: String) -> void:
	var shown := 0
	var off := 0
	for item in _view._objects.items():
		if not item.node.visible:
			continue
		shown += 1
		var info := _data.graphics.sprite_infos[item.sprite]
		var pixel := GalaxyObjectLayer.pixel_of(info, item.position)
		if item.node.position != Vector2(pixel) or item.pixel != pixel:
			off += 1
		var texture := item.node.texture
		if (
			texture != null
			and texture.get_size() != Vector2(_data.graphics.sprite(item.sprite).get_size())
		):
			off += 1
	assert_true(shown > 0, "%s: sprites shown" % what)
	assert_equal(off, 0, "%s: every sprite on the original's pixel, unscaled" % what)


func _can_show() -> bool:
	return _data != null and _tree != null and _tree.root.is_inside_tree()


## Keen 5's view with every option off.
func _create_original_view() -> void:
	_create_view()
	_off()


func _off() -> void:
	_view._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	_view._settings.backgrounds = false
	_view._settings.graphics = DisplaySettings.Graphics.ORIGINAL
	_view._settings.smooth_motion = false
	_view._apply_display_settings()


## Keen 5's view with the defaults (widescreen and the pictures on).
func _create_view() -> void:
	_free_view()
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as Keen5View
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._settings.aspect = DisplaySettings.Aspect.WIDESCREEN
	_view._settings.backgrounds = true
	_view._apply_display_settings()
	_view._new_game()
	_run_queue()


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


func _run_queue() -> void:
	for frame in QUEUE_FRAMES:
		if not _view.shows_message():
			return
		_view._process(FRAME_SECONDS)


func _play(frames: int) -> void:
	for frame in frames:
		_view._process(FRAME_SECONDS)
