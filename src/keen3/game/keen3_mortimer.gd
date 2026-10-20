class_name Keen3Mortimer
extends RefCounted
## Mortimer speaks when level 16 starts (Chocolate Keen,
## `CVort3_handle_grand_intellect`; docs/keen3/research.md §9): on the first
## frame, after the level is drawn and before Keen can move, the MORTIMER
## sound plays to its end, then his nine boxes from KEEN3.EXE are typed one
## after another ([Keen3TypedBoxes]), each with its size, its place and its
## pause from [constant BOX_SIZES], [constant BOX_ROWS] and
## [constant PAUSE_RETRACES]. Escape, Space or a button skips the rest
## ([method skip]). Only the logic; [Keen3EndingScreen] draws it and keeps
## the level still until [method is_finished].
##
## A box of w x h cells (its inside) has its frame's top left at column
## 19 - w / 2 and row r - h / 2, where r is the box's middle row: 20 for
## most, 18 for Mortimer's two longer answers.

## The inside of each box, in cells (Choco).
const BOX_SIZES: Array[Vector2i] = [
	Vector2i(5, 1),
	Vector2i(12, 1),
	Vector2i(18, 1),
	Vector2i(38, 5),
	Vector2i(38, 5),
	Vector2i(31, 2),
	Vector2i(35, 4),
	Vector2i(34, 1),
	Vector2i(38, 3),
]
## The middle row of each box (Choco: 20, or 18 for the boxes of type B).
const BOX_ROWS: PackedInt32Array = [20, 20, 20, 20, 20, 20, 18, 20, 18]
## The pause after each box, in retraces (Choco).
const PAUSE_RETRACES: PackedInt32Array = [180, 180, 240, 240, 240, 180, 180, 180, 240]
## The boxes are centred on this column.
const CENTER_COLUMN := 19

var boxes := Keen3TypedBoxes.new()
## Seconds of the MORTIMER sound still to wait.
var sound_left := 0.0
var _skipped := false


## Mortimer with his nine [param messages] (from [Keen3GameData]); the
## sound lasts [param sound_seconds]. Without nine messages only the sound
## is waited for.
static func create(messages: Array[PackedStringArray], sound_seconds: float) -> Keen3Mortimer:
	var mortimer := Keen3Mortimer.new()
	mortimer.sound_left = maxf(sound_seconds, 0.0)
	if messages.size() == BOX_SIZES.size():
		for index in messages.size():
			var size := BOX_SIZES[index]
			mortimer.boxes.add(
				messages[index], box_cell(size, BOX_ROWS[index]), size, PAUSE_RETRACES[index]
			)
	return mortimer


## Where the frame of a box of [param size] cells inside, centred on
## [param middle_row], has its top left (text cells of the 320x200 picture).
static func box_cell(size: Vector2i, middle_row: int) -> Vector2i:
	return Vector2i(CENTER_COLUMN - size.x / 2, middle_row - size.y / 2)


## Goes on for [param seconds]: first the sound, then the boxes.
func advance(seconds: float) -> void:
	if is_finished():
		return
	if sound_left > 0.0:
		var used := minf(seconds, sound_left)
		sound_left -= used
		seconds -= used
		if sound_left > Keen3TypedBoxes.TIME_TOLERANCE / Keen3TypedBoxes.RETRACES_PER_SECOND:
			return
		sound_left = 0.0
	boxes.advance(seconds)


## Skips everything that is left.
func skip() -> void:
	_skipped = true
	sound_left = 0.0
	boxes.finish()


func is_finished() -> bool:
	return _skipped or (sound_left <= 0.0 and boxes.is_finished())


## The box on the screen, or null (while the sound plays, and at the end).
func current_box() -> Keen3TypedBoxes.Box:
	if sound_left > 0.0 or is_finished():
		return null
	return boxes.current()
