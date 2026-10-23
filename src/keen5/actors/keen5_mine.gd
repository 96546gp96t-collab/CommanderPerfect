class_name Keen5Mine
extends Keen5Creature
## The Shikadi mine of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): unclipped, it floats 10 units a tic from
## tile to tile. At each tile it picks its way towards Keen: first along
## the axis where he is nearer (the other one when he is farther along it),
## then the other axis, then straight on, then any other way (in a random
## order), and only then back; a way is free when the 3 × 2 tiles it would
## enter have no solid side. When it changes its way, its eye (a second
## sprite, [member GalaxyObject.overlays]) first moves back to its middle
## and then to the side it goes to, 4 units a tic; the mine waits for it.
## When Keen comes near (two zones: one while it floats, a wider one while
## its eye moves) it pulses (sound "mine_explode", four pictures of 10
## tics, the eye gone), then bursts into six pieces ([Keen5Piece], which
## also tell an object they touch: E5's QED) and shows two pictures of 20
## tics of blast. The blast and the pieces kill Keen; the mine itself never
## does, and a shot only stops at it.

## (Omni CK5_ACT_Mine*, CK5_ACT_MineExplode*, CK5_ACT_MineShrap0.)
const ROWS: PackedStringArray = [
	"float SHIKADIMINE SHIKADIMINE think -- 8 0 0 float mine eye -",
	"eye_back SHIKADIMINE SHIKADIMINE think -- 0 0 0 eye_back mine eye eye_out",
	"eye_out SHIKADIMINE SHIKADIMINE think -- 0 0 0 eye_out mine eye float",
	"pulse_1 SHIKADIMINEPULSE1 SHIKADIMINEPULSE1 step -- 10 0 0 - mine - pulse_2",
	"pulse_2 SHIKADIMINEPULSE2 SHIKADIMINEPULSE2 step -- 10 0 0 - mine - pulse_3",
	"pulse_3 SHIKADIMINEPULSE1 SHIKADIMINEPULSE1 step -- 10 0 0 - mine - pulse_4",
	"pulse_4 SHIKADIMINEPULSE2 SHIKADIMINEPULSE2 step -- 10 0 0 burst mine - blast_1",
	"blast_1 SHIKADIMINEBOOM1 SHIKADIMINEBOOM1 step -- 20 0 0 - deadly - blast_2",
	"blast_2 SHIKADIMINEBOOM2 SHIKADIMINEBOOM2 step -- 20 0 0 - deadly - -",
	"piece SHIKADIMINEPIECE SHIKADIMINEPIECE think -- 8 0 0 fall piece shrapnel -",
]
const RISE := Vector2i(0, -0x1F1)
const PRIORITY := 0
## Units a tic, and the distance from tile to tile (Omni).
const SPEED := 10
const TILE := GalaxyUnits.PER_TILE
## The ways it can go, in the original's order: up, right, down, left.
const WAYS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const NO_WAY := -1
## The tiles a way must have free: 3 wide, 2 high, from the next tile
## (Omni CK5_MinePathClear).
const PATH_SIZE := Vector2i(3, 2)
## Keen this near makes it explode (Omni: the mine's position minus his,
## both ends excluded): while it floats ...
const FLOAT_ZONE := Rect2i(-0x500, -0x50, 0x700, 0x350)
## ... and while its eye moves.
const EYE_ZONE := Rect2i(-0x300, -0x300, 0x500, 0x600)
## The eye: its sprite's place in the middle and at each side, how fast it
## moves (units a tic), its drawing priority (Omni).
const EYE_MIDDLE := Vector2i(0x100, 0xD0)
const EYE_LEFT := 0x80
const EYE_RIGHT := 0x180
const EYE_UP := 0x50
const EYE_DOWN := 0x150
const EYE_SPEED := 4
const EYE_PRIORITY := 2
## The six pieces: where they start from its position, their speed, and
## the random part of their sideways speed (divided by this; 0: none)
## (Omni CK5_MineExplode).
const PIECE_STARTS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(0x100, 0),
	Vector2i(0, 0),
	Vector2i(0x100, 0),
	Vector2i(0, 0),
	Vector2i(0x100, 0),
]
const PIECE_SPEEDS: Array[Vector2i] = [
	Vector2i(0, -48),
	Vector2i(0, -48),
	Vector2i(40, -24),
	Vector2i(-40, -24),
	Vector2i(24, 16),
	Vector2i(24, 16),
]
const PIECE_RANDOM_DIVISORS: PackedInt32Array = [-8, 8, 16, 16, 0, 0]

## Where its eye is drawn, from its position (Omni user2, user3).
var eye := EYE_MIDDLE
## Units to the next tile (Omni velX).
var to_next := TILE


## A mine at [param cell] (info 7, 8, 9): the first free way of up, right,
## down and left (Omni CK5_SpawnMine).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Mine:
	var mine := Keen5Mine.new()
	mine.priority = PRIORITY
	mine.clip = Clip.NONE
	mine.direction = Vector2i.ZERO
	mine.place(world, cell, RISE, ROWS, sprites, &"eye_out")
	for way in WAYS.size():
		if mine._try_way(way):
			break
	return mine


## Think while floating: Keen near sets it off; at each tile it chooses its
## way, and when that changes its eye moves first (Omni CK5_MineMove).
func _think_float() -> void:
	if _keen_within(FLOAT_ZONE):
		_light_fuse()
		return
	var distance := world.tics * SPEED
	if to_next <= distance:
		step = direction * to_next
		distance -= to_next
		var was := direction
		_seek_keen()
		to_next = TILE
		if direction != was:
			_continue_as(&"eye_back")
			return
	to_next -= distance
	step += direction * distance


## Think: the eye goes back to the middle (Omni CK5_MineMoveDotsToCenter).
func _think_eye_back() -> void:
	_move_eye(EYE_MIDDLE)


## Think: the eye goes to the side it floats to (Omni
## CK5_MineMoveDotsToSides).
func _think_eye_out() -> void:
	var side := EYE_MIDDLE
	if direction.x != 0:
		side.x = EYE_LEFT if direction.x < 0 else EYE_RIGHT
	if direction.y != 0:
		side.y = EYE_UP if direction.y < 0 else EYE_DOWN
	_move_eye(side)


## Think at the last pulse: six pieces fly off (Omni CK5_MineExplode).
func _think_burst() -> void:
	world.play_sound(&"mine_explode")
	for index in PIECE_STARTS.size():
		var speed := PIECE_SPEEDS[index]
		var divisor := PIECE_RANDOM_DIVISORS[index]
		if divisor != 0:
			# The original divides by a negative number for the first piece.
			speed.x += world.random() / divisor
		var piece := Keen5Piece.throw(
			world, position + PIECE_STARTS[index], speed, ROWS, sprites, &"piece"
		)
		piece.reports_touches = true


## Contact: a stunner shot stops at it (Omni CK5_MineCol).
func _contact_mine(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()


## React: the eye is drawn with it (Omni CK5_MineTileCol).
func _react_eye() -> void:
	if overlays.is_empty():
		var drawn := Overlay.new()
		drawn.sprite = sprites.get(&"SHIKADIMINEEYE", NO_SPRITE)
		drawn.priority = EYE_PRIORITY
		overlays.append(drawn)
	overlays[0].offset = eye


func _keen_within(zone: Rect2i) -> bool:
	var away := position - _keen().position
	return (
		away.x > zone.position.x
		and away.x < zone.end.x
		and away.y > zone.position.y
		and away.y < zone.end.y
	)


## Keen came near: it pulses and bursts; the eye is gone.
func _light_fuse() -> void:
	world.play_sound(&"mine_explode")
	_continue_as(&"pulse_1")
	overlays.clear()


## Moves the eye towards [param target], 4 units a tic each way; each way
## that arrives moves the action on (both arriving at once skips the next
## one, as in the original). Keen near sets it off first.
func _move_eye(target: Vector2i) -> void:
	if _keen_within(EYE_ZONE):
		_light_fuse()
		return
	needs_react = true
	var speed := world.tics * EYE_SPEED
	if _eye_arrives(0, target.x, speed):
		action = action.next
	if _eye_arrives(1, target.y, speed):
		action = action.next


## Moves axis [param axis] of the eye towards [param target]; whether it
## got there now.
func _eye_arrives(axis: int, target: int, speed: int) -> bool:
	if eye[axis] == target:
		return false
	if eye[axis] < target:
		eye[axis] = mini(eye[axis] + speed, target)
	else:
		eye[axis] = maxi(eye[axis] - speed, target)
	return eye[axis] == target


## Chooses the way towards Keen (Omni CK5_SeekKeen; never back unless
## nothing else is free).
func _seek_keen() -> void:
	var ahead := WAYS.find(direction)
	var back := (ahead + 2) % WAYS.size()
	var gap := _keen().position - (position + step)
	var along_x := NO_WAY
	var along_y := NO_WAY
	if gap.x != 0:
		along_x = 1 if gap.x > 0 else 3
	if gap.y != 0:
		along_y = 2 if gap.y > 0 else 0
	var first := along_y
	var second := along_x
	if absi(gap.y) > absi(gap.x):
		first = along_x
		second = along_y
	for way in [first, second]:
		if way != NO_WAY and way != back and _try_way(way):
			return
	if _try_way(ahead):
		return
	var order := [0, 1, 2, 3] if world.random() > HALF_RANDOM else [3, 2, 1, 0]
	for way in order:
		if way != back and _try_way(way):
			return
	_try_way(back)


## Goes way [param way] when its path is free (Omni CK5_Walk).
func _try_way(way: int) -> bool:
	var next := position + step
	var cell := Vector2i(GalaxyUnits.to_tile(next.x), GalaxyUnits.to_tile(next.y)) + WAYS[way]
	for y in PATH_SIZE.y:
		for x in PATH_SIZE.x:
			if world.clip.is_solid(world.fore_tile(cell.x + x, cell.y + y)):
				return false
	direction = WAYS[way]
	return true
