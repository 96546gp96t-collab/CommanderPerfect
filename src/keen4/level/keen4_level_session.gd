class_name Keen4LevelSession
extends GalaxyLevelSession
## One Keen 4 level being played (milestones D4-D6; on the shared
## [GalaxyLevelSession] since milestone E13): the [GalaxyWorld] with Keen
## (walking, or swimming in level 17), and the items, creatures, platforms
## and people the info plane places for the difficulty, in the order the
## original scans it (Omni `ck4_misc.c:CK4_ScanInfoLayer`;
## [Keen4Creatures]), the camera that follows him (Omni
## `ck_play.c:CK_NormalCamera`; under water CK_MapCamera), and how the
## level ends:
##   - Keen leaves the area the views can cover, to the left or right: the
##     level is done;
##   - the Foot carries him off ([method ending] [code]&"foot"[/code]), he
##     rescues a council member ([code]&"council"[/code]) or takes the
##     wetsuit ([code]&"wetsuit"[/code]): the level is done too;
##   - he falls below it: he dies (also in god mode); his death ends when
##     he has left the view; the Dopefish's meal ends it too;
##   - gems are lost either way.
## Lindsey and the janitor ask for their messages on the way
## ([method take_conversation]). The view ([Keen4View]) draws it, shows the
## messages and decides what comes next.
## A second player (ours, D12; docs/keen4/gameplay.md, "Two players") is
## [member partner], a Keen of the same kind with a camera of his own
## ([member camera_2]): either Keen leaving the level completes it, either
## death ends the attempt; the inventory is shared.

## Info values (Omni, research.md §6): 57-68 items 0-11 lying as sprites;
## 34 a stunner, only when Keen has fewer than 5 charges.
const FIRST_ITEM_INFO := 57
const LAST_ITEM_INFO := 68
const LOW_STUNNER_INFO := 34
const STUNNER_ITEM := GalaxyInventory.STUNNER_ITEM
const LOW_SHOTS := 5

## Keen swimming (level 17); null on land ([member keen] is null then).
var swimmer: Keen4SwimmingKeen


func _init() -> void:
	rules = Keen4Episode.game_rules()


## The level [param level_map] (read fresh: it changes while played) with
## Keen carrying [param carried], or null when the map has no standing or
## swimming Keen. [param random_start] is where the random table starts;
## [param level] decides which creatures are there; [param number] is the
## map's number (the janitor's level, the elder under water).
static func start(
	data: GalaxyData,
	level_map: GalaxyMap,
	carried: GalaxyInventory,
	random_start := 0,
	level := GalaxyDifficulty.DEFAULT,
	map_number := -1
) -> Keen4LevelSession:
	return start_level(
		data, Keen4Episode.game_rules(), level_map, carried, random_start, level, map_number
	)


## The same by [param game_rules] (the view's).
static func start_level(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	level_map: GalaxyMap,
	carried: GalaxyInventory,
	random_start := 0,
	level := GalaxyDifficulty.DEFAULT,
	map_number := -1
) -> Keen4LevelSession:
	var session := Keen4LevelSession.new()
	if not session.begin(data, game_rules, level_map, carried, random_start, level, map_number):
		return null
	return session


## Keen stands, or swims in level 17.
func _can_start(start_place: GalaxyStart) -> bool:
	return start_place.is_standing() or start_place.kind == GalaxyStart.Kind.SWIMMING


func _spawn_player(start_place: GalaxyStart) -> void:
	if start_place.kind == GalaxyStart.Kind.SWIMMING:
		swimmer = Keen4SwimmingKeen.spawn(world, start_place.cell, rules.sprites)
	else:
		super(start_place)


func _player_body() -> GalaxyKeenBody:
	return swimmer if swimmer != null else keen


## Keen 4 shows the moon (D13: Keen's sprite above the map's), and the
## jumps on Easy.
func _set_up_keen(walker: GalaxyKeen) -> void:
	walker.shows_moon = true
	super(walker)


## Player 2 is of player 1's kind: swimming, or walking with his jumps and
## his moon.
func _spawn_partner(cell: Vector2i, first: GalaxyKeenBody) -> GalaxyKeenBody:
	if swimmer != null:
		return Keen4SwimmingKeen.spawn(world, cell, rules.sprites)
	var walker := GalaxyKeen.spawn(world, cell, first.direction.x, rules.sprites)
	walker.easy_jumps = keen.easy_jumps
	walker.shows_moon = keen.shows_moon
	return walker


## Keen 4's creatures, platforms and people ([Keen4Creatures]).
func _place_info(info: int, cell: Vector2i) -> void:
	Keen4Creatures.place_info(world, info, cell, difficulty, rules.sprites)


## Under water the view follows as on the world map (Omni CK_MapCamera).
func _after_frame(body: GalaxyKeenBody, view: GalaxyCamera, tics: int) -> void:
	if body is GalaxyKeen:
		super(body, view, tics)
	elif not body.scroll_disabled:
		var box := body.box
		view.follow_map(box.left, box.top, box.right, box.bottom)
