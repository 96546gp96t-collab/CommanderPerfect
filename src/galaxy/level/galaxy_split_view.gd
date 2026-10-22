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
## Looking up and down (D13.2): while the screen is split each half moves
## as far as his own camera has moved for looking ([method
## GalaxyCamera.look_pixels]), as alone, but only so far that his Keen
## stays inside his half; one shared view does not move for it (it shows
## both Keens, and moving it for one could push the other out).
## Small areas (D13.2): while the screen is split and either Keen's area is
## less than 1.2 views wide or high ([method is_small]; a room behind a
## door), the line turns into a
## standing one through the middle ([member straight]): the player who was
## further left when it began gets the left half, until the line has
## turned back. Each half then shows its Keen's area, never more: centred
## in his half when the area is smaller than the half, else scrolling
## inside it. Once neither area is small, the line turns back to the one
## at right angles between the Keens. Along an axis where an area is
## smaller than the view a split view also puts it in its own half (not
## in the middle of the screen, which may be the other player's half).
## The views and the line glide with the shared smoothing; only numbers
## here, the screen ([Keen4CoopScreen]) puts the cameras where they say.

const PLAYERS := SplitScreen.PLAYERS
## While he looks, a Keen's middle stays this many pixels inside his half
## (from its edges and from the line): about half his height, as a look
## down alone leaves his head at the top of the view.
const LOOK_MARGIN := 16.0
## How close [member straight] gets to where it is going before it is
## there (the gliding never quite ends by itself).
const STRAIGHT_SNAP := 0.001
## The players' sides of a standing line: player 1 on the side away from
## [member line_normal], player 2 on its side.
const SIDES: Array[float] = [-1.0, 1.0]
## An area is small (the line stands) when it is less than this many views
## wide or high. Split, a view sits up to a quarter view off its Keen,
## toward the partner ([method SplitScreen.reach]); in an area with less
## room than a fifth of a view around the view it can hardly do that, so
## with a slanting line the area stays in the middle of the screen, partly
## in the other half. The rooms behind doors are 13 tiles high or less
## (Border Village's house: 208 pixels, 8 more than the view); the low
## parts of levels where both play are 16 tiles or more (Border Village's
## start: 288), and keep the slanting line.
const SMALL_AREA_VIEWS := 1.2

var split := SplitScreen.new()
## What each player sees now, in level pixels.
var views: Array[Rect2i] = [Rect2i(), Rect2i()]
## How far the line has turned into a standing one through the middle for a
## small area: 0 not at all (the line of [SplitScreen]), 1 fully.
var straight := 0.0
## The player in the left half while the line stands (or turns).
var left_player := 0
## Unit vector across the line that is drawn, toward player 2's half.
var line_normal := Vector2.RIGHT
var _started := false


## The next [method update] puts the views at once, without gliding.
func reset() -> void:
	_started = false
	split.shared = true
	straight = 0.0


## Moves the views of [param size] pixels after [param delta] seconds,
## toward the Keens at [param positions] (their middles, in pixels), each
## view inside its Keen's area [param areas] (pixels). A Keen that is not
## [param alive] keeps his focus, so he flies out of the view. With
## [param even_x] the views keep the original's 2-pixel steps sideways.
## After [method reset] the focus points start at [param starts] (each
## player's own view, so the picture does not jump), kept within the dead
## zone around his Keen. [param looks] (pixels, down positive, one per
## player) moves each half for its Keen looking up or down while split.
func update(
	positions: Array[Vector2],
	alive: Array[bool],
	areas: Array[Rect2i],
	size: Vector2i,
	delta: float,
	even_x := false,
	starts: Array[Vector2] = [],
	looks: Array[float] = []
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
	if not split.shared and looks.size() == PLAYERS:
		for player in PLAYERS:
			var keen := positions[player] - targets[player]
			targets[player].y += look_within_half(player, looks[player], keen, view_size)
	for player in PLAYERS:
		targets[player] = inside(targets[player], areas[player], view_size)
		if not split.shared:
			var anchor := half_anchor(player, split.normal)
			targets[player] = centre_small_axes(targets[player], areas[player], view_size, anchor)
	var weight := 1.0 - exp(-SplitScreen.SMOOTHING_SPEED * delta)
	_turn_line(_wants_straight(areas, view_size), weight)
	if straight > 0.0:
		for player in PLAYERS:
			var look := looks[player] if looks.size() == PLAYERS else 0.0
			var standing := _standing_target(
				player, positions[player], look, areas[player], view_size
			)
			targets[player] = targets[player].lerp(standing, straight)
	if not _started:
		_started = true
		split.centers = targets.duplicate()
	else:
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


## Whether the line should stand through the middle: split, with a small
## area ([method is_small]) for a view of [param size].
func _wants_straight(areas: Array[Rect2i], size: Vector2) -> bool:
	if split.shared:
		return false
	for area in areas:
		if is_small(area, size):
			return true
	return false


## Turns the line [param weight] of the way toward standing (or back), and
## sets [member line_normal]. The sides are chosen when it starts to turn.
func _turn_line(wanted: bool, weight: float) -> void:
	var goal := 1.0 if wanted else 0.0
	if wanted and straight == 0.0:
		left_player = 0 if split.focus[0].x <= split.focus[1].x else 1
	if not _started:
		straight = goal
	else:
		straight = lerpf(straight, goal, weight)
		if absf(straight - goal) < STRAIGHT_SNAP:
			straight = goal
	if straight == 0.0:
		line_normal = split.normal
	elif straight == 1.0:
		line_normal = standing_normal()
	else:
		line_normal = split.normal.slerp(standing_normal(), straight)


## Unit vector across the standing line, toward player 2's half.
func standing_normal() -> Vector2:
	return Vector2.RIGHT if left_player == 0 else Vector2.LEFT


## Where [param player]'s view looks while the line stands: his focus
## point in the middle of his half, moved for his [param look] (his Keen's
## middle at [param keen]) as far as [method look_within_half] allows, and
## his half (half the width of [param size]) inside his
## [param area], centred on it where it is smaller.
func _standing_target(
	player: int, keen: Vector2, look: float, area: Rect2i, size: Vector2
) -> Vector2:
	var normal := standing_normal()
	var anchor := half_anchor(player, normal)
	var center := split.focus[player] - anchor
	center.y += _look_within(player, look, keen - center, size, normal)
	var half := Vector2(size.x / 2.0, size.y)
	return inside(center + anchor, area, half) - anchor


## The middle of [param player]'s half of the view split across
## [param normal], from the middle of the view: where his Keen stays in a
## split screen ([method SplitScreen.reach]).
func half_anchor(player: int, normal: Vector2) -> Vector2:
	return SIDES[player] * normal * split.reach(normal)


## Whether [param area] is too small for a slanting line with a view of
## [param size]: less than [constant SMALL_AREA_VIEWS] views along either
## axis (an empty area is no area).
static func is_small(area: Rect2i, size: Vector2) -> bool:
	if area.size.x <= 0 or area.size.y <= 0:
		return false
	var least := size * SMALL_AREA_VIEWS
	return area.size.x < least.x or area.size.y < least.y


## [param center] of a view of [param size], with [param area] put at
## [param anchor] (from the middle of the view) along each axis where it is
## smaller than the view, instead of in the middle of the view.
static func centre_small_axes(
	center: Vector2, area: Rect2i, size: Vector2, anchor: Vector2
) -> Vector2:
	if area.size.x <= 0 or area.size.y <= 0:
		return center
	var middle := Vector2(area.get_center())
	var placed := center
	if area.size.x < size.x:
		placed.x = middle.x - anchor.x
	if area.size.y < size.y:
		placed.y = middle.y - anchor.y
	return placed


## How far [param player]'s half moves down for his look of [param look]
## pixels, with his Keen [param keen] pixels from the middle of his view
## of [param size]: as far as the look, but his Keen stays
## [constant LOOK_MARGIN] inside the view and on his side of the line
## (player 2's half lies along the split's normal). Never against a
## move that would already have been allowed (0 always is).
func look_within_half(player: int, look: float, keen: Vector2, size: Vector2) -> float:
	return _look_within(player, look, keen, size, split.normal)


## [method look_within_half] for a line across [param normal].
func _look_within(player: int, look: float, keen: Vector2, size: Vector2, normal: Vector2) -> float:
	var reach_y := size.y / 2.0 - LOOK_MARGIN
	# The view moving down by d moves the Keen up by d on the screen.
	var lowest := keen.y - reach_y
	var highest := keen.y + reach_y
	var side := 1.0 if player == 1 else -1.0
	var tilt := side * normal.y
	if not is_zero_approx(tilt):
		var room := (side * keen.dot(normal) - LOOK_MARGIN) / tilt
		if tilt > 0.0:
			highest = minf(highest, room)
		else:
			lowest = maxf(lowest, room)
	return clampf(look, minf(lowest, 0.0), maxf(highest, 0.0))


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
