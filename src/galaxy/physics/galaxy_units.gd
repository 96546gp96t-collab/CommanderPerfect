class_name GalaxyUnits
extends RefCounted
## The Galaxy engine's measures (docs/keen4/research.md §2): positions,
## velocities, hit boxes and sprite origins are integers in **global
## units**, 16 per pixel and 256 per tile; velocities are units per tic
## (1/70 s). Keen 4 keeps them unconverted, so the original's numbers go
## into the code as they are.

const PER_PIXEL := 16
const PER_TILE := 256
## A tile is 16 pixels; a unit position >> this is a tile.
const TILE_SHIFT := 8
## A unit position >> this is a pixel.
const PIXEL_SHIFT := 4
const PIXELS_PER_TILE := 16


## The tile that unit position [param units] lies in (also below 0).
static func to_tile(units: int) -> int:
	return units >> TILE_SHIFT


## The pixel that unit position [param units] lies in.
static func to_pixel(units: int) -> int:
	return units >> PIXEL_SHIFT


## The first unit of tile [param tile].
static func from_tile(tile: int) -> int:
	return tile * PER_TILE


## [param pixels] in units.
static func from_pixels(pixels: int) -> int:
	return pixels * PER_PIXEL
