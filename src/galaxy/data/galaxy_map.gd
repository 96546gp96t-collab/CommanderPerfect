class_name GalaxyMap
extends RefCounted
## One map of GAMEMAPS: its name, its size in tiles and its three planes,
## each one 16-bit value per tile. See docs/keen4/file-formats.md.

## The three planes ("Plane" is a Godot type, hence "Layer").
enum Layer { BACKGROUND, FOREGROUND, INFO }

const PLANE_COUNT := 3

## The map's slot in MAPHEAD (0 is the world map in Keen 4).
var number := 0
## The name in the file (not always the name the game shows).
var name := ""
var width := 0
var height := 0
## One array per [enum Layer], row by row.
var planes: Array[PackedInt32Array] = []


## The value of plane [param layer] at tile ([param x], [param y]); 0
## outside the map.
func tile(layer: Layer, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= width or y >= height or layer >= planes.size():
		return 0
	return planes[layer][y * width + x]
