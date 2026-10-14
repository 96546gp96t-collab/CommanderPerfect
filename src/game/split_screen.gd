class_name SplitScreen
extends RefCounted
## Where the two cameras look when two play: one screen while the players
## are close together, two halves when they are far apart.
##
## Each player has a focus point that follows him with a dead zone, as the
## camera does for one player. While both focus points are close enough to
## the middle of one shared view, both cameras look at that view: one
## screen. When one of them gets further from the middle than
## [method reach], the cameras move apart, each keeping its player part of
## the way from the middle of the screen to its edge, on the side of his
## partner. The screen is then split by a line through its middle, at right
## angles to the line between the players, and each half shows the camera
## of the player in it. The cameras glide apart, so that the picture does
## not jump when the screen splits; the dividing line fades in.
##
## Near the edges of a level the shared view cannot be centered between the
## players, so they can be far apart and still both be on one screen; the
## screen only splits when one of them would get too close to its edge. To
## keep it from switching back and forth there, it only joins again once
## both players are [constant JOIN_DISTANCE] pixels further in.
##
## Only the logic; [LevelView] draws the halves and the line.

const SMOOTHING_SPEED := LevelCamera.SMOOTHING_SPEED
const DEAD_ZONE := LevelCamera.DEAD_ZONE
## How far from the middle of the screen toward its edge each player stays
## when the screen is split: 0 is the middle, 1 the edge.
const PLAYER_REACH := 0.5
## Below this distance (in pixels) between the cameras there is one screen.
const SPLIT_DISTANCE := 0.5
## The dividing line fades in while the cameras move this far apart.
const LINE_FADE_DISTANCE := 4.0
## How much further toward the middle than [method reach] both players must
## be before a split screen becomes one again.
const JOIN_DISTANCE := 8.0
const PLAYERS := 2
## No limits, until the level sets them.
const UNLIMITED := Rect2(-1e9, -1e9, 2e9, 2e9)

## Size of the view in game pixels.
var view_size := Vector2(DisplaySettings.ORIGINAL_SIZE)
## Where the middle of a view can be (see [method LevelCamera.center_range]).
var center_range := UNLIMITED
## The points the cameras follow, one per player.
var focus: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
## The middle of each player's view.
var centers: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
## Unit vector from player 1 to player 2: the half of the screen on this
## side of the dividing line shows player 2.
var normal := Vector2.RIGHT
## Whether the cameras share one view, rather than following a player each.
var shared := true


## Starts with both cameras looking at [param center], or as close to it as
## they can.
func reset(center: Vector2) -> void:
	var start := _clamp(center)
	focus = [start, start]
	centers = [start, start]
	shared = true


## Follows the players, whose middles are at [param positions], for
## [param delta] seconds. A player who is not [param alive] keeps his camera
## where it is, so that he flies off the screen.
func update(positions: Array[Vector2], alive: Array[bool], delta: float) -> void:
	for player in PLAYERS:
		if alive[player]:
			focus[player] = _follow(focus[player], positions[player])
	var targets := targets_for(focus[0], focus[1])
	var weight := 1.0 - exp(-SMOOTHING_SPEED * delta)
	for player in PLAYERS:
		centers[player] = centers[player].lerp(targets[player], weight)


## Where the cameras should look for focus points [param first] and
## [param second], without smoothing. Decides whether the view is
## [member shared].
func targets_for(first: Vector2, second: Vector2) -> Array[Vector2]:
	var between := second - first
	var distance := between.length()
	if distance > SPLIT_DISTANCE:
		normal = between / distance
	var player_reach := reach(normal)
	var middle := _clamp((first + second) / 2.0)
	# How far each player's own camera would be from the shared one, along
	# the line between them. Against an edge of the level a player is off
	# the middle of his own view too; that does not count.
	var spread := maxf(
		absf((_clamp(first) - middle).dot(normal)), absf((_clamp(second) - middle).dot(normal))
	)
	shared = spread <= player_reach - (0.0 if shared else JOIN_DISTANCE)
	if shared:
		return [middle, middle]
	var offset := normal * minf(distance / 2.0, player_reach)
	return [_clamp(first + offset), _clamp(second - offset)]


## How far a player stays from the middle of a split screen, along
## [param direction].
func reach(direction: Vector2) -> float:
	var half := view_size / 2.0
	var to_edge := INF
	if not is_zero_approx(direction.x):
		to_edge = half.x / absf(direction.x)
	if not is_zero_approx(direction.y):
		to_edge = minf(to_edge, half.y / absf(direction.y))
	return to_edge * PLAYER_REACH


## Whether the cameras look at different places, so that the screen is
## split.
func is_split() -> bool:
	return _camera_distance() >= SPLIT_DISTANCE


## How clearly the dividing line shows: 0 (not at all) to 1.
func line_strength() -> float:
	return clampf(_camera_distance() / LINE_FADE_DISTANCE, 0.0, 1.0)


## What [param player] sees, in level pixels.
func view_rect(player: int) -> Rect2:
	return Rect2(centers[player] - view_size / 2.0, view_size)


func _camera_distance() -> float:
	return centers[0].distance_to(centers[1])


## [param point] moved just enough that [param target] is inside the dead
## zone around it.
func _follow(point: Vector2, target: Vector2) -> Vector2:
	var margin := view_size / 2.0 * DEAD_ZONE
	return point.clamp(target - margin, target + margin)


func _clamp(center: Vector2) -> Vector2:
	return center.clamp(center_range.position, center_range.end)
