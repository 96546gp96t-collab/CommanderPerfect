class_name Keen3TypedBoxes
extends RefCounted
## Boxes whose text is typed letter by letter, one box after another, each
## followed by a pause: Mortimer's messages in level 16 ([Keen3Mortimer])
## and the boxes of the ending ([Keen3Ending]). The original counts in VGA
## retraces (70.086 a second) and types a letter every
## [constant LETTER_RETRACES] (Choco). Every character of a line counts as a
## letter, its trailing spaces from KEEN3.EXE too, and so does the end of
## every line ([constant LINE_END_LETTERS]): seen in the original (C11),
## where the ending's pages took one letter time per stored character and
## line end (a line of 31 letters and 7 trailing spaces waited 9 letter
## times before the next line). Only the logic is here: the view draws
## [method current] with [method visible_lines].

## Emitted when another letter is shown or another box begins.
signal changed

const RETRACES_PER_SECOND := 70.086
## 6 retraces per letter (Choco; seen in the original, C11: 85.6 ms).
const LETTER_RETRACES := 6.0
## The end of a line takes a letter's time too (seen in the original, C11).
const LINE_END_LETTERS := 1
## Times that add up to a whole number of retraces are taken as reached
## within this much (seconds turned into retraces are not exact).
const TIME_TOLERANCE := 0.001


## One box: its lines, where its frame's top left is (in 8-pixel text cells
## of the 320x200 picture), the size of its inside (in cells) and the pause
## after it is typed.
class Box:
	extends RefCounted
	var lines := PackedStringArray()
	var cell := Vector2i.ZERO
	var size := Vector2i.ONE
	var pause_retraces := 0.0

	## How many letter times typing takes: every character and every line
	## end.
	func letter_count() -> int:
		var count := 0
		for line in lines:
			count += line.length() + LINE_END_LETTERS
		return count


var boxes: Array[Box] = []
## The box being typed or waited after; [code]boxes.size()[/code] when all
## are done.
var index := 0
## Letters of the current box shown so far.
var typed := 0
var _time := 0.0


## Adds a box with [param lines] whose frame starts at [param cell], at
## least [param size] cells inside (more when a line is longer; its trailing
## spaces do not count), followed by
## [param pause_retraces].
func add(lines: PackedStringArray, cell: Vector2i, size: Vector2i, pause_retraces: float) -> void:
	var box := Box.new()
	box.lines = lines
	box.cell = cell
	box.size = size
	for line in lines:
		box.size.x = maxi(box.size.x, line.strip_edges(false, true).length())
	box.size.y = maxi(box.size.y, lines.size())
	box.pause_retraces = pause_retraces
	boxes.append(box)


## The box on the screen, or null when all are done.
func current() -> Box:
	return boxes[index] if index < boxes.size() else null


func is_finished() -> bool:
	return index >= boxes.size()


## Whether the current box is fully typed (its pause runs).
func is_pausing() -> bool:
	var box := current()
	return box != null and typed >= box.letter_count()


## The lines of the current box as far as they are typed.
func visible_lines() -> PackedStringArray:
	var shown := PackedStringArray()
	var box := current()
	if box == null:
		return shown
	var left := typed
	for line in box.lines:
		shown.append(line.left(clampi(left, 0, line.length())))
		left -= line.length() + LINE_END_LETTERS
	return shown


## Goes on for [param seconds]: letters, pauses, the next box.
func advance(seconds: float) -> void:
	_time += seconds * RETRACES_PER_SECOND
	var moved := false
	while not is_finished():
		var box := current()
		var typing := typed < box.letter_count()
		var needed := LETTER_RETRACES if typing else box.pause_retraces
		if _time < needed - TIME_TOLERANCE:
			break
		_time -= needed
		moved = true
		if typing:
			typed += 1
		else:
			index += 1
			typed = 0
	if moved:
		changed.emit()


## Skips every box that is left.
func finish() -> void:
	if is_finished():
		return
	index = boxes.size()
	typed = 0
	changed.emit()


## How long all boxes take, in seconds.
func total_seconds() -> float:
	var retraces := 0.0
	for box in boxes:
		retraces += box.letter_count() * LETTER_RETRACES + box.pause_retraces
	return retraces / RETRACES_PER_SECOND
