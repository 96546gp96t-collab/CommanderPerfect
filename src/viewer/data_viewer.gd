extends Control
## Browser for everything that is read from the original game files: levels,
## tiles, sprites, bitmaps and the font. Used to check that the data is
## decoded correctly before the game itself is built on top of it.

const TILE_ATLAS_COLUMNS := 16
const FONT_ATLAS_COLUMNS := 32
const MISSING_DATA_MESSAGE := (
	"Keen 1 data not found. Put the files in game_data/keen1 "
	+ "(see game_data/README.md) or start with: -- --data-dir=PATH"
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
	_files = GameFiles.locate()
	if _files == null:
		_show_error(MISSING_DATA_MESSAGE)
		return

	_graphics = EgaGraphics.load_from(_files)
	if _graphics == null:
		_show_error("The game files in %s could not be read." % _files.directory)
		return

	_status_label.text = "Loaded game data from %s" % _files.directory
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


func _show_error(message: String) -> void:
	_status_label.text = message
	_tabs.visible = false
	push_error(message)


func _fill_level_select() -> void:
	for number in _files.level_numbers():
		var label := "World map" if number == GameFiles.WORLD_MAP_LEVEL else "Level %d" % number
		_level_select.add_item(label, number)


func _show_selected_level() -> void:
	if _level_select.item_count == 0:
		return
	var number := _level_select.get_selected_id()
	var file_name := GameFiles.level_file_name(number)
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
