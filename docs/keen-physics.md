# Keen's movement

How `KeenBody` moves Keen, and where its numbers come from. All constants
live in `src/keen/keen_physics.gd`, so fine-tuning only touches that file.

## Ticks and units

Keen's logic runs in fixed ticks of 1/60 second, independent of the frame
rate (`Keen` keeps the leftover time between frames). Positions are in game
pixels, speeds in pixels per tick. The constants are written as multiples of
1/32 pixel, because that is the unit the starting values were measured in.
Those fractions are exact in floating point, so the tests can compare heights
exactly.

## Where the starting values come from

The original code is not decompiled (see `CLAUDE.md`). The starting values are
the published constants of Commander Genius, which its authors tuned by
comparing with the original game at 60 logic frames per second and 1/32 pixel
per unit. Only the numbers were taken; the state machine in `KeenBody` is our
own and simpler.

| What | Value | In pixels |
|---|---|---|
| Walking speed | 68 / 32 px per tick | 127.5 px/s, 8 tiles/s |
| First step | 16 / 32 px per tick | |
| Walking acceleration | 3.5 / 32 px per tick² | full speed after 15 ticks |
| Friction on the ground | 14 / 32 px per tick² | stops within 5 ticks |
| Jump speed | 120 / 32 px per tick | |
| Slowdown while rising | 4 / 32 px per tick² | full jump: 58.1 px, 3.6 tiles |
| Speedup while falling after a jump | 8 / 32 px per tick² | |
| Falling off a ledge | starts at 32 / 32, +4 / 32 per tick | |
| Maximum fall speed | 104 / 32 px per tick | 195 px/s |
| Pogo bounce, jump not held | same as a full jump | 58.1 px |
| Pogo bounce, jump held | 165 / 32 px per tick | 108.9 px, 6.8 tiles |
| First pogo bounce, jump held | 175 / 32 px per tick | 122.4 px, 7.6 tiles |
| Pogo compression time | 11 ticks | |

## Behavior

- **Jump wind-up.** Keen crouches through five frames, one every 2 ticks.
  Releasing the button early gives a lower jump (`frame / 5` of the full
  speed); holding it to the end gives a full jump. Holding the button keeps
  him jumping.
- **In the air** the sideways control is weaker (3 / 32 px per tick² while
  jumping, 1 / 32 after walking off a ledge, 2 / 32 on the pogo stick).
  Pressing the opposite direction during a jump stops the sideways movement
  at once.
- **Bumping his head** halves the upward speed every tick until it is gone,
  so Keen sticks to the ceiling for a moment.
- **Pogo stick.** The pogo button takes it out or puts it away. With it out,
  Keen bounces by himself; holding jump at the moment of the bounce makes it
  a high bounce. The first bounce after taking out the stick with jump held is
  even higher (the "impossible pogo" trick).
- **Ice (floor type 3):** Keen slides at full speed the way he faces and
  cannot turn until a wall stops him. **Slippery floor (2):** no friction.
- **Tiles:** each side of a tile blocks on its own (see
  `docs/file-formats.md`); doors are solid until keycards exist. Touching a
  deadly tile or falling out of the bottom of the level puts Keen back at the
  start (dying and lives follow in milestone 4).
- **Collision box:** 8 x 23 pixels, from x 4 to 12 and y 1 to 24 in the
  16 x 24 sprite (sprite table in `EGAHEAD.CK1`, extended down to his feet).
- **Start:** the top left of the sprite is put at the top left of the start
  cell; Keen then drops onto the floor (8 pixels in every level of version 1.1).

## Still to compare with the original

These can only be settled by playing the original (e.g. in DOSBox) next to
CommanderPerfect:

- Walking acceleration and the speed of the walking animation.
- How high a quick tap of the jump button goes (now only 2.6 pixels).
- Whether Keen turns around in the air, and how fast he steers there.
- Pogo heights, and whether the high bounce needs the button held at the
  bounce or at any time during the compression.
- The speed of tile animations (now 0.1 s per frame).
- How the camera scrolls (now a dead zone of 10% left/right and 20% up/down
  around the center).
