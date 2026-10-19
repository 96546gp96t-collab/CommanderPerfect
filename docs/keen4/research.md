# Keen 4 ("Secret of the Oracle"): research

Research notes for adding episode 4 to CommanderPerfect, collected in
milestone D1 (see [roadmap.md](roadmap.md)). Written for the developer of
D2 and later: look here before searching again. When a fact is checked
against the original game, update it here. Facts that end up as code get
their final, short description in `file-formats.md` and a `gameplay.md`
(written from D3 on).

Keen 4 is the first **Galaxy** episode. Almost nothing of the Vorticon
research (`docs/keen2/research.md`, `docs/keen3/research.md`) holds; what
does hold is the process: find data by content, mark every number with its
source, compare with the original while building.

Every fact names its source:

- **(files)**: checked in the user's own files (v1.0, see §0), read-only;
  every dump stayed in the scratchpad.
- **(Omni)**: Omnispeak (github.com/sulix/omnispeak, commit 144f21e), a
  GPL reimplementation of Keen 4-6 v1.4 that aims to be "bug-for-bug"
  with the original. References are `file:function` under `src/`, or its
  own text tables `data/keen4/ACTION.CK4`, `EPISODE.CK4`, `STRINGS.CK4`.
  Whether its facts and numbers may be used as Chocolate Keen's are for
  Keen 3 is **a question for the user** (§13); until then they are
  documentation, as Commander Genius is. Never copy its code.
- **(CG)**: Commander Genius (`src/engine/keen/galaxy`), documentation
  only. Its speeds and timings are often its own guesses in its own units;
  where it disagrees with Omnispeak, Omnispeak wins.
- **uncertain**: inferred, contradictory, or memory.

## 0. Versions: the user has 1.0

The user uploaded their Keen 4 on 19-10-2026: `KEEN4E.EXE` (102,355
bytes), `EGAGRAPH.CK4` (487,332), `GAMEMAPS.CK4` (99,040), `AUDIO.CK4`
(33,325), `CONFIG.CK4`. They were copied to `game_data/keen4/` (ignored by
git) for this session only.

- The text-mode sign-on screen in the EXE says **"Copyright 1991 Id
  Software Inc. (v1.0)"** (files). Omnispeak supports only v1.4 (and Keen 6
  v1.5); Commander Genius's offsets are for v1.4. The same situation as
  Keen 3 (the user had 1.00, the sources knew 1.31).
- `KEEN4E.EXE` 1.0 is **LZEXE 0.91-packed** (`LZ91`); our `DosExecutable`
  unpacks it to an image of **246,288 bytes** (files). v1.4 is not packed
  (CG: 263,488 bytes, image 0x3D740).
- v1.0 has **107 pictures** where v1.4 has 115 (files vs CG/Omni). So
  every chunk number after the pictures differs by 8 between the versions
  (sprites start at chunk 116 in 1.0, 124 in 1.4). **Never hard-code a
  chunk number**; use indices inside a range (sprite 0-396, tile 0-2915)
  and take the range starts from the file. The counts of sprites (397),
  tiles (1296 + 2916), 8×8 tiles (104 + 20), fonts (3), texts (7) and demos
  (5) are the same in both.
- The texts include "HOW TO ORDER COMMANDER KEEN" and "This level is not
  available" (files): Keen 4 was the shareware episode of the trilogy; the
  whole game is in the files.
- Behaviour differences between 1.0 and 1.4 are **not documented** in our
  sources. Omnispeak describes 1.4. Anything that looks off in 1.0 is a
  question for the original (js-dos with the user's own 1.0).
- Plan: support 1.0 (the user's) and 1.4 (Steam, GOG, the shareware
  `4keen14.zip`) by content search. A test that compares both versions
  needs a 1.4 copy; until the user has one, the 1.4 positions from CG are
  only the first place to look.

## 1. Files and the EXE (files)

The headers are inside the unpacked EXE; all six were found **by content**
in 1.0 (raw image offsets, i.e. after the MZ header):

| Piece | 1.0 position | 1.4 position (CG) | How it was found |
|---|---|---|---|
| `AUDIOHED` | 0x1FB80, 163 × 4 bytes | (searched) | 32-bit offsets from 0, ending at the size of `AUDIO.CK4`. **Entries 104-155 (the digitised slots) hold a bogus repeated value (8743) that is larger than entry 156**, so a "never decreasing" walk back from the end fails: allow that block, or walk forward from 0 |
| `EGAHEAD` | 0x1FE10, 4744 × 3 bytes (4743 chunks) | 0x21080 (4751 chunks) | 3-byte offsets from 0 to the size of `EGAGRAPH.CK4`, walking back from that size, skipping 0xFFFFFF |
| `MAPHEAD` | 0x235B0, 402 bytes | 0x24830 | 0xABCD then 100 offsets into `GAMEMAPS.CK4`; 20 maps (0-19) |
| `TILEINFO` | 0x23742 (= MAPHEAD + 402), 23,004 bytes | 0x249C2 | Follows `MAPHEAD` |
| `AUDIODCT` | 0x33FF6 | (searched) | A Huffman tree: 255 nodes, every leaf value 0-255 exactly once, every inner node 256-509 at most once, 510 never. Exactly two such places exist in 1.0; decompressing tells them apart |
| `EGADICT` | 0x343F6 | 0x358F6 | As above; it decompresses chunk 0 to 428 bytes = 107 × 4 |

In memory each dictionary takes 1024 bytes (256 nodes, the last unused);
the two are 1024 apart. The search for a valid tree over the whole image
takes a fraction of a second in Python; in GDScript, try the known places
first.

### Chunks in EGAGRAPH (files, 1.0)

| Range | Chunks (1.0) | Count |
|---|---|---|
| Tables (pictures, masked pictures, sprites) | 0, 1, 2 | 3 |
| Fonts | 3-5 | 3 |
| Pictures | 6-112 | 107 |
| Masked pictures | 113-115 | 3 |
| Sprites | 116-512 | 397 |
| 8×8 tiles, masked 8×8 tiles | 513, 514 | 1 chunk each, no length prefix |
| 16×16 background tiles | 515-1810 | 1296 (one chunk each, 128 bytes, no prefix; empty = 0xFFFFFF) |
| 16×16 foreground tiles | 1811-4726 | 2916 (160 bytes each) |
| Misc | 4727-4730 | 4: two 80×25 text screens (4008 bytes: an 8-byte header and 4000 bytes of characters and colours) and two tables of 200 line offsets (the "Terminator"-style intro credits) |
| Texts | 4731-4737 | 7: help, story ("Goodbye Galaxy"), the keys, about id, the end text, "WHOOPS!" (level not available), how to order |
| Demos | 4738-4742 | 5: each starts with its map number (1, 9, 11, 15, 19) |

The empty chunks (1344 in 1.0) are all 16×16 tiles that are never used.

- **Sprite table** (chunk 2): 18 bytes per sprite: width in bytes,
  height in pixels, origin x/y, the hit box (xl, yl, xh, yh) and the
  number of shifts. Origin and box are in **global units** (1/16 px):
  checked, sprite 10 has the box 64-304 × 48-496 = 4-19 px × 3-31 px in a
  24 × 29 px picture (files). The box is what the game collides with; it
  changes with every frame (Omni `ck_phys.c:CK_ResetClipRects`).
- **Texts** use `^P` (page), `^E` (end), `^G<chunk>,<x>,<y>` (a picture),
  `^C`/`^c<colour>`, `^L<x>,<y>`, `^T<chunk>,<x>,<y>,<tics>` (a timed
  picture), with CR LF line ends (files). **The picture numbers in `^G`
  are chunk numbers of this version** (Omni `ck_text.c`): they must be
  turned into picture indices by subtracting the start of the picture
  range.

### GAMEMAPS (files, 1.0)

All 20 maps decode with Carmack and then RLEW (tag 0xABCD) to exactly
width × height words per plane, and carry the `!ID!` signature.

| Map | Name in the file | Size | Name in the game (Omni) |
|---|---|---|---|
| 0 | ShadowLands | 61 × 66 | Shadowlands (the world map) |
| 1 | Border Village | 112 × 63 | |
| 2 | Slug Village | 146 × 44 | |
| 3 | Perilous Pit | 60 × 84 | The Perilous Pit |
| 4 | DescendentsCave | 165 × 80 | Cave of the Descendents |
| 5 | Chasm of Chills | 120 × 102 | |
| 6 | Crystalus | 80 × 124 | |
| 7 | HillVille | 150 × 44 | Hillville |
| 8 | Sand Yego | 88 × 89 | |
| 9 | Miragia | 84 × 75 | |
| 10 | Lifewater Oasis | 58 × 93 | |
| 11 | PyramidOfMoons | 100 × 100 | Pyramid of the Moons |
| 12 | Pyramid_Shadows | 100 × 99 | Pyramid of Shadows |
| 13 | PyramidAncients | 100 × 112 | Pyramid of the Gnosticene Ancients |
| 14 | PyramidForbid | 100 × 90 | Pyramid of the Forbidden |
| 15 | Isle of Tar | 112 × 92 | |
| 16 | Isle of Fire | 140 × 46 | |
| 17 | Well Of Wishes | 100 × 100 | (under water) |
| 18 | BWB Megarocket | 24 × 17 | Bean-with-Bacon Megarocket |
| 19 | HighScores | 24 × 17 | the high-score screen |

The names shown to the player come from the EXE's string table (D2: find
them by content; 1.0 has the story text at raw 0x1DB40 and the council
messages around 0x2F7DB).

### TILEINFO (files, 1.0; layout Omni `id_ti.c`)

Arrays in this order: background animation time (1296), background
animation offset (1296), then for the foreground tiles (2916 each): **top,
right, bottom, left, animation offset, misc, animation time**. (The order
in `file-formats.md` from before the files were seen was wrong; corrected
there.)

Counts in 1.0: 79 animated background tiles, 247 animated foreground
tiles, 535 foreground tiles drawn in front of sprites (misc bit 0x80).
Top values used: 0, 1, 2-7 (slopes), 9 (deadly with slope 1), 17 (pole
hole), 128 (one tile, unknown). Right and left are only 0 or 1.

## 2. Time and units

### The clock (Omni `id_sd.c`, `id_rf.c:RFL_CalcTics`)

- The timer runs at 140 Hz (560 Hz while AdLib music plays); the game's
  `TimeCount` ticks at about **70 Hz: one tic = 1/70 s**.
- A logic frame takes the tics since the last frame, at least **2**
  (MINTICS) and at most **5** (MAXTICS; slower machines slow the game
  down). **On any modern machine the original runs exactly 2 tics per
  frame: 35 logic frames per second.**
- Demos always use **3** tics per frame.
- A level starts with 3 tics.

### Units (Omni)

- **16 global units = 1 pixel, 256 = 1 tile.** Positions, velocities
  (units per tic), sprite origins and hit boxes are all in these units.
- Movement per frame is clamped to ±239 units in x and −239…+255 in y, so
  nothing crosses a whole tile in one frame (`ck_phys.c:CK_PhysUpdateNormalObj`).
- Timers count tics.

### The decision for our engine (architect)

Keen 1-3 run 60 ticks per second in n/32 px. **Keen 4 does not convert.**
It keeps the original's units and tics, so every number from the research
goes into the code as it is, and its own `GalaxyClock` runs a logic frame
of **2 tics (35 per second)**, 3 for demos. Reasons:

- Gravity and acceleration act on **odd absolute tics**, some things every
  8th tic; thresholds like "jump timer ≤ 9" and the per-frame clip limits
  would drift with any conversion.
- At 1 tic per frame the original's ledge grabbing breaks (Omnispeak needs
  a fix for it: `ck_keen.c:CK_KeenJumpThink`).
- The shared `Interpolation` already draws "part of the way between two
  logic steps", so the existing **smooth motion** option (off by default)
  gives high-frame-rate pictures without touching the logic.

For readers who think in our old units: a velocity of v units/tic is
4.375·v px/s (walk 24 → 105 px/s); a time of t tics is t/70 s.

### Random numbers (Omni `id_us_1.c:US_RndT`)

A fixed 256-byte table, read in order from an index; the index starts from
the clock at every level load, and from 0 in demos. The table is data in
the EXE: read it from there (D2, by content: it starts 0, 8, 109, 220,
222, 241, 149). Exactness matters only for demos.

## 3. The action (state) system (Omni `ck_def.h`, `ck_play.c`)

Every object runs an **action**: a record of 30 bytes in the original's
data segment (Omni `ACTION.CK4` gives the offsets in 1.4, stepping 0x1E):

| Field | Meaning |
|---|---|
| left / right sprite | the sprite for each facing (one if only "left" is set) |
| type | 0 step once at the end of the timer; 1 slide (velocity × tics every frame), think at the end; 2 think every frame, no timer; 3 step + think every frame; 4 slide + think every frame |
| protect | 0: a frame never runs past the end of the action (leftover tics are lost); 1: leftover tics carry into the next action |
| stick to ground | the object never walks off a ledge (it is pushed down, and moved back if there is no floor; its react sees "no floor" and turns) |
| timer | tics |
| vel x, vel y | multiplied by the facing |
| think, contact, react | functions: think (AI), contact (with another object), react (after the tile collision; draws) |
| next | the next action (none: the object is removed) |

Order of one frame (`ck_play.c:CK_PlayLoop`): input; per object: wake up
within the screen + 1 tile, sleep beyond + 4 tiles (only with a chance of
2 × tics in 256 per frame; some objects stay awake, some are removed
off-screen), then think + motion + tile clipping; Keen rides his
platform; every pair of awake objects is tested, **both** contact
functions run; Keen's tile specials; react; camera; score box; draw.
At most 100 objects; slot 0 is Keen, slot 1 the score box.

**For our code**: the actions become our own data (a table per object
kind with the numbers above), the think/contact/react functions become
methods named in the table. Reading the 30-byte records out of the user's
EXE is possible (CG does it), but they contain code addresses and are at
other places in 1.0; we write our own tables (question for the user,
§13).

## 4. Physics and tiles (Omni `ck_phys.c`, `ck_def.h`)

### Gravity and helpers

| Helper | Does |
|---|---|
| Gravity high | on each odd tic vel y += 4, at most **70**; a value −4…−1 becomes 0 |
| Gravity mid | the same with +3 (Keen on Easy, mushrooms, fireballs, death) |
| Gravity low | Omnispeak's condition is never true: constant velocity (§12) |
| Accel horizontal (a, max) | += a on odd tics up to ±max, turns the facing |
| Damp horizontal | ±1 towards 0 on odd tics |

### Tile sides

- **Top** (and bottom for ceilings): 0 none, 1 flat, 2-7 slopes (heights
  per pixel column in a table; 2/3 gentle down to the right, upper/lower
  half; 4 steep down to the right; 5/6 gentle up to the right; 7 steep up),
  **8-15 deadly floor** (the slope is value & 7), **17 pole hole** (shots
  and Keen going up pass). The code uses 0x19 for "standing on a
  platform".
- **Right / left**: walls. The tile's right flag stops an object's *left*
  edge and the other way round.
- **Misc** (low 7 bits): 1 pole, 2 door, 3 deadly, 4 lifewater drop, 5/6
  platform switch on/off, 7-10 gem holders (four colours), 11-14 water on
  the map (four sides), 15 bridge switch, 16 the "moon" spot, 18 bridge,
  21-26 point items (100 … 5000), 27 extra life, 28 stunner charge.
  Bit 0x80: draw in front of sprites. (Hidden passages are just tiles with
  that bit; nothing turns see-through.)
- In 1.0 (files): one platform switch tile (misc 5) is used in 13 levels;
  misc 6 is never used; two bridge switch tiles (misc 15) in levels 8,
  11-15; misc 18 does not occur; the moon spot in level 11; the gem
  holders in levels 3, 4, 6, 8, 10-16.

### Clipping

- Floors and ceilings are found under the **middle column** of the hit
  box only; on a slope the object snaps to the slope's height at that
  pixel. Walls: the left and right columns over the box's rows (the bottom
  row skipped on a slope); pushed out by whole tiles. The result per side
  is kept (the flag value) for the react function.
- A simpler box clip for the swimmers and flyers (school fish, Dopefish,
  the flying bird, Keen swimming), and no clip for some.
- Platforms carry Keen: he moves with the platform each frame and leaves
  it when he moves up or off its sides. Objects can push Keen sideways
  (the Bounder).

## 5. Keen (Omni `ck_keen.c`, `ACTION.CK4`)

Timers in tics, speeds in units/tic.

| Move | Numbers |
|---|---|
| Start | info 1 facing right, 2 facing left; y = tile × 256 − 241 |
| Walk | 24 (105 px/s), frames of 6 tics; on slopes +0/+4/+8 down, −4/−8 up (§12) |
| Idle | after 200 tics looks up; after 300 bored animations (or the moon on misc 16); after 700 sits and reads a book |
| Look up / down | the camera follows 1 px per tic; looking down + jump on a thin flat tile drops through it |
| Jump | vel y −40 kept for up to 18 tics while jump is held, then gravity high; air control ±2 on odd tics up to 24, damping without input; from a run vel x 16 |
| Fall off a ledge | vel x 8 |
| Pogo | start: −48 and at once 288 units up, timer 24; every bounce −48, timer 24; air control ±1, no damping; pogo again → fall |
| Shoot | standing 9 + 6 tics (also up); in the air in 3 directions including down; on a pole 4 directions |
| Pole | grab with up/down (or up in the air); climb 8, slide 24; jump off: −20 for 10 tics, vel x ±8 |
| Ledge | while falling with left/right held: hang, then up or towards the wall pulls up (4 × 10 tics), down or away drops |
| Door (misc 2) | up: slide to the door's middle, 5 × 9 tics in; the target is the info word under the door (x in the high byte, y in the low); 110 tics untouchable |
| Switch, gem holder | up / standing with the gem: slide, then 8 + 8 / 6 tics |
| Death | random death sprite, vel y −40, vel x 16, gravity mid; the camera stops; then the "Try Again / Exit to Shadowlands" box (§9) |

Heights (Omnispeak's numbers in a scratch model without walls): jump held
**70 px** (4.4 tiles), tapped 30-40 px; pogo held **108 px**, not held
~45-49 px; the first pogo from the ground ~126 px. These are the first
things to check in js-dos (§12).

### The neural stunner

Shot speed 64 (4 px/tic), 4 frames of 6 tics; removed 10 tiles beyond the
screen (6 vertically), but it still stuns and wakes objects there; stops
at walls except pole holes. Without charges: a click (sound
KEENOUTOFAMMO).

### Inventory and score (Omni `ck_game.c`, `ck_keen.c`)

- New game: **3 lives, 5 charges, extra life at 20,000**, then 40,000,
  80,000 … (doubling).
- Items (info 57-68 or misc 21-28): four gems (no points), 100, 200, 500,
  1000, 2000, 5000 points, an extra life, a stunner (+5 charges, +8 on
  Easy). The gem colours and item names are **uncertain** (memory:
  red/yellow/blue/green; soda, gum, candy bar, jawbreaker, doughnut, ice
  cream cone): read them from the sprites in D2.
- **Lifewater drops** (misc 4): 100 drops give a life.
- Gems are lost at the end of a level and on death. Stunned enemies give
  no points.

### Swimming (level 17)

A separate set of actions for Keen, placed by info 42: box clip, every 8th
tic the velocity relaxes towards (0, +4) (slow sinking), the stick adds
±2, jump kicks (18 in the held directions), a bubble every 60 tics, no
stunner (Omni `ck4_misc.c:CK4_KeenSwim`).

## 6. The info plane in levels (Omni `ck4_misc.c:CK4_ScanInfoLayer`; checked against 1.0)

"a/b/c": a on Easy and up, b only from Normal, c only on Hard.

| Value | Object | In 1.0 maps (files) |
|---|---|---|
| 1 / 2 | Keen facing right / left | every level |
| 3 | Keen on the world map | 0 |
| 4 | council member (the janitor in level 14) | 3, 4, 6, 10, 12, 13, 14, 16, 17 |
| 5 / 49 / 50 | Berkeloid | |
| 6 | Princess Lindsey | 5, 7 |
| 7 / 51 / 52 | Wormmouth | |
| 8 / 45 / 46 | Skypest | |
| 9 | cloud | |
| 10 | the Foot | 14 |
| 11 | inchworm | 7, 11 |
| 12 | Bounder | 1, 2, 3, 7 (and 19, the high-score map) |
| 13 | egg (CG: a bird on Normal/Hard, §12) | 5, 6 |
| 77 / 78 | bird (Normal / Hard) | |
| 14 / 47 / 48 | Lick | |
| 15 / 87 / 88 | Dopefish | 17 |
| 16 | school fish | 17 |
| 17 / 23 / 24 | sprite (under water) | 17 |
| 18 | Smirky (the treasure eater) | 13 |
| 19 | Mimrock | |
| 20 / 73 / 74 | Arachnut (73 does not occur in 1.0) | |
| 21 | Mad Mushroom | |
| 22 / 43 / 44 | poison slug | |
| 25 / 26 | scroll block horizontal / vertical | |
| 27-30 | platform going up / right / down / left | |
| 31 | turn point for platforms and mines ("B-block") | |
| 32 | falling platform | |
| 33 | Miragia (map) | 0 |
| 34 | stunner, only if Keen has fewer than 5 charges | |
| 35 | the wetsuit | 9 |
| 42 | Keen swimming | 17 |
| 53-56, 79-82, 83-86 | dart gun up / right / down / left (all, Normal, Hard) | |
| 57-60 | gems | |
| 61-66 | point items | |
| 67 | extra life | |
| 68 | stunner | |
| 69-72 | mine going up / right / down / left (69 does not occur in 1.0) | 17 |
| 75 | (only loads the moon sprites) | 11 |

Values ≥ 0x100 in levels are **targets**: x in the high byte, y in the low
byte, under doors, gem holders and switches (files: e.g. 0x1A1F in level
1).

## 7. Enemies and objects (Omni `ck4_obj1/2/3.c`, `ck_obj.c`)

"Stun lasts" = stays stunned (stars) for good; a stun makes the object hop
(−24).

| Object | Moves | Kills Keen | Stunner |
|---|---|---|---|
| Poison slug | 8 per tic; sometimes stops 60 tics facing Keen and leaves slime (deadly 300 tics, fades in 60) | touch, slime | stun lasts |
| Mad Mushroom | hops in place towards Keen: two hops −40, then −68 | touch | no effect |
| Egg / bird | the egg hatches when touched or shot; the bird walks to Keen, flies when Keen is 3+ tiles higher (up to 16), lands near him | touch | 240 tics + recovery |
| Arachnut | ~21 per tic, turns to Keen every 4 steps | touch (also on a pole) | 240 + 80 tics, harmless then |
| Skypest | flies at random (up to 20), lands and preens ~240 tics | touch in the air | only pushed; **dies only when Keen pogos on it on the ground** |
| Wormmouth | hidden mound, slides 16 to Keen, peeks, bites when Keen is close in front | only the bite | stun lasts |
| Cloud | sleeps until touched, then follows Keen; above him: flashes and strikes with lightning | the bolt | none |
| Berkeloid | floats 8, bobs, throws fireballs (±48, −8) that burn on the ground ~100 tics | touch, fireball | no effect |
| Inchworm / Foot | worms creep to Keen; when one touches 11 others they become the Foot | no | none |
| Bounder | bounces −50, sometimes sideways (24); Keen can ride and steer it | no (pushes) | stun lasts (then a platform) |
| Lick | hops to Keen, flames near him | the flame | stun lasts |
| Smirky | jumps for items, eats items and item tiles, teleports | no | stun lasts |
| Mimrock | a rock that sneaks after Keen when he looks away, then jumps | in the air | stun lasts |
| Dopefish | swims to Keen (up to 10), eats him (and school fish), burps | eats | none |
| School fish | follows Keen | no | none |
| Sprite (water) | bobs, aims 40 tics, shoots (64) | touch, shot | none |
| Mine | moves like a platform (12), turns at turn points | touch | none |
| Dart gun | every 150 tics while awake; dart 64 | the dart | none |
| Platforms | 12; turn at a turn point; the falling platform sinks under Keen, falls, comes back (32) | no | none |
| Council member | walks 64 per 10 tics, pauses | no | none |
| Lindsey | floats; touching shows her message | no | none |
| Wetsuit | touching it: message, the level ends | no | none |

Exact frames, timers and chances per action are in Omnispeak's
`ACTION.CK4` and the obj files; the developer of D5/D6 transcribes them
per object (as numbers, marked `(Omni)`, if the user allows that).

## 8. The world map (map 0; Omni `ck_map.c`, `ck4_map.c`)

- **Keen** walks in 8 directions at 24 per tic on each axis (diagonals are
  faster), 4 frames of 4 tics, waves after 360 tics.
- **Entering a level**: jump, pogo or fire on info **0xC000 + n** (n =
  1-18; in 1.0 map 0 has 0xC001-0xC012) (files).
- **Done levels** (1-17): every info word whose low byte is the level is
  cleared; high byte **0xD0**: the foreground tile is removed too (1.0:
  0xD001, 0xD002, the fences of levels 1 and 2); high byte **0xF0**: a
  flag goes there (1.0: 0xF001-0xF011). The level just finished gets a
  flag **thrown** in an arc from Keen (~50 tics, two sounds); the others
  wave.
- **Water** (misc 11-14): without the wetsuit "I can't swim!" and Keen is
  pushed back; with it he swims (16 per tic, own frames). The wetsuit is
  in **Miragia** (level 9) and is needed to reach the Well of Wishes
  (level 17).
- **Miragia** (info 33): a 6×4 block that fades in and out from template
  tiles on row 60 of the map (300 tics, 30-tic steps, 300 tics); stays
  hidden while Keen is in the area.
- **The Foot** (level 14 or the inchworms): touching it ends the level
  (done) and on the map Keen flies on the Foot to the Pyramid of the
  Forbidden (or back), in a straight line.
- Each level has a text on entering ("Keen enters …") in a box with a
  count-down picture while loading.
- Galaxy has **no "Keens left" window**.

## 9. Levels, the story and the end

- **Level exit**: walking out of the scroll area to the left or right
  (no exit door). Falling out of the bottom: death.
- **Gem holders** (misc 7-10): the holder's tile becomes tile + 18; the
  info word under it points at the door; the door (as tall as the column
  of equal tiles) opens in three steps of 10 tics.
- **Switches** (misc 5): the switch tile flips; it toggles a turn point
  (info XOR 0x1F) at the target, so platforms stop or turn. **Bridge
  switches** (misc 15): the bridge tiles at the target advance by their
  animation offset.
- **Council members** (8 to rescue; 9 in the files): touching one while
  standing: the Oracle message box ("Oh thank you so much …", in level 17
  the bubbly version), Keen's answer (8 different ones), the level is
  done. The one in level 14 is the **janitor**: a five-box conversation;
  he does not count.
- **Lindsey** (levels 5 and 7): hints (the wetsuit in Miragia; the way to
  the Pyramid of the Forbidden lies under the Pyramid of the Moons).
- **The end**: after the 8th rescue the end text pages (`^P` pages with a
  blinking arrow), then the high scores.
- **Try again**: after a death a box "You didn't make it past <level> /
  Try Again / Exit to Shadowlands"; game over with no lives left.
- **Cheats** (original): B+A+T (all gems, 99 charges, a life), E+N+D (to
  the end), A+2+Enter turns on F10 debug keys (god mode, warp, …). The
  warp and god mode make js-dos checks easy.

## 10. Screens, menus, sound

- **Score box**: a sprite at the top left of the view with score (9
  digits), lives and charges (2 digits), turned off in the menu
  (Configure → Options). In demos a DEMO sign.
- **Status window** (Enter): drops down; location, score, extra life at,
  rescued (one icon each), difficulty, gems, charges, lives, drops,
  wetsuit.
- **Help** (F1): five topics from the texts.
- **Menus**: the original's "control panel" with cards: New Game (Easy,
  Normal, Hard), Load/Save (6 slots), Configure (sound off/PC/AdLib, music
  off/AdLib, options, keyboard, joystick), **Paddle War**, End Game, Quit.
- **Demo loop**: intro credits → demo → story → demo → high scores (demo
  on map 19) → demo → demo. Demos run at 3 tics per frame with "two-button
  firing" and the fixed random table.
- **High scores**: 8 entries with the number of rescued elders as icons;
  typed in on map 19.
- **Sound**: 52 sounds, each as PC speaker and as AdLib version, 140 Hz,
  with priorities. **Music**: 6 songs, AdLib only, 560 Hz; the song per
  map is a table (Omni `EPISODE.CK4`: map 0 song 0; 1 → 4; 2, 3 → 3; 4, 5
  → 2; 6 → 4; 7 → 3; 8-10 → 1; 11-16 → 2; 17 → 1; 18 → 3); the council
  messages have their own song (5); the end uses the song of map 7. The
  song titles contain the series name: never show them.
- 1.0 (files): `AUDIOHED` chunks 0-51 are the PC sounds, 52-103 the
  AdLib sounds, 104-155 empty, **156-161 the six songs** (3734 … 2282
  bytes, starting with a 16-bit length).

## 11. Things an implementer will trip over

1. **Version 1.0 vs 1.4**: other chunk numbers (pictures 107 vs 115), other
   positions, a packed vs an unpacked EXE. Indices in ranges, never chunk
   numbers. The `^G` numbers in texts are chunk numbers.
2. **The digitised-sound gap in `AUDIOHED`** breaks the simple
   "walk back from the file size" search (§1).
3. **The tileinfo order** (§1): top, right, bottom, left, anim offset,
   misc, anim time.
4. **Hit boxes change per frame** (from the sprite table), not per object.
5. **Logic at 35 Hz, not 60**: everything shared that counts 60 Hz ticks
   (the views' tick loops) is copied into Keen 4's own view, as Keen 2 and
   3 did, with `GalaxyClock`.
6. **Widescreen shows beyond scroll blocks** (§13, question).
7. **Masked tiles in front**: only bit 0x80 decides; the lesson of the
   masked-tile bug after C7.
8. **Tiles that change while playing** (doors, switches, bridges, gem
   holders, Miragia, done levels on the map, slime): always through one
   `set_tile` that updates the layer, xBRZ and the collision.
9. **No Real-ESRGAN pipeline** unless the user wants it (Keen 2 and 3
   skipped it).
10. **The OPL2 synthesiser** is the largest single new piece (§13).

## 12. Only the original can answer

To check in js-dos with the user's own 1.0 (`tools/original/` on the C
branches; the cheats and warp in §9 help):

1. **The pogo**: Omnispeak's "gravity low" never accelerates (its own
   comment calls this suspect). It decides the pogo height (108 px held).
2. **The jump**: 70 px held? (Keen 1-3's jumps turned out too high in our
   engine; measure Keen 4's in D3, not at the end.)
3. **Walking on slopes**: faster downhill and slower uphill (Omnispeak adds
   the slope table to x; the disassemblers disagree).
4. **Smirky's teleport**: Omnispeak removes it after the first teleport,
   which is probably wrong.
5. **Info 13**: an egg on every difficulty (Omnispeak) or a bird on
   Normal/Hard (CG)?
6. **Map 18** (the Megarocket): entrance 0xC012 is on the map in 1.0; what
   happens when Keen enters?
7. **Differences 1.0 / 1.4** in anything we measure.
8. **The original's bugs** (1-tic ledge grabbing at high speed, the
   platform draw order fixed only in Keen 6, the Bounder pole/door glitch):
   at 2 tics per frame most do not show; reproduce what shows.
9. **The speeds and timers of every enemy**, as far as Omnispeak's numbers
   are not trusted; looking at an enemy while Keen stands still is enough
   for most.

## 13. Questions for the user

1. **Sources**: may Omnispeak's facts and numbers (speeds, timers,
   chances, info values, action tables) be used, marked `(Omni)`, as
   Chocolate Keen's for Keen 3? Never its code. And the reconstructed
   Keen 4-6 source (K1n9_Duk3; decompiled code): not at all, or the same
   as Omnispeak? *Advice: Omnispeak yes, the reconstruction no.*
2. **Logic rate**: Keen 4 runs at the original's 35 logic frames per
   second (2 tics), with the existing smooth motion as the option for a
   higher frame rate. *Advice: yes.*
3. **Widescreen and scroll blocks**: the camera stops at scroll blocks as
   in 4:3, and what the wider picture would show beyond them is covered
   (black or the picture behind the level). *Advice: yes.*
4. **HUD**: the original's score box is the HUD, in 4:3 and widescreen;
   no extra HUD. *Advice: yes.*
5. **Sound**: our own OPL2 synthesiser in GDScript that renders sounds and
   songs once (in the background) into a cache in `user://keen4/cache/`;
   AdLib sounds and music on by default (as the original with a sound
   card), PC speaker as a choice. *Advice: yes. Alternative: a C++
   GDExtension (faster, but a native build for macOS and Windows).*
6. **Two players**: up/down are needed in levels, so the two-player keys
   get up/down; that adds four lines to the shared Controls menu (also
   seen in Keen 1-3). *Advice: yes, in D12.*
7. **Paddle War**: build it (last milestone, D11)? *Advice: yes, it is
   small.*
8. **Demos and the intro**: the title loop with the five demos and the
   intro credits as in the original (needs the exact random table and 3
   tics per frame)? *Advice: yes, in D8.*
9. **Real-ESRGAN**: skip, as for Keen 2 and 3? *Advice: skip.*
10. **Branches**: D2 starts after Keen 3 is on `main` (fourth icon on top
    of a finished Keen 3), or now from the newest C branch? *Advice: after
    Keen 3, or from the newest C branch if Keen 4 must start sooner.*
11. **A 1.4 copy**: the Steam/GOG version or the shareware `4keen14.zip`
    (davidgow.net; blocked in the cloud) would let us test both versions.
    Not required.

### The user's answers (19-10-2026)

1. **Omnispeak: yes.** Its facts and numbers may be used, marked `(Omni)`;
   never its code. The reconstructed Keen 4-6 source is not used.
2. **35 logic frames per second** (2 tics), smooth motion as the existing
   option (off by default).
3. **Widescreen**: the camera stops at scroll blocks; what lies beyond is
   covered.
4. **The score box is the HUD**, in 4:3 and widescreen; no extra HUD.
5. **Sound**: our own OPL2 synthesiser in GDScript, rendered once into
   `user://keen4/cache/`; AdLib sounds and music on by default.
6. **Two players**: up/down are added to the shared two-player keys (D12).
7. **Paddle War**: yes (D11).
8. **Intro and the five demos**: yes (D8).
9. **Real-ESRGAN**: skipped, as for Keen 2 and 3.
10. **D2 starts after Keen 3 is on `main`.**
11. Not asked; a 1.4 copy stays optional.

## Watching the original

The js-dos tools from C1 (`tools/original/`, on the C branches) work for
Keen 4 unchanged: bundle `game_data/keen4/*`, start `KEEN4E`. Keen 4
needs no `/LEVEL` trick: New Game, then the warp debug key (A+2+Enter,
then F10+W) or walking on the map. God mode (F10+G) keeps Keen alive
while watching. The D1 cloud session had no browser pane, so nothing was
measured in js-dos yet.

## Lessons for the new-episode guide

(To be added to `docs/new-episode-guide.md` when Keen 3 is merged; that
file is not changed now because another session is working on it.)

- D1: the Galaxy headers can all be found by content in the unpacked EXE:
  the two Huffman trees by their shape, the offset tables by their end
  value, `MAPHEAD` by its tag. Do the same for Keen 5 and 6.
- D1: Omnispeak is to Galaxy what Chocolate Keen is to Vorticons: a
  reimplementation that follows the original closely. Clone it from
  GitHub (the proxy allows it); davidgow.net and shikadi.net are blocked.
- D1: the Keen 4 shareware is not in the PCjs repository; the user's own
  files are needed (or the shareware zip on the Mac).
- D1: keep the Galaxy engine (`src/galaxy/`) apart from the episode
  (`src/keen4/`), so Keen 5 and 6 never need to subclass Keen 4.
