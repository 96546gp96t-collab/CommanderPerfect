class_name GalaxyLevelSession
extends RefCounted
## One level of a Galaxy episode being played (made from Keen 4's
## [Keen4LevelSession], with the episode's numbers from its
## [GalaxyGameRules]): the [GalaxyWorld] with Keen, and the items the info
## plane places, in the order the original scans it (Omni
## CKx_ScanInfoLayer), the camera that follows him (Omni
## `ck_play.c:CK_NormalCamera`), and how the level ends:
##   - Keen leaves the area the views can cover, to the left or right: the
##     level is done;
##   - an object ends it ([method ending], such as Keen 5's exit door);
##   - he falls below it: he dies (also in god mode); his death ends when
##     he has left the view;
##   - what the episode loses at a level's end goes either way
##     ([method GalaxyInventory.drop_gems]: the gems, Keen 5's keycard).
## What an episode adds comes through hooks: its own Keen
## ([method _new_keen]), what he can do there ([method _set_up_keen]), and
## the creatures and objects of its info values ([method _place_info]).
## A second player ([member partner], ours) is a Keen of the same kind with
## a camera of his own ([member camera_2]): either Keen leaving the level
## completes it, either death ends the attempt; the inventory is shared.

var rules: GalaxyGameRules
var map: GalaxyMap
var world: GalaxyWorld
var keen: GalaxyKeen
## The Keen that is played.
var player: GalaxyKeenBody:
	get:
		return keen
var camera: GalaxyCamera
## Player 2's Keen and his view; null while one plays.
var partner: GalaxyKeenBody
var camera_2: GalaxyCamera
var inventory: GalaxyInventory
var difficulty := GalaxyDifficulty.DEFAULT
## The map's number in the episode; -1 unknown.
var number := -1


## The level [param level_map] (read fresh: it changes while played) of the
## episode of [param game_rules] with Keen carrying [param carried], or
## null when the map has no standing Keen. [param random_start] is where
## the random table starts; [param level] decides which creatures are
## there; [param map_number] is the map's number.
static func start(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	level_map: GalaxyMap,
	carried: GalaxyInventory,
	random_start := 0,
	level := GalaxyDifficulty.DEFAULT,
	map_number := -1
) -> GalaxyLevelSession:
	var session := GalaxyLevelSession.new()
	if not session.begin(data, game_rules, level_map, carried, random_start, level, map_number):
		return null
	return session


## Sets up this session as [method start] describes; returns whether the
## map has a standing Keen. An episode's own session class calls it on a
## new object of its class.
func begin(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	level_map: GalaxyMap,
	carried: GalaxyInventory,
	random_start := 0,
	level := GalaxyDifficulty.DEFAULT,
	map_number := -1
) -> bool:
	rules = game_rules
	var start_place := GalaxyStart.find(level_map, rules)
	if not start_place.is_standing():
		return false
	map = level_map
	inventory = carried
	difficulty = level
	number = map_number
	camera = GalaxyCamera.for_map(
		Vector2i(level_map.width, level_map.height),
		GalaxyCamera.blocks_in(level_map, rules.column_block_info, true),
		GalaxyCamera.blocks_in(level_map, rules.row_block_info, false)
	)
	world = GalaxyWorld.create(level_map, data.tile_info, data.graphics.sprite_infos)
	world.camera = camera
	world.random_table = data.executable.random_table()
	world.random_index = random_start
	world.map_number = map_number
	keen = GalaxyKeen.spawn(world, start_place.cell, start_place.facing, rules.sprites, _new_keen())
	_set_up_keen(keen)
	carried.charges_per_stunner = rules.charges_for(level)
	keen.inventory = carried
	_place_objects()
	camera.centre_on(keen.position.x, keen.box.bottom)
	return true


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
	var first := keen
	var cell := Vector2i(
		GalaxyUnits.to_tile(first.position.x), GalaxyUnits.to_tile(first.position.y)
	)
	var walker := GalaxyKeen.spawn(world, cell, first.direction.x, rules.sprites, _new_keen())
	_set_up_keen(walker)
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
	camera_2.wide_width = camera.wide_width
	return partner


## Both views are drawn [param width] pixels wide (0: the original's
## width): objects wake up around what they show ([member
## GalaxyCamera.wide_width]).
func set_wide_width(width: int) -> void:
	camera.wide_width = width
	if camera_2 != null:
		camera_2.wide_width = width


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


## How a done level was left when not by walking out of it: the name the
## object that ended it gave ([method GalaxyWorld.complete]); otherwise
## empty.
func ending() -> StringName:
	return world.ending


## The message a frame asked for, once; empty when none.
func take_conversation() -> StringName:
	var asked := world.conversation
	world.conversation = &""
	return asked


## The Keen the episode plays with: a [GalaxyKeen], or its own subclass
## (Keen 5's [Keen5Keen]).
func _new_keen() -> GalaxyKeen:
	return GalaxyKeen.new()


## What [param walker] can do in this episode, before he is placed (Keen 4
## shows the moon; the jumps on Easy are every episode's).
func _set_up_keen(walker: GalaxyKeen) -> void:
	walker.easy_jumps = difficulty == GalaxyDifficulty.Level.EASY


## Whether [param info] is where Keen starts (he is placed already).
func _places_keen(info: int) -> bool:
	return info == rules.keen_right_info or info == rules.keen_left_info


## Places what info value [param info] at [param cell] stands for, when it
## is no item and not Keen's start: the episode's creatures and objects (Keen 4's
## [Keen4Creatures]). Nothing by default.
func _place_info(_info: int, _cell: Vector2i) -> void:
	pass


## After the frame: [param body]'s camera [param view] follows him, and
## the edges of the level count (a door puts the view on him itself,
## [GalaxyKeen]).
func _after_frame(body: GalaxyKeenBody, view: GalaxyCamera, tics: int) -> void:
	var walker := body as GalaxyKeen
	if walker != null:
		_follow_keen(walker, view, tics)


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


static func _target(walker: GalaxyKeen, tics: int) -> GalaxyCamera.Target:
	var target := GalaxyCamera.Target.new()
	target.x = walker.position.x
	target.feet = walker.box.bottom
	target.moved_down = walker.moved.y
	var hanging := walker.action == walker.actions[&"hang_1"]
	target.grounded = (walker.top_hit != 0 or walker.clip == GalaxyObject.Clip.NONE or hanging)
	target.pulling = walker.action.name.begins_with("pull_") and walker.action.name != &"pull_5"
	if walker.action == walker.actions[&"look_up_2"]:
		target.look = -1
	elif walker.action == walker.actions[&"look_down_3"]:
		target.look = 1
	target.tics = tics
	return target


## The items, creatures and objects of the info plane, row by row; then
## all of them but the ever-awake ones sleep until the view comes near
## (Omni CKx_ScanInfoLayer).
func _place_objects() -> void:
	var actions := player.item_actions()
	var stunner := GalaxyInventory.STUNNER_ITEM
	for y in map.height:
		for x in map.width:
			var info := map.tile(GalaxyMap.Layer.INFO, x, y)
			var cell := Vector2i(x, y)
			var item := rules.item_of_info(info)
			if info == rules.low_stunner_info:
				if inventory.shots < rules.low_shots:
					GalaxyItem.place(world, cell, stunner, rules.sprites, actions)
			elif item >= 0:
				GalaxyItem.place(world, cell, item, rules.sprites, actions)
			elif info != 0 and not _places_keen(info):
				_place_info(info, cell)
	for object in world.objects:
		if object.activity != GalaxyObject.Activity.ALWAYS:
			object.activity = GalaxyObject.Activity.INACTIVE
