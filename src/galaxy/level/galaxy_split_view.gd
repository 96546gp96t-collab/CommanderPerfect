class_name GalaxySplitView
extends RefCounted
## Where the two views of a Galaxy level look when two play on one
## keyboard (ours, milestone D12; docs/keen4/gameplay.md, "Two players"):
## the shared [SplitScreen] of Keen 1-3, kept inside the scroll blocks.
##
## As in Keen 1-3 each player has a focus point that follows his Keen with
## the shared dead zone; while both are close enough to the middle of one
## shared view, both look at it; further apart the screen splits, each view
## moved toward the partner. Each Keen's own [GalaxyCamera] still follows
## him by the original's rules (for waking the creatures and for his death);
## its area between the scroll blocks ([method GalaxyCamera.area_pixels])
## is where his view may look, so a view never shows what lies beyond a
## block (in widescreen that is covered, as alone). Two Keens in different
## areas (one in a room behind a block) always split.
## The views glide with the shared smoothing; only numbers here, the
## screen ([Keen4CoopScreen]) puts the cameras where they say.

const PLAYERS := SplitScreen.PLAYERS

var split := SplitScreen.new()
## What each player sees now, in level pixels.
var views: Array[Rect2i] = [Rect2i(), Rect2i()]
var _started := false


## The next [method update] puts the views at once, without gliding.
func reset() -> void:
	_started = false
	split.shared = true


## Moves the views of [param size] pixels after [param delta] seconds,
## toward the Keens at [param positions] (their middles, in pixels), each
## view inside its Keen's area [param areas] (pixels). A Keen that is not
## [param alive] keeps his focus, so he flies out of the view. With
## [param even_x] the views keep the original's 2-pixel steps sideways.
## After [method reset] the focus points start at [param starts] (each
## player's own view, so the picture does not jump), kept within the dead
## zone around his Keen.
func update(
	positions: Array[Vector2],
	alive: Array[bool],
	areas: Array[Rect2i],
	size: Vector2i,
	delta: float,
	even_x := false,
	starts: Array[Vector2] = []
) -> void:
	var view_size := Vector2(size)
	split.view_size = view_size
	var same_area := areas[0] == areas[1]
	split.center_range = centre_range(areas[0], view_size) if same_area else SplitScreen.UNLIMITED
	if not _started:
		split.focus = starts.duplicate() if starts.size() == PLAYERS else positions.duplicate()
	var margin := view_size / 2.0 * SplitScreen.DEAD_ZONE
	for player in PLAYERS:
		if alive[player]:
			split.focus[player] = split.focus[player].clamp(
				positions[player] - margin, positions[player] + margin
			)
	var targets := split.targets_for(split.focus[0], split.focus[1])
	if not same_area:
		# A block between them: the views cannot be shared.
		split.shared = false
		var first := split.focus[0]
		var second := split.focus[1]
		var reach := split.reach(split.normal)
		var offset := split.normal * minf(first.distance_to(second) / 2.0, reach)
		targets = [first + offset, second - offset]
	for player in PLAYERS:
		targets[player] = inside(targets[player], areas[player], view_size)
	if not _started:
		_started = true
		split.centers = targets.duplicate()
	else:
		var weight := 1.0 - exp(-SplitScreen.SMOOTHING_SPEED * delta)
		for player in PLAYERS:
			split.centers[player] = split.centers[player].lerp(targets[player], weight)
	for player in PLAYERS:
		var top_left := Vector2i((split.centers[player] - view_size / 2.0).round())
		if even_x:
			top_left.x &= ~(GalaxyCamera.PAN_STEP - 1)
		views[player] = Rect2i(top_left, size)


## Whether the screen shows two halves now.
func is_split() -> bool:
	return split.is_split()


## Where the middle of a view of [param size] may be inside [param area]:
## one point along an axis where the area is smaller than the view.
static func centre_range(area: Rect2i, size: Vector2) -> Rect2:
	var low := inside(Vector2(area.position), area, size)
	var high := inside(Vector2(area.end), area, size)
	return Rect2(low, high - low)


## The middle [param center] of a view of [param size] moved inside
## [param area]; centred on the area along an axis where it is smaller.
static func inside(center: Vector2, area: Rect2i, size: Vector2) -> Vector2:
	if area.size.x <= 0 or area.size.y <= 0:
		return center
	var low := Vector2(area.position) + size / 2.0
	var high := Vector2(area.end) - size / 2.0
	var middle := Vector2(area.get_center())
	return Vector2(
		clampf(center.x, low.x, high.x) if low.x <= high.x else middle.x,
		clampf(center.y, low.y, high.y) if low.y <= high.y else middle.y
	)
