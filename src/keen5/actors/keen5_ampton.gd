class_name Keen5Ampton
extends Keen5Creature
## The Little Ampton of Keen 5 (Omni `ck5_obj2.c`, `ck_keen.c`; facts and
## numbers only; docs/keen5/research.md §7): it walks 128 units a step,
## four steps of 8 tics (sounds "ampton_walk_1" and "_2" on the first and
## third). Between two tiles (its x not on a tile's edge) it looks at the
## tile right of its box's left column, at its top row:
##   - a computer (misc 31): it works it, five pictures of 12 tics;
##   - a pole (misc 1), with 196 in 256: it grabs it (two pictures of 8
##     tics) and climbs up or slides down at 32 units a tic, the way the
##     pole goes on (two tiles up or down; both: a coin toss); unclipped on
##     the pole. Going up it comes out through a pole hole when fewer than
##     four pole tiles are above, or by a coin toss; at the top of the pole
##     it goes down again. Going down it gets off on a floor that is no
##     pole hole, or by a coin toss at a hole; at the bottom it goes up.
##     Getting off: two pictures of 8 tics, then a pause of 4 frames.
## A wall or a ledge turns it (one picture of 8 tics). It never hurts Keen
## while it walks: it pushes him out of its way; on a pole it kills him.
## Touching Keen on a pole or a ledge knocks him off. A shot stuns it for
## good (sound "ampton_stun").

## (Omni CK5_ACT_Ampton*.)
const ROWS: PackedStringArray = [
	"walk_1 AMPTONWALKL1 AMPTONWALKR1 step -s 8 128 0 walk ampton ampton walk_2",
	"walk_2 AMPTONWALKL2 AMPTONWALKR2 step -s 8 128 0 walk ampton ampton walk_3",
	"walk_3 AMPTONWALKL3 AMPTONWALKR3 step -s 8 128 0 walk ampton ampton walk_4",
	"walk_4 AMPTONWALKL4 AMPTONWALKR4 step -s 8 128 0 walk ampton ampton walk_1",
	"turn AMPTONFACE AMPTONFACE step -s 8 0 0 - ampton - walk_1",
	"grab_1 AMPTONGRAB1 AMPTONGRAB1 step -s 8 0 0 - ampton - grab_2",
	"grab_2 AMPTONGRAB2 AMPTONGRAB2 step -s 8 0 0 - ampton - pole",
	"pole AMPTONGRAB2 AMPTONGRAB2 slide+ -- 0 0 32 climb ampton - -",
	"get_off_1 AMPTONGRAB2 AMPTONGRAB2 step -- 8 0 0 - ampton - get_off_2",
	"get_off_2 AMPTONGRAB1 AMPTONGRAB1 step -- 8 0 0 pause ampton - walk_1",
	"computer_1 AMPTONGRAB1 AMPTONGRAB1 step -s 12 0 0 - ampton - computer_2",
	"computer_2 AMPTONGRAB2 AMPTONGRAB2 step -s 12 0 0 - ampton - computer_3",
	"computer_3 AMPTONGRAB1 AMPTONGRAB1 step -s 12 0 0 - ampton - computer_4",
	"computer_4 AMPTONGRAB2 AMPTONGRAB2 step -s 12 0 0 - ampton - computer_5",
	"computer_5 AMPTONGRAB1 AMPTONGRAB1 step -s 12 0 0 pause ampton - walk_1",
	"stunned AMPTONSTUN AMPTONSTUN think -- 0 0 0 fall - stunned -",
]
const RISE := Vector2i(0, -0x80)
const PRIORITY := 0
const STARS := Vector2i(0, -0x80)
## Chances in 256 (Omni): taking a pole, getting off at a hole.
const CLIMB_CHANCE := 0xC4
const GET_OFF_CHANCE := 0x80
## A pole goes on when there is pole two tiles up or down; going up it
## always gets off with fewer than this many pole tiles above (Omni).
const POLE_AHEAD := 2
const POLE_HIGH := 4
## Frames without thinking: after grabbing the pole, after getting off and
## after a computer (Omni).
const GRAB_PAUSE := 6
const PAUSE := 4
## Getting off it is put this far down onto the floor, twice (Omni).
const GET_OFF_DROP := 0x10
const TILE_MASK := 0xFF


## A Little Ampton at [param cell] (info 42, 43, 44), facing a random way.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Ampton:
	var ampton := Keen5Ampton.new()
	ampton.priority = PRIORITY
	ampton.stars_offset = STARS
	ampton.direction = Vector2i(random_side(world), 1)
	ampton.place(world, cell, RISE, ROWS, sprites, &"walk_1")
	return ampton


## Whether it is on a pole now (the only time it kills Keen).
func is_on_pole() -> bool:
	return action == actions[&"pole"]


## Keen on a pole or a ledge falls off when it touches him (Omni
## CK_KeenSpecialColFunc).
func touched_by_player(player: GalaxyObject, holding: bool) -> void:
	_knock_off(player, holding)


## Think while walking: its steps' sounds, then computers and poles
## between two tiles (Omni CK5_AmptonWalk).
func _think_walk() -> void:
	if action == actions[&"walk_1"]:
		world.play_sound(&"ampton_walk_1")
	elif action == actions[&"walk_3"]:
		world.play_sound(&"ampton_walk_2")
	if position.x & TILE_MASK == 0:
		return
	var x := box.tile_left + 1
	var y := box.tile_top
	var kind := _misc_at(x, y)
	if kind == COMPUTER:
		_continue_as(&"computer_1")
	elif kind == POLE and world.random() < CLIMB_CHANCE:
		_take_pole(x, y)


func _take_pole(x: int, y: int) -> void:
	var down := _misc_at(x, y + POLE_AHEAD) == POLE
	var up := _misc_at(x, y - POLE_AHEAD) == POLE
	if up and down:
		if world.random() < HALF_RANDOM:
			up = false
		else:
			down = false
	if not up and not down:
		return
	direction.y = -1 if up else 1
	_continue_as(&"grab_1")
	clip = Clip.NONE
	think_delay = GRAB_PAUSE
	step.x = 0


## Think on the pole: entering a new tile row it may get off, or turn at
## the pole's end (Omni CK5_AmptonPoleClimb).
func _think_climb() -> void:
	var row := GalaxyUnits.to_tile(box.bottom + step.y)
	if row == box.tile_bottom:
		return
	var x := box.tile_left + 1
	if direction.y == -1:
		_climb_into(x, row)
	else:
		_slide_into(x, row)


func _climb_into(x: int, row: int) -> void:
	if _top_at(x, row) == 0 and _top_at(x, row + 1) != 0:
		# Through a pole hole in a floor.
		var short := _misc_at(x, row - POLE_HIGH) != POLE
		if short or world.random() >= GET_OFF_CHANCE:
			var lift := (box.bottom & TILE_MASK) + 1
			position.y -= lift
			box.bottom -= lift
			_get_off()
	elif _misc_at(x, row - 1) != POLE:
		step.y = 0
		direction.y = 1


func _slide_into(x: int, row: int) -> void:
	if _top_at(x, row) != 0 and _top_at(x, row - 1) == 0:
		if _misc_at(x, row) != POLE or world.random() >= GET_OFF_CHANCE:
			var drop := TILE_MASK - (box.bottom & TILE_MASK)
			position.y += drop
			# The original moves the box's right edge here, not its bottom.
			box.right += drop
			_get_off()
	elif _misc_at(x, row) != POLE:
		step.y = 0
		direction.y = -1


## Off the pole onto the floor: clipped again, put down twice (Omni: the
## move is done here and once more after the think).
func _get_off() -> void:
	clip = Clip.NORMAL
	_continue_as(&"get_off_1")
	step.y = GET_OFF_DROP
	direction.y = 1
	world.clip.update_normal(self)
	think_delay = PAUSE


## Think: a pause before walking on (Omni CK5_AmptonSwitch).
func _think_pause() -> void:
	think_delay = PAUSE


## Contact: on the pole it kills Keen, otherwise it pushes him; a shot
## stuns it, off the pole (Omni CK5_AmptonCol).
func _contact_ampton(other: GalaxyObject) -> void:
	if is_player(other):
		if is_on_pole():
			kill_player(other)
		else:
			_push_keen(other)
		return
	var shot := live_shot(other)
	if shot != null:
		clip = Clip.NORMAL
		direction.y = 1
		velocity.y = 0
		world.play_sound(&"ampton_stun")
		stun(shot, &"stunned")


## React while walking: walls and ledges turn it (Omni CK5_AmptonTileCol;
## the three checks are separate, as the original's).
func _react_ampton() -> void:
	if direction.x == 1 and left_hit != 0:
		_face(-1)
	if direction.x == -1 and right_hit != 0:
		_face(1)
	if top_hit == 0:
		_face(-direction.x)


func _face(facing: int) -> void:
	position.x -= moved.x
	direction.x = facing
	set_action(actions[&"turn"])


func _top_at(x: int, y: int) -> int:
	return world.clip.top_of(world.fore_tile(x, y))
