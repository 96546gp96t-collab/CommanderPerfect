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
## The start cell of a level puts the top of the sprite at the top of the
## cell, so his feet hang 8 pixels above the floor. A floor at most this far
## below him is where he starts standing, like in the original.
const START_DROP := 16.0

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

# --- Raygun ------------------------------------------------------------------
## Ticks Keen holds the raygun out after firing. On the ground he cannot walk
## or jump during that time.
const SHOOT_FRAME_TICKS := 25
## Firing again is possible once fewer than this many of those ticks are left.
const SHOOT_REPEAT_TICKS := 7
const SHOT_SPEED := 124 * SUBPIXEL
## The shot leaves the raygun this many pixels below the top of the sprite.
const SHOT_HEIGHT := 9
## Size of the shot sprite (KEENSHOT).
const SHOT_SIZE := Vector2(16, 8)

# --- Dying --------------------------------------------------------------------
## Ticks per frame of the two-frame dying animation.
const DIE_FRAME_TICKS := 6
## Ticks Keen lies still before he flies off the screen.
const DIE_WAIT_TICKS := 80
const DIE_RISE_SPEED := 160 * SUBPIXEL
## Sideways speed while flying off; he drifts away from where he looked.
## An estimate, still to be compared with the original.
const DIE_DRIFT_SPEED := 16 * SUBPIXEL
## Once Keen has risen this far he is surely off the screen.
const DIE_RISE_DISTANCE := 240.0

# --- Leaving a level ----------------------------------------------------------
## Keen walks slowly through the exit door by himself.
const EXIT_WALK_SPEED := 12 * SUBPIXEL
## Ticks from touching the exit until the level is over.
const EXIT_TICKS := 200
## Keen disappears behind a line this many pixels into the exit door,
## counted from the left of the exit tile he touched: the doorway is two
## tiles wide and he is hidden 2 pixels before its right side.
const EXIT_HIDE_DISTANCE := 2 * 16 - 2

# --- Enemies ------------------------------------------------------------------
## A push from a Yorp or robot dies down by this much per tick. While it
## lasts, Keen cannot walk. An estimate, still to be compared with the original.
const PUSH_DECELERATION := 2 * SUBPIXEL
## Upward speed when Keen lands on a Yorp's head and stuns it.
const STOMP_BOUNCE_SPEED := 64 * SUBPIXEL
## Ticks Keen stays frozen after an ice chunk hits him. Near the end he thaws.
const FROZEN_TICKS := 250
const THAW_TICKS := 20
const FROZEN_FRAME_TICKS := 25

# --- Sprites (numbers in the sprite table) ------------------------------------
const SPRITE_WALK_RIGHT := 0
const SPRITE_WALK_LEFT := 4
const WALK_FRAMES := 4
const SPRITE_JUMP_RIGHT := 8
const SPRITE_JUMP_LEFT := 14
const SPRITE_POGO_RIGHT := 24
const SPRITE_POGO_LEFT := 26
const SPRITE_SHOOT_RIGHT := 20
const SPRITE_SHOOT_LEFT := 21
const SPRITE_DEAD := 22
const DEAD_FRAMES := 2
const SPRITE_FROZEN := 28
const FROZEN_FRAMES := 2
const SPRITE_THAWING := 31
