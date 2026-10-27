class_name Launcher
extends Control
## The start screen: CommanderPerfect always begins here. The picture of
## CommanderPerfect fills the screen, whole; below it, in a dark gray bar,
## an icon for each game ([GameCatalog]) from the left: Keen 1, then Keen
## 2, then Keen 3, then Keen 4, then Keen 5. Picking one
## starts that game with its main menu open. See docs/menus.md.
##
## The mouse, the arrow keys and the controller pick an icon; a click,
## Enter or A starts it. Escape twice closes the program. With
## [code]-- --level=N[/code] or [code]-- --ending[/code] on the command
## line Keen 1 starts at once, for testing ([GameLaunch]); with
## [code]-- --game=2[/code] Keen 2 does, with [code]-- --game=3[/code] Keen 3,
## with [code]-- --game=4[/code] Keen 4, with [code]-- --game=5[/code] Keen 5.

const BACKGROUND := preload("res://assets/launcher/background.png")
const BAR_COLOR := Color("303030")
const MESSAGE_COLOR := Color("e0e0e0")
## Seconds within which a second Escape closes the program.
const QUIT_SECONDS := 3.0
const QUIT_MESSAGE := "Press Escape again to quit"
## Filled in with the game's title and its data folder.
const MISSING_FILES_MESSAGE := (
	"The files of %s were not found. Put them in %s "
	+ "(see game_data/README.md), next to the app."
)
## The message is this part of the height of the bar.
const MESSAGE_SHARE := 0.22

var _picture := TextureRect.new()
var _message := Label.new()
var _icons: Array[GameIcon] = []
var _games: Array[GameCatalog.Game] = []
var _quit_time_left := 0.0


func _ready() -> void:
	if GameLaunch.skips_launcher(OS.get_cmdline_user_args()):
		var scene := GameLaunch.scene_for(OS.get_cmdline_user_args())
		get_tree().change_scene_to_file.call_deferred(scene)
		return
	_apply_window_mode()
	_build()
	resized.connect(_arrange)
	_arrange()


func _process(delta: float) -> void:
	if _quit_time_left <= 0.0:
		return
	_quit_time_left -= delta
	if _quit_time_left <= 0.0 and _message.text == Lang.text(QUIT_MESSAGE):
		_message.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if _takes_keys(event):
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _quit_time_left > 0.0:
		get_tree().quit()
		return
	_quit_time_left = QUIT_SECONDS
	_message.text = Lang.text(QUIT_MESSAGE)


## No icon is chosen until the keys or the controller are used, so that
## only the mouse makes one darker. The first arrow key (or Enter) chooses
## the first icon; from then on Godot moves between them.
func _takes_keys(event: InputEvent) -> bool:
	if _icons.is_empty() or get_viewport().gui_get_focus_owner() != null:
		return false
	for action in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_accept"]:
		if event.is_action_pressed(action):
			_icons[0].grab_focus()
			get_viewport().set_input_as_handled()
			if action == "ui_accept":
				_icons[0].chosen.emit()
			return true
	return false


## The icon of each game, in the order of [method GameCatalog.games].
func icons() -> Array[GameIcon]:
	return _icons


## The message in the bar, such as why a game cannot start.
func message() -> String:
	return _message.text


## Full screen or a window, as the player last chose in the game.
func _apply_window_mode() -> void:
	var settings := UserSettings.load_from()
	var mode := (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if settings.fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BAR_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_picture.texture = BACKGROUND
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)
	_message.add_theme_color_override("font_color", MESSAGE_COLOR)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_message)
	_games = GameCatalog.games()
	for game in _games:
		var icon := _make_icon(game)
		icon.chosen.connect(_start.bind(game))
		add_child(icon)
		_icons.append(icon)


func _make_icon(game: GameCatalog.Game) -> GameIcon:
	var icon := GameIcon.new()
	icon.title = game.title
	icon.available = game.is_available()
	if game.is_available() and game.icon_picture.is_valid():
		icon.sprite = game.icon_picture.call()
		if game.icon_title.is_valid():
			icon.title_picture = game.icon_title.call()
	elif game.is_available():
		var graphics := EgaGraphics.load_from(game.files, game.files.extension)
		if graphics != null:
			icon.textures = GraphicsTextures.create(graphics)
			icon.sprite = icon.textures.sprite(KeenPhysics.SPRITE_WALK_RIGHT)
	return icon


## Puts the picture, the icons and the message where [LauncherLayout] says.
func _arrange() -> void:
	var screen := size
	var picture := LauncherLayout.picture_rect(screen, BACKGROUND.get_size())
	_picture.position = picture.position
	_picture.size = picture.size
	var bar := LauncherLayout.bar_rect(screen, picture)
	var scale := LauncherLayout.icon_scale(bar.size.y)
	var icon_size := Vector2(GameIcon.BASE_SIZE * scale)
	var positions := LauncherLayout.icon_positions(bar, icon_size, _icons.size())
	for index in _icons.size():
		_icons[index].pixel_scale = scale
		_icons[index].position = positions[index]
	# The message goes to the right of the icons.
	var gap := LauncherLayout.gap_in(bar)
	var left := positions[-1].x + icon_size.x + gap if not positions.is_empty() else gap
	_message.position = Vector2(left, bar.position.y)
	_message.size = Vector2(maxf(0.0, bar.end.x - gap - left), bar.size.y)
	_message.add_theme_font_size_override("font_size", maxi(12, roundi(bar.size.y * MESSAGE_SHARE)))


## Starts [param game] with its main menu open, or says why it cannot.
func _start(game: GameCatalog.Game) -> void:
	if not game.is_available():
		_message.text = Lang.text(MISSING_FILES_MESSAGE) % [game.title, game.data_folder]
		_quit_time_left = 0.0
		return
	GameLaunch.request_menu()
	# Deferred: this runs inside the handling of a click or a key, and
	# changing the scene takes this one out of the tree at once.
	get_tree().change_scene_to_file.call_deferred(game.scene)
