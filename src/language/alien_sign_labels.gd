class_name AlienSignLabels
extends Node2D
## The translations of the signs in the alien alphabet, in level pixels:
## when the option is on and a player's Keen comes close to a sign, a small
## plate with what it says (in the language in use, [method Lang.alien])
## fades in above it (only for the sign closest to him), and fades out
## when he walks on. The sign itself stays as it is. Lives in the World
## viewport, so both views of the split screen show it and the camera moves
## it with the level.
##
## What it needs comes from the game screen as callables, so that every
## game can give its own: [member level] (what is shown now; the signs are
## found again when it changes), [member find_signs], [member readers] (the
## middles of the players' Keens) and [member make_plate] (the plate of some
## lines in the game's own font).

## How far from a sign Keen may be, in pixels, for its plate to show.
const NEAR := Vector2(48.0, 40.0)
const FADE_SECONDS := 0.25
const CELL := 16
## Pixels between a plate and its sign.
const GAP := 2
## Longest line on a plate, in characters.
const LINE_LENGTH := 18

## Whether translations are shown (the player's option).
var is_on: Callable = func() -> bool: return false
## The level or map shown now (any object); null when none is.
var level: Callable = func() -> Object: return null
## The signs of what [member level] gives ([AlienSigns.Sign]).
var find_signs: Callable = func() -> Array[AlienSigns.Sign]: return []
## The middles of the players' Keens, in level pixels.
var readers: Callable = func() -> Array[Vector2]: return []
## The plate (an Image) for some lines of text.
var make_plate: Callable

var _level: Object = null
var _signs: Array[AlienSigns.Sign] = []
var _plates: Array[Sprite2D] = []
var _language := ""


func _process(delta: float) -> void:
	var shown: Object = level.call() if is_on.call() else null
	if shown != _level:
		_level = shown
		_show(find_signs.call() if shown != null else ([] as Array[AlienSigns.Sign]))
	if _signs.is_empty():
		return
	if Lang.code() != _language:
		_make_plates()
	var wanted := _nearest_signs(readers.call())
	var step := delta / FADE_SECONDS
	for index in _signs.size():
		var plate := _plates[index]
		plate.modulate.a = move_toward(plate.modulate.a, 1.0 if wanted.has(index) else 0.0, step)
		plate.visible = plate.modulate.a > 0.0


## The signs now shown; for tests.
func signs() -> Array[AlienSigns.Sign]:
	return _signs


## Whether the plate of sign [param index] shows (at all); for tests.
func is_showing(index: int) -> bool:
	return index < _plates.size() and _plates[index].visible


## [param text] in lines of at most [constant LINE_LENGTH] characters, split
## between words; new lines in a translation are kept.
static func wrap_lines(text: String) -> PackedStringArray:
	var lines := PackedStringArray()
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" ", false):
			if not line.is_empty() and line.length() + 1 + word.length() > LINE_LENGTH:
				lines.append(line)
				line = ""
			line += (" " if not line.is_empty() else "") + word
		lines.append(line)
	return lines


func _show(found: Array[AlienSigns.Sign]) -> void:
	for plate in _plates:
		plate.queue_free()
	_plates.clear()
	_signs = found
	for sign in _signs:
		var plate := Sprite2D.new()
		plate.centered = false
		plate.visible = false
		plate.modulate.a = 0.0
		add_child(plate)
		_plates.append(plate)
	_make_plates()


func _make_plates() -> void:
	_language = Lang.code()
	if make_plate.is_null():
		return
	for index in _signs.size():
		var sign := _signs[index]
		var image: Image = make_plate.call(wrap_lines(Lang.alien(sign.text)))
		var plate := _plates[index]
		plate.texture = ImageTexture.create_from_image(image)
		var size := Vector2(image.get_size())
		var area := _area(sign)
		var at := Vector2(area.get_center().x - size.x / 2.0, area.position.y - size.y - GAP)
		if at.y < 0.0:
			at.y = area.end.y + GAP
		plate.position = at.round()


## For each of [param near_keens] the sign closest to him, if one is near
## enough: only that one shows, so that plates of signs close together do
## not cover each other.
func _nearest_signs(near_keens: Array[Vector2]) -> Dictionary[int, bool]:
	var nearest: Dictionary[int, bool] = {}
	for keen in near_keens:
		var best := -1
		var best_distance := INF
		for index in _signs.size():
			var area := _area(_signs[index])
			var reach := area.grow_individual(NEAR.x, NEAR.y, NEAR.x, NEAR.y)
			if not reach.has_point(keen):
				continue
			var distance := keen.distance_to(keen.clamp(area.position, area.end))
			if distance < best_distance:
				best = index
				best_distance = distance
		if best >= 0:
			nearest[best] = true
	return nearest


static func _area(sign: AlienSigns.Sign) -> Rect2:
	return Rect2(Vector2(sign.cells.position * CELL), Vector2(sign.cells.size * CELL))
