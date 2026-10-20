class_name Keen4LevelScreen
extends GameScreen
## How a Keen 4 level is drawn on the shared [GameScreen] ([Keen4View]
## extends it with what happens): the World viewport stretched over the
## window, the keys F1-F6, and on top of that the Galaxy drawing:
##   - the map's three tile layers ([GalaxyLevelMap]) with their animation,
##     from atlases of only the tiles the level shows ([GalaxyTileAtlas]);
##   - the sprites ([GalaxyObjectLayer]);
##   - the original graphics or xBRZ ([GalaxyScaledGraphics], F5), made
##     on worker threads for each level the first time;
##   - the camera node put where [GalaxyCamera] says, widened in
##     widescreen, with what lies beyond the area between the scroll
##     blocks covered ([GalaxyViewCover]);
##   - the picture behind the level, in widescreen, when the option is on
##     and the level has sky ([GalaxyBackdropPictures]).
## The node layout is [code]level_view.tscn[/code]'s, as Keen 2 and 3 copy
## it ([GameScreen] finds its nodes by name); Keen 1-3's nodes (LevelMap,
## Keen, ActorLayer, ...) stay empty and hidden.

const MISSING_DATA_MESSAGE := (
	"Keen 4 data not found. Put the files in game_data/keen4 "
	+ "or start with: -- --data-dir-keen4=PATH"
)
const UNREADABLE_MESSAGE := "The Keen 4 files in %s could not be read."

## The Keen 4 files. Found with [method Keen4Files.locate] unless they are
## set before the view enters the tree.
var files: GameFiles
var _data: GalaxyData
## The map on the screen; null before one is shown.
var _map: GalaxyMap
var _galaxy_camera: GalaxyCamera
var _scaled: GalaxyScaledGraphics
var _backdrops: GalaxyBackdropPictures
## The colour of the sky that the picture behind the level replaces;
## transparent while no picture is shown.
var _sky_color := Color.TRANSPARENT
## Whether the atlases and sprites now show xBRZ graphics.
var _showing_scaled := false
## Background tiles with their sky made see-through, by tile.
var _cleared_tiles: Dictionary[int, Image] = {}
var _cleared_color := Color.TRANSPARENT
## The sprites a level draws, for xBRZ.
var _sprites_shown := PackedInt32Array()
## The picture behind the level shown now, or null.
var _backdrop_picture: Texture2D

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
	_apply_display_settings()


## Reads the Keen 4 files. Returns whether that worked; otherwise the
## screen says why.
func _load_data() -> bool:
	if files == null:
		files = Keen4Files.locate()
	if files == null:
		_show_error(MISSING_DATA_MESSAGE)
		return false
	_data = Keen4Episode.load_data(files)
	if _data == null:
		_show_error(UNREADABLE_MESSAGE % files.directory)
		return false
	_scaled = GalaxyScaledGraphics.create(_data.graphics)
	_backdrops = GalaxyBackdropPictures.for_episode(
		files,
		Keen4Episode.BACKDROP_FOLDER,
		Keen4Episode.SKY_TILES,
		Keen4Episode.FIRST_LEVEL,
		Keen4Episode.LAST_LEVEL
	)
	_objects.use_graphics(_data.graphics)
	return true


## Shows [param map] with its tiles, in the graphics the settings ask for.
## [param sprites] are the sprites it will draw.
func _show_map(map: GalaxyMap, sprites: PackedInt32Array) -> void:
	_map = map
	_sprites_shown = sprites
	_sky_color = _wanted_sky_color()
	_showing_scaled = _settings.graphics == DisplaySettings.Graphics.XBRZ and _scaled_ready()
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
		if _scaled.is_busy():
			_show_message("Preparing %s..." % GRAPHICS_TITLES[_settings.graphics])
		return
	if want_scaled != _showing_scaled:
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
## in widescreen and kept inside the area between the scroll blocks.
func _frame_view() -> void:
	if _galaxy_camera == null or _cover == null:
		return
	var view_size := _settings.game_size()
	var top_left := Vector2i(
		_galaxy_camera.wide_view_left(view_size.x), _galaxy_camera.view_pixels().y
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
	_galaxy_map.use_atlases(
		_atlas(GalaxyMap.Layer.BACKGROUND, _galaxy_map.wanted_tiles(GalaxyMap.Layer.BACKGROUND)),
		_atlas(GalaxyMap.Layer.FOREGROUND, _galaxy_map.wanted_tiles(GalaxyMap.Layer.FOREGROUND))
	)


func _on_tiles_missing(_layer: GalaxyMap.Layer) -> void:
	if _showing_scaled and not _scaled_ready():
		# Original tiles until the new ones are scaled.
		_showing_scaled = false
		_objects.use_graphics(_data.graphics)
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
			if big != null:
				scaled[tile] = big
	if scaled.size() != images.size():
		scaled.clear()
	return GalaxyTileAtlas.build(images, scaled, _scaled.factor)


## Background tile [param tile] with the sky colour made see-through, kept
## for the next time.
func _cleared(tile: int, image: Image) -> Image:
	if _cleared_color != _sky_color:
		_cleared_tiles.clear()
		_cleared_color = _sky_color
	if not _cleared_tiles.has(tile):
		_cleared_tiles[tile] = GalaxyBackdropPictures.cleared(image, _sky_color)
	return _cleared_tiles[tile]
