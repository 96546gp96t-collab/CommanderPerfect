class_name GalaxyEga
extends RefCounted
## Small helpers for drawing with the EGA's colour numbers where the
## original does arithmetic on them: finding the number of a decoded colour,
## and the XOR the original's text printing does with what is under it (the
## status window's labels, the high-score names).

const COLOR_COUNT := 16


## The EGA number (0-15) of [param color]; -1 for a colour that is none of
## them (or a see-through pixel).
static func index_of(color: Color) -> int:
	if color.a < 0.5:
		return -1
	var wanted := color.to_rgba32() | 0xFF
	for index in COLOR_COUNT:
		if EgaPalette.color(index).to_rgba32() == wanted:
			return index
	return -1


## [param color] with its EGA number XORed with [param mask].
static func xor(color: Color, mask: int) -> Color:
	var index := index_of(color)
	return EgaPalette.color((maxi(index, 0) ^ mask) & (COLOR_COUNT - 1))
