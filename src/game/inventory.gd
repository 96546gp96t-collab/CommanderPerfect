class_name Inventory
extends RefCounted
## What Keen carries from level to level: score, lives, raygun charges, the
## pogo stick and ship parts. Keycards only count inside the current level.
##
## Ship parts picked up in a level are lost again when Keen dies before he
## leaves it, so that dying cannot be used to keep a part.

enum ShipPart { JOYSTICK, BATTERY, VACUUM, WHISKEY }

const START_LIVES := 4
## Keen gets an extra life every time his score passes another multiple.
const EXTRA_LIFE_EVERY := 20000
## Charges in one raygun found in a level.
const RAYGUN_CHARGES := 5
const SHIP_PART_POINTS := 10000
## Charges the item cheat gives.
const CHEAT_CHARGES := 99

var score := 0
var lives := START_LIVES
var charges := 0
var has_pogo := false
var keycards: Array[bool] = [false, false, false, false]
var ship_parts: Array[bool] = [false, false, false, false]
var _next_extra_life := EXTRA_LIFE_EVERY
var _parts_this_level: Array[bool] = [false, false, false, false]


func add_points(points: int) -> void:
	score += points
	while score >= _next_extra_life:
		lives += 1
		_next_extra_life += EXTRA_LIFE_EVERY


## The score at which Keen gets his next extra life.
func next_extra_life() -> int:
	return _next_extra_life


## Gives Keen everything at once (the cheat): all keycards, the pogo stick
## and a full raygun.
func give_everything() -> void:
	keycards.fill(true)
	has_pogo = true
	charges = maxi(charges, CHEAT_CHARGES)


func add_ship_part(part: ShipPart) -> void:
	if not ship_parts[part]:
		_parts_this_level[part] = true
	ship_parts[part] = true
	add_points(SHIP_PART_POINTS)


## Whether Keen has found every part of his ship: then he can fly home.
func has_all_ship_parts() -> bool:
	return not ship_parts.has(false)


func has_keycard(color: TileProperties.KeyColor) -> bool:
	return keycards[color]


## Starts a level: keycards from the previous level are gone.
func enter_level() -> void:
	keycards.fill(false)
	_parts_this_level.fill(false)


## Keen died: one life less, and the ship parts found in this level are lost.
func lose_life() -> void:
	lives -= 1
	for part in ship_parts.size():
		if _parts_this_level[part]:
			ship_parts[part] = false
	_parts_this_level.fill(false)


## Whether the game is over: Keen died with no lives left.
func is_game_over() -> bool:
	return lives < 0
