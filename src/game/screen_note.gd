class_name ScreenNote
extends Node2D
## A short note in the middle of the view, a little below its top: "Battery
## still missing" in the ship ([ShipVisit]). There is one note at a time; a
## new one takes the place of the old one, which is gone at once. Drawn
## with the game font on a panel like those of the [Hud]. Put the node in a
## CanvasLayer, so that the camera does not move it.

## Seconds a note stays.
const SECONDS := 2.5
## Top of the panel: under the panels of the HUD.
const TOP := 30
const PADDING := 3

## Size of the view in game pixels; the note is centered in it.
var view_size := Vector2i(426, 200)
var _textures: GraphicsTextures
var _text := ""
var _time_left := 0.0


func _ready() -> void:
	set_process(false)


func set_textures(textures: GraphicsTextures) -> void:
	_textures = textures


## Shows [param text], instead of the note shown now.
func show_text(text: String) -> void:
	_text = text
	_time_left = SECONDS
	set_process(true)
	queue_redraw()


## Takes the note away at once.
func clear() -> void:
	_time_left = 0.0
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		clear()


func _draw() -> void:
	if _textures == null or _time_left <= 0.0:
		return
	var width := _text.length() * EgaGraphics.FONT_CHAR_SIZE
	var at := Vector2(roundi((view_size.x - width) / 2.0), TOP + PADDING)
	var box := Rect2(at, Vector2(width, EgaGraphics.FONT_CHAR_SIZE)).grow(PADDING)
	draw_rect(box, Hud.PANEL_COLOR)
	draw_rect(box.grow(1), Hud.OUTLINE_COLOR, false, 1.0)
	_textures.draw_text(self, at, _text, true)
