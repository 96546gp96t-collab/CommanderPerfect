class_name Keen2Spark
extends Keen2Enemy
## The spark in the glass of a Tantalus Ray machine (info value 7). It
## flickers (frames 128-131, one every [constant FRAME_TICKS] ticks) and is
## harmless to touch. One shot from Keen destroys it: it disappears, and the
## machine falls apart around it ([Keen2Tantalus]). The session counts the
## destroyed machines ([method Keen2LevelSession.machine_destroyed]). The
## enemies' shots fly through it.

const SPRITE_FIRST := 128
const FRAMES := 4
const FRAME_TICKS := 6  # estimate
## The collision box inside the sprite. estimate: to be read from the sprite
## table of EGAHEAD.CK2.
const BODY_BOX := Rect2(0, 0, 16, 16)  # estimate

## The machine falling apart, once the spark is shot; null before.
var wreck: Keen2Tantalus


## A spark at the cell whose top left is [param cell_start].
static func create(cell_start: Vector2) -> Keen2Spark:
	var spark := Keen2Spark.new()
	spark.position = cell_start
	spark.body_box = BODY_BOX
	spark.falls = false
	return spark


## The cell of the spark, the middle of its machine.
func cell() -> Vector2i:
	return Vector2i((position / EgaGraphics.TILE_SIZE).floor())


func step(session: LevelSession) -> void:
	if wreck == null:
		super.step(session)
		return
	wreck.step(session)
	removed = wreck.finished


func sprite_index() -> int:
	if is_dead:
		return -1
	return SPRITE_FIRST + (_timer / FRAME_TICKS) % FRAMES


func touches_keen() -> bool:
	return false


func touch_keen(_session: LevelSession, _keen: KeenBody) -> void:
	pass


## One shot destroys the spark and starts the wreck of the machine, in this
## very tick.
func hit_by_shot(session: LevelSession) -> void:
	if is_dead:
		return
	die()
	wreck = Keen2Tantalus.wreck(cell())
	wreck.step(session)
	var keen_2 := session as Keen2LevelSession
	if keen_2 != null:
		keen_2.machine_destroyed()


func _think(_session: LevelSession) -> void:
	_timer += 1
