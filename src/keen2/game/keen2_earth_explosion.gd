class_name Keen2EarthExplosion
extends RefCounted
## The Earth explodes, on map 81 (docs/keen2/gameplay.md, "The wrong
## switch"). Only the logic, one tick at a time, so that the tests can run
## it; [Keen2View] draws [member actors] and the map, and lets the camera
## follow [method view_center].
##   beam       the Tantalus Ray (sprites 58 and 59 in turn) flies from tile
##              (4, 9) to the right and down until it reaches column 47
##   explosion  steps of [constant STEP_TICKS] ticks: in steps 0-15 an
##              explosion (60-63) bursts somewhere near the Earth and
##              leaves empty space (tile 155) behind, but not on the Earth; step 5 throws ten small
##              chunks (68/70) every way, steps 6-8 one more each; step 10
##              four big chunks (64/66) fly off diagonally and the Earth's
##              3x3 tiles at (47, 22) become the wreck (tile 561); after
##              step 32 the scene is over ([member finished])
## The numbers come from Commander Genius; check them in the original.
## Where we differ: Commander Genius sends all ten chunks of step 5 the
## same way (a slip); here they fly apart. The explosions burst around the
## middle of the Earth, not around the end of the beam: with Commander
## Genius's speeds the beam ends about four tiles below the Earth's middle.
## Commander Genius also blanks 4x4 tiles from (47, 21); the Earth in
## LEVEL81.CK2 is 3x3 tiles, the rest is black space anyway.

## A tile of the map changed; every change goes through here, so that the
## pictures (original, xBRZ, HD) change per cell.
signal tile_changed(cell: Vector2i, tile: int)
## A sound of the game: the beam fires.
signal sound_played(sound: Sound.Id)
## The beam hit the Earth: Keen 2's own EARTHPOW sound (our choice; Commander
## Genius plays none).
signal earth_hit

const SUBPIXEL := KeenPhysics.SUBPIXEL
const TILE := EgaGraphics.TILE_SIZE
const BEAM_START_CELL := Vector2i(4, 9)  # estimate
const BEAM_VELOCITY := Vector2(252, 108) * SUBPIXEL  # estimate
const BEAM_SPRITES: PackedInt32Array = [58, 59]
const BEAM_FRAME_TICKS := 1
## The beam stops when it reaches this column.
const TARGET_COLUMN := 47  # estimate
## The Earth in LEVEL81.CK2: 3x3 tiles (572-574, 585-587, 598-600).
const EARTH_CELL := Vector2i(47, 22)
const EARTH_SIZE := 3
## What is left of the Earth: a black tile. estimate: Commander Genius's
## choice; the picture fits.
const WRECKED_EARTH := 561  # estimate
## What an explosion leaves behind: the empty space of map 81.
const SPACE_TILE := 155
const STEP_TICKS := 6  # estimate
const LAST_STEP := 32  # estimate
const EXPLOSION_STEPS := 16  # estimate
const EXPLOSION_SPRITES: PackedInt32Array = [60, 61, 62, 63]
const EXPLOSION_FRAME_TICKS := 6  # estimate
## How far from the middle of the Earth an explosion bursts, in pixels.
const EXPLOSION_SPREAD := 32  # estimate
## Half the size of an explosion's picture: it bursts around its middle.
const EXPLOSION_HALF_SIZE := Vector2(8, 8)
const SMALL_BURST_STEP := 5
const SMALL_BURST_COUNT := 10
const SINGLE_CHUNK_STEPS: PackedInt32Array = [6, 7, 8]
const BIG_CHUNK_STEP := 10
## Chunk pictures: the first of two frames, flying left and flying right.
const SMALL_CHUNK_SPRITES: PackedInt32Array = [68, 70]
const BIG_CHUNK_SPRITES: PackedInt32Array = [64, 66]
const CHUNK_FRAMES := 2
const CHUNK_FRAME_TICKS := 6  # estimate
## The directions of the small chunks (20/32 and 10/32 pixels per tick)
## and of the big ones (16/32 diagonally).
const SMALL_CHUNK_VELOCITIES: Array[Vector2] = [
	Vector2(-20, -10) * SUBPIXEL,
	Vector2(-10, -20) * SUBPIXEL,
	Vector2(10, -20) * SUBPIXEL,
	Vector2(20, -10) * SUBPIXEL,
	Vector2(20, 10) * SUBPIXEL,
	Vector2(10, 20) * SUBPIXEL,
	Vector2(-10, 20) * SUBPIXEL,
	Vector2(-20, 10) * SUBPIXEL,
]
const BIG_CHUNK_VELOCITIES: Array[Vector2] = [
	Vector2(-16, -16) * SUBPIXEL,
	Vector2(16, -16) * SUBPIXEL,
	Vector2(16, 16) * SUBPIXEL,
	Vector2(-16, 16) * SUBPIXEL,
]
## Seed for the explosions' places, so that every run is the same.
const RANDOM_SEED := 1991

## Map 81, changed as the Earth breaks up.
var level: LevelData
## Everything that flies: the beam, explosions and chunks.
var actors: Array[Actor] = []
var finished := false
var rng := RandomNumberGenerator.new()
var _beam: Keen2SpaceSprite
var _explosions: Array[Keen2SpaceSprite] = []
## Ticks since the beam hit; -1 while it flies.
var _tick := -1
var _started := false


## The scene on [param space_map] (map 81).
static func create(space_map: LevelData) -> Keen2EarthExplosion:
	var scene := Keen2EarthExplosion.new()
	scene.level = space_map
	scene.rng.seed = RANDOM_SEED
	scene._beam = Keen2SpaceSprite.flying(
		Vector2(BEAM_START_CELL * TILE), BEAM_SPRITES, BEAM_FRAME_TICKS, BEAM_VELOCITY
	)
	scene.actors.append(scene._beam)
	return scene


## The middle of the Earth, in map pixels: where it explodes.
static func earth_center() -> Vector2:
	return Vector2(EARTH_CELL * TILE) + Vector2.ONE * EARTH_SIZE * TILE / 2.0


## Where the view looks: at the beam while it flies, then at the Earth.
func view_center() -> Vector2:
	if _beam != null:
		return _beam.position
	return earth_center()


## Whether the beam is still on its way.
func is_beam_flying() -> bool:
	return _beam != null


## Advances one tick.
func step() -> void:
	if finished:
		return
	if not _started:
		_started = true
		sound_played.emit(Sound.Id.KEEN_FIRE)
	for actor: Keen2SpaceSprite in actors:
		actor.advance()
	_clear_finished_explosions()
	if _beam != null:
		_fly_beam()
		return
	if _tick % STEP_TICKS == 0:
		_run_step(_tick / STEP_TICKS)
	_tick += 1


func _fly_beam() -> void:
	if _beam.position.x < TARGET_COLUMN * TILE:
		return
	_beam.removed = true
	_beam = null
	_tick = 0
	earth_hit.emit()


func _run_step(number: int) -> void:
	if number < EXPLOSION_STEPS:
		_burst()
	if number == SMALL_BURST_STEP:
		for index in SMALL_BURST_COUNT:
			_throw(
				SMALL_CHUNK_SPRITES, SMALL_CHUNK_VELOCITIES[index % SMALL_CHUNK_VELOCITIES.size()]
			)
	if number in SINGLE_CHUNK_STEPS:
		var index := rng.randi_range(0, SMALL_CHUNK_VELOCITIES.size() - 1)
		_throw(SMALL_CHUNK_SPRITES, SMALL_CHUNK_VELOCITIES[index])
	if number == BIG_CHUNK_STEP:
		for velocity in BIG_CHUNK_VELOCITIES:
			_throw(BIG_CHUNK_SPRITES, velocity)
		_wreck_earth()
	if number >= LAST_STEP:
		finished = true


## An explosion somewhere near the middle of the Earth.
func _burst() -> void:
	var offset := Vector2(
		rng.randi_range(-EXPLOSION_SPREAD, EXPLOSION_SPREAD),
		rng.randi_range(-EXPLOSION_SPREAD, EXPLOSION_SPREAD)
	)
	var start := earth_center() + offset - EXPLOSION_HALF_SIZE
	var explosion := Keen2SpaceSprite.flying(start, EXPLOSION_SPRITES, EXPLOSION_FRAME_TICKS)
	explosion.once = true
	_explosions.append(explosion)
	actors.append(explosion)


## A chunk from the middle of the Earth with [param velocity]; its picture
## is one of [param sprites], for flying left or right.
func _throw(sprites: PackedInt32Array, velocity: Vector2) -> void:
	var first := sprites[0] if velocity.x < 0 else sprites[1]
	var frames := PackedInt32Array(range(first, first + CHUNK_FRAMES))
	actors.append(Keen2SpaceSprite.flying(earth_center(), frames, CHUNK_FRAME_TICKS, velocity))


func _wreck_earth() -> void:
	for y in EARTH_SIZE:
		for x in EARTH_SIZE:
			_set_tile(EARTH_CELL + Vector2i(x, y), WRECKED_EARTH)


## Explosions that are over leave empty space in their middle cell, except
## on the Earth itself: its wreck stays whole.
func _clear_finished_explosions() -> void:
	var earth := Rect2i(EARTH_CELL, Vector2i.ONE * EARTH_SIZE)
	for explosion in _explosions:
		var middle := explosion.position + EXPLOSION_HALF_SIZE
		var cell := Vector2i((middle / TILE).floor())
		if explosion.removed and not earth.has_point(cell):
			_set_tile(cell, SPACE_TILE)
	_explosions = _explosions.filter(
		func(sprite: Keen2SpaceSprite) -> bool: return not sprite.removed
	)
	actors = actors.filter(func(actor: Actor) -> bool: return not actor.removed)


func _set_tile(cell: Vector2i, tile: int) -> void:
	if not level.playable_rect().has_point(cell):
		return
	level.set_tile(cell, tile)
	tile_changed.emit(cell, tile)
