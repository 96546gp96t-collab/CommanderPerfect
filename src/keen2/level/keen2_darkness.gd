class_name Keen2Darkness
extends CanvasModulate
## Darkens the picture of a Keen 2 level while its lights are off
## ([method Keen2LevelSession.is_dark]). [Keen2View] puts it into the World
## viewport, where it tints everything drawn on the level's own canvas: the
## tiles (original, xBRZ or HD alike, since those are only other textures),
## Keen and the other sprites, in widescreen as well. The HUD and the
## windows sit on a CanvasLayer of their own and stay readable.
##
## How the original looks in the dark is not known: Commander Genius
## darkens the palette, which this copies by dimming every color to
## [constant DARK_BRIGHTNESS]. Milestone B10 compares it with the original.

## How bright the level is in the dark, from 0 (black) to 1 (unchanged).
const DARK_BRIGHTNESS := 0.3  # estimate


func _init() -> void:
	name = "Darkness"
	color = Color(DARK_BRIGHTNESS, DARK_BRIGHTNESS, DARK_BRIGHTNESS)
	visible = false


## Turns the darkness on ([param dark] true) or off.
func set_dark(dark: bool) -> void:
	visible = dark


func is_dark() -> bool:
	return visible
