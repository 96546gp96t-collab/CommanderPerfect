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
  changes with every frame (Omni `ck_phys.c:CK_ResetClipRects`). **D2:**
  both origin and box are relative to the object's position, and the
  picture is drawn at position + origin: sprite 10's origin is (0, 32), so
  its box covers pixels 4-19 × 1-29 of the picture and ends on its bottom
  row (files).
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

The names shown to the player come from the EXE (found by shape in D2;
file-formats.md, "Texts and tables in KEEN4E.EXE"): in 1.0 the story text
is at raw 0x1DB40, the 19 level names (maps 0-18) at 0x1DD40, each on a
16-byte boundary, then the 19 "Keen enters …" texts and the janitor's
records; the council, Lindsey and wetsuit messages are 17 records from
0x2F5BC (files).

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
the EXE: read it from there (by content: it starts 0, 8, 109, 220,
222, 241, 149; D2 found it at raw 0x1DA32 in 1.0). Exactness matters only
for demos.

## 3. The action (state) system (Omni `ck_def.h`, `ck_play.c`)

Every object runs an **action**: a record of 30 bytes in the original's
data segment (Omni `ACTION.CK4` gives the offsets in 1.4, stepping 0x1E):

| Field | Meaning |
|---|---|
| left / right sprite | the sprite for each facing (one if only "left" is set) |
| type | 0 step once at the end of the timer; 1 slide (velocity × tics every frame), think at the end; 2 think every frame, no timer; 3 step + think every frame; 4 slide + think every frame |
| protect | when an action is reached with leftover tics: 1 lets them run it to its end in that frame; 0 stops it one tic short and the rest is lost (D4: corrected; Omni CK_RunAction tests the action reached, not the one that ended) |
| stick to ground | the object never walks off a ledge (it is pushed down, and moved back if there is no floor; its react sees "no floor" and turns) |
| timer | tics |
| vel x, vel y | multiplied by the facing |
| think, contact, react | functions: think (AI), contact (with another object), react (after the tile collision; draws) |
| next | the next action (none: the object is removed) |

Order of one frame (`ck_play.c:CK_PlayLoop`): input; per object: wake up
within the screen + 1 tile, sleep beyond + 4 tiles (only with a chance of
2 × tics in 256 per frame; some objects stay awake, some are removed
off-screen), then think + motion + tile clipping; Keen rides his
platform; (D13, seen in the demos: after placing them,
`CK4_ScanInfoLayer` puts every object but the ever-awake ones to sleep;
the step of the object that runs is one shared variable, which starting an
action on any other object clears; a door puts the view on Keen inside his
think, so the objects after him in the list already see the new view); every pair of awake objects is tested, **both** contact
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
| Gravity low | Omnispeak's condition is never true: constant velocity (§12; D4: the original does the same) |
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
things to check in js-dos (§12). **D4, seen in the original:** held jump
67 px, pogo held 105 px, not held 41 px, the first bounce from the ground
50 px: the scratch model ran its frames on even tics; the original's first
frame of a level is 3 tics, so its frames start on odd tics ("Watched in
D4").

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
- D7, seen in the original (details in "Watched in D7"): the walk (3
  pixels a frame, the pictures walking 2, standing, walking 1, standing),
  waving after 360 tics, the box when leaving the map ("One moment") and
  entering one, the thrown flag, the fences, "I can't swim!", swimming
  (2 pixels a frame), Miragia's 300 / 30 tics, the Foot's flight, map 18.

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
  he does not count. (D2: the EXE holds four records for it, three of his
  and Keen's reply. D6, seen in the original: the fifth box has no text,
  only Keen's talking picture with his cross face over it; then the
  janitor is gone and the level goes on.)
- **Lindsey** (levels 5 and 7): hints (the wetsuit in Miragia; the way to
  the Pyramid of the Forbidden lies under the Pyramid of the Moons). D6,
  seen in the original: level 7 gives the wetsuit hint (Omni
  CK4_LindseyMessage1Level 7), level 5 the pyramid.
- **The end**: after the 8th rescue the end text pages (`^P` pages with a
  blinking arrow), then the high scores.
- **Try again**: after a death a box "You didn't make it past <level> /
  Try Again / Exit to Shadowlands"; game over with no lives left.
- **Cheats** (original): B+A+T (all gems, 99 charges, a life), E+N+D (to
  the end), A+2+Enter turns on F10 debug keys (god mode, warp, …). The
  warp and god mode make js-dos checks easy. D8, seen: E+N+D on the world
  map shows the elder's box, Keen's eighth answer and his thumb, then the
  end pages.

## 10. Screens, menus, sound

- **Score box**: a sprite at the top left of the view with score (9
  digits), lives and charges (2 digits), turned off in the menu
  (Configure → Options). In demos a DEMO sign.
- **Status window** (Enter): drops down; location, score, extra life at,
  rescued (one icon each), difficulty, gems, charges, lives, drops,
  wetsuit.
- **Help** (F1): five topics from the texts. D8: v1.0's help has no
  border pictures and a light grey background ("Watched in D8").
- **Menus**: the original's "control panel" with cards: New Game (Easy,
  Normal, Hard), Load/Save (6 slots), Configure (sound off/PC/AdLib, music
  off/AdLib, options, keyboard, joystick), **Paddle War**, End Game, Quit.
- **Demo loop**: intro credits → demo → story → demo → high scores (demo
  on map 19) → demo → demo. Demos run at 3 tics per frame with "two-button
  firing" and the fixed random table. D8: seen so, and all five demos play
  frame for frame as in the original ("Watched in D8").
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
- D9 (Omni `id_sd.c`, facts only): the timer is set with 1192030 / rate,
  so the music ticks at 1193182 / 2128 = **560.7 Hz** and the sounds (every
  4th tick with AdLib music) at **140.2 Hz**. A sound plays when its
  priority is at least that of the sound playing; when its steps are done
  the priority is 0. PC sound bytes × 60 are the timer divisor. AdLib
  sounds: channel 0, the instrument's ten operator bytes (not its
  connection byte), block | 0x20 in 0xB0, notes in 0xA0, 0 = key off.
  Songs: every command whose time has come is written in a tick, and after
  the last command the song starts again on the next tick (a round = delay
  sum − last delay + 1). Starting a song (StartMusic) always starts it
  from its beginning; StartMusic(−1) plays the special song 5 (council,
  janitor); the end plays map 7's song, the story map 12's; the help and
  the pause stop the music. The sound list, the song table and where each
  sound is played: gameplay.md, "Sound and music".

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

1. ~~**The pogo**: Omnispeak's "gravity low" never accelerates (its own
   comment calls this suspect). It decides the pogo height (108 px held).~~
   Done in D4: the original does not accelerate either; a held bounce is
   105 px (see "Watched in D4").
2. ~~**The jump**: 70 px held? (Keen 1-3's jumps turned out too high in our
   engine; measure Keen 4's in D3, not at the end.)~~ Done in D4: 67 px.
3. ~~**Walking on slopes**: faster downhill and slower uphill (Omnispeak adds
   the slope table to x; the disassemblers disagree).~~ Done in D4: uphill
   20 a tic instead of 24, as Omnispeak adds.
4. **Smirky's teleport**: Omnispeak removes it after the first teleport,
   which is probably wrong. D5: in the original (level 6 with Smirky put
   next to Keen, 25 s) he hopped about and against the edge of the view
   but no teleport was caught; ours teleports to the last item still lying
   in the level and is gone only when there is none (architecture.md,
   "Deviations in D5", 9). D13: watched 70 s (level 6, Smirky put next to
   Keen): he stood 40 tics, hopped left to the wall, jumped for the items
   above, hopped right and left the view after 11 s; no puff in the view.
   Still open (a teleport off screen cannot be seen).
5. ~~**Info 13**: an egg on every difficulty (Omnispeak) or a bird on
   Normal/Hard (CG)?~~ Done in D5: an egg on Normal (the shot broke it: the
   shell, the bits and the bird appeared), as Omnispeak.
6. ~~**Map 18** (the Megarocket): entrance 0xC012 is on the map in 1.0; what
   happens when Keen enters?~~ Done in D7: "One moment", "Keen launches
   into the Bean-with-Bacon Megarocket", and a small level with the ship in
   which Keen walks; walking out of it (left) ends it as any level: the
   map's box, Keen back at the place he entered. It gets no flag (flags are
   1-17) and can be entered again (see "Watched in D7").
7. **Differences 1.0 / 1.4** in anything we measure.
8. **The original's bugs** (1-tic ledge grabbing at high speed, the
   platform draw order fixed only in Keen 6, the Bounder pole/door glitch):
   at 2 tics per frame most do not show; reproduce what shows.
9. **D6: what was not measured.** The falling platform (Keen did not land
   on the one put next to him in level 2 in three tries), the switch's
   effect on a platform, a horizontal platform's turn, the Dopefish (it
   was not reached in level 17 within the time; a scratch map with it
   next to Keen is the way), the sprites under water and the mines: all
   Omnispeak's numbers. Also open: after the wetsuit's first box the
   first key press seemed not to be taken (one try; D13: it is taken,
   it shows Keen's thumb up, a second key closes the box). D13: the falling
   platform seen (as ours, "Watched in D13: estimates"); the switch, the
   horizontal turn, the Dopefish, the sprites under water, the mines and
   the wetsuit's key still open. D13 (continued): the Dopefish, the
   sprite, the mines (they bounce off a turn point; so do the platforms)
   and the wetsuit's box seen; only the switch left.
10. **The speeds and timers of every enemy**, as far as Omnispeak's numbers
   are not trusted; looking at an enemy while Keen stands still is enough
   for most. D5: the Bounder, Mad Mushroom, bird, Arachnut, Skypest,
   Lick, Berkeloid and Mimrock watched (see "Watched in D5"); all as
   Omnispeak. Not watched: the slug's slime, Wormmouth, cloud, inchworms
   and the Foot, the dart guns, Smirky's teleport. D13: Smirky's stand
   (40 tics) and hops seen; the others still open (time). D13
   (continued): the slime, the Wormmouth's peek, the cloud and its bolt,
   the inchworms, the dart guns and the fireball's burn seen, all
   Omnispeak's; the Wormmouth's bite, the Foot and Smirky's teleport
   left.

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

### Watched in D3 (js-dos, the user's v1.0)

Headless js-dos (`tools/original/headless.js`, bundle in the scratchpad,
frames never in the repository): `KEEN4E`, a key past the sign-on screen
and the intro, New Game, Normal, then the debug keys (A+2+Enter holds A
and 2 and presses Enter: "Debug keys active") and the warp (hold F10 for
~300 ms and press W: "Warp to which level(1-18):"). Our 4:3 picture
(320 × 200, the World viewport) compared pixel by pixel:

- **The first view of level 1, 4, 11, 14 and 17 and of the world map is
  the original's to the pixel**: the same scroll position, the same tiles
  of all three layers, Keen (standing, map Keen, swimming Keen) on the same
  pixel. Only the score box (D4), the enemies (D5) and the phase of the
  animated tiles differ. So CK_CentreCamera, the scroll limits, the start
  y (tile × 256 − 241) and the sprite origins are confirmed for v1.0.
- Level 17's view moves sideways in the first frames as Keen sinks (the
  world-map style camera; D6); frame 0010 of the recording matches ours.
- **Tile animation** (level 1, 6 s recorded, 35 frames a second: a frame
  every 28.6 ms = 2 tics): drops every 114 ms (8 tics), eyes 571 / 2,855 ms
  (40 / 200 tics), a tree 286 ms (20 tics), a face 3,140 ms (220 tics):
  TILEINFO's times in tics of 1/70 s, confirmed.
- **In front of Keen**: the original draws the in-front tiles (misc bit
  0x80) over Keen; ours too (checked with Keen moved behind the rock in
  level 1 and behind the Megarocket in map 18; not compared in js-dos,
  where Keen cannot move yet in our engine).
- Level 14 on Normal: Keen is killed within seconds of the warp by the
  enemies near the start ("You didn't make it past Pyramid of the
  Forbidden / Try Again / Exit to Shadowlands"); Try Again restarts the
  level with the same first view.

### Watched in D4 (js-dos, the user's v1.0)

Headless js-dos as in D3 (warp needs F10 held ~500 ms with W held 400 ms;
the first try often fails). Keys: Ctrl jump, Alt pogo. Recordings of every
frame (`rec 400 0`), Keen found by his shirt colour (255, 85, 255) and the
view's movement by matching the background between frames (scratchpad
scripts; frames never in the repository). Positions are the sprite's top
row; the shirt's row in each sprite was read from our own decoding.

| What | Omnispeak (scratch model) | The original (v1.0) | Ours (D4) |
|---|---|---|---|
| Jump, held | 70 px | 67 px: 9 frames of 5 px (−40 for 18 tics), then 4, 4, 4, 3, 2, 2, 2, 1, 0, 0; airtime 35 frames | 67 px, the same frames |
| Jump, held ~90 ms (3 frames) | 30-40 px | 37 px | 37 px |
| Pogo, held | 108 px | 6 px in each of 12 frames (−48 kept for 24 tics: no gravity), then gravity: ~105 px | 105 px |
| Pogo, not held | 45-49 px | 41 px a bounce; the first from the ground 50 px (−14 px in its first frame: the 6 × −48 lift clamped to 239 units) | 41; the first 50 or 56 (by when the standing timer ends) |
| Walking, flat | 24 a tic | 36 px per 24 tics | 24 |
| Walking up a gentle slope | 24 − 4 | 30 px per 24 tics (level 1's hill) | 20 |
| Pole: sliding / climbing | 24 / 8 a tic | the view follows him 3 / 1 px a frame | 24 / 8 |
| Door | 5 × 9 tics in, info target | he walks to the door, walks in, stands in the room; level 1's door at x 77-78 leads to the room with four sodas, the one at 66-67 to the room with the pole (two stunners, two candy bars) | the same rooms |
| Score box | — | the box with dim "8"s, 0, 3 lives, 5 charges, 4 px from the corner | the same |

Not measured in the original yet (time): grabbing a ledge (level 1's pits
are too shallow: the spikes touch Keen before his hands reach the line;
level 4 has ledges, our engine grabs and pulls up there), the gem door,
items' rising shadows, the idle animations' timing. Open for D13.

### Watched in D5 (js-dos, the user's v1.0)

Headless js-dos as in D4, Normal, god mode (F10+G), warp (F10+W).
Creatures that are not near a level's start were watched in a **scratch
copy of `GAMEMAPS.CK4`** (scratchpad only, never in the repository): one
info value added in the first view of levels 1-7 (the info plane written
back as plain Carmack and RLEW words at the end of the file, the map
header pointing at it). Recordings of every frame with Keen standing
still; creatures found by their colour or by what changes in a region.

| What | Omnispeak | The original (v1.0) | Ours (D5) |
|---|---|---|---|
| Bounder (level 1) | −50 from every landing, gravity high; 24 sideways | 39 px up in 12 frames (6, 5, 5, 5, 4, 3, 3, 3, 2, 1, 1, 1), down in 12; landings 26 frames apart; 3 px a frame sideways | −50, 24; 36-39 px depending on the tic parity (below) |
| Mad Mushroom (level 2, placed) | hops −40, −40, then −68, gravity mid; in place, facing Keen | two hops of 30-32 px, then a leap of 22 frames up, again and again; it stays in place | the same (31 px a hop) |
| Egg, info 13 (level 1, placed) | an egg on every difficulty | an egg on Normal; a shot broke it into the shell, three bits and a bird | an egg |
| Bird | stands 120 tics, then 128 units every 7 tics | stood ~1 s after the recording began, then 8 px every 3-4 frames (7 tics) towards Keen | the same |
| Arachnut (level 3, placed) | 128 units every 6 tics, to Keen every 4 steps | 145 px in 1.5 s (~8 px every 86 ms), turning back past Keen | 128 / 6 tics (140 px in 1.5 s) |
| Skypest (level 9) | preening frames 10 tics, rests 100 / 60 / 100 tics | preening pictures 143 ms (10 tics) each, the last rest 1427 ms (100 tics), then it takes off; wing frames 5 tics | the same |
| Lick (level 14) | flame frames 4 tics | 57 ms (4 tics) a frame; two Licks hop to Keen and burn him | the same |
| Berkeloid (level 4, placed) | fireball 48 sideways from −8, gravity mid, burns on the ground | 70 px in 24 tics (48 a tic) sideways; the fire burns on the ground | the same |
| Mimrock (level 7, placed) | sits; sneaks when Keen looks away | sat, and sneaked a few steps back and forth as Keen's facing changed | the same rules |
| Smirky (level 6, placed) | teleports after two misses | hopped about, also against the view's edge, for 25 s; no teleport seen | see §12 point 4 |

**The tic parity drifts in the original.** The Bounder's 39 px fit −50
with gravity on the *second* tic of every frame (frames starting on even
tics); D4 measured Keen's jump at a level's start, where frames start on
odd tics. Any frame of 3 tics (js-dos jitter, a slow machine) flips the
parity for the rest of the level, so a rise of the same speed can differ
by 3 px in the original. Ours keeps odd tics while the clock runs evenly.

### Watched in D6 (js-dos, the user's v1.0)

Headless js-dos as in D5, Normal, god mode, warp (F10+W: the W held when
the prompt opens is typed into it; a Backspace clears it). A scratch
`GAMEMAPS.CK4` (scratchpad only) put a council member next to Keen in
levels 1 and 14, Lindsey in 5 and 7, the wetsuit in 9, a falling platform
in 2.

| What | Omnispeak | The original (v1.0) | Ours (D6) |
|---|---|---|---|
| Message boxes (council, Keen's answer and thumb up, janitor ×5, Lindsey ×3, wetsuit) | US_CenterWindow(26, 8), picture left or right, text 6 / 12 down | every box compared pixel by pixel with ours: **0 pixels differ** (frame, white inside, centred text in the menu font, the pictures) | `GalaxyWindow`, `Keen4Messages` |
| The janitor's fifth box | Keen talking + cross face, no text | the same; then he is gone, the level goes on | the same |
| Lindsey's hint by level | level 7: the wetsuit | level 7: "There's gear to help you swim …" | the same |
| After the third council box | — | a key: back on the world map, "Keen enters …" | the next level (D7: the map) |
| Platform (level 8, info 29) | 12 units a tic | 170 px in 3.25 s: 52.3 px a second (12 × 70 / 16 = 52.5) | 12 |
| Swimming, nothing held | every 8th tic towards (0, +4); 0 → +1 → 0 sideways | sinks 19.4-19.8 px a second (4 and 5 by turns: 4.5 a tic = 19.7); drifts right 2 px a second | the same rules |
| Swimming, right held | stick +2 every 8th tic | 50 px a second after a second (12-13 a tic: 55) | the same rules |
| Swimming, kick with nothing held | the kick only sets the held directions | no change of speed | the same |
| Level 17's view | CK_MapCamera | moves once Keen's box leaves 80-112 px from the top | `GalaxyCamera.follow_map` |

### Watched in D7 (js-dos, the user's v1.0)

Headless js-dos as in D6, Normal, debug keys (A+2+Enter), warp (F10+W),
"end level" (F10+E). Two scratch copies of `GAMEMAPS.CK4` (scratchpad
only): A moved the map Keen to (54, 42) above a water tile and Miragia to
(46, 44), with the wetsuit next to Keen in level 9; B moved the map Keen
to (53, 34) under level 1's entrance, with the Foot next to Keen in level
1. Keen and the flags were found in every recorded frame by matching our
own decoded sprites exactly (scratchpad script); boxes were compared pixel
by pixel by laying ours over the original's frame.

| What | Omnispeak | The original (v1.0) | Ours (D7) |
|---|---|---|---|
| Map Keen walking | 24 a tic on each axis, a picture every 4 tics | 3 px a frame (2, 4, 2, 4 on the screen: drawn on even pixels), stand, walk 1, stand, walk 2; walking left from the start the view scrolls up with him as he slides along a sloped wall, 3 px a frame from the 14th frame | the same frames and the same scroll (x 1 px off on odd pixels, see below) |
| Waving | after 360 tics, 5 × 20 tics | after about 5.3 s, pictures 286 ms apart | the same |
| Leaving the map | "One moment" (US_Print from the left) | the box "One moment", **centred**, for 0.4-0.7 s; 0 pixels differ (centred) | centred, 28 tics |
| "Keen enters …" | box 26 × 8, the count-down picture, text centred in the rest 4 above the middle; fingers 4 … 0 at (24, 40) | over the last picture of the map or level (not black); 0 pixels differ (box and every finger); fingers 130-630 ms apart (the time to read the files), the last 0.4 s before a fade of three 6-tic steps, ~0.35 s black, three 6-tic steps back | 21 tics, 4 × 20, 28, fade 3 × 6, 19 black, 3 × 6 |
| Map 18 | entrance 0xC012 | a level; walking out ends it, back on the map; no flag | the same |
| Thrown flag | from a tile up-left of Keen's place, 30 points, 50 tics, Flips 12 tics | starts at Keen's place, up 8.5 px a frame (with Keen's place one tile lower: 8.5 = Omnispeak's arc), frames 12 tics; it waits while the map fades in | the same path; waits for the fade (the map runs only after it) |
| Fences | 0xD001 / 0xD002 clear the tile | level 1 done: the fence north of the village is gone, Keen walks through | the same |
| Waving flag | holder + (0x60, -0x1E0) | at its holder | the same |
| "I can't swim!" | text 6 down | text **12** down; 0 pixels differ with 12 | 12 |
| Swimming | 16 a tic, 18 tics on by himself (user3 −= 6, the stick after) | 2 px a frame; into the water from the north he swims back north 9 frames, turns at the **third** think (12 tics, not 18) and swims south; out of the water he **walks on at once** (Omnispeak stands him first) | the same positions frame by frame |
| Miragia | 300 hidden, 30 / 30 / 30, 300 whole, 30 / 30 / 30 | 300, 30, 30, 30 tics (429 ms steps), 300 whole, 30 × 3 back, 300 hidden | the same |
| The Foot | 140 tics back to (0x1000, 0x2F00) from the east | flew west on the Foot, 8 px a frame, the two pictures 30 tics each; landed by the Pyramid of the Moons | the same targets |
| Status window | CK_DrawStatusWindow, 8 px a tic | dropped in ~0.3 s; **0 pixels differ** (window, arm, strap, labels in XOR) | the same |
| Try Again | window 20 × 8, choice frame blinking 12 / 1 every 16 tics | 0 pixels differ (both colours); over the death scene; Exit → the map's box, Keen at his place, one life less | the same |

**Sprites on even pixels.** The map Keen and the thrown flag only ever
showed on even x pixels (272, 268, 266, 262 … where our positions give
272, 269, 266, 263): the original keeps four shifts of a sprite, so it
draws them at x steps of 2 pixels. Ours draws on whole pixels; the
difference is at most one pixel sideways, in levels too. Built in D8.1
(see "Watched in D8.1").

### Watched in D8 (js-dos, the user's v1.0)

Headless js-dos as before; a bundle without `CONFIG.CK4` (the original's
own high scores) and one whose `CONFIG.CK4` had every score set to 0 (to
reach the name entry with E+N+D's 0 points). Every changed frame recorded;
Keen found in each frame by matching our decoded sprites exactly; pages
and tables laid over the original's frames pixel by pixel.

| What | Omnispeak | The original (v1.0) | Ours (D8) |
|---|---|---|---|
| Title loop | intro, demo 0, story, demo 1, high scores (demo 4), demo 2, demo 3 | the same; after the fizzle the title stays 6.0 s (420 tics), then black and the "DEMO" box | the same |
| Intro scroll | 1864 tics (1.0's words), credits at 160 − width / 2 | ~26.6 s; frames at 2-tic steps match ours exactly (**0 pixels differ** at tics 498 … 1398); the 72-pixel credit sits at 128, not 124: centred by **whole bytes** (160 − (bytes / 2) × 8) | the same (fixed in D8) |
| Zoom | 30 tics | 11 frames, each equal to one of ours (**0 pixels differ**) | the same |
| Fizzle | 360 steps, `VL_DelayTics(1)` | a step every 14 ms (one tic), over the zoom's last picture with the words white | the same (our own random order) |
| Story | a row every 4 tics, squeezed rows | **0 pixels differ** (frame of run 2b, distance 277) | the same |
| Demo box | `CK_LoadLevel` with "DEMO" | the loading box with "DEMO", over black after a full screen, over the last picture after a demo; the high scores without a box | the same |
| Help (1.0) | 1.4 has borders and red | light grey, no borders, text dark grey, "pg n of m" at (248, 190), menu picture at (96, 8), hand at (48, 48 + 24 n); **0 pixels differ** (menu and 8 pages) | the same |
| End pages | `help_endgame` | light grey; the ^T pauses as written (100, 10, 140, 1, 10, 140, 10, 140 tics on page 1); keys during them are lost; arrow at (296, 184), dim / bright every ~1 s; **0 pixels differ** (pages 1, 3, 16) | the same |
| B+A+T | box 20 × 7 | lives + 1, 99 charges (the box itself was not caught: it went by with the keys) | the same |
| E+N+D | rescued = 7, council rescued | on the world map too: the elder's box over the map, "You're the last one, fella …", Keen's thumb, then the end; with 0 points no name (the table has 10,000) | the same |
| High scores | names at (24, 51 + 16 n), icons at 152, scores right at 296, colour 15 | XOR into the map's picture; **0 pixels differ** (the table over map 19) | the same |
| Name entry | `US_LineInput`, cursor 0x80 | map 19's tiles only (no Keen, no creatures), the new row empty with its icons; "AB" typed: **0 pixels differ**, with the cursor and without (it blinks every ~0.51 s) | the same |

**Demos.** Each demo recorded in full (every changed frame) and Keen
found in every frame; our engine played the same demo headless and the
two lists laid side by side (aligned on the first movement, a frame of 3
tics = 42.9 ms, one frame of slack for the recorder's timing):

| Demo | Map | Frames | Compared | Result |
|---|---|---|---|---|
| 0 | 1 (Border Village) | 744 | 525 recorded frames, to the last | in sync to the end: sprite and place equal in every frame (Keen walks, jumps, pogoes, goes through two doors) |
| 1 | 9 | 687 | 470 | in sync to the end |
| 2 | 11 | 749 | 418 | in sync to the end |
| 3 | 15 | 645 | 463 | in sync to the end |
| 4 | 19 (high scores) | 271 | 243 | in sync to the end |

So D3-D7's Keen, physics and creatures play the demos as the original
does; nothing needed fixing. The random table from index 0 and
two-button firing (Omnispeak's facts) are confirmed by it.

**Sprites and scrolling in steps.** Measured on Keen in the demos: the
original draws a sprite at its x rounded down to 8 / (the sprite's shifts
in the sprite table) pixels: 2 pixels for most sprites (4 shifts), 8 for
Keen going through a door (sprites 73-76 have 1 shift: he jumps 6 pixels
left at the door), and it scrolls the view in steps of 2 pixels. With that
rule ours and the original's places are equal in every frame of all five
demos. Ours drew on whole pixels until D8.1, which draws the same way
(see "Watched in D8.1").

### Watched in D8.1 (js-dos recordings of D8, the user's v1.0)

The rule of D8, now in the engine (`GalaxyObjectLayer.pixel_of`,
`GalaxyCamera.view_pixels`), checked against Omnispeak's `id_rf.c` and
`id_ca.c`: a sprite is cached in 1, 2 or 4 shifted copies (the sprite
table's count); with 4 the shift used is (x & 7) / 2 (2-pixel steps), with
2 the copies cover shifts 0-1 and 2-3 (4-pixel steps), with 1 there is only
the unshifted one (8-pixel steps). The view's left is panned by the scroll's
units & 0xef (an even pixel); its top is not rounded. The score box (sprite
129) and the DEMO sign (sprite 5) are sprites with 4 shifts and origin x 0
placed at the scroll + 4 and + 128 pixels, so they keep their place in the
view; the DEMO sign's origin puts it 3 pixels lower (y 11), which D8 had
missed (fixed).

**Whole frames compared.** Our engine played each demo in the real Keen 4
view (4:3, xvfb, OpenGL) and saved the World viewport after every logic
frame; the original's recorded frames of D8 were aligned with them by
Keen's track (as in D8) and compared pixel by pixel with our frames n − 1,
n and n + 1:

| Demo | Recorded frames compared | Identical (D8 code) | Identical (D8.1) | What still differs |
|---|---|---|---|---|
| 0 (map 1) | 639 | 40.7 % | **91.2 %** (583) | the stars over a stunned creature in another phase (two runs of ~35 frames, 39-79 pixels), a tile animation 1 frame apart (18 pixels), a poison slug drawn one frame later after a door (1 frame), and in the last 18 frames a Bounder that bounces elsewhere (its random choices) |
| 1 (map 9) | 662 | 26.4 % | **100 %** (662) | nothing |
| 2 (map 11) | 664 | – | 85.2 % (566) | the drops from the ceiling and the inchworms in another phase or place (33-600 pixels) |
| 3 (map 15) | 599 | – | 41.7 % (250) | the poison slugs walk elsewhere from the first seconds (their random turns); Keen and the view stay in sync |

(The D8 column masks the DEMO sign, which D8 drew 3 pixels too high.)
Sprites and the view are drawn exactly as the original's; what remains
are creatures whose random choices or animation phases differ from the
original's (Keen's own track is equal in every frame, D8). Not part of
D8.1: the creatures' use of the random table (Omnispeak deactivates an
object off screen only when `US_RndT() < sprite sync × 2`, which draws a
random number) is a candidate for a later look. Done in D13: every
difference had a cause and all five demos now match (see "Watched in D13:
demos").

### Watched in D9 (js-dos, the user's v1.0)

Headless js-dos as before, with the bundle's `dosbox.conf` given a
`[mixer]` (44.1 kHz) and `[sblaster]` (OPL2) section. js-dos 8 sends
DOSBox's audio from its worker straight to an AudioWorklet that
time-stretches it to keep up; the page replaced `AudioWorkletNode` by a
subclass whose `port` is a MessageChannel of its own, so the raw samples
were recorded on their way (and passed on). The game waits on its sign-on
screen ("Ready - Press a Key", AdLib detected) for a key. Recorded: the
title loop with the user's `CONFIG.CK4` (AdLib sounds and music) and with
music set off in a copy of it (bytes 520-521 = 0). Ours: the cached
renderings and our demo 0 with its sounds logged per tic.

| What | The original (v1.0, DOSBox's OPL) | Ours (D9) |
|---|---|---|
| Story song (song 2) | at its start the same partials (65, 129, 522, 781, 980 Hz; then 393, 312, 75 Hz …) | the same; laid side by side second by second the spectra correlate 0.8-0.93 for the whole round |
| Demo 0's song (song 4) | the same notes and timbre; per-second spectra correlate 0.5-0.9 (Keen's and the Bounder's sounds on top) | the same |
| Tempo | the song drifts steadily against ours by 11.8 % (both runs: cycles=auto and fixed 30000), and so do the sounds' steps and Keen's walk sounds (12 tics apart: 0.195 s instead of 0.171) | 560.7 ticks a second, 8 per game tic |
| Sounds in demo 0 | the Bounder's leap (sound 16) every 48 tics, Keen's steps every 12 tics, a step hidden when the leap (priority 60) plays over it (20); a leap: loudest 86 Hz, 0.29 s, average spectrum correlates 0.84 with ours; steps 0.02 and 0.05 s (3 and 7 heard steps) | the same order and intervals; the leap 86 Hz, 0.30 s; the steps 0.02 and 0.05 s |
| Loudness | about a third of ours (RMS) | chosen against the PC speaker |

So the songs, the sounds, their priorities and the "last step is never
heard" rule are confirmed. The 11.8 % applies to the music, the sounds and
the game's own tics alike: js-dos's emulated time runs slower than its
audio stream (its pitches are right), so the absolute tempo cannot be read
from it, but the music's tempo relative to the game is ours. The 560.7 Hz
stays Omnispeak's PIT divisor (1192030 / 560).

### Watched in D10 (js-dos, the user's v1.0)

Headless js-dos as before (the developer on port 8768, the tester on
8769 with a bundle without CONFIG.CK4); every card, dialog and step
snapshotted, ours drawn on a 320 × 200 picture and laid over it.

| What | Omnispeak | The original (v1.0) | Ours (D10) |
|---|---|---|---|
| Opening | a key in the demo loop, Escape in a game | the same; the cursor on NEW GAME (demo) or RETURN TO GAME (game) | the same |
| Main card | NEW GAME … PADDLE WAR, QUIT | the same 8 choices; SAVE GAME and END GAME with the "x" icon out of a game; "RETURN TO DEMO" out of a game; "Press F1 for Help and Order Info" is part of the watch picture | **0 pixels differ** (apart from our CHOOSE GAME in PADDLE WAR's row) |
| Colours | foreground 10, "disabled" 2 (EPISODE.CK4) | the other way round: a choice dark green (2), the one under the cursor light green (10); footer 2; lines and frames 10 | as the original |
| Cursor | blinks every 35 tics | the icon blinks; a slot's box (its icon) blinks too | the same |
| New game | cursor on the second choice | BEGIN NORMAL GAME under the cursor, also in a game | **0 pixels differ** |
| Load / save | six boxes 11 px apart, "Empty" at x + 60 | the same; typing empties the box, footer "Type name / Enter accepts", the cursor (0x80) on the text's last column; after Enter the save card stays with the name, no message | **0 pixels differ** (card, empty box, "TEST" typed) |
| Dialogs | USL_CtlDialog | the watch's screen dots out the card (masked picture 0 at x **72**, whole bytes); box, line, answer lines; REALLY QUIT? (also Escape on the main card), REALLY END CURRENT GAME?, YOU'RE IN A GAME | **0 pixels differ** (end, new game; quit apart from the card behind) |
| End Game | load_game_error | Y: the panel closes, the map fades, the high scores, the title loop; no Game Over | the same |
| Loading | "GAME LOADED" pause | black, then the game with a **PAUSED** box (US_CenterWindow) until a key | the same; the box **0 pixels differ** |
| Configure | SOUND, MUSIC, OPTIONS, KEYBOARD, JOYSTICK #1/#2 | SOUND, MUSIC, OPTIONS, (gap) USE KEYBOARD, USE JOYSTICK #1, #2 (disabled), "CONTROL: KEYBOARD" | OPTIONS, (gap) KEYBOARD, RESET KEYS (architecture.md, "Deviations in D10", 5) |
| Options | four options | SCORE BOX (ON), SVGA COMPATIBILITY (OFF), TWO-BUTTON FIRING (OFF); Enter: "Score box now off / Press any key" | SCORE BOX and the display settings, the same message |
| Keyboard | MOVEMENT, BUTTONS cards | KEYBOARD MENU (MOVEMENT, BUTTONS), MOVEMENT SETUP, BUTTON SETUP: each key in a box at x + 90 | one list on the BUTTON SETUP card, the same boxes |
| Easy jump | gravity mid after the push | frame for frame as ours with gravity mid: 75 px held (Normal 67) | the same |

### Watched in D11 (js-dos, the user's v1.0)

Headless js-dos as before (the developer on port 8771, the tester on 8772
with AdLib music and sound); ours drawn on a 320 × 200 picture and laid
over the original's frames; Paddle War's paddles and ball tracked frame by
frame (70 frames a second).

| What | Omnispeak | The original (v1.0) | Ours (D11) |
|---|---|---|---|
| Main card | PADDLE WAR in row 7 | the same | **0 pixels differ** |
| Paddle War's card | title at (130, 48), lines 60 / 143, "KEEN:" at 80, "COMP:" at 182, the number after the label | the same, the title on x 128; the computer's number always at x 217 (6 pixels after "COMP:") | **0 pixels differ** at the start, the serve and after a point |
| Paddles | Keen 2 px a tic, the computer 1 px on 2 tics of 3 | the same; the computer's paddle shown on even x only (sprite shifts) | the same |
| Serve | after 70 tics, from 612/4, 396/4 | ~1000 ms after the point, (153, 99) | the same |
| The end | USL_CtlDialog "You lost!" / "Press any key" | over the dotted field, the last ball under the dots; a key: the main card on PADDLE WAR; a key held when it comes closes it at once | the same; dialog and score 0 pixels differ |
| Sound / Music cards | 4 / 2 radio items | NO SOUND EFFECTS, PC SPEAKER, ADLIB/SOUNDBLASTER, QUIET ADLIB/SOUNDBLASTER; NO MUSIC, ADLIB/SOUNDBLASTER; checked dot, unchecked ring; Enter checks, the card stays | **0 pixels differ** (tester) |
| Quiet AdLib | carrier level 0x3F − (x >> 1) − (x >> 2) | status_down (byte 0x80) 35.6 dB quieter, status_up (0x00) 12.7 dB (tester) | 36.75 / 12.75 dB |
| F1 in the panel | HelpScreens, then US_DrawCards | the help; Escape twice: the same card and cursor | the same |
| Score-box message | | the card behind still says (ON) until the key | the same |
| Music | StopMusic before the panel in a game, StartMusic after | stops at once (also from the story in the title loop); Return to Game: the map's song from its start; Return to Demo: the next demo with its song | the same |
| Cursors | selectedItem per card | Configure keeps its cursor between visits | Configure, Options, keys |

### Watched in D13: estimates (js-dos, the user's v1.0)

Headless js-dos as before (port 8782), Normal, debug keys, god mode, warp,
"free items" (F10+I: the four gems, 99 charges, 3,000 points, the
wetsuit). A scratch `GAMEMAPS.CK4` (scratchpad only) moved Keen's start in
levels 2 (over a falling platform put two tiles below him, a turn point
under it), 3 (in the air beside a ledge, facing right), 4 (two tiles left
of a gem holder) and 5 (beside a ledge, facing left), and put Smirky next
to Keen in level 6. Every changed frame recorded; Keen, the platform and
Smirky found in each frame by matching our decoded sprites exactly
(anchored on the sprite's rarest colour in the frame: a second for a
recording); the view's movement by matching the background; our engine
played the same scratch levels headless with the same keys and printed
each sprite's screen pixel (`GalaxyObjectLayer.pixel_of`) for the
comparison. Boxes laid over the original's frames pixel by pixel.

| What | Omnispeak | The original (v1.0) | Ours | |
|---|---|---|---|---|
| Bored (after looking up) | 90, 10, 90, 10, 90, 70 tics | WAIT_2 / WAIT_1 pictures 1,283, 143, 1,285, 142, 1,285 and 998 ms: exactly 90, 10, 90, 10, 90, 70 tics | the same | done |
| The book | 700 tics after the boredom began; SIT 4 × 16, READ 300, 16, 16; stowing 3 × 12 | the book 10,015 ms (701 tics) after the boredom began (its own 360 tics count); 235, 221, 230, 228 ms; READ_1 4,281 ms (300), READ_2 and 3 228 ms (16); a key: three pictures of 172 ms (12), then he runs | the same | done |
| Looking up after 200 tics | 60 tics | levels 11 (twice): LOOK_UP 132-133 tics after the level's first frame, up 64 tics (60 within the frames) | 135 / 60: the standing think counts 1.5 × while the 4-tic stand action ends inside a frame (Omni's CK_RunAction), as in the original | done |
| Moon (level 11) | instead of the boredom | Keen put on a moon tile (47, 66): MOON_1, MOON_2, MOON_1 for 16, 92 and 20 tics (20, 90, 20 within the frames), then standing; it came 224 tics after the look up began | the same pictures and times; 302 tics after the look up (after the 60-tic look the stand counts 1 × in ours, 1.5 × in that recording: the frame phase, see the moon below) | done (pictures); the wait left (phase) |
| Gem door (level 4) | Keen walks to the holder; the door's tiles + 1 three times, 10 tics apart | from the first step to the holder to Keen standing again 405 ms (28 tics); the door's tiles change at that frame, then 142 and 142 ms later (10 tics) | 26-28 tics (frame steps), the door at the same frame, 10 tics apart | done |
| Falling platform (level 2) | sinks 16 a tic for 128 units, then gravity high; stops on a turn point; rises 32 a tic | Keen lands, then the platform's top at +8 / +18 / +26 / +30 / +34 tics: 8, 15, 30, 41, 48 pixels down, standing from 34 tics; Keen jumps off: it rises 4 px a frame (32 a tic) back to its place, the first move ~10 tics after the jump | the same track to the pixel (8, 16, 31, 41, 48 at those tics, standing from 36); the rise 32 a tic, the first move 6 tics after the jump | done (the rise starts ~4 tics later in the original: one try, within the recording's frame steps; not changed) |
| Pulling up a ledge, facing right (level 3, two recordings) | hang 12 tics; pulls 4 × 10 tics: (0, −256), (+128, 0), (+128, −128), (0, −128), (0, +128) | the four climbing pictures 579 ms (40.5 tics): 4 × 10 as Omnispeak; the pictures sit at hang + (0, 0), (+128, −128), (+256, −256), (+128, ≈ −495) and Keen **stands at hang + 128** sideways, then runs on 176, 178, 182, 184, 188, 190, 192 px (both recordings the same) | was: stands at hang + 256 (8 px further on); **now** the first pull does not move him sideways: he stands at hang + 128 and runs on over the same pixels (one frame later); the pictures in between still differ (below) | **fixed: the end** |
| Pulling up a ledge, facing left (level 5, second recording) | hang (0, −128); pulls (0, −128), (−128, −128), (0, −128), (0, +128) | hang pictures equal to ours to the pixel; climbing pictures at hang + (0, 0), (0, −128), (−256, ≈ −288), (−128, −512); stands at hang − 128 | the same hang, the same end (hang − 128) and the same run; the first three climbing pictures 128 units higher (and the third 128 less far) | done (end); the pictures left |
| A ledge's lip, facing left (level 5) | — | the two recordings had different scratch starts: (12, 33) grabs the ledge as ours (the same pixels: 150,109 → 148,111 … 148,127, hang); (12, 32) starts with his feet on the ledge's top level and lands, because the level's first frame lasted 6 tics (85 ms, loading) and took him over the ledge before he fell past its top | (12, 33) the same; (12, 32) our first frame is 3 tics, he falls past the top and is stopped by the wall | done: no rule differs (the first frame's length); not changed |
| Status window with items | CK_DrawStatusWindow | four gems, 99 charges, 3,000 points, the wetsuit, "Chasm of Chills", Normal | **0 pixels differ** (`Keen4StatusWindow.window` over the original's frame) | done |
| "Game Over!" | 4 s or a key (IN_UserInput) | the window (**0 pixels differ** with ours) over the last picture of the level, up **4,758 ms** (333 tics), then the fade (three steps of 6 tics), black, the high scores and the title | 4 s | **fixed: 333 tics** |
| Smirky's teleport (level 6) | after two misses | 70 s watched: stood 40 tics (two pictures of 20), hopped left to the wall, jumped for the items above, hopped right out of the view after 11 s; no puff in the view | Omni with our teleport rule | left (§12 point 4) |
| Dopefish (level 17, without god mode) | swims to Keen (1 on odd tics, at most 10); eats him: 32 a tic to its mouth; burps 60, 60, 60; lost 180 tics after the swallow | it reached Keen at the same frame as ours (39 frames after the first); eating 16 tics, its bite ending 2 pixels higher than ours; burp pictures 60 / 60 / 60 tics, the big bubble with the third picture; the level lost 181 tics after the swallow | eating 14 tics, the rest the same | done; the bite's last 2 pixels left (cause not found) |
| Sprite under water (level 17) | aims 40, shoots 40 + 30, the shot 64 a tic | aim 40, shoot 40 + 30, the shot 8 pixels a frame, its four pictures, all as ours to the frame; the shot is first drawn one frame after it leaves (8 px further); the bob after the shot 1 frame ahead of ours | the same; the shot drawn in its first frame | done; the shot's first frame and the bob's frame left (1 frame) |
| Mine (level 17) | 12 a tic as a platform; turns at turn points stopping on the edge; explodes 30 + 30 | 12 a tic (800 units in 66.9 tics); at each turn it **bounces**: what it would have gone past the turn point's edge takes it back (Omnispeak loses it: ours fell 16-24 units behind at every turn); explodes 30 + 30, also in god mode | was Omnispeak's; **now** the bounce: its track matches the original's at 110 of 166 frames to the pixel and within 2 px (a constant start phase) at the rest | **fixed: the turn** |
| Slug (level 15) | 64 every 8 tics; squirts 60; slime 300 + 60 | 4 px every 8 tics; squirts 56-60 tics; the slime appears when the squirt ends, SLIME_2 300-304 tics later, gone 56-60 after that (four puddles) | the same; its first way and the squirt's moment are random (part A) | done |
| Wormmouth (level 1) | slides 16; peeks 20, 8, 20, 8, 20, 8, 20, 8 | slides 16 a tic; four peeks, each 20, 8, 20, 8, 20, 8, 20, 8 (±1 frame); no bite (it never came close) | the same | done; the bite left (not reached) |
| Cloud (level 10) and bolt | strikes: 8 × 10 + 48; the bolt 6 × 8 | flashes every 10 tics, the last 45-48; the bolt up 45 and 48 tics; strikes at the same x as ours (144, 168, 128) | the same; the drift between strikes is random | done |
| Inchworm (level 7) | 128 every 30 tics, to Keen | 8 px every 30 tics, back and forth over Keen (32 / 48 px) as ours | the same; its first way is random | done |
| The Foot | — | not watched (needs eleven worms) | Omni | left (time) |
| Dart guns (level 11) | every 150 tics; darts 64 a tic | all four fire together every 150 tics (2,121-2,204 ms); darts 8 px a frame; the pictures change every 6 tics, as ours to the pixel | the same | done |
| Berkeloid's fireball (level 16) | throws 6 × 6 + 6 × 6; flies ±48; burns 6 + 8 × 12 | throw 36 + 36 tics; flies 3 px a tic; burns FIRE_1, then BURST 1/2/1/2 of 12 tics, then FIRE 1/2/1/2 of 12 (two fireballs) | the same | done |
| A horizontal platform's turn | Omni CK_AxisPlatform | the mines use the same function (seen above: they bounce); a platform in level 7 was not caught moving (Keen fell past) | the bounce, for platforms and mines | **fixed** (by the mines) |
| A switch and a platform | Omni | not reached (level 6, the scratch start fell into a shaft) | Omni | left |
| The wetsuit's box (level 9) | CK4_ShowWetsuitMessage: wait for the sound, the box, a key, his thumb up, a key | the game stood still 1.9 s after the touch (the sound, then the pictures loading), then the box; the first key **is** taken: it shows his thumb up; the second closes the box | the box at once with the exit sound; the two keys the same | **fixed: the wait** (73 tics, the sound's length; the loading not, as decided in D7); the exit sound after the box |
| The load timings of "Keen enters" | — | D7: the fingers 130-630 ms apart (the time to read the files) | 4 × 20 tics | left as decided in D7 |
| High-score entry, the end | — | compared in D8 (0 pixels differ) | — | done in D8 |

**The ledge.** Three recordings with a full pull (two facing right, one
facing left) agree on the timings (Omnispeak's) and on where Keen ends:
one step (128 units) from where he hung, towards the ledge, facing either
way. Omnispeak's first pull moves him a step sideways when he faces right
(and lifts him when he faces left), which ends him 128 units further on;
ours now lifts him only when he faces left and leaves him in place when he
faces right (his hang already lifted him twice as far), so both
directions end as the original and his walk afterwards is the original's
to the pixel. The climbing pictures in between are drawn elsewhere in the
original (the first at the hang's height, then up 128 a picture, and the
third one step further sideways than the end) by a rule that does not fit
Omnispeak's moves in either order; left as they are (each picture is up
for 10 tics). The lip "facing left" turned out to be two different starts
(row 32 and row 33, see the table): from the same start the original
and ours do the same; the landing came from the level's first frame,
which lasts 6 tics after loading in js-dos.

**The second session (D13 B, continued).** New scratch maps: level 17
with a sprite level with Keen, a mine between two turn points below him
and (without god mode) a Dopefish in the open water; Keen next to a slug
(15), a Wormmouth (1), a cloud (10), the dart guns (11), on a moon tile
(11) and near a Berkeloid (16); level 9 beside the wetsuit. Our engine
played the same maps (`Keen4LevelSession` headless, every object's
screen pixel per frame) and the tracks were laid side by side, aligned
on the first frame both show. Where a sprite moves with the view, its
position was taken relative to something that stands still in the level
(the mine's track relative to the sprite, which never moves sideways).

**The turn of a mine or platform.** Before its first turn the mine's
track was the original's to the pixel; after each turn ours fell a
little further behind (2 pixels after two turns). Omnispeak's
CK_AxisPlatform stops the platform on the turn point's edge and drops
the rest of the move (its comment: "TODO: Change DeltaVelocity").
Taking the rest back (a bounce: twice what went past the edge)
matches every frame after both turns, with only the constant start
phase left. The mine has no code of its own (CK4_ACT_Mine0 runs
CK_AxisPlatform), so the platforms bounce the same way. Up and down
was not seen; it stays Omnispeak's (stopping on the edge).

**The moon and the boredom's wait.** Omnispeak counts the idle time in
the standing think; Keen's stand action lasts 4 tics, and when it ends
inside a 2-tic frame the think runs twice in that frame, so the count
runs 1.5 × as fast (the look up after 132-135 tics instead of 200, in
both engines). Which way it goes depends on the frame phase: after the
60-tic look up ours is in step (1 ×, 302 tics to the moon), the
original's recording was not (224 tics; frames of 3 tics happen in
js-dos). Not changed: it is Omnispeak's rule, only the phase differs.

### Watched in D13: demos (D8's js-dos recordings, the user's v1.0)

Our engine played each demo in the real Keen 4 view (4:3, xvfb, OpenGL)
and saved the World viewport after every logic frame; each recorded frame
of the original (D8: demo 0 in run 2a, demo 1 and the high scores in run
3, demo 2 in run 4, demo 3 in run 3b) was laid on ours. Alignment: the
first of our frames from frame 30 on that equals a recorded frame pixel
for pixel, then the recorder's time at 3 tics a frame, each recorded frame
compared with our frames n − 1, n and n + 1 (the recorder's timing). To
find causes, the state per frame (objects, actions, timers, the random
table's index and who drew each number) was laid beside Omnispeak's order
and the original's sprites were found in its frames pixel for pixel.

| Demo | Recorded frames compared | Identical before (D12 code) | Identical after (D13) |
|---|---|---|---|
| 0 (map 1) | 638 | 91.5 % | **100 %** |
| 1 (map 9) | 660 | 100 % | **100 %** |
| 2 (map 11) | 664 | 86.4 % | **100 %** |
| 3 (map 15) | 598 | 42.0 % | **100 %** |
| 4 (map 19, high scores) | 267 | 14.6 % | **100 %** |

The causes (each fixed; no other difference is left):

1. **Everything sleeps at the start.** `CK4_ScanInfoLayer` ends by
   putting every object that is not always awake to sleep (Omni; ours
   started them awake and only put those beyond 4 tiles to sleep). A
   creature 1-4 tiles beyond the first view therefore stayed awake in ours
   and drew random numbers: demo 3's skypest, just below the view, drew 2
   a frame from the first frame, so the slug's slime chance read index 15
   (21) instead of index 1 (8): the original's slug stops to slime at
   frame 5 (seen), ours did not, and every later random choice of the demo
   moved with it (demo 2's drips from the ceiling likewise).
2. **The shared step.** In the original the step of the running object is
   one shared variable (Omni `ck_nextX`, `ck_nextY`); `CK_SetAction` and
   `CK_SetAction2` on any object set it to 0 (and the new object's own
   clipping may leave 16 in y when its action sticks to the ground). A
   slug leaving its slime (`CK4_SlugSlime` makes the slime with
   `CK_SetAction` in the think at the end of its 60-tic stop) loses the
   step back of 64 that ends the stop: seen in demo 3 at frame 25, the
   original's slug stays at x 232 (ours stepped to 228); demo 4's slugs
   the same. The 1.0 program's own action record (found by its shape in
   the unpacked program: sprites 314 / 309, type 0, stick 1, 60 tics,
   x 64) has the same step as 1.4, so it is the shared step and not other
   numbers.
3. **A door moves the view at once.** `CK_KeenEnterDoor` calls
   `CK_CentreCamera` in Keen's think, so the objects after Keen in that
   frame wake up (and fall asleep) by the new view; ours put the view on
   him after the frame, one frame late. What woke behind a door was one
   frame behind: demo 0's poison slug (drawn a frame late, later its stars
   in another phase, and the Bounder's random bounces at the end), demo
   2's inchworms (their 30-tic steps), demo 3's soda bottle
   (its 20-tic animation).

Checked as numbers in `tests/test_keen4_demo_sync.gd`: 67 sprites (Keen,
creatures, their stars, drips, slime) at 24 frames of the five demos, each
found in the original's recorded frame pixel for pixel; the suite fails
without any one of the three fixes.

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
- D3: `clip_children` does not clip children with their own z index;
  cover with a node drawn on top instead.
- D3: atlases per level (only the tiles a level shows) keep xBRZ for
  Galaxy's 4212 tiles fast and small.
- D3: the debug warp in js-dos needs F10 held a few hundred ms before W.
- D4: in js-dos measure from **recordings of every frame**, not single
  snapshots: Keen's shirt colour finds him, matching the background
  between frames finds the view's movement.
- D4: the phase of the frames matters: the first frame of a Galaxy level
  is 3 tics, so the others start on odd tics; a model on even tics was 3
  pixels off in every jump.
- D4: a `const` array of `PackedInt32Array`s returned garbage in Godot
  4.7.2: keep constant tables flat or computed.
- D5: to watch a creature that is not near a level's start, write a
  scratch copy of `GAMEMAPS` with the creature's info value in the first
  view (plain Carmack/RLEW words appended, the map header pointing at
  them) and play it in js-dos; the same copy, given with
  `--data-dir-keen4=`, puts it in our view for screenshots.
- D5: in the original the tic parity of the frames drifts (a 3-tic frame
  flips it); compare speeds over several frames, not single steps.
- D6: a message box can be checked to the pixel by drawing ours on a
  transparent 320 × 200 picture and laying it over the original's frame
  (scratchpad script): no shift, no differing pixel means done.
- D6: the debug warp types the W still held into its prompt; press
  Backspace before the level number.
- D7: find sprites in recorded frames by matching your own decoded sprite
  pictures exactly (only the opaque pixels): it gives the frame and the
  pixel of every map Keen, swimmer, flag and Foot without guessing.
- D7: one-line labels (the status window) cannot be found by their numbers
  of lines; find such a run by the lengths of its records.
- D7: a box of the original over a moving scene can be caught mid-draw
  (one row in the old colour); compare the rest before doubting the
  layout.
- D8: a demo is the best check of the whole engine: play it headless,
  find Keen in every recorded frame of the original (exact sprite match)
  and compare the lists, aligned on the best offset. Account for the
  original's drawing: sprites at 8 / (shifts) pixel steps, the view at
  2-pixel steps.
- D8.1: compare whole frames, not only Keen: render the demo in the real
  view (xvfb), save the viewport after every logic frame and lay it over
  the original's recorded frame. It found the DEMO sign 3 pixels off and
  creatures that drift from the original, which a track of Keen cannot.
- D8: the recorder in js-dos loses keys and frames when the machine is
  busy; drive menus step by step with snapshots in between.
- D8: a full screen effect (the story) can be checked by rendering the same
  rule on the processor in a scratch script and searching the scroll
  distance that matches the original's frame.
- D8: in GDScript `[] if condition else typed_array` is an untyped
  `Array`; assigning it to an `Array[Image]` stops the function with a
  script error at run time. Screenshots of a whole flow catch what the
  suites (without a running scene tree) cannot.
- D10: Omnispeak's colour names can be swapped against the original's
  data (foreground / disabled): measure the colours in a snapshot before
  trusting the names.
- D10: the original puts pictures (also masked ones) on whole bytes: a
  picture asked at x 74 is drawn at 72.
- D10: a deterministic engine can save a level as its start plus the
  frames since and play them again when loading; a save-and-load
  screenshot pair (identical outside the box) proves it.
- D13: to find a sprite in a recorded frame fast, anchor the exact match
  on the sprite's colour that is rarest in that frame (a second for a
  whole recording instead of minutes); and move Keen's *start* in a
  scratch map next to what is to be measured (a ledge, a gem holder, over
  a falling platform), then play the same scratch map in our engine with
  the same keys and print each sprite's screen pixel for the comparison.
- D13: the debug key F10+I ("Free items!") gives the gems, 99 charges,
  3,000 points and the wetsuit, enough for gem doors and the status window.
