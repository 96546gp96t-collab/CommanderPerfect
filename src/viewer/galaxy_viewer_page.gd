class_name GalaxyViewerPage
extends TabContainer
## The data viewer's page for a Galaxy episode (Keen 4, chosen with
## [code]-- --game=4[/code]): the maps with their three planes, both 16×16
## tile sets, the sprites with their hit boxes and origins, the pictures,
## the fonts and 8×8 tiles, and what was found in the program. Everything
## is decoded when its tab is first shown, so the viewer opens at once.

const TILE := GalaxyGraphics.TILE16_SIZE
const ATLAS_COLUMNS := 18
const FONT_SAMPLE := "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789 !?.,:;()-+"
const FONT_COLOR := Color.WHITE
const BOX_COLOR := Color(1.0, 0.2, 0.2)
const ORIGIN_COLOR := Color(0.2, 1.0, 0.2)
const PANEL_COLOR := Color(0.25, 0.25, 0.25)

var _data: GalaxyData
var _zoom := 2
var _built: Dictionary[int, bool] = {}
var _map_select := OptionButton.new()
var _plane_toggles: Array[CheckBox] = []
var _map_details := Label.new()
var _map_image := TextureRect.new()
var _map: GalaxyMap
var _zoomable: Array[TextureRect] = []


## Fills the page with [param data] and follows [param zoom]. Returns a
## line for the viewer's status bar.
func show_data(data: GalaxyData, zoom: SpinBox) -> String:
	_data = data
	_zoom = int(zoom.value)
	zoom.value_changed.connect(_on_zoom_changed)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for title in ["Maps", "Background tiles", "Foreground tiles", "Sprites", "Pictures"]:
		_add_tab(title)
	_add_tab("Fonts and 8x8 tiles")
	_add_tab("Program")
	tab_changed.connect(_build_tab)
	_build_tab(0)
	var ranges := data.graphics.ranges
	return (
		"Keen 4 %s: %d pictures, %d sprites, %d + %d tiles, %d maps"
		% [
			data.executable.version,
			ranges.picture_count,
			ranges.sprite_count,
			ranges.back_tile_count,
			ranges.fore_tile_count,
			data.maps.map_count(),
		]
	)


func _add_tab(title: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = title
	add_child(scroll)


func _build_tab(index: int) -> void:
	if _built.has(index):
		return
	_built[index] = true
	var scroll := get_child(index) as ScrollContainer
	match index:
		0:
			scroll.add_child(_map_page())
		1:
			scroll.add_child(_picture(_data.graphics.tile_atlas(false, ATLAS_COLUMNS)))
		2:
			scroll.add_child(_picture(_data.graphics.tile_atlas(true, ATLAS_COLUMNS)))
		3:
			scroll.add_child(_sprite_list())
		4:
			scroll.add_child(_picture_list())
		5:
			scroll.add_child(_font_list())
		6:
			scroll.add_child(_program_text())
	_apply_zoom()


func _map_page() -> Control:
	var page := VBoxContainer.new()
	var toolbar := HBoxContainer.new()
	page.add_child(toolbar)
	toolbar.add_child(_map_select)
	for number in _data.maps.map_count():
		if _data.maps.has_map(number):
			_map_select.add_item("%d %s" % [number, _data.maps.map_name(number)], number)
	_map_select.item_selected.connect(func(_index: int) -> void: _show_map())
	for title in ["Background", "Foreground", "Info"]:
		var toggle := CheckBox.new()
		toggle.text = title
		toggle.button_pressed = true
		toggle.toggled.connect(func(_on: bool) -> void: _draw_map())
		toolbar.add_child(toggle)
		_plane_toggles.append(toggle)
	toolbar.add_child(_map_details)
	_map_image.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_image.gui_input.connect(_on_map_input)
	page.add_child(_map_image)
	_zoomable.append(_map_image)
	_show_map()
	return page


func _show_map() -> void:
	_map = _data.maps.load_map(_map_select.get_selected_id())
	_draw_map()


func _draw_map() -> void:
	if _map == null:
		_map_details.text = "This map could not be read."
		_map_image.texture = null
		return
	var layers: Array[bool] = []
	for toggle in _plane_toggles:
		layers.append(toggle.button_pressed)
	var image := GalaxyMapImage.build(_map, _data.graphics, layers)
	_map_image.texture = ImageTexture.create_from_image(image)
	_map_details.text = "%d x %d tiles" % [_map.width, _map.height]
	_apply_zoom()


func _sprite_list() -> Control:
	var list := _flow()
	for index in _data.graphics.ranges.sprite_count:
		var info := _data.graphics.sprite_infos[index]
		var image := _data.graphics.sprite(index)
		if image == null:
			continue
		var marked := _with_box(image, info)
		var caption := "%d" % index
		var tip := (
			"Sprite %d: %d x %d px, origin %s, box %d,%d - %d,%d (global units)"
			% [
				index,
				info.width,
				info.height,
				info.origin,
				info.box_left,
				info.box_top,
				info.box_right,
				info.box_bottom
			]
		)
		list.add_child(_named(marked, caption, tip))
	return list


## [param image] on a dark panel with its hit box (red) and the object's
## position (green, from the origin), with room around for a box that
## sticks out.
static func _with_box(image: Image, info: GalaxySpriteInfo) -> Image:
	var box := info.hit_box_pixels()
	var position := -info.origin / GalaxySpriteInfo.UNITS_PER_PIXEL
	var bounds := Rect2i(Vector2i.ZERO, image.get_size()).merge(box).expand(position)
	bounds = bounds.grow(1)
	var canvas := Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(PANEL_COLOR)
	var shift := -bounds.position
	canvas.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), shift)
	var edges := Rect2i(box.position + shift, box.size + Vector2i.ONE)
	for x in range(edges.position.x, edges.end.x):
		canvas.set_pixel(x, edges.position.y, BOX_COLOR)
		canvas.set_pixel(x, edges.end.y - 1, BOX_COLOR)
	for y in range(edges.position.y, edges.end.y):
		canvas.set_pixel(edges.position.x, y, BOX_COLOR)
		canvas.set_pixel(edges.end.x - 1, y, BOX_COLOR)
	canvas.set_pixelv(position + shift, ORIGIN_COLOR)
	return canvas


func _picture_list() -> Control:
	var list := _flow()
	for index in _data.graphics.ranges.picture_count:
		var image := _data.graphics.picture(index)
		if image != null:
			list.add_child(_named(image, "%d" % index, "Picture %d" % index))
	for index in _data.graphics.ranges.masked_picture_count:
		var image := _data.graphics.masked_picture(index)
		if image != null:
			list.add_child(_named(image, "M%d" % index, "Masked picture %d" % index))
	return list


func _font_list() -> Control:
	var list := VBoxContainer.new()
	for index in _data.graphics.ranges.font_count:
		var font := _data.graphics.font(index)
		if font != null:
			var picture := _picture(font.render(FONT_SAMPLE, FONT_COLOR))
			picture.tooltip_text = "Font %d, %d px high" % [index, font.height]
			list.add_child(picture)
	for masked in [false, true]:
		var count := (
			_data.graphics.ranges.masked_tile8_count
			if masked
			else _data.graphics.ranges.tile8_count
		)
		var tiles := _flow()
		for index in count:
			var tile := _data.graphics.tile8(index, masked)
			if tile != null:
				tiles.add_child(
					_named(tile, "", "%s 8x8 tile %d" % ["Masked" if masked else "", index])
				)
		list.add_child(tiles)
	return list


func _program_text() -> Control:
	var executable := _data.executable
	var lines := PackedStringArray()
	lines.append("Version: %s" % executable.version)
	for piece in GalaxyEpisode.Header.values():
		var at: int = _data.headers.found_at.get(piece, GalaxyHeaders.NOT_FOUND)
		var where := "a file next to the game" if at == GalaxyHeaders.FROM_FILE else "0x%X" % at
		lines.append("%s: %s" % [GalaxyEpisode.Header.keys()[piece], where])
	lines.append("Random numbers at 0x%X" % GalaxyExecutable.find_random_table(executable.image))
	var names := executable.level_names()
	var entries := executable.entry_texts()
	for index in names.size():
		var entry := GalaxyExeTexts.one_line(entries[index]) if index < entries.size() else ""
		lines.append("Map %d: %s / %s" % [index, GalaxyExeTexts.one_line(names[index]), entry])
	for shape in _data.episode.message_shapes:
		for message in executable.messages(shape):
			lines.append("%s: %s" % [shape, GalaxyExeTexts.one_line(message)])
	var label := Label.new()
	label.text = "\n".join(lines)
	return label


func _flow() -> HFlowContainer:
	var list := HFlowContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return list


func _picture(image: Image) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(image)
	_zoomable.append(picture)
	return picture


func _named(image: Image, caption: String, tip: String) -> Control:
	var box := VBoxContainer.new()
	var picture := _picture(image)
	picture.tooltip_text = tip
	box.add_child(picture)
	if not caption.is_empty():
		var label := Label.new()
		label.text = caption
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(label)
	return box


func _apply_zoom() -> void:
	for picture in _zoomable:
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if picture.texture != null:
			picture.custom_minimum_size = picture.texture.get_size() * _zoom


func _on_zoom_changed(value: float) -> void:
	_zoom = int(value)
	_apply_zoom()


func _on_map_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null or _map == null:
		return
	var cell := Vector2i(motion.position / float(TILE * _zoom))
	_map_details.text = (
		"%d x %d tiles; at %d,%d: background %d, foreground %d, info 0x%X"
		% [
			_map.width,
			_map.height,
			cell.x,
			cell.y,
			_map.tile(GalaxyMap.Layer.BACKGROUND, cell.x, cell.y),
			_map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y),
			_map.tile(GalaxyMap.Layer.INFO, cell.x, cell.y),
		]
	)
