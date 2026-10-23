class_name Keen5BackdropPictures
extends GalaxyGameBackdrops
## The pictures behind Keen 5's levels and its world map (ours, milestone
## E10; an extra, widescreen only, on by default; docs/keen5/gameplay.md
## "Pictures behind the levels"). Keen 5 plays inside the Omegamatic: its
## walls and floors are drawn in front, its back walls are patterns, never
## one plain colour. The only plain background is outside: black space
## (tile 0, with the star tiles in it) and Korath III's light cyan sky
## (tile 105). So a map shows a picture when it has open sky somewhere,
## not only in its top row as Keen 4's rule wants: sky or space at the
## edge of what the view shows (the outside), or an open-sky tile with
## nothing in front: Korath III's sky, or stars (the station's windows to
## space). The world map (map 0) gets one as well, in the space around the
## station. Where the picture shows within such a map is [Keen5OpenSky]'s
## rule.

var _world_map := 0
var _open_tiles := PackedInt32Array()


## The pictures for [param files] by Keen 5's [param rules], with
## [param open_tiles] the background tiles that are open sky
## ([constant Keen5Episode.OPEN_SKY_TILES]).
static func with_open_tiles(
	files: GameFiles, rules: GalaxyGameRules, open_tiles: PackedInt32Array
) -> GalaxyGameBackdrops:
	var pictures := Keen5BackdropPictures.new()
	pictures.set_up(files, rules)
	pictures._world_map = rules.world_map
	pictures._open_tiles = open_tiles
	return pictures


## The sky tile of [param map]: the plain sky tile it uses most (space
## when it has none: a window may be drawn with star tiles only), when the
## map has open sky; otherwise -1.
func sky_tile(map: GalaxyMap) -> int:
	if map == null or not _may_show(map.number) or _sky_tiles.is_empty():
		return -1
	var counts: Dictionary[int, int] = {}
	var has_open := false
	var inside := Keen5OpenSky.inside(map)
	for y in map.height:
		for x in map.width:
			var tile := map.tile(GalaxyMap.Layer.BACKGROUND, x, y)
			if _sky_tiles.has(tile):
				counts[tile] = counts.get(tile, 0) + 1
			if has_open or map.tile(GalaxyMap.Layer.FOREGROUND, x, y) != 0:
				continue
			has_open = (
				_open_tiles.has(tile)
				or (_sky_tiles.has(tile) and not inside.has_point(Vector2i(x, y)))
			)
	if not has_open:
		return -1
	var best := _sky_tiles[0]
	for tile in counts:
		if not counts.has(best) or counts[tile] > counts[best]:
			best = tile
	return best


func clear_tile(image: Image, color: Color) -> Image:
	return Keen5OpenSky.cleared(image, color)


## The holes in a floor (Keen 4's rule) and everything see-through that is
## not joined to the open sky keep the sky's colour.
func kept_sky(
	map: GalaxyMap, back_image: Callable, fore_image: Callable, walkable: Callable
) -> Array[Rect2i]:
	var rows := super(map, back_image, fore_image, walkable)
	rows.append_array(Keen5OpenSky.closed(map, back_image, fore_image, _open_tiles))
	return rows


func _may_show(number: int) -> bool:
	return number == _world_map or (number >= _first_level and number <= _last_level)
