class_name GalaxyLevelScreen
extends GameScreen
## How a level of a Galaxy episode is drawn on the shared [GameScreen]
## (made from Keen 4's [Keen4LevelScreen]; [GalaxyPlayScreen] extends it
## with what happens, the episode's view with its flow): the World viewport
## stretched over the window, the keys F1-F6, and on top of that the Galaxy
## drawing:
##   - the map's three tile layers ([GalaxyLevelMap]) with their animation,
##     from atlases of only the tiles the level shows ([GalaxyTileAtlas]);
##   - the sprites ([GalaxyObjectLayer]);
##   - the original graphics or xBRZ ([GalaxyScaledGraphics], F5), made
##     on worker threads for each level the first time;
##   - the camera node put where [GalaxyCamera] says, widened in
##     widescreen, with what lies beyond the area between the scroll
##     blocks covered ([GalaxyViewCover]);
##   - the picture behind the level, in widescreen, when the option is on
##     and the level has sky ([GalaxyGameBackdrops]); sky shut in by
##     the level's drawing (glass) keeps its colour ([GalaxySkyPockets];
##     the episode decides both, E10).
## The episode's numbers are its [member rules] ([GalaxyGameRules]). The
## node layout is [code]level_view.tscn[/code]'s, as Keen 2-4 copy it
## ([GameScreen] finds its nodes by name); Keen 1-3's nodes (LevelMap,
## Keen, ActorLayer, ...) stay empty and hidden.

## The episode played: where its files are, its maps and sprites. Set by the
## episode's view before it enters the tree.
var rules: GalaxyGameRules
## The episode's files. Found with [member GalaxyGameRules.locate_files]
## unless they are set before the view enters the tree.
var files: GameFiles
var _data: GalaxyData
## The map on the screen; null before one is shown.
var _map: GalaxyMap
var _galaxy_camera: GalaxyCamera
var _scaled: GalaxyScaledGraphics
var _backdrops: GalaxyGameBackdrops
## The colour of the sky that the picture behind the level replaces;
## transparent while no picture is shown.
var _sky_color := Color.TRANSPARENT
## Whether the atlases and sprites now show xBRZ graphics.
var _showing_scaled := false
## Whether the xBRZ atlases hold stand-ins (original tiles made larger) for
## tiles a switch or a gem put there that are still being scaled.
var _stand_ins := false
## Background tiles with their sky made see-through, by tile.
var _cleared_tiles: Dictionary[int, Image] = {}
var _cleared_color := Color.TRANSPARENT
## The sprites a level draws, for xBRZ.
var _sprites_shown := PackedInt32Array()
## The picture behind the level shown now, or null.
var _backdrop_picture: Texture2D
## The sky shut in by the level's drawing (glass), painted in its colour
## while a picture is behind the level (D13.2).
var _sky_patch := GalaxySkyPatch.new()
## The shut-in sky found per map and sky colour (a level played again is
## the same at its start; finding it takes a moment).
var _sky_pockets: Dictionary[String, Array] = {}
## The cells changed while the map is played, with the rows of each that
## keep the sky's colour now (E12, E12.1); they replace what was found at
## the start.
var _changed_cells: Dictionary[Vector2i, Array] = {}
## The cells whose background tile changed while the map is played.
var _changed_backs: Dictionary[Vector2i, bool] = {}

@onready var _galaxy_map: GalaxyLevelMap = %GalaxyMap
@onready var _objects: GalaxyObjectLayer = %Objects
@onready var _cover: GalaxyViewCover = %Cover


func _exit_tree() -> void:
	if _scaled != null:
		_scaled.finish()


## What [GameScreen] needs before anything is shown: the settings and the
## World viewport stretched over the window.
func _set_up_screen() -> void:
	_user_settings = UserSettings.load_from()
	_settings = _user_settings.display
	_menus.window = _window
	_menus.settings = _user_settings
	add_child(_menus)
	# GameScreen's drawings of Keen 1's ship stay empty here; in the tree
	# they are freed with the scene.
	_add_ship_drawings()
	for node: CanvasItem in [_level_map, _keen, _mark, _actor_layer, _pictures, _hud]:
		node.visible = false
	_camera.follow_exactly(true)
	_apply_window_mode()
	resized.connect(_fit_screen)
	_screen.texture = _world.get_texture()
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_screen.material = ShaderMaterial.new()
	_screen.material.shader = EVEN_PIXELS_SHADER
	_galaxy_map.tiles_missing.connect(_on_tiles_missing)
	# Behind the tiles, in front of the picture.
	_galaxy_map.add_sibling(_sky_patch)
	_galaxy_map.get_parent().move_child(_sky_patch, _galaxy_map.get_index())
	_apply_display_settings()


## Reads the episode's files. Returns whether that worked; otherwise the
## screen says why.
func _load_data() -> bool:
	if files == null:
		files = rules.locate_files.call()
	if files == null:
		_show_error(rules.missing_data_message())
		return false
	_data = rules.load_data.call(files)
	if _data == null:
		_show_error(rules.unreadable_message(files.directory))
		return false
	_scaled = GalaxyScaledGraphics.create(_data.graphics)
	if rules.make_backdrops.is_valid():
		_backdrops = rules.make_backdrops.call(files, rules)
	else:
		_backdrops = GalaxyGameBackdrops.for_rules(files, rules)
	_objects.use_graphics(_data.graphics)
	return true


## Shows [param map] with its tiles, in the graphics the settings ask for.
## [param sprites] are the sprites it will draw.
func _show_map(map: GalaxyMap, sprites: PackedInt32Array) -> void:
	_map = map
	_sprites_shown = sprites
	_changed_cells.clear()
	_changed_backs.clear()
	_sky_color = _wanted_sky_color()
	_showing_scaled = _settings.graphics == DisplaySettings.Graphics.XBRZ and _scaled_ready()
	_stand_ins = false
	_galaxy_map.show_map(
		map,
		_data.tile_info,
		_atlas(GalaxyMap.Layer.BACKGROUND, _tiles_of(GalaxyMap.Layer.BACKGROUND)),
		_atlas(GalaxyMap.Layer.FOREGROUND, _tiles_of(GalaxyMap.Layer.FOREGROUND))
	)
	_objects.use_graphics(_data.graphics, _scaled if _showing_scaled else null)
	_apply_graphics()
	_apply_backdrop()


## Switches to the graphics the settings ask for: the original ones, or
## xBRZ once the worker threads have made it for this level.
func _apply_graphics() -> void:
	if _map == null:
		return
	var want_scaled := _settings.graphics == DisplaySettings.Graphics.XBRZ
	if want_scaled and not _scaled_ready():
		if _scaled.is_busy() and not _showing_scaled:
			_show_message("Preparing %s..." % GRAPHICS_TITLES[_settings.graphics])
		return
	if want_scaled != _showing_scaled or (want_scaled and _stand_ins):
		_showing_scaled = want_scaled
		_rebuild_atlases()
		_objects.use_graphics(_data.graphics, _scaled if want_scaled else null)
		_fit_screen()


## Shows the picture behind the level when the settings want it and the
## level has sky; the sky then leaves the tiles. Otherwise the level looks
## as in the original.
func _apply_backdrop() -> void:
	var picture: Texture2D = null
	if _backdrops != null and _map != null and _settings.shows_backgrounds():
		picture = _backdrops.picture_for(_map)
	_backdrop_picture = picture
	_backdrop.show_picture(picture, _playable_pixels())
	_backdrop_2.show_picture(picture, _playable_pixels())
	_frame_view()
	var color := _wanted_sky_color() if picture != null else Color.TRANSPARENT
	if color != _sky_color:
		_sky_color = color
		_rebuild_atlases()
	_update_sky_patch()


## The holes in a floor keep the sky's colour (as where Keen 4's level 9
## has glass columns in the walkway): the picture shows everywhere else
## (D13.2). The cells changed since the map was shown keep what was
## worked out for them then.
func _update_sky_patch() -> void:
	if _sky_color.a == 0.0 or _map == null:
		_sky_patch.show_rows([], Color.TRANSPARENT)
		return
	var key := "%d %s" % [_map.number, _sky_color.to_html()]
	if not _sky_pockets.has(key):
		var walkable := func(tile: int) -> bool:
			return _data.tile_info.fore(GalaxyTileInfo.Fore.TOP, tile) != 0
		var is_pole := func(tile: int) -> bool:
			return _data.tile_info.misc_kind(tile) == GalaxyTileKinds.POLE
		_sky_pockets[key] = _backdrops.kept_sky(
			_map, _cleared_back, _data.graphics.fore_tile, walkable, is_pole
		)
	var rows: Array[Rect2i] = []
	for row: Rect2i in _sky_pockets[key]:
		if not _changed_cells.has(row.position / GalaxyGraphics.TILE16_SIZE):
			rows.append(row)
	for cell in _changed_cells:
		rows.append_array(_changed_cells[cell])
	_sky_patch.show_rows(rows, _sky_color)


## Puts [param tile] in [param cell] of [param layer] while the map is
## played, and works out what shows behind the cell then.
func _place_tile(layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	var before := _tiles_at(cell)
	_galaxy_map.set_tile(layer, cell, tile)
	if layer == GalaxyMap.Layer.BACKGROUND:
		_changed_backs[cell] = true
	_keep_sky_in(cell, before)


## What shows behind [param cell] after a tile there changed (it held
## the tiles [param before]: background, foreground). An item taken (its
## foreground tile gone, the background the map's own) leaves what is
## around it: a revealed part shows the picture when it is joined to the
## picture ([GalaxyRevealedSky], E12.1: the cell kept the sky's colour as
## a square before). Any other tile placed while the map is played (the
## QED breaking, a bridge, a door) keeps the sky's colour in its whole
## cell, so that what the original shows black there stays black and the
## picture never shows through a change the open-sky rule has not looked
## at (milestone E12: the broken QED showed the picture in its window).
## Only with the picture shown; in 4:3 or without pictures nothing is
## painted.
func _keep_sky_in(cell: Vector2i, before: Vector2i) -> void:
	if _sky_color.a == 0.0 or _map == null:
		return
	var size := GalaxyGraphics.TILE16_SIZE
	var rows: Array[Rect2i] = [Rect2i(cell * size, Vector2i(size, size))]
	var fore := _map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y)
	if fore == GalaxyTileKinds.EMPTY_TILE and not _changed_backs.has(cell):
		rows = _kept_after_taking(cell, before)
	_changed_cells[cell] = rows
	_update_sky_patch()


## The rows of [param cell] that keep the sky's colour once the item drawn
## there (the tiles [param before]) is gone.
func _kept_after_taking(cell: Vector2i, before: Vector2i) -> Array[Rect2i]:
	var size := GalaxyGraphics.TILE16_SIZE
	var painted := _painted_around(cell)
	var old := _mask_of(before.x, before.y)
	var corner := cell * size
	var showed := func(index: int) -> bool:
		var pixel := corner + Vector2i(index % size, index / size)
		return not old.is_empty() and old[index] == 1 and not painted.has(pixel)
	var shows := func(pixel: Vector2i) -> bool:
		var at := pixel / size
		if pixel.x < 0 or pixel.y < 0 or at.x >= _map.width or at.y >= _map.height:
			return false
		var tiles := _tiles_at(at)
		var mask := _mask_of(tiles.x, tiles.y)
		var index := (pixel.y % size) * size + pixel.x % size
		return not mask.is_empty() and mask[index] == 1 and not painted.has(pixel)
	var now := _tiles_at(cell)
	return GalaxyRevealedSky.kept_rows(cell, _mask_of(now.x, now.y), showed, shows)


## The tiles in [param cell]: background (x) and foreground (y).
func _tiles_at(cell: Vector2i) -> Vector2i:
	return Vector2i(
		_map.tile(GalaxyMap.Layer.BACKGROUND, cell.x, cell.y),
		_map.tile(GalaxyMap.Layer.FOREGROUND, cell.x, cell.y)
	)


## The see-through pixels of a cell holding background [param back] and
## foreground [param fore] ([method GalaxySkyPockets.see_through]).
func _mask_of(back: int, fore: int) -> PackedByteArray:
	var fore_image: Image = _data.graphics.fore_tile(fore) if fore != 0 else null
	return GalaxySkyPockets.see_through(_cleared_back(back), fore_image)


## The level pixels painted in the sky's colour now in [param cell] and
## the cells around it.
func _painted_around(cell: Vector2i) -> Dictionary[Vector2i, bool]:
	var size := GalaxyGraphics.TILE16_SIZE
	var area := Rect2i((cell - Vector2i.ONE) * size, Vector2i(size, size) * 3)
	var painted: Dictionary[Vector2i, bool] = {}
	for row in _sky_patch.rows():
		var inside := row.intersection(area)
		for x in range(inside.position.x, inside.end.x):
			for y in range(inside.position.y, inside.end.y):
				painted[Vector2i(x, y)] = true
	return painted


## Background tile [param tile] with its sky cleared, or null.
func _cleared_back(tile: int) -> Image:
	var image := _data.graphics.back_tile(tile)
	return _cleared(tile, image) if image != null else null


func _apply_display_settings() -> void:
	super()
	_frame_view()


## Scaled graphics are drawn smoothly; the shared code only knows Keen
## 1-3's.
func _fit_screen() -> void:
	super()
	if _showing_scaled:
		for viewport: SubViewport in [_world, _world_2]:
			viewport.canvas_item_default_texture_filter = (
				Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
			)


## Puts the camera node where [member _galaxy_camera] has the view, widened
## in widescreen and kept inside the area between the scroll blocks: in
## the original's 2-pixel steps, or on whole pixels with smooth motion
## (which draws the sprites at their exact places too).
func _frame_view() -> void:
	if _galaxy_camera == null or _cover == null:
		return
	var view_size := _settings.game_size()
	var exact := _settings.smooth_motion
	var top_left := Vector2i(
		_galaxy_camera.wide_view_left(view_size.x, exact), _galaxy_camera.view_pixels().y
	)
	_camera_anchor.position = Vector2(top_left) + Vector2(view_size) / 2.0
	_camera.reset_smoothing()
	_update_backdrops()
	var view := Rect2i(top_left, view_size)
	var picture_rect := Rect2()
	if _backdrop_picture != null:
		picture_rect = LevelBackdrop.picture_rect(
			_backdrop_picture.get_size(),
			_playable_pixels(),
			Vector2(view.get_center()),
			Vector2(view_size)
		)
		picture_rect.position += Vector2(top_left)
	_cover.cover(_galaxy_camera.area_pixels(), view, _backdrop_picture, picture_rect)


## The sky colour the picture behind [member _map] would replace; the
## level's sky tile decides.
func _wanted_sky_color() -> Color:
	var tile := _backdrops.sky_tile(_map) if _backdrops != null and _map != null else -1
	var image := _data.graphics.back_tile(tile) if tile >= 0 else null
	return image.get_pixel(0, 0) if image != null else Color.TRANSPARENT


## The map inside its border, in pixels: what the original can show.
func _playable_pixels() -> Rect2:
	if _map == null:
		return Rect2()
	var border := Vector2i(GalaxyCamera.BORDER_TILES, GalaxyCamera.BORDER_TILES)
	var size := Vector2i(_map.width, _map.height) - 2 * border
	return Rect2(
		Vector2(border * GalaxyCamera.TILE_PIXELS), Vector2(size * GalaxyCamera.TILE_PIXELS)
	)


## Whether the xBRZ graphics of the map shown are there; starts making
## them when not.
func _scaled_ready() -> bool:
	if _map == null:
		return false
	return _scaled.prepare(
		_tiles_of(GalaxyMap.Layer.BACKGROUND), _tiles_of(GalaxyMap.Layer.FOREGROUND), _sprites_shown
	)


## The tiles of [param layer] that [member _map] needs now.
func _tiles_of(layer: GalaxyMap.Layer) -> PackedInt32Array:
	if _galaxy_map.map == _map:
		return _galaxy_map.wanted_tiles(layer)
	return GalaxyLevelMap.tiles_of(_map, _data.tile_info, layer)


func _rebuild_atlases() -> void:
	if _galaxy_map.map == null:
		return
	_stand_ins = false
	_galaxy_map.use_atlases(
		_atlas(GalaxyMap.Layer.BACKGROUND, _galaxy_map.wanted_tiles(GalaxyMap.Layer.BACKGROUND)),
		_atlas(GalaxyMap.Layer.FOREGROUND, _galaxy_map.wanted_tiles(GalaxyMap.Layer.FOREGROUND))
	)


## A switch or a gem put tiles the atlases lack: with xBRZ they get stand-ins
## until they are scaled ([method _apply_graphics] then builds them again),
## so the level does not flash back to the original graphics (D11).
func _on_tiles_missing(_layer: GalaxyMap.Layer) -> void:
	if _showing_scaled:
		_scaled_ready()
	_rebuild_atlases()


## The atlas of [param tiles] of [param layer] in the graphics shown now,
## with the sky left out when a picture is behind the level.
func _atlas(layer: GalaxyMap.Layer, tiles: PackedInt32Array) -> GalaxyTileAtlas:
	var images: Dictionary[int, Image] = {}
	var scaled: Dictionary[int, Image] = {}
	var back := layer == GalaxyMap.Layer.BACKGROUND
	for tile in tiles:
		var image := _data.graphics.back_tile(tile) if back else _data.graphics.fore_tile(tile)
		if image == null:
			continue
		if back and _sky_color.a > 0.0:
			image = _cleared(tile, image)
		images[tile] = image
		if _showing_scaled:
			var big := _scaled.back_tile(tile) if back else _scaled.fore_tile(tile)
			if big != null and back and _sky_color.a > 0.0:
				big = GalaxyBackdropPictures.with_holes_of(big, image)
			if big == null:
				big = _stand_in(image)
			scaled[tile] = big
	return GalaxyTileAtlas.build(images, scaled, _scaled.factor)


## Tile [param image] made larger without smoothing, in place of its xBRZ
## version while that is being made.
func _stand_in(image: Image) -> Image:
	_stand_ins = true
	var big := image.duplicate() as Image
	big.resize(
		image.get_width() * _scaled.factor,
		image.get_height() * _scaled.factor,
		Image.INTERPOLATE_NEAREST
	)
	return big


## Background tile [param tile] with the sky colour made see-through, kept
## for the next time.
func _cleared(tile: int, image: Image) -> Image:
	if _cleared_color != _sky_color:
		_cleared_tiles.clear()
		_cleared_color = _sky_color
	if not _cleared_tiles.has(tile):
		_cleared_tiles[tile] = _backdrops.clear_tile(image, _sky_color)
	return _cleared_tiles[tile]
