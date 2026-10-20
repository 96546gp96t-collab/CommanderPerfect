class_name GalaxyStatusDrop
extends RefCounted
## How a Galaxy status window drops into the picture and rises again (Omni
## `ck_play.c`: CK_ShowStatusWindow, CK_ScrollStatusWindow; facts and
## numbers only; seen in the original, D7: down in about 0.3 s):
##   - its bottom starts 16 pixels from the top and moves down 8 pixels a
##     tic until it is 168 pixels down; the game waits for a key;
##   - then it starts again 16 higher and rises 8 a tic until it is gone;
##   - the window hangs with its top 152 pixels above its bottom; the strap
##     above it only shows while the whole window is in the picture, the arm
##     beside it once its bottom is 72 pixels down.
## The pictures and their places come from the episode
## ([Keen4StatusWindow]); this class only counts.

enum Stage { DROPPING, DOWN, RISING, GONE }

const START_BOTTOM := 16
const DOWN_BOTTOM := 168
const RISE_START := DOWN_BOTTOM - 16
const PIXELS_PER_TIC := 8
const WINDOW_HEIGHT := 152
const ARM_FROM := 72

var stage := Stage.DROPPING
## The window's bottom, in pixels from the top of the picture.
var bottom := START_BOTTOM


## Lets [param tics] tics pass.
func advance(tics: int) -> void:
	match stage:
		Stage.DROPPING:
			bottom = mini(bottom + tics * PIXELS_PER_TIC, DOWN_BOTTOM)
			if bottom == DOWN_BOTTOM:
				stage = Stage.DOWN
		Stage.RISING:
			bottom = maxi(bottom - tics * PIXELS_PER_TIC, 0)
			if bottom == 0:
				stage = Stage.GONE


## A key was pressed: once it is down, it rises.
func release() -> void:
	if stage == Stage.DOWN:
		stage = Stage.RISING
		bottom = RISE_START


func is_gone() -> bool:
	return stage == Stage.GONE


## How far the window (and its hangers) are moved from where they are when
## it is down, in pixels (0 or less).
func shift() -> int:
	return bottom - DOWN_BOTTOM


## Whether the strap above the window shows.
func shows_strap() -> bool:
	return bottom > WINDOW_HEIGHT and stage != Stage.GONE


## Whether the arm beside the window shows.
func shows_arm() -> bool:
	return bottom >= ARM_FROM and stage != Stage.GONE
