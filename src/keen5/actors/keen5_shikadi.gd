class_name Keen5Shikadi
extends Keen5Creature
## The Shikadi of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): it stands (four pictures of 8 tics) and
## walks 128 units a step of 8 tics, turning at walls and ledges (waiting a
## random 0-7 frames). While it walks:
##   - with Keen on a pole (or hanging, or looking up or down) or his bottom
##     within a tile of its own, it goes after him (turning when he is more
##     than a tile away), and when the tile ahead at its top row is a pole
##     right under his middle column, it zaps it;
##   - otherwise it stops to stand now and then (16 in 256 a step), and on
##     the screen, at a tile's edge, it zaps a pole ahead of it.
## Zapping: it grabs the pole (sound "pole_zap"; two pictures of 20 tics)
## and a spark runs along it towards Keen ([Keen5PoleSpark]). Touching the
## Shikadi kills Keen. It has 4 hit points: each of the first three shots
## makes it flash white for two drawings, the fourth stuns it for good.

## (Omni CK5_ACT_Shikadi*.)
const ROWS: PackedStringArray = [
	"stand_1 SHIKADI1 SHIKADI1 step -s 8 0 0 - shikadi shikadi stand_2",
	"stand_2 SHIKADI2 SHIKADI2 step -s 8 0 0 - shikadi shikadi stand_3",
	"stand_3 SHIKADI3 SHIKADI3 step -s 8 0 0 - shikadi shikadi stand_4",
	"stand_4 SHIKADI4 SHIKADI4 step -s 8 0 0 - shikadi shikadi walk_1",
	"walk_1 SHIKADIWALKL1 SHIKADIWALKR1 step -s 8 128 0 walk shikadi shikadi walk_2",
	"walk_2 SHIKADIWALKL2 SHIKADIWALKR2 step -s 8 128 0 walk shikadi shikadi walk_3",
	"walk_3 SHIKADIWALKL3 SHIKADIWALKR3 step -s 8 128 0 walk shikadi shikadi walk_4",
	"walk_4 SHIKADIWALKL4 SHIKADIWALKR4 step -s 8 128 0 walk shikadi shikadi walk_1",
	"zap_1 SHIKADIGRABL SHIKADIGRABR step -s 20 0 0 zap shikadi shikadi zap_2",
	"zap_2 SHIKADIGRABL SHIKADIGRABR step -s 20 0 0 - shikadi shikadi walk_1",
	"stunned SHIKADISTUN SHIKADISTUN think -- 0 0 0 fall - stunned -",
]
const RISE := Vector2i(0, -0x100)
const PRIORITY := 0
const HEALTH := 4
## Keen's bottom within this of its own: it goes after him (Omni).
const SAME_HEIGHT := 0x100
## It turns to Keen when he is more than this away (Omni).
const NEAR := 0x100
const STAND_CHANCE := 0x10
const TILE_MASK := 0xFF
## The spark starts this far under its position; it waits 2 frames after
## zapping (Omni).
const SPARK_DROP := 0x80
const ZAP_PAUSE := 2
## Keen's contact while he holds on (a pole, a ledge, looking).
const KEEN_HOLDING := &"_contact_special"

## Shots it can still take (Omni user2).
var health := HEALTH


## A Shikadi at [param cell] (info 99, 100, 101), facing a random way.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Shikadi:
	var shikadi := Keen5Shikadi.new()
	shikadi.priority = PRIORITY
	shikadi.direction = Vector2i(random_side(world), 1)
	shikadi.place(world, cell, RISE, ROWS, sprites, &"stand_1")
	return shikadi


## Think at each step: after Keen, or now and then a rest; a pole ahead may
## be zapped (Omni CK5_ShikadiWalk).
func _think_walk() -> void:
	var keen := _keen()
	var column := 0
	if _near_keen(keen):
		if position.x > keen.position.x + NEAR:
			direction.x = -1
		elif position.x < keen.position.x - NEAR:
			direction.x = 1
		column = _front_column()
		if keen.box.tile_middle != column:
			return
	else:
		if world.random() < STAND_CHANCE:
			step.x = 0
			_continue_as(&"stand_1")
			return
		if position.x & TILE_MASK != 0 or not world.on_screen(self):
			return
		column = _front_column()
	# The original compares the whole misc byte here (no in-front pole).
	var tile := world.fore_tile(column, box.tile_top)
	if world.tile_info.fore(GalaxyTileInfo.Fore.MISC, tile) == POLE:
		_continue_as(&"zap_1")
		step.x = 0
		world.play_sound(&"pole_zap")


## Think: the spark runs along the pole (Omni CK5_ShikadiPole).
func _think_zap() -> void:
	think_delay = ZAP_PAUSE
	var x := GalaxyUnits.from_tile(_front_column())
	var way := -1 if position.y > _keen().position.y else 1
	Keen5PoleSpark.send(world, Vector2i(x, position.y + SPARK_DROP), way, sprites)
	world.play_sound(&"pole_zap")


## Contact: Keen dies; a shot costs a hit point and flashes it, the last one
## stuns it (Omni CK5_ShikadiCol).
func _contact_shikadi(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player(other)
	var shot := live_shot(other)
	if shot == null:
		return
	health -= 1
	if health != 0:
		_flash_hit(shot)
	else:
		velocity = Vector2i.ZERO
		stun(shot, &"stunned")


## React: walls and ledges turn it; it flashes (Omni CK5_ShikadiTileCol).
func _react_shikadi() -> void:
	if direction.x == 1 and left_hit != 0:
		_turn_round(-1)
	elif direction.x == -1 and right_hit != 0:
		_turn_round(1)
	elif top_hit == 0:
		_turn_round(-direction.x)
	_show_flash()


func _near_keen(keen: GalaxyObject) -> bool:
	if keen.action != null and keen.action.contact == KEEN_HOLDING:
		return true
	return absi(box.bottom - keen.box.bottom) <= SAME_HEIGHT


## The column ahead of it: its box's right one facing right, else its left.
func _front_column() -> int:
	return box.tile_right if direction.x == 1 else box.tile_left
