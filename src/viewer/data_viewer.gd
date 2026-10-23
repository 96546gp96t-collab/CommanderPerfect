extends Control
## Browser for everything that is read from the original game files: levels,
## tiles, sprites, bitmaps and the font. Used to check that the data is
## decoded correctly before the game itself is built on top of it.
## With [code]-- --game=2[/code] on the command line it shows Keen 2's
## files instead of Keen 1's, with [code]-- --game=3[/code] Keen 3's, with
## [code]-- --game=4[/code] Keen 4's on a page of its own ([GalaxyViewerPage]),
## with [code]-- --game=5[/code] Keen 5's on the same kind of page.

const TILE_ATLAS_COLUMNS := 16
const FONT_ATLAS_COLUMNS := 32
const MISSING_DATA_MESSAGE := (
	"Keen 1 data not found. Put the files in game_data/keen1 "
	+ "(see game_data/README.md) or start with: -- --data-dir=PATH"
)
const KEEN_2_MISSING_DATA_MESSAGE := (
	"Keen 2 data not found. Put the files in game_data/keen2 "
	+ "(see game_data/README.md) or start with: -- --game=2 --data-dir-keen2=PATH"
)
const KEEN_3_MISSING_DATA_MESSAGE := (
	"Keen 3 data not found. Put the files in game_data/keen3 "
	+ "(see game_data/README.md) or start with: -- --game=3 --data-dir-keen3=PATH"
)
const KEEN_4_MISSING_DATA_MESSAGE := (
	"Keen 4 data not found. Put the files in game_data/keen4 "
	+ "(see game_data/README.md) or start with: -- --game=4 --data-dir-keen4=PATH"
)
const KEEN_5_MISSING_DATA_MESSAGE := (
	"Keen 5 data not found. Put the files in game_data/keen5 "
	+ "(see game_data/README.md) or start with: -- --game=5 --data-dir-keen5=PATH"
)

var _files: GameFiles
var _graphics: EgaGraphics
var _zoom := 2

@onready var _status_label: Label = %StatusLabel
@onready var _zoom_spin_box: SpinBox = %ZoomSpinBox
@onready var _tabs: TabContainer = %Tabs
@onready var _level_select: OptionButton = %LevelSelect
@onready var _info_layer_toggle: CheckBox = %InfoLayerToggle
@onready var _level_details: Label = %LevelDetails
@onready var _level_image: TextureRect = %LevelImage
@onready var _tile_atlas: TextureRect = %TileAtlas
@onready var _tile_hover: Label = %TileHover
@onready var _sprite_list: HFlowContainer = %SpriteList
@onready var _bitmap_list: HFlowContainer = %BitmapList
@onready var _font_atlas: TextureRect = %FontAtlas
@onready var _font_hover: Label = %FontHover


func _ready() -> void:
	var game := GameLaunch.game_number(OS.get_cmdline_user_args())
	if game == 4:
		_show_keen_4()
		return
	if game == 5:
		_show_keen_5()
		return
	var keen_2 := game == 2
	var keen_3 := game == 3
	if keen_3:
		_files = Keen3Files.locate()
	else:
		_files = Keen2Files.locate() if keen_2 else GameFiles.locate()
	if _files == null:
		if keen_3:
			_show_error(KEEN_3_MISSING_DATA_MESSAGE)
		else:
			_show_error(KEEN_2_MISSING_DATA_MESSAGE if keen_2 else MISSING_DATA_MESSAGE)
		return

	_graphics = EgaGraphics.load_from(_files, _files.extension)
	if _graphics == null:
		_show_error("The game files in %s could not be read." % _files.directory)
		return

	_status_label.text = "Loaded game data from %s" % _files.directory
	if keen_2:
		_status_label.text += _keen_2_executable_summary()
	if keen_3:
		_status_label.text += _keen_3_executable_summary()
	_zoom_spin_box.value = _zoom
	_zoom_spin_box.value_changed.connect(_on_zoom_changed)
	_level_select.item_selected.connect(_on_level_selected)
	_info_layer_toggle.toggled.connect(_on_info_layer_toggled)
	_tile_atlas.gui_input.connect(_on_tile_atlas_input)
	_font_atlas.gui_input.connect(_on_font_atlas_input)

	_fill_level_select()
	_tile_atlas.texture = ImageTexture.create_from_image(
		_graphics.create_tile_atlas(TILE_ATLAS_COLUMNS)
	)
	_font_atlas.texture = ImageTexture.create_from_image(
		_graphics.create_font_atlas(FONT_ATLAS_COLUMNS)
	)
	_fill_image_lists()
	_show_selected_level()
	_apply_zoom()


## Keen 4 is a Galaxy game, with files of its own kind: its own page
## takes the place of the tabs.
func _show_keen_4() -> void:
	var files := Keen4Files.locate()
	var data := Keen4Episode.load_data(files) if files != null else null
	if data == null:
		_show_error(KEEN_4_MISSING_DATA_MESSAGE)
		return
	_tabs.visible = false
	var page := GalaxyViewerPage.new()
	_tabs.get_parent().add_child(page)
	_status_label.text = (
		"Loaded game data from %s. %s" % [files.directory, page.show_data(data, _zoom_spin_box)]
	)


## Keen 5 is a Galaxy game too: the same page, with Keen 5's files.
func _show_keen_5() -> void:
	var files := Keen5Files.locate()
	var data := Keen5Episode.load_data(files) if files != null else null
	if data == null:
		_show_error(KEEN_5_MISSING_DATA_MESSAGE)
		return
	_tabs.visible = false
	var page := GalaxyViewerPage.new()
	_tabs.get_parent().add_child(page)
	_status_label.text = (
		"Loaded game data from %s. %s"
		% [files.directory, page.show_data(data, _zoom_spin_box, "Keen 5")]
	)


func _show_error(message: String) -> void:
	_status_label.text = message
	_tabs.visible = false
	push_error(message)


func _fill_level_select() -> void:
	for number in _files.level_numbers():
		_level_select.add_item(GameFiles.level_title(number), number)


func _show_selected_level() -> void:
	if _level_select.item_count == 0:
		return
	var number := _level_select.get_selected_id()
	var file_name := _files.level_file(number)
	var level := LevelData.parse(_files.read(file_name))
	if level == null:
		_level_details.text = "%s could not be read." % file_name
		_level_image.texture = null
		return

	var image := LevelImageBuilder.build(level, _graphics, _info_layer_toggle.button_pressed)
	_level_image.texture = ImageTexture.create_from_image(image)
	_level_details.text = "%s: %d x %d cells" % [file_name, level.width, level.height]
	_apply_zoom()


## Sprites and bitmaps are shown as a list of pictures with their names.
func _fill_image_lists() -> void:
	for i in _graphics.sprites.size():
		var entry := _graphics.header.sprites[i]
		_sprite_list.add_child(_create_named_image(_graphics.sprites[i], "%d %s" % [i, entry.name]))
	for i in _graphics.bitmaps.size():
		var entry := _graphics.header.bitmaps[i]
		_bitmap_list.add_child(_create_named_image(_graphics.bitmaps[i], entry.name))


## What was found inside KEEN2.EXE, for the status line.
func _keen_2_executable_summary() -> String:
	var executable := Keen2Executable.load_from(_files)
	if executable == null:
		return " (%s could not be read)" % Keen2Files.EXECUTABLE
	var found := PackedStringArray()
	if Keen2Executable.find_sound_block(executable.image) >= 0:
		found.append("sounds")
	for block in Keen2Executable.TextBlock.size():
		if (
			Keen2Executable.find_text_block(executable.image, block as Keen2Executable.TextBlock)
			>= 0
		):
			found.append(Keen2Executable.TextBlock.keys()[block].to_lower())
	if Keen2Executable.find_city_names(executable.image) >= 0:
		found.append("cities")
	return (
		" (%s version %s; found: %s)"
		% [Keen2Files.EXECUTABLE, executable.version, ", ".join(found)]
	)


## What was found inside KEEN3.EXE, for the status line.
func _keen_3_executable_summary() -> String:
	var executable := Keen3Executable.load_from(_files)
	if executable == null:
		return " (%s could not be read)" % Keen3Files.EXECUTABLE
	var image := executable.image
	var found := PackedStringArray()
	if Keen3Executable.find_sound_block(image) >= 0:
		found.append("sounds")
	for block in Keen3Executable.TextBlock.size():
		if Keen3Executable.find_text_block(image, block as Keen3Executable.TextBlock) >= 0:
			found.append(Keen3Executable.TextBlock.keys()[block].to_lower())
	if executable.tile_properties(_graphics.tiles.size()) != null:
		found.append("tiles")
	var pieces: Dictionary[String, int] = {
		"status box": executable.status_box_lines().size(),
		"mortimer": executable.mortimer_messages().size(),
		"ending": executable.ending_pages().size(),
		"the end": executable.the_end().size(),
		"ship": executable.ship_messages().size(),
	}
	for piece in pieces:
		if pieces[piece] > 0:
			found.append(piece)
	if executable.score_texts() != null:
		found.append("scores")
	return (
		" (%s version %s; found: %s)"
		% [Keen3Files.EXECUTABLE, executable.version, ", ".join(found)]
	)


func _create_named_image(image: Image, caption: String) -> Control:
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(image)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.tooltip_text = caption

	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var box := VBoxContainer.new()
	box.add_child(picture)
	box.add_child(label)
	return box


func _apply_zoom() -> void:
	for picture: TextureRect in [_level_image, _tile_atlas, _font_atlas]:
		_scale_texture_rect(picture)
	for list: HFlowContainer in [_sprite_list, _bitmap_list]:
		for box in list.get_children():
			_scale_texture_rect(box.get_child(0))


func _scale_texture_rect(picture: TextureRect) -> void:
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if picture.texture != null:
		picture.custom_minimum_size = picture.texture.get_size() * _zoom


## Returns the atlas cell under [param position], or -1 outside the atlas.
func _atlas_cell_at(position: Vector2, cell_size: int, columns: int, count: int) -> int:
	var cell := Vector2i(position / float(cell_size * _zoom))
	var index := cell.y * columns + cell.x
	return index if cell.x < columns and index < count else -1


func _on_zoom_changed(value: float) -> void:
	_zoom = int(value)
	_apply_zoom()


func _on_level_selected(_index: int) -> void:
	_show_selected_level()


func _on_info_layer_toggled(_enabled: bool) -> void:
	_show_selected_level()


func _on_tile_atlas_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var tile := _atlas_cell_at(
			event.position, EgaGraphics.TILE_SIZE, TILE_ATLAS_COLUMNS, _graphics.tiles.size()
		)
		_tile_hover.text = "Tile %d" % tile if tile >= 0 else ""


func _on_font_atlas_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var character := _atlas_cell_at(
			event.position,
			EgaGraphics.FONT_CHAR_SIZE,
			FONT_ATLAS_COLUMNS,
			_graphics.font_chars.size()
		)
		_font_hover.text = "Character %d" % character if character >= 0 else ""
