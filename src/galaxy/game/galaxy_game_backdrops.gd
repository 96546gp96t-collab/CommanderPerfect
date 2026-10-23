class_name GalaxyGameBackdrops
extends GalaxyBackdropPictures
## The pictures behind the levels as the Galaxy game ([GalaxyLevelScreen])
## shows them: [GalaxyBackdropPictures] with two hooks an episode can
## override (milestone E10). By default they do what Keen 4 does: a
## background tile loses the sky's colour wherever that touches its edge,
## and the holes in a floor keep the sky's colour ([GalaxySkyPockets]).
## Keen 5's space is black, a colour its station draws with too, so it
## clears less and keeps more ([Keen5BackdropPictures]).


## The pictures for [param files] by the episode's [param rules]: its own
## folder, its sky tiles and its levels.
static func for_rules(files: GameFiles, rules: GalaxyGameRules) -> GalaxyGameBackdrops:
	var pictures := GalaxyGameBackdrops.new()
	pictures.set_up(files, rules)
	return pictures


## Fills in what [method GalaxyBackdropPictures.for_episode] does, for a
## subclass made with its own [code]new()[/code].
func set_up(files: GameFiles, rules: GalaxyGameRules) -> void:
	_files = files
	_folder = rules.backdrop_folder
	_sky_tiles = rules.sky_tiles
	_first_level = rules.first_level
	_last_level = rules.last_level


## Background tile [param image] with the sky of [param color] made
## see-through where the picture may show.
func clear_tile(image: Image, color: Color) -> Image:
	return cleared(image, color)


## The see-through pixels of [param map] that keep the sky's colour, as
## one-pixel-high rows in level pixels ([method GalaxySkyPockets.find]
## explains the arguments).
func kept_sky(
	map: GalaxyMap, back_image: Callable, fore_image: Callable, walkable: Callable
) -> Array[Rect2i]:
	return GalaxySkyPockets.find(map, back_image, fore_image, walkable)
