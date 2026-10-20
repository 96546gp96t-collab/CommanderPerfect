class_name Keen4LevelSession
extends RefCounted
## One Keen 4 level being played (milestones D4-D6): the [GalaxyWorld]
## with Keen (walking, or swimming in level 17), and the items, creatures,
## platforms and people the info plane places for the difficulty, in the
## order the original scans it (Omni `ck4_misc.c:CK4_ScanInfoLayer`;
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

var map: GalaxyMap
var world: GalaxyWorld
## Keen walking; null under water.
var keen: GalaxyKeen
## Keen swimming (level 17); null on land.
var swimmer: Keen4SwimmingKeen
## Whichever of the two is played.
var player: GalaxyKeenBody:
	get:
		return swimmer if swimmer != null else keen
var camera: GalaxyCamera
## Player 2's Keen (walking or swimming, as player 1) and his view; null
## while one plays.
var partner: GalaxyKeenBody
var camera_2: GalaxyCamera
var inventory: GalaxyInventory
var difficulty := GalaxyDifficulty.DEFAULT


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
	number := -1
) -> Keen4LevelSession:
	var start_place := Keen4Start.find(level_map)
	if start_place.kind not in [Keen4Start.Kind.STANDING, Keen4Start.Kind.SWIMMING]:
		return null
	var session := Keen4LevelSession.new()
	session.map = level_map
	session.inventory = carried
	session.difficulty = level
	session.camera = GalaxyCamera.for_map(
		Vector2i(level_map.width, level_map.height),
		GalaxyCamera.blocks_in(level_map, Keen4Episode.COLUMN_BLOCK_INFO, true),
		GalaxyCamera.blocks_in(level_map, Keen4Episode.ROW_BLOCK_INFO, false)
	)
	var world := GalaxyWorld.create(level_map, data.tile_info, data.graphics.sprite_infos)
	world.camera = session.camera
	world.random_table = data.executable.random_table()
	world.random_index = random_start
	world.map_number = number
	session.world = world
	var sprites := Keen4Sprites.all()
	if start_place.kind == Keen4Start.Kind.SWIMMING:
		session.swimmer = Keen4SwimmingKeen.spawn(world, start_place.cell, sprites)
	else:
		session.keen = GalaxyKeen.spawn(world, start_place.cell, start_place.facing, sprites)
		session.keen.shows_moon = true
		session.keen.easy_jumps = level == GalaxyDifficulty.Level.EASY
	carried.charges_per_stunner = Keen4Inventory.charges_for(level)
	session.player.inventory = carried
	session._place_objects(sprites)
	session.camera.centre_on(session.player.position.x, session.player.box.bottom)
	return session


## Runs one logic frame of [param tics] tics ending on absolute tic
## [param tic], with [param input] held (and [param partner_input] by
## player 2); then the cameras follow.
func run_frame(input: KeenInput, tics: int, tic: int, partner_input: KeenInput = null) -> void:
	if world.state != GalaxyWorld.LevelState.PLAYING:
		return
	world.tics = tics
	player.begin_frame(input)
	if partner != null:
		partner.begin_frame(partner_input if partner_input != null else KeenInput.new())
	world.run_frame(tics, tic)
	_after_frame(player, camera, tics)
	if partner != null:
		_after_frame(partner, camera_2, tics)
	if world.state != GalaxyWorld.LevelState.PLAYING:
		inventory.drop_gems()


## Player 2 joins: his Keen appears where player 1's is, facing the same
## way, with a view of his own on him. Returns his Keen.
func add_player() -> GalaxyKeenBody:
	if partner != null:
		return partner
	var sprites := Keen4Sprites.all()
	var first := player
	var cell := Vector2i(
		GalaxyUnits.to_tile(first.position.x), GalaxyUnits.to_tile(first.position.y)
	)
	if swimmer != null:
		partner = Keen4SwimmingKeen.spawn(world, cell, sprites)
	else:
		var walker := GalaxyKeen.spawn(world, cell, first.direction.x, sprites)
		walker.easy_jumps = keen.easy_jumps
		walker.shows_moon = keen.shows_moon
		partner = walker
	world.objects.erase(partner)
	camera_2 = GalaxyCamera.for_map(
		Vector2i(map.width, map.height), camera.column_blocks, camera.row_blocks
	)
	world.add_partner(partner, camera_2)
	partner.inventory = inventory
	partner.god_mode = first.god_mode
	partner.position = first.position
	partner.direction = first.direction
	partner.start(partner.action)
	camera_2.scroll = camera.scroll
	camera_2.feet_on_screen = camera.feet_on_screen
	return partner


## Player 2 leaves the level.
func remove_player() -> void:
	world.remove_partner()
	partner = null
	camera_2 = null


func is_playing() -> bool:
	return world.state == GalaxyWorld.LevelState.PLAYING


func is_done() -> bool:
	return world.state == GalaxyWorld.LevelState.COMPLETED


func is_lost() -> bool:
	return world.state == GalaxyWorld.LevelState.DIED


## How a done level was left when not by walking out: [code]&"foot"[/code]
## (the Foot), [code]&"council"[/code] (an elder rescued),
## [code]&"wetsuit"[/code]; otherwise empty.
func ending() -> StringName:
	return world.ending


## The message a frame asked for ([code]&"lindsey"[/code],
## [code]&"janitor"[/code]), once; empty when none.
func take_conversation() -> StringName:
	var asked := world.conversation
	world.conversation = &""
	return asked


## After the frame: [param body]'s camera [param view] follows him, a door
## puts it on him, and the edges of the level count.
func _after_frame(body: GalaxyKeenBody, view: GalaxyCamera, tics: int) -> void:
	var walker := body as GalaxyKeen
	if walker != null and walker.went_through_door:
		walker.went_through_door = false
		view.centre_on(walker.position.x, walker.box.bottom)
	if walker == null:
		_follow_swimmer(body, view)
	else:
		_follow_keen(walker, view, tics)


## Under water the view follows as on the world map (Omni CK_MapCamera).
static func _follow_swimmer(body: GalaxyKeenBody, view: GalaxyCamera) -> void:
	if body.scroll_disabled:
		return
	var box := body.box
	view.follow_map(box.left, box.top, box.right, box.bottom)


## The camera after a frame, and the edges of the level (Omni
## CK_NormalCamera).
func _follow_keen(walker: GalaxyKeen, view: GalaxyCamera, tics: int) -> void:
	if walker.scroll_disabled or world.state != GalaxyWorld.LevelState.PLAYING:
		return
	var limits := view.limits()
	var size := GalaxyCamera.VIEW_TILES * GalaxyUnits.PER_TILE
	var outside := walker.box.left < limits.position.x or walker.box.right > limits.end.x + size.x
	# While the other Keen dies nobody walks out (as in Keen 1-3).
	if outside and not _a_keen_dies():
		world.state = GalaxyWorld.LevelState.COMPLETED
		return
	var bottom := limits.end.y + size.y
	if walker.box.bottom > bottom:
		walker.position.y -= walker.box.bottom - bottom
		walker.god_mode = false
		walker.kill()
		return
	view.follow(_target(walker, tics))


## Whether either Keen is dying.
func _a_keen_dies() -> bool:
	return player.is_dying() or (partner != null and partner.is_dying())


static func _target(keen: GalaxyKeen, tics: int) -> GalaxyCamera.Target:
	var target := GalaxyCamera.Target.new()
	target.x = keen.position.x
	target.feet = keen.box.bottom
	target.moved_down = keen.moved.y
	var hanging := keen.action == keen.actions[&"hang_1"]
	target.grounded = keen.top_hit != 0 or keen.clip == GalaxyObject.Clip.NONE or hanging
	target.pulling = keen.action.name.begins_with("pull_") and keen.action.name != &"pull_5"
	if keen.action == keen.actions[&"look_up_2"]:
		target.look = -1
	elif keen.action == keen.actions[&"look_down_3"]:
		target.look = 1
	target.tics = tics
	return target


## The items and creatures of the info plane, row by row.
func _place_objects(sprites: Dictionary[StringName, int]) -> void:
	var actions := player.item_actions()
	for y in map.height:
		for x in map.width:
			var info := map.tile(GalaxyMap.Layer.INFO, x, y)
			var cell := Vector2i(x, y)
			if info == LOW_STUNNER_INFO and inventory.shots < LOW_SHOTS:
				GalaxyItem.place(world, cell, STUNNER_ITEM, sprites, actions)
			elif info >= FIRST_ITEM_INFO and info <= LAST_ITEM_INFO:
				GalaxyItem.place(world, cell, info - FIRST_ITEM_INFO, sprites, actions)
			else:
				Keen4Creatures.place_info(world, info, cell, difficulty, sprites)
