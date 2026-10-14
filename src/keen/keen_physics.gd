class_name KeenPhysics
extends RefCounted
## All numbers that decide how Keen moves, in one place for fine-tuning.
##
## Keen's logic runs in fixed ticks of 1/60 second, whatever the frame rate.
## Distances are in game pixels; speeds in pixels per tick; accelerations in
## pixels per tick per tick. The values are written as multiples of
## [constant SUBPIXEL] (1/32 pixel), the unit in which they were measured.
##
## The starting values come from the published constants of Commander Genius,
## which were tuned to feel like the original (see docs/keen-physics.md). They
## still have to be compared side by side with the original game.

const TICKS_PER_SECOND := 60
const TICK := 1.0 / TICKS_PER_SECOND
## The original game never falls behind more than this; after a long hitch
## Keen skips time instead of running dozens of ticks at once.
const MAX_TICKS_PER_FRAME := 5
const SUBPIXEL := 1.0 / 32.0

# --- Body ---------------------------------------------------------------------
const SPRITE_SIZE := Vector2(16, 24)
## Keen's collision box inside the 16x24 sprite, from the sprite table of
## EGAHEAD.CK1 (left 4, top 1, 8 wide) down to his feet in the bottom row.
const HITBOX := Rect2(4, 1, 8, 23)

# --- Walking ------------------------------------------------------------------
const WALK_MAX_SPEED := 68 * SUBPIXEL
## Speed of the first step, so that walking starts without delay.
const WALK_START_SPEED := 16 * SUBPIXEL
## Speed gained per tick while a direction is held on the ground.
const WALK_ACCELERATION := 3.5 * SUBPIXEL
## Speed lost per tick on the ground when no direction is held.
const GROUND_FRICTION := 14 * SUBPIXEL
## Ticks per frame of the four-frame walking animation.
const WALK_FRAME_TICKS := 9

# --- Jumping ------------------------------------------------------------------
## Keen crouches before he jumps. Every [constant CROUCH_FRAME_TICKS] ticks the
## next crouch frame is shown, until the jump button is released or the last
## frame is reached. The longer the crouch, the higher the jump.
const CROUCH_FRAME_TICKS := 2
const CROUCH_FRAMES := 5
const JUMP_SPEED := 120 * SUBPIXEL
## Upward speed lost per tick while rising.
const JUMP_DECELERATION := 4 * SUBPIXEL
## Horizontal speed when jumping off with a direction held.
const JUMP_HORIZONTAL_SPEED := 64 * SUBPIXEL
## Speed gained per tick in the air while a direction is held.
const JUMP_AIR_CONTROL := 3 * SUBPIXEL
## Speed lost per tick in the air when no direction is held.
const AIR_FRICTION := 2 * SUBPIXEL

# --- Falling ------------------------------------------------------------------
const MAX_FALL_SPEED := 104 * SUBPIXEL
## Downward speed gained per tick after the top of a jump.
const JUMP_FALL_ACCELERATION := 8 * SUBPIXEL
## Speed when walking off a ledge, and the speed gained per tick after that.
const LEDGE_FALL_START_SPEED := 32 * SUBPIXEL
const LEDGE_FALL_ACCELERATION := 4 * SUBPIXEL
## Speed gained per tick while falling off a ledge with a direction held.
const LEDGE_AIR_CONTROL := 1 * SUBPIXEL

# --- Pogo stick ---------------------------------------------------------------
## Ticks Keen stays compressed on the pogo stick before bouncing.
const POGO_COMPRESS_TICKS := 11
## Bounce without the jump button: as high as a full jump.
const POGO_LOW_SPEED := JUMP_SPEED
## Bounce with the jump button held.
const POGO_HIGH_SPEED := 165 * SUBPIXEL
## The first bounce after taking out the pogo stick with the jump button held
## goes even higher (the "impossible pogo" trick).
const POGO_FIRST_BOUNCE_SPEED := 175 * SUBPIXEL
const POGO_AIR_CONTROL := 2 * SUBPIXEL

# --- Sprites (numbers in the sprite table) ------------------------------------
const SPRITE_WALK_RIGHT := 0
const SPRITE_WALK_LEFT := 4
const WALK_FRAMES := 4
const SPRITE_JUMP_RIGHT := 8
const SPRITE_JUMP_LEFT := 14
const SPRITE_POGO_RIGHT := 24
const SPRITE_POGO_LEFT := 26
