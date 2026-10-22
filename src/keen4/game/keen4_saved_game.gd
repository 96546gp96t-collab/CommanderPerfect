class_name Keen4SavedGame
extends RefCounted
## A saved game of Keen 4. The original saves anywhere through its menu,
## on the world map and in a level, and a loaded level goes on exactly as
## it was (Omni `ck_game.c`: CK_SaveGame writes the game state, the three
## planes and every object). Ours keeps the same promise another way:
##   - on the world map: what Keen carries, the progress (rescues, wetsuit,
##     levels done) and his place on the map;
##   - in a level: the same as it was when Keen entered the level, the place
##     the random table started, and every logic frame since (the keys held
##     and its tics, plus the cheats and god mode as events). Loading starts
##     the level again and plays those frames at once: the engine is
##     deterministic (the five demos play frame for frame as the original),
##     so every creature, tile and item is where it was.
## Stored as a dictionary in a [GalaxySaveSlots] slot.

## Events among the frames (a frame of 0 tics); EVERYTHING is Shift+I
## (D13.2). VIEW_WIDTH is followed by one more pair of bytes, the width
## the view is drawn from then on (low byte first; 0: the original's):
## objects wake up around what it shows, so the frames played again need
## it (D13.2; a game saved before has none and played the original's).
enum Event { ITEMS_CHEAT = 1, GOD_MODE_ON, GOD_MODE_OFF, EVERYTHING, VIEW_WIDTH }

## Bits of a frame's first byte.
const LEFT := 1
const RIGHT := 2
const UP := 4
const DOWN := 8
const JUMP := 16
const POGO := 32
const FIRE := 64
const FRAME_BYTES := 2
const BYTE_BITS := 8
const BYTE_MASK := 0xFF
const DIFFICULTY_KEY := "difficulty"
const INVENTORY_KEY := "inventory"
const PROGRESS_KEY := "progress"
const MAP_KEY := "map"
const RANDOM_KEY := "random_start"
const FRAMES_KEY := "frames"

var difficulty := GalaxyDifficulty.DEFAULT
## What Keen carries (in a level: when he entered it).
var inventory := Keen4Inventory.new_game()
## The progress (in a level: when he entered it; its map position is then
## where he entered).
var progress := Keen4Progress.new()
## 0: the world map; otherwise the level played.
var map_number := Keen4Episode.WORLD_MAP
## In a level: where its random table started, and its frames.
var random_start := 0
var frames := PackedByteArray()


## Whether the game was saved in a level (not on the world map).
func in_level() -> bool:
	return map_number != Keen4Episode.WORLD_MAP


## Adds a logic frame of [param tics] tics with [param input] held to
## [param recorded].
static func record_frame(recorded: PackedByteArray, input: KeenInput, tics: int) -> void:
	var bits := 0
	bits |= LEFT if input.direction < 0 else (RIGHT if input.direction > 0 else 0)
	bits |= UP if input.vertical < 0 else (DOWN if input.vertical > 0 else 0)
	bits |= JUMP if input.jump else 0
	bits |= POGO if input.pogo else 0
	bits |= FIRE if input.fire else 0
	recorded.append(bits)
	recorded.append(tics)


## Adds [param event] (between two frames) to [param recorded].
static func record_event(recorded: PackedByteArray, event: Event) -> void:
	recorded.append(event)
	recorded.append(0)


## Adds that the view is drawn [param width] pixels wide from here on.
static func record_view_width(recorded: PackedByteArray, width: int) -> void:
	record_event(recorded, Event.VIEW_WIDTH)
	recorded.append(width & BYTE_MASK)
	recorded.append(width >> BYTE_BITS)


## Frames being played again on a level just started, a few at a time (a
## long level takes seconds; the view shows black meanwhile).
class Replay:
	extends RefCounted
	var session: Keen4LevelSession
	var recorded := PackedByteArray()
	## Called with every frame's tics (the view animates its tiles).
	var each_frame := Callable()
	## The absolute tic of the last frame played.
	var tic := 0
	var _at := 0

	## Plays frames for about [param milliseconds] (all of them when 0);
	## returns whether every frame is played.
	func play(milliseconds := 0) -> bool:
		var until := Time.get_ticks_msec() + milliseconds
		while _at + 1 < recorded.size():
			var bits := recorded[_at]
			var tics := recorded[_at + 1]
			_at += FRAME_BYTES
			if tics == 0 and bits == Event.VIEW_WIDTH and _at + 1 < recorded.size():
				session.set_wide_width(recorded[_at] | (recorded[_at + 1] << BYTE_BITS))
				_at += FRAME_BYTES
				continue
			if tics == 0:
				Keen4SavedGame._apply(session, bits)
				continue
			tic += tics
			session.run_frame(Keen4SavedGame._input_of(bits), tics, tic)
			if each_frame.is_valid():
				each_frame.call(tics)
			# The messages were seen when the game was played.
			session.take_conversation()
			if milliseconds > 0 and Time.get_ticks_msec() >= until:
				return _at + 1 >= recorded.size()
		return true


## A replay of [param recorded] on [param session] (a level just started).
static func replay_on(
	session: Keen4LevelSession, recorded: PackedByteArray, each_frame := Callable()
) -> Replay:
	var replay := Replay.new()
	replay.session = session
	replay.recorded = recorded
	replay.each_frame = each_frame
	return replay


## Plays all of [param recorded] on [param session] at once; returns the
## absolute tic of its last frame.
static func replay(session: Keen4LevelSession, recorded: PackedByteArray) -> int:
	var whole := replay_on(session, recorded)
	whole.play()
	return whole.tic


static func _input_of(bits: int) -> KeenInput:
	var input := KeenInput.new()
	input.direction = -1 if bits & LEFT else (1 if bits & RIGHT else 0)
	input.vertical = -1 if bits & UP else (1 if bits & DOWN else 0)
	input.jump = bits & JUMP != 0
	input.pogo = bits & POGO != 0
	input.fire = bits & FIRE != 0
	return input


static func _apply(session: Keen4LevelSession, event: int) -> void:
	match event:
		Event.ITEMS_CHEAT:
			Keen4Cheats.give_items(session.inventory)
		Event.EVERYTHING:
			Keen4Cheats.give_everything(session.inventory)
		Event.GOD_MODE_ON, Event.GOD_MODE_OFF:
			session.player.god_mode = event == Event.GOD_MODE_ON


func to_dictionary() -> Dictionary:
	return {
		DIFFICULTY_KEY: int(difficulty),
		INVENTORY_KEY: inventory_to_dictionary(inventory),
		PROGRESS_KEY: progress.to_dictionary(),
		MAP_KEY: map_number,
		RANDOM_KEY: random_start,
		# Godot complains about encoding nothing.
		FRAMES_KEY: Marshalls.raw_to_base64(frames) if not frames.is_empty() else "",
	}


## The game kept in [param saved]; null (and says why) when it is not one.
static func from_dictionary(saved: Dictionary) -> Keen4SavedGame:
	var stored_inventory: Variant = saved.get(INVENTORY_KEY)
	var stored_progress: Variant = saved.get(PROGRESS_KEY)
	if not (stored_inventory is Dictionary and stored_progress is Dictionary):
		push_error("The saved game has no inventory or progress.")
		return null
	var game := Keen4SavedGame.new()
	game.difficulty = (
		clampi(
			int(saved.get(DIFFICULTY_KEY, GalaxyDifficulty.DEFAULT)),
			GalaxyDifficulty.Level.EASY,
			GalaxyDifficulty.Level.HARD
		)
		as GalaxyDifficulty.Level
	)
	game.inventory = inventory_from_dictionary(stored_inventory)
	game.progress = Keen4Progress.from_dictionary(stored_progress)
	game.map_number = int(saved.get(MAP_KEY, Keen4Episode.WORLD_MAP))
	if game.map_number < Keen4Episode.WORLD_MAP or game.map_number > Keen4Episode.LAST_MAP:
		push_error("The saved game is on map %d, which Keen 4 does not have." % game.map_number)
		return null
	game.random_start = int(saved.get(RANDOM_KEY, 0)) & GalaxyWorld.RANDOM_MASK
	var stored_frames := str(saved.get(FRAMES_KEY, ""))
	if not stored_frames.is_empty():
		game.frames = Marshalls.base64_to_raw(stored_frames)
	return game


static func inventory_to_dictionary(carried: GalaxyInventory) -> Dictionary:
	return {
		"score": carried.score,
		"next_life_at": carried.next_life_at,
		"lives": carried.lives,
		"shots": carried.shots,
		"drops": carried.drops,
		"gems": Array(carried.gems),
	}


static func inventory_from_dictionary(saved: Dictionary) -> Keen4Inventory:
	var carried := Keen4Inventory.new_game()
	carried.score = int(saved.get("score", 0))
	carried.next_life_at = int(saved.get("next_life_at", carried.next_life_at))
	carried.lives = int(saved.get("lives", carried.lives))
	carried.shots = int(saved.get("shots", carried.shots))
	carried.drops = int(saved.get("drops", 0))
	var gems: Variant = saved.get("gems", [])
	if gems is Array and (gems as Array).size() == carried.gems.size():
		for colour in carried.gems.size():
			carried.gems[colour] = int(gems[colour])
	return carried
