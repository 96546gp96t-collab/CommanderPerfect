class_name ShipSmoke
extends Node2D
## Smoke rising from Keen's crashed ship ([ShipLevels]): puffs that come out
## of a few places, drift up and to the side, grow and fade away. Drawn in
## level pixels, between the tiles and the sprites. Only for the eye: it
## does not take part in the game, so it simply follows the frames.

## Seconds between two puffs from one place.
const PUFF_INTERVAL := 0.35
## Seconds a puff lives.
const PUFF_LIFE := 3.2
## Pixels per second upwards, and at most this much to either side.
const RISE_SPEED := 14.0
const MAX_DRIFT := 5.0
## A puff starts small and dark, and ends large and light.
const START_RADIUS := 1.5
const END_RADIUS := 7.0
const START_COLOR := Color("555555")
const END_COLOR := Color("aaaaaa")
const START_ALPHA := 0.85
## The wind blows the smoke a little to the right.
const WIND := 4.0
## So that the smoke looks the same every time.
const RANDOM_SEED := 1990

var _sources: Array[Vector2] = []
var _puffs: Array[Dictionary] = []
var _time_to_next := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_process(false)


## Starts smoke at [param sources] (level pixels), or stops it when there
## are none.
func start(sources: Array[Vector2]) -> void:
	_sources = sources
	_puffs.clear()
	_rng.seed = RANDOM_SEED
	_time_to_next = 0.0
	set_process(not sources.is_empty())
	# Smoke has been rising for a while already when the level appears.
	for step in int(PUFF_LIFE / PUFF_INTERVAL):
		_advance(PUFF_INTERVAL)
	queue_redraw()


func _process(delta: float) -> void:
	_advance(delta)
	queue_redraw()


func _advance(delta: float) -> void:
	for puff in _puffs:
		puff.age += delta
		puff.position += Vector2(puff.drift + WIND, -RISE_SPEED) * delta
	_puffs = _puffs.filter(func(puff: Dictionary) -> bool: return puff.age < PUFF_LIFE)
	_time_to_next -= delta
	while _time_to_next <= 0.0 and not _sources.is_empty():
		_time_to_next += PUFF_INTERVAL
		for source in _sources:
			var drift := _rng.randf_range(-MAX_DRIFT, MAX_DRIFT)
			_puffs.append({"position": source, "age": 0.0, "drift": drift})


func _draw() -> void:
	for puff in _puffs:
		var progress: float = puff.age / PUFF_LIFE
		var color := START_COLOR.lerp(END_COLOR, progress)
		color.a = START_ALPHA * (1.0 - progress)
		var radius := lerpf(START_RADIUS, END_RADIUS, progress)
		# Whole pixels, so that the smoke looks like the rest of the game.
		draw_circle(Vector2(puff.position).round(), roundf(radius), color)
