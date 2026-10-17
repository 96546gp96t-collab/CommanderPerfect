class_name Keen2Icons
extends RefCounted
## The tiles that the [Hud] draws for the raygun and the keycards in Keen 2.
## Keen 1 has their numbers fixed ([StatusScreen]); here they are looked up
## in the tile properties: the first tile that behaves as that item, which
## is the picture Keen picks up in the levels, as Keen 1's HUD shows. In
## version 1.31 these are 175 (raygun) and 190-193 (keycards), the same
## numbers as Keen 1. The status screen has its own icons (414 and 424-427,
## docs/keen2/research.md section 6).


## The raygun's tile, or -1 when no tile is a raygun.
static func raygun(properties: TileProperties) -> int:
	return first_tile_with(properties, TileProperties.Behavior.RAYGUN)


## The keycards' tiles, in the order of [enum TileProperties.KeyColor]; -1
## for a color that no tile has.
static func keycards(properties: TileProperties) -> PackedInt32Array:
	var tiles := PackedInt32Array()
	for color in TileProperties.KeyColor.size():
		tiles.append(first_tile_with(properties, TileProperties.Behavior.KEYCARD_YELLOW + color))
	return tiles


## The first tile with behaviour [param behavior], or -1.
static func first_tile_with(properties: TileProperties, behavior: int) -> int:
	for tile in properties.tile_count:
		if properties.behavior(tile) == behavior:
			return tile
	return -1
