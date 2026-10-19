# Keen 3 ("Keen Must Die!"): what differs from Keen 1 and Keen 2

Research notes for adding episode 3 to CommanderPerfect, collected in
milestone C1 (see [roadmap.md](roadmap.md)). Written for the developer of
C2-C11: look here before searching again. When a fact is checked against
the original game, update it here. Facts that end up as code get their final,
short description in `file-formats.md` and `gameplay.md` (written in C2 and
later).

Every fact names its source:

- **(files)**: checked in the user's own files in `game_data/keen3/`
  (v1.00), read-only; every dump stayed in the scratchpad.
- **(Choco)**: Chocolate Keen (github.com/jamesfmackenzie/chocolatekeen), a
  reconstruction of the original v1.31 code. Since C1 its facts and numbers
  may be used (decision of the user, 17-10-2026, see `CLAUDE.md`); its code is
  never copied. References are `file:function` under `src/`.
- **(CG)**: Commander Genius (commit 58a3c4f), documentation only. CG has
  bugs and guesses; where CG and Choco disagree, Choco wins (it follows the
  original code), and the original in js-dos beats both.
- **(KeenWiki)**: keenwiki.shikadi.net.
- **uncertain**: inferred, contradictory, or memory.

## Units: how to turn Choco's numbers into ours

Our engine (Keen 1 and 2) runs **60 logic ticks per second** with speeds in
**n/32 pixel per tick**, the units of Commander Genius and of
`docs/keen-physics.md`. Keen 3 keeps them: `KeenBody`, the enemies' base
classes and the online code all count in them.

The original works differently (Choco, `engine/engine_timing.c`,
`render/gfx.c:CVort_engine_syncDrawing`, `game/physics.c`):

- a game clock of **145.65 Hz** (PIT 1,193,182 / 8192);
- a logic frame at least every **6 clock ticks** (about 24.3 frames/s); a
  frame moves `velocity × ticks since the last frame` (capped at 15);
- positions in 1/256 pixel (1 tile = 4096), velocities per clock tick;
- delays in cut-scenes and text boxes count **VGA retraces** (70.086 Hz);
- the helpers for gravity, Keen's walking and the held pogo add the velocity
  once more for 5 of the 6 ticks: an axis through one helper moves 11/6 of
  its velocity, through two helpers 16/6 ("double step").

Conversion (Choco number → our unit):

| Kind of value | Multiply by |
|---|---|
| A plain velocity (enemies walking, shots, platforms, balls) | **0.3034** (90 → 27/32, 250 → 76/32, 400 → 121/32) |
| A velocity through one helper (anything rising or falling under gravity; Keen's horizontal) | **0.556** |
| A velocity through two helpers (rising on the pogo with jump held) | **0.809** |
| An acceleration per clock tick (gravity 3) | **1.350** per tick² |
| A time in clock ticks → our ticks | **0.412** (40 → 16.5, 400 → 165) |
| A time in retraces → seconds | ÷ 70.086 |
| A chance "random byte < k × sync" per frame | ≈ **9.5 · k in 1000 per tick** |

The map and Messie move **per frame** in the original (not per clock tick):
at 24.3 frames/s, "n px per frame" is n × 24.3 / 60 pixels per our tick.

Choco's random numbers come from a fixed 256-byte table in the EXE (1.00:
raw 0x1EB92) and a lagged Fibonacci generator seeded from "fibs17" (raw
0x1ECBA). We use Godot's random numbers; nothing depends on the exact
sequence.

Side note for the sounds of all three games: Choco plays one value per clock
tick, so **145.65 Hz**, not the 140 Hz that `docs/sounds.md` had. The user
decided on 17-10-2026 that all three games use 145.65 Hz; done in C8 (the
shared `SoundFile.STEPS_PER_SECOND`).

---

## 0. Versions: the user has 1.00

| What | Value | Source |
|---|---|---|
| `KEEN3.EXE` | 61,619 bytes, LZEXE 0.91 (`LZ91`) | files |
| Unpacked image (after the MZ header) | **127,086** bytes | files (the project's `DosExecutable` and two own unpackers agree) |
| Version text in the EXE | "… part 3 … (version 1.0)" at raw 0x1BCEB | files |
| CG's version table | 127,598 (= image + 512) is 1.00, 127,616 is 1.31 (`fileio/CExeFile.cpp`) | CG |
| 1.31 | 61,599 bytes packed, 127,616 unpacked *including* its header; the image size depends on the header size, so recognise 1.31 by content, not by one number | Choco `engine/engine_loader.c`; uncertain |
| 1.32 (UK) | PKLite instead of LZEXE, slightly different `EGAHEAD.CK3` | KeenWiki. Not supported (no PKLite unpacker) unless a user brings it |

- **Offsets shift between 1.00 and 1.31, and not by one amount:** +0x130 up
  to the tile table, +0x126 in the data segment, −0x13 at its end. CG's and
  Choco's offsets are 1.31 only. **Find everything by content.**
- **Bugs in 1.00** (KeenWiki, "Keen 3 Versions"): the yellow keycard in level
  10 cannot be reached (the platform over the water is too small), and the
  school in level 13 cannot be reached. 1.1 fixed both. Level 10 and 13 are
  optional, so 1.00 can be won. We keep the files as they are.
- The user's Keen 2 is 1.31; the user's Keen 3 is 1.00.

## 1. Files and the EXE

| File | Notes |
|---|---|
| `KEEN3.EXE` | v1.00, LZEXE (files) |
| `EGAHEAD.CK3` (19,216) | Standard layout: **624 tiles**, **14 bitmaps**, **148 sprites**; latch plane 29,200, sprite plane 8,768 (files) |
| `EGALATCH.CK3`, `EGASPRIT.CK3` | Uncompressed, as Keen 1/2 (files) |
| `LEVEL01`-`16`, `80`, `81`, `90.CK3` | RLEW, the same loader (files) |
| `FINALE.CK3` (18,480) | The same RLE picture format; `FinaleImage` loads it (files) |
| `SCORES.CK3` (203), `CTLPANEL.CK3` (44), `SAVED1-7.CK3` (92) | Written by the game; same sizes as Keen 2's (files). The names in `SCORES.CK3` were typed by earlier owners: never show or store them |
| — | No `SOUNDS`, `HELPTEXT`, `STORYTXT`, `ENDTEXT` or `PREVIEWS` file: all inside the EXE (files) |
| `Commander Keen 3 - …ba1` | An 80-byte batch file of an old launcher; not game data (files) |

### Positions in the unpacked image (raw offsets)

| What | 1.00 (files) | 1.31 (Choco/CG) | Find it by |
|---|---|---|---|
| ANSI quit screen (7-byte BSAVE header + 4000 bytes) | 0x12BF0 | 0x12AC0 | header `FD 00 B8 …` |
| Sound block `SND\0` | 0x13BA0 – 0x16604 | 0x13A70 | `SND\0` |
| Help text | 0x17B00 – 0x182CB | 0x179D0 | the first text block after the sounds |
| End text ("CONGRATULATIONS! …") | 0x182D0 – 0x1860B | 0x181A0 | second block |
| Previews text | 0x18610 – 0x18CF3 | 0x184E0 | third block |
| Story text | 0x18D00 – 0x19922 | 0x18BD0 | fourth block |
| Data segment start | 0x19950 | 0x19820 | Borland string at DS + 4 |
| **Tile table** (6 planes, stride 715) | **0x199F8** | 0x198C8 | plausibility scan with stride 715 |
| Cheat text | 0x1BBE2 | — | "You are now cheating" |
| Status box labels (11 line records) | 0x1BC38 | — | "SCORE" |
| God mode texts | 0x1BCC4 | — | |
| Char map / 4 palettes of 17 bytes | 0x1BDF0 / 0x1BEAA | 0x1BCCA / 0x1BD84 | |
| **Camera-flash palette** (17 bytes, Keen 3 only) | 0x1C198 | 0x1C072 | the 17 bytes before the points |
| **Points table** (500, 100, 200, 1000, 5000) | 0x1C1A9 | 0x1C083 | pattern |
| Mortimer's messages (line records) | 0x1C1B3 – 0x1C492 | after the points | follow the points table |
| Ending pages, `finale.ck3`, "The End... For now!" | 0x1C493 – 0x1C642 | | strings |
| `SCORES.` default names; rank words | 0x1C6CA, 0x1C77D | | as Keen 1/2 (`ScoreTexts` works) |
| "Keens Left" | 0x1C8F1 | | |
| Main menu words, About ID, `SAVED?.`, ordering text | 0x1C8FC, 0x1C996, 0x1CB4E, 0x1CD14 | | |
| The ship's four messages | 0x1CF00, 0x1CF74, 0x1CFD2, 0x1D04D | | strings |
| Random table / fibs17 / upper-case table | 0x1EB92 / 0x1ECBA / 0x1ED08 | 0x1EBA5 / 0x1ECCD / 0x1ED1B | |

Notes:

- **Text order differs from Keen 2:** help, end, previews, story (Keen 2: end,
  help, previews, story). The texts use the Keen 1 text format (CR LF, `~`,
  0x1F, ends with 0x1A). The help text starts with ANSI-art lines. (files)
- `Keen2Executable.text_blocks` finds the four blocks in KEEN3.EXE but starts
  the first one two bytes early: the `0xFFFF` of a word table right before
  the help text passes as text (found in C2; not the end of the sound block,
  which ends at 0x16604). (files)
- **There are no** city names, `TO BE CONTINUED`, Elder messages or switch
  texts. (files)
- **Status box:** 11 line records (Keen 2 has 12): "SCORE / EXTRA KEEN AT",
  "KEENS / PISTOL", "ANKH TIME / KEY CARDS", "PLEASE PRESS A KEY". (files)
- The u16 after `SND\0` is **not** the length of the block (Keen 3: 16,224;
  the block ends at the last sound's `0xFFFF`). This also holds for Keen 2: its
  block is 9,386 bytes, not the 12,554 that `docs/keen2/research.md` says.
  (files, CG)
- The EXE has `/LEVEL` and `TEDLEVEL.`: a start option for a level (see
  "Watching the original"). (files)

## 2. Sounds

- 63 entries of 16 bytes, **45 named**: entries 0-40 are Keen 1's names and
  priorities; **41 ANKH, 42 MEEP, 43 MORTIMER, 44 FOOTSLAM** are new (Keen 2's
  41 was EARTHPOW). 18 placeholders with priority 1. `SoundFile.parse` reads
  the block. (files, Choco)
- Priorities that matter: ANKH, MORTIMER, CRYSTALSND, vortscream, keensleft,
  EXTRAMANSND 255; FOOTSLAM, TELEPORTSND, YORPSCREAM, CLICKSND 250;
  GETCARDSND 240; DOOROPENSND 230; MEEP, SHOTHIT, TANKFIRE 200; GOTITEMSND 190.
  A sound starts only if nothing plays or its priority is at least that of the
  sound started last. (Choco `engine/engine_audio.c`)
- Where they play (Choco, CG agrees unless noted):

| Sound | When |
|---|---|
| ANKH | Keen picks up an ankh |
| MEEP | A Meep sends its wave |
| MORTIMER | Level 16 starts (before the messages, which wait for it to end); also during the end text |
| FOOTSLAM | A foot of the machine reaches the floor |
| TANKFIRE | The mother spits; a wall gun fires |
| SHOTHIT | A shot hits a wall; the machine's sweeps |
| YORPSCREAM | A Foob gets scared; a Foob dies |
| vortscream | A grunt, youth, mother, Meep or ninja dies |
| TELEPORTSND | A teleporter on the map |
| CRYSTALSND | Keen gets on Messie |
| CLICKSND | Each camera flash in the ending |
| GOTITEMSND | A single charge |
| KEENFIRESND / GUNCLICK | Keen fires / has no charges |

## 3. Graphics

- **624 tiles, but the tile table rows are 715 entries wide** (entries
  624-714 are filler `1,0,0,0,0,0`). Reading with stride 624 finds a wrong
  table without an error. (files; CG `CTileLoader.cpp` "forced 715"; Choco
  `CVort3_TILENUM` 715)
- **14 bitmaps:** TITLE 264x112, IDLOGO 112x40, F1HELP 64x16, HIGHSCOR
  136x24, NAME 48x16, SCORE 48x16, GAMEOVER 112x24, AN, PRESENT, APOGEE,
  ONEMOMEN, OFAN, PRODUCT, IDSOFT. No SAVED, KEENSHIP, WINDON or WINDOFF.
  GAMEOVER is bitmap 6 (Keen 1/2: 7). (files, Choco)
- **148 sprites** (names from the file; box = left, top, right, bottom):

| Sprites | What | Size, box |
|---|---|---|
| 0-21 | Keen walking, jumping, shooting | 16x24, 4,1,11,23 |
| 22-23 | Keen dead | 16x16, 4,4,11,15 |
| 24-27 | Keen on the pogo | 16x24, 4,0,11,23 |
| 28-29 | Keen stunned (KEENSICLE1-2) | 16x24 |
| 30 | Keen getting up (KEENMELT). **There is no KEENSBACK**, so every number from here on is one lower than in Keen 2 | 16x24 |
| 31-46 | Keen on the map: right 31-34, down 35-38, left 39-42, up 43-46 | 16x16, 2,1,9,15 |
| 47-50 / 51-54 / 55-56 | Youth left / right / dying | 16x24, 1,6,14,23 and 4,4,11,23 (the right frames keep Keen 1's Yorp box, as in Keen 2) |
| 57-58 / 59-60 | The mother's fireball left / right | 16x8, 0,0,15,7 |
| 61-62 | GODHALO, BYEHALO: the ankh's halo | 32x40 |
| 63-66 / 67-70 / 71-74 / 75-76 | Grunt left / right / looking around / dying. 73 = jump while moving right, 74 = left (CG has them swapped) | 24x32, 2,1,21,31 |
| 77-78 / 79-80 / 81-82 / 83-84 | Ninja left / right / jumping left, right / dying | 32x32, 4,4,27,31 |
| 85-86 / 87-88 / 89-90 / 91-92 | Mother left / right / spitting left, right / dying | 24x32, 2,2,21,31 |
| 93-94 / 95-96 / 97-98 / 99-101 | Foob left / right / yelling / dying | 16x16 |
| 102 | Keen's shot | 16x8 |
| 103 / 104 | The wall gun's shot, sideways / downwards | 16x8 / 8x16 |
| 105-106 | Shot splash right / left | 16x16 |
| 107-108 | Platform (Keen 2's is 32x16) | 32x8 |
| 109 / 110-113 | Ball / jack | 16x16 |
| 114-117 | Spark in the machine | 16x16, 2,2,13,13 |
| 118-119 / 120-121 / 122-123 / 124-125 | Meep right / left / singing right, left / dying | 16x24, 2,2,13,23 |
| 126-127 / 128-129 | Meep's wave right / left | 8x16, 2,2,5,13 |
| 130-137 | Messie (left-down 130-131, right-down 132-133, up-right 134-135, up-left 136-137) | 32x24 |
| 138-145 | Messie with Keen on her back, same order | 32x24 |
| 146-147 | Mortimer's heart | 16x16 |

The machine's body, arms and legs are **tiles**, not sprites. (files)

## 4. Tiles (behaviours from the table)

| Tiles | Behaviour | What (files unless noted) |
|---|---|---|
| 13r + 1 … 13r + 12 for the rows r = 11-16 (row starts 143, 156, 169, 182, 195, 208) | 6, 7, 8, 9, 10, **27**, **28**, 15, 18-21 | Candy bar (500), burger (100), Vorta-Cola (200), cake (1000), stuffed ninja (5000), **ankh**, **single charge**, raygun, yellow/red/green/blue keycard. Each row has its own background colour |
| 143, 156, 169, 182, 195, 208 | 0 | The empty background of each row: **what an item leaves behind is `(tile / 13) * 13`** (Choco `physics.c:CVort_keen_bgtile_col`, CG "smart tile changer") |
| 234-241 | 2-5 | Doors, two cells high. An opened door's cells get **the tile left of the door's top cell**; it sinks 1 px per 5 clock ticks (Choco) |
| 255 | 17 | Exit. Keen walks right through everything (18/32), tiles 257 and 246 are drawn over him, and the level ends when he reaches 2 cells right of the exit (Choco) |
| 66, 78, 110, 279-282, 303-306, 316-319, 325-328, 338-341, 416-425, 462-465, 597, 606-610, 618-623 | 1 | Deadly (also the machine) |
| 108, 329, 398, 411, 479, 492, 505, 524, 526, 565 | −2 | Masked foreground (108 is used 285 times in level 14) |
| 337, 351-381, 384-387, 391-393, 404-406, 445-452, 567-569 | −1 | Foreground |
| 271 | 23 | A leftover light switch; used in no level |
| **245** | 0 | **The level border is an "OH no!" picture.** It must never be visible |
| 52-55 / 56 | 0 | "Done" on the map: 2x2 / 1x1 (Choco, CG) |
| 62, 63-64 + 76-77, 101, 120, 139-142 | 0 | Map entrances: cave, dome, the whirl of level 15, the castle of level 16, small castles |
| 130-133 / 134 | anim / 0 | Teleporter animation / teleporter at rest |
| 126-129 | anim 4 | Messie's weed |

- **Points:** the behaviour picks the points from the table. The candy bar
  gives 500 and the burger 100; the help text says it the other way round (a
  known bug of the original). (files, KeenWiki)
- Behaviour 22 does nothing in Keen 3 except turning the tile into 143
  (Choco); no level uses it. No behaviours 11-14, 16, 24-26; no floor types
  (no ice). (files)
- Animated runs: frames 1, 2 or 4. (files)

## 5. Levels and the info layer

| Value | Object | Value | Object |
|---|---|---|---|
| 1 | Grunt | 10 | Vertical platform |
| 2 | Youth | 11 | Same as 1; used in no level |
| 3 | Vorticon mother | 12 | Spark (machine) |
| 4 | Meep | 13 | Heart (machine) |
| 5 | Ninja | 14 | Wall gun, fires right |
| 6 | Foob | 15 | Wall gun, fires down |
| 7 | Ball | 16 | Arm (machine) |
| 8 | Jack | 17 / 18 | Left / right leg (machine) |
| 9 | Horizontal platform | 255 | Keen's start (cell + 8 px down) |

(files; Choco `episode3.c:CVort3_init_level`; CG `CVorticonMapLoader.cpp`.)
No value ≥ 0x100 in any level (no bridges).

| Level | Size | Contents | Notes |
|---|---|---|---|
| 1 | 84x26 | grunt 2, youth 4, mother 1, Foob 3 | |
| 2 | 100x24 | grunt 13, Foob 2, vertical platform 2 | |
| 3 | 69x47 | grunt 11, mother 1, ninja 1, Foob 3, ball 1 | ankh |
| 4 | 200x46 | grunt 7, youth 5, mother 3, Meep 1, ninja 4, Foob 6, jack 1, gun → 1 | |
| 5 | 154x40 | grunt 21, youth 7, mother 14, vertical platform 3 | |
| 6 | 74x17 | grunt 3, youth 5, ball 3 | |
| 7 | 124x37 | grunt 12, youth 5, mother 2, ninja 1 | |
| 8 | 104x57 | grunt 7, youth 2, ninja 1, ball 2, platforms 2 + 2 | |
| 9 | 67x117 | grunt 14, youth 4, ball 6, jack 1, platforms 4 + 3, gun → 11 | **two starts** (2,10) and (63,17): the row-major scan of the original takes the later one, (63,17) (Choco) |
| 10 | 64x37 | grunt 5, youth 2, ninja 4, platforms 2 + 2, gun → 3, gun ↓ 1 | ankh; 1.00 bug: yellow keycard |
| 11 | 44x37 | grunt 2, youth 5, platform 1, gun → 4 | |
| 12 | 54x47 | grunt 5, Meep 6, ninja 2, Foob 1, platform 3, gun → 2, gun ↓ 9 | two exits |
| 13 | 84x107 | youth 7, mother 1, Foob 18 | Hidden City (secret); two exits; 1.00 bug: school |
| 14 | 184x25 | grunt 4, Meep 3, ninja 21, Foob 1, platform 1, gun → 1, gun ↓ 1 | 3 ankhs |
| 15 | 128x120 | grunt 9, ninja 9, Foob 8, ball 13, jack 2 | two exits; 55 single charges |
| 16 | 25x24 | Meep 2, spark 6, heart 1, gun ↓ 2, arm 2, leg 1 + 1 | the Mangling Machine; **no exit** |

- Keycards and doors in levels 3, 4, 9, 10, 11, 12, 14 and 15. (CG census)
- Map 81 (24x17): the Big V award hall; no info values. Map 90 (126x17): six
  screens as in Keen 1 (title at cells 2.., the Ordering-info room at 22..,
  About ID at 63.., high scores at 84..). (files, Choco)

## 6. Enemies and objects

General (Choco unless noted):

- A sprite wakes when its cell is within the view −2 … +23 tiles across and
  −2 … +12 down; it sleeps again outside −8 … +28 / −8 … +18. Shots, splashes
  and corpses are deleted there. Platforms always run.
- A killed enemy shows its first dying frame, the next one after 40 clock
  ticks (16.5 of ours), then lies as a corpse that falls. **Enemies give no
  points in Keen 3**; only sparks and the heart (1000 each) and items do.
- Touching Keen: grunt, ninja, jack, enemy shots, Meep waves **kill**; youth
  **stuns**; mother and Meep **push** him aside; ball and platforms **carry**
  him (solid); Foob, spark and heart do nothing to Keen.
- Keen's shot (sprite 102, 121/32) splashes on **any** sprite except Keen
  and corpses.

Speeds below are already converted to our units (n/32 px per tick at 60
ticks/s); times in our ticks. "Chance k" means ≈ 9.5·k in 1000 per tick.

| Object | Behaviour (Choco) | Touch | Hits |
|---|---|---|---|
| **Grunt** (1, 11) | Walks 27/32 toward Keen, frames every 6.6 ticks. Each frame two chances 2: a jump (up-speed random 0 … 167/32, at most 107 px) or a switch of speed 27 ↔ 36/32. Reverses at a wall; walks off ledges. After every landing it looks around for 33 ticks (frames 71-74) and then walks toward Keen (no distance limit). Also killed by enemy shots | death | 1 |
| **Youth** (2) | Runs 76/32 toward Keen, frames every 6.6. Hop chance 3: up-speed random 0 … 222/32 (at most 191 px). Reverses at a wall; falls off ledges | **stun** | 1 (only Keen's shots) |
| **Mother** (3) | Walks 15/32 toward Keen, frames every 6.6; does not walk off ledges. Chance 1 to spit: she **turns round**, stops (frame 89/90), after 12.4 ticks TANKFIRE and one fireball, after 20.6 ticks she walks on in the new direction | pushes | 5 |
| Fireball | From (x, y + 12 px), 45.5/32 straight, no gravity, frames every 3.3. Splashes on walls and on anything except a mother or a corpse, so **Keen can shoot it down**. Kills Keen, grunts and Foobs | death | — |
| **Meep** (4) | Spawns 8 px below its cell. Walks 19.7/32, frames every 6.6. Chance 1 to sing, and also whenever it is not on the ground (a bug in the original: at a ledge it stops in the air and sings, then falls). Sings (122/123), after 24.7 ticks MEEP and a wave, after 33 walks on | pushes | 1 |
| Wave | From the Meep's front (x or x + 16 px, y + 4 px), 61/32, **flies through walls**, frames every 3.3, deleted outside the active area. Keen's shots splash on it, it flies on | death | — |
| **Ninja** (5) | Stands facing Keen, frames every 13.2. When Keen is within 5 tiles vertically: chance 3 to jump, up-speed random 0 … 195/32 (at most 146 px), sideways 76/32 toward Keen; stands again when it lands | death | 4 |
| **Foob** (6) | Walks 15/32, frames every 13.2. On screen: chance 2 to get scared (YORPSCREAM, frames 97-98 for 10 ticks), then runs **away from Keen** at 76/32 and stops at a wall. **Touching Keen kills the Foob**, not Keen; shots kill it too | Foob dies | 1 |
| **Ball** (7) | Starts diagonally toward Keen, 121/32 on each axis, no gravity, bounces off walls, floors and ceilings | carries Keen; stops shots | never |
| **Jack** (8) | The same movement, frames every 3.3 | death; stops shots | never |
| **Platform →** (9) | 4 px above its cell; starts right at 22.8/32; frames every 13.2; at a wall waits 31 ticks, then reverses | carries; stops shots | never |
| **Platform ↕** (10) | Starts **down** at 22.8/32; at a floor it reverses at once; at a ceiling it waits 31 ticks, then goes down | carries; stops shots | never |
| **Wall gun →** (14) | Invisible. Every 165 ticks (2.75 s): TANKFIRE and a shot (sprite 103) from (x, y + 3 px), 121/32 right. **Runs off screen too**, so its sound is always heard (the off-screen shot is deleted at once). All guns fire in step | — | — |
| **Wall gun ↓** (15) | The same, sprite 104 from (x + 4 px, y), downwards | — | — |
| Gun shot | Straight until a wall (SHOTHIT, splash); flies through sprites; kills Keen, grunts and Foobs on its way | death | — |

CG disagrees on many of these numbers (for example mother 5 HP but walking
15/32 and no turning, ninja kicks every 80-99 ticks, ball 120/32 starting
up-left, guns every 256 ticks); the Choco numbers are used.

### The Mangling Machine (level 16)

(Choco `episode3.c:CVort3_think_mangling_*`, `CVort3_handle_grand_intellect`;
CG `ai/CManglingMachine.cpp`; files for the cells.)

- **Layout:** body columns 8-16, rows 2-18; Mortimer's face at (12,6);
  sparks at (11,4), (13,4), (9,6), (15,6), (9,13), (15,13); heart at (12,8);
  two Meeps at (12,9) and (12,12); arms at (6,10) and (18,16); legs at
  (11,18) and (13,18); two wall guns firing down at (4,2) and (20,2); Keen
  starts at (3,10).
- **Arm** (16): starts **down**, one tile every 6.2 ticks; up one tile every
  16.5 ticks. Each step clears its cell and the cells beside and below it,
  draws the shaft (597) and the claws (618/620/619). Turns up when the tile
  3 below is 471, turns down when the tile above is not the shaft.
- **Leg** (17 left, 18 right): a step every 14.4 ticks; the left leg starts
  up, the right one down. Turns down when the tile above is not the shaft;
  at tile 430 below: **FOOTSLAM**, wait 82 ticks, then up. The foot is drawn
  622, 623, 623, 621 (left foot; the right one mirrored).
- **Spark** (12): frames every 3.3; one shot removes it: a border flash, **+1000**.
  At the sixth: both arms stop where they are, and a sweep clears columns 5-7
  and 17-19, rows 7-18, a row every 12.4 ticks (SHOTHIT and splashes). That
  removes tile 611 at (7,8) and (17,8), which blocks shots to the heart.
- **Heart** (13): 146/147 alternating (each 9.9 ticks). One shot: a border flash,
  **+1000**, both legs stop, **every sprite is removed** (enemies, shots, the
  remaining sparks), and a sweep clears columns 8-16, rows 3-18, a row every
  8.2 ticks; 181 ticks (3 s) after the shot **the level is won**.
- The border flash: the screen border blinks (colour 14 / 3 every 26 ticks
  for 124 ticks). We have no EGA border; a short flash of the frame around
  the 4:3 picture, or nothing, is a choice for C7.
- CG shakes the screen on a hit; Choco does not.

## 7. Keen

- **Physics are the same in all three episodes** (Choco, CG). Keen 3 uses the
  shared `KeenBody` unchanged. (Choco shows that some of Keen 1's numbers in
  `docs/keen-physics.md` are off, see "Notes for Keen 1 and Keen 2" below;
  they are not changed.)
- **Jump heights:** the original Keen 2 jumps lower than our shared physics
  (pogo 50 px against our 58), and Chocolate Keen gives the original's
  heights; Commander Genius, which our numbers come from, probably made
  them higher on purpose. Keen 3 shares the physics, so it will jump as high
  as Keen 1 and 2 do now. Not researched further; the decision (all games,
  Keen 3 only, or nothing) is open in `PROGRESS.md` and is needed before C3.
  The measurements: [choco-keen1-keen2.md](choco-keen1-keen2.md).
- **Start:** 4 lives, **5 charges**, the pogo stick, score 0; an extra life
  every 20,000 (EXTRAMANSND). Keycards are taken away at the end of every
  level. (Choco `game/menus.c`, `gameplay.c:CVort_add_score`; CG agrees on 5)
- **Shooting:** jump and pogo together; a shot costs a charge (KEENFIRESND),
  none left: GUNCLICK. (Choco)
- **Items:** raygun +5 charges; **single charge (28) +1** with GOTITEMSND.
- **The ankh (27)** (Choco `gameplay.c:level_draw_invincibility`,
  `physics.c:CVort_kill_keen`):
  - ANKH; **+1400 clock ticks (9.6 s, 577 of ours), added up** when Keen
    picks up another one.
  - The timer is **set to 0 at the start of every level** (it never carries
    over) and only counts during play.
  - It protects against everything that kills (tiles, grunt, ninja, jack,
    fireball, shots, waves) and against the stun; **not** against being
    pushed or falling out of the level (PLUMMET).
  - Halo: sprites 61/62 at Keen − 8 px, − 8 px, alternating every 6.6 ticks;
    in the last 250 clock ticks (103 of ours) it blinks.
  - The status screen shows ANKH TIME as remaining clock ticks / 144 (whole
    seconds; a fresh ankh shows 9).
  - (CG: 1255 ticks; KeenWiki: 15 s. Both disagree with Choco; check in js-dos.)
- **Stun by a youth:** Keen takes the youth's speed, lies 400 clock ticks
  (165 of ours) with frames 28/29 every 13.2, slides to a stop (friction 3),
  then frame 30 for 16.5 more ticks. A stunned Keen still dies to deadly
  things, and a shot kills him. (Choco `enemies.c:CVort_think_keen_stunned`)
  This differs from `Keen2Body` (250 ticks, a shot shortens it, frame 31), so
  `Keen3Body` overrides the stun.
- **Death:** frames 22/23, after 82 ticks he flies straight up at 121/32
  with a random sideways drift. (Choco)

## 8. The world map (map 80, 70x73)

(Choco `game/worldmap.c`, `episode3.c:CVort3_worldmap_sprites`,
`CVort3_do_messie`; files for the cells.)

- **Keen** walks 4 px per frame on each pressed axis (about 97 px/s);
  frames 31-46. The 0x8000 cells are walls until their level is done.
- **The button** (jump or pogo) while Keen's box overlaps a non-zero info
  cell:

| Info | Action |
|---|---|
| 1-16 (also with 0x8000) | Enter the level, if not done (WLDENTER) |
| 20 | The ship: one of **four messages** at random, then "press a key"; enters nothing |
| 0x0Fsd | A **teleporter**: s = its own slot, d = the slot it sends Keen to |
| 0x2000-0x22FF | Messie's cells: nothing |
| 255 | Start; nothing |

- **Entrances** (files): 1 (45,43); 2 2x2 at (48,45), right column 0x8002; 3
  (52,37); 4 2x2 at (58,36), right column 0x8004; 5 2x2 at (21,36), top row
  0x8005; 6 (13,35); 7 (11,33); 8 (15,32); 9 (39,27); 10 2x2 at (38,23); 11
  (45,24); 12 2x2 at (43,28); 13 2x2 at (24,58); 14 2x2 at (48,19); 15 2x2 at
  (25,12) with three cells 0x800F; 16 (33,13). Start (44,47). Ship (42,48) and
  (43,48).
- **Done:** the info cells are cleared (which also opens the 0x8000 walls),
  the tiles become 56 (1x1) or 52, 53 / 54, 55 (2x2). (Choco; Keen 1/2 use 77
  and 78-81)
- **Teleporters** (16 slots, all on tile 134; not all two-way):

| Slot (cell) → slot | Slot (cell) → slot |
|---|---|
| 0 (51,25) → 2 | 8 (17,30) → 12 |
| 1 (46,41) → 3 | 9 (9,32) → 4 |
| 2 (51,44) → 5 | 10 (12,25) → 14 |
| 3 (55,41) → 1 | 11 (14,28) → 9 |
| 4 (60,35) → 7 | 12 (18,25) → 0 |
| 5 (16,40) → 2 | 13 (56,24) → 15 |
| 6 (20,34) → 11 | 14 (37,28) → 8 |
| 7 (13,37) → 3 | 15 (24,18) → 14 |

  Using one: TELEPORTSND, the tile cycles 130-133 (4 retraces each, twice),
  back to 134; the view jumps so the destination is at (10, 6) tiles from its
  corner; the same animation there; Keen stands at the destination cell. Messie
  is frozen meanwhile. (Choco)
- **Messie** (0x2000 path, a closed loop of 256 cells; 0x2100 weed at
  (14,20), (35,16), (61,30), (28,55); 0x2200 landings at (33-34,15), (33,16),
  (26-28,56)):
  - She starts at the first row whose middle column holds 0x2000, **(35,8)**,
    heading left. (Choco; CG differs)
  - She moves 2 px per frame on each axis of her direction (8 frames per cell,
    ~3 cells/s). At each cell she takes the first neighbour (columns x−1, x,
    x+1, rows y−1, y, y+1) that is path or weed and is neither her cell nor
    the one she came from. Before a weed cell she waits **122 frames (~5 s)**.
  - Frames by direction: 130-131 left/down-left/standing, 132-133
    right/down/down-right, 134-135 up-right, 136-137 up-left/up; with Keen
    138-145. The second frame every 2 frames.
  - **Getting on:** Keen walks into her (his top-left inside her rectangle):
    CRYSTALSND. Keen is hidden and cannot enter anything; the camera follows
    her.
  - **Getting off:** a pressed direction (8 ways, no button) toward a
    neighbouring 0x2200 cell puts Keen there. Then 30 frames before she can
    be mounted again.
  - (CG: get on and off with the jump button within 2 tiles; Choco wins.)
  - Messie is the only way to level 13 (Hidden City). (KeenWiki)
- **Winning:** when level 16 ends with anything but a death, the ending
  runs. No other level is required, but the map's walls and teleporters
  decide which levels Keen must pass to get there (CG's analysis: 15, plus
  4 or both 2 and 5).
- **"Keens Left":** a 16x4 box, at most 6 little map Keens, 0.86 s or a key.
  (Choco; Keen 1/2 use 3 s, see `docs/keen2/gameplay.md`)

## 9. Status screen, scenes, menus

- **Status screen** (Choco `episode3.c:CVort3_show_pause_menu`): a box 28x11
  inside the border. Row 0 labels; row 1 the score ending before column 10
  and the next extra life ending before column 26; row 2 labels; rows 3-5 a
  little Keen (sprite 0) per life from column 1, two apart, at most 9; the
  pistol tile 216 at column 21, 4 px below row 3, the charges at column 24,
  row 4; row 6 labels; the ankh tile 214 at column 3, the seconds at column 7,
  row 8; keycard tiles 217-220 at columns 13, 17, 21, 25; row 10 "PLEASE
  PRESS A KEY". The clock stops while it is open.
- **Mortimer** (first frame of level 16, Choco
  `CVort3_handle_grand_intellect`): MORTIMER plays to its end, then **9
  boxes** typed at 6 retraces per letter, centred on column 19 (rows 20 or
  18): a gasp, disbelief, his name, two narration boxes, Keen's question,
  Mortimer's answer, Keen's threat, Mortimer's Mangling Machine; pauses of
  180-240 retraces. Escape, Space or a button skips the rest. The middle of
  type A boxes is row 20, of type B row 18 (x = 19 − w/2, y = row − h/2):

  | # | Box w x h | Type | Content | Pause after (retraces) |
  |---|---|---|---|---|
  | 1 | 5 x 1 | A | a gasp | 180 |
  | 2 | 12 x 1 | A | disbelief | 180 |
  | 3 | 18 x 1 | A | his name | 240 |
  | 4 | 38 x 5 | A | narration: his IQ beat Keen's by one point | 240 |
  | 5 | 38 x 5 | A | narration: years of bullying | 240 |
  | 6 | 31 x 2 | A | Keen asks why | 180 |
  | 7 | 35 x 4 | B | Mortimer answers | 180 |
  | 8 | 34 x 1 | A | Keen's threat | 180 |
  | 9 | 38 x 3 | B | Mortimer: the Mangling Machine | 240 |
- **The ending** (Choco `CVort3_draw_win`, `CVort3_blink_camera_flash`):
  1. Map 81, view at tile (2,2); a Vorticon (sprite 67) at tile (14,6), Keen
     (sprite 0) at (15.5, 6.5); fade in.
  2. Four boxes typed one after another (4, 3, 3 and 1 lines), 120
     retraces each: the Vorticons are freed, the honour, the Big V, Keen's
     thanks.
  3. Five camera flashes: a tile changes ((19,5) → 58 → 72, (3,8) → 60 → 61,
     (5,8), (20,5), (8,8)), the camera-flash palette for 2 retraces, CLICKSND
     each, waits of 20, 10, 5, 10, 15; then 120 and a fade.
  4. `FINALE.CK3`; after 400 retraces a box "The End... / For now!"; a key.
  5. The end text, with MORTIMER playing.
  6. GAME OVER / high scores.
- **GAME OVER:** bitmap 6, GAMEOVERSND, 5.1 s or a key.
- **High scores:** map 90 at cells (84,2), 16.5 s or a key; HIGHSCOR at
  (88,7), NAME at (80,44), SCORE at (192,44); 7 rows from y 64, 16 apart,
  names from x 80, scores ending at x 240; **no third column**. A new entry: a
  32x13 box, up to 12 letters. (Choco; CG gives other places)
- **Attract loop:** the Apogee logo (first time only) → Title (TITLE at
  (32,1), **F1HELP at (120,182)**; Keen 1/2: 96) → About ID → High scores →
  Ordering info (a Foob walks in, Keen raises his gun, the Foob screams and
  runs) → Title …, 16.5 s each. No demo. (Choco)
- **Main menu:** New Game, Continue Game, Story, About ID..., High Scores,
  Ordering Info, Previews!, Restart Demo. (files)

## 10. What Keen 3 has and has not

| Mechanic | Keen 1 | Keen 2 | Keen 3 |
|---|---|---|---|
| Platforms | — | horizontal | horizontal and **vertical** |
| Bridges, switches, darkness | — | yes | **no** |
| Stun | ice | youth | youth (longer; a shot kills) |
| Pushing enemies | Yorp | — | mother, Meep |
| Enemy shots | tank | Elite, Guard | fireball (can be shot), wave (through walls), wall guns |
| Invincibility | — | — | **ankh** |
| Map teleporters | table in the EXE | — | **in the info layer** |
| Riding on the map | — | — | **Messie** |
| Ship on the map | parts | — | four messages |
| Tiles that change while playing | doors, items | bridges, wreck, lights | doors, items, the machine, done signs, teleporters |
| Win | four parts | eight cities | level 16 |

## 11. Things an implementer will trip over

1. Version 1.00: search the EXE by content; CG's and Choco's offsets are 1.31.
2. The tile table stride (715) is not the tile count (624).
3. Sprite numbers from 31 on are one lower than in Keen 2.
4. The "OH no!" border (tile 245) must never be visible: check widescreen,
   two players, the map, map 81 and map 90.
5. Items leave `(tile / 13) * 13`; doors take the tile to their left.
6. Points from the table, not from the help text.
7. Map info values 0x0Fsd, 0x2000-0x22FF, 0x8000 + n, 20.
8. Messie moves, carries and hides Keen, and waits at the weed.
9. Level 16 has no exit, changes many tiles while playing (xBRZ and HD must
   follow), removes every sprite and ends by itself.
10. Level 9 has two starts (the later one counts); levels 12, 13, 15 have two
    exits.
11. The ankh: a timer reset per level, a halo, not against falling out.
12. A fireball that can be shot down, waves through walls, invisible guns that
    fire off screen.
13. The vertical platform turns at once at the floor and waits at the ceiling.
14. Choco counts in 145.65 Hz clock ticks and frames; convert (top of this
    file).
15. Co-op: Messie carries one Keen; the machine and the ankh in a snapshot.

## Watching the original

How to run the original in js-dos and record its frames:
[tools/original/README.md](../../tools/original/README.md). In C1 the
user's `KEEN3.EXE` (1.00) was watched that way (17-10-2026). Two problems of
B10 are solved there: keys no longer arrive seconds late, and the emulator
keeps running while the browser pane is hidden. A level cannot be started
from the command line (`/LEVEL` loads `TEDLEVEL.CK3`, which gave a garbled
screen); walking there on the map works now.

Measured (sure unless noted; positions in the raw 320x200 frame):

- **The game draws ~24.2 times a second** (every 3, sometimes 2 retraces),
  also with a fixed CPU speed. This matches Choco's frame every 6 clock
  ticks.
- **Attract loop:** a "one moment" box, the starfield intro (~13.6 s), title
  16.8 s, id Software page 16.7 s, high scores ~21.3 s (the border animates
  ~15 s, then the screen stands still 4.9 s), ordering page with the Foob
  scene ~12-13 s (rough), title again; no demo. Screens are drawn piece by
  piece, without a fade between them.
- **Title:** map 90 cells 2-21, map row 2 at screen y 0; `TITLE` at (32,1),
  `F1HELP` at **(120,182)**.
- **High scores:** cells 84-103; `HIGHSCOR` (88,7), `NAME` (80,44), `SCORE`
  (192,44); 7 rows from y 64, 16 apart; names from x 80, scores ending at x
  240; text **red**; no third column. id page: cells 63-82, map row 2 at y 4,
  `IDLOGO` (104,23). Ordering page: cells 22-41.
- **New game:** 4 Keens, **5 charges**, ankh time 0, score 0, next extra
  Keen at 20000. The map starts with cell (35,44) in the top-left corner.
- **Status screen** (Space, on the map and in a level): window x 40-279, y
  48-151, inside 28x11 text cells; labels red on gray bars, values in white
  boxes. Score ends before text column 16, next extra Keen before 32 (inside
  the window: 10 and 26, as Keen 2); little Keens from x 56, 16 apart, top
  y 80; pistol icon at x 216, y 80, charges at x 240, y 88; ankh icon at
  x 72, y 116; ankh time at x 104, y 120; keycards from text column 18.
  (C6: the pistol is at y 84 and the keycards from x 152, see below.)
- **Level 1:** the view starts with cell (2,12) in the corner. A Foob walks 2
  px per frame toward Keen, is scared for ~0.2 s when it sees him (~110 px
  away), then runs away at 6 px per frame (~145 px/s); at a wall it bobs 1 px.
  The green plant right of the start is deadly, also in god mode.
- **Messie** swims by herself at 2 px per frame on each axis (diagonals not
  normalised), two animation frames of 2 frames each (likely).
- **Death:** Keen's sprite rises, the screen fades out in 2 steps ~114 ms
  apart and back in on the map. **Keens Left:** box x 88-231, y 72-119, text
  at (120,80), little Keens from x 104, 16 apart, y 88; gone by itself after
  **0.87 s**. **GAME OVER** after the last life: the bare `GAMEOVER` bitmap at
  (96,80) over the level, no window, 5.27 s, then the high scores.
- **Cheats:** C+T+Space (a 4-line box at x 48-271, y 72-119) and G+O+D (god
  mode, a one-line box at x 72-247, y 88-111) work.
- **F1** opens a full-width help reader (frame y 8-183, gray bar at y 168).
- Not seen yet: the enemies other than the Foob, level 16, sound.

Watched again in C4 (17-10-2026; js-dos 8.5.3, level 1 reached by script
as described, then G+O+D):

- **God mode shows the halo** (the ankh's bubble, GODHALO/BYEHALO) around
  Keen; it is drawn behind foreground tiles (a pillar of level 1 covers it).
- **The Foob:** the first Foob had already fled to the rocks right of the
  plant and stood there facing them, its two running frames taking turns
  (the "bob"), as in C1 and as our Foob does in the same place. When Keen
  stepped off the rocks onto it, **the Foob died** (its flat last dying frame
  stayed on the floor) and Keen did not: confirmed.
- Not measured: the grunt, the youth and the mother. Keen died twice at the
  pit after the waterfall (by hopping and on the pogo stick), so the house
  with the mother and the youths (cells 48-59) was not reached. js-dos only
  logs frames in which something changed, and the plant and the waterfall
  animate, so the Foob's frame timing could not be read from these
  recordings either. The Choco numbers stay (C11).

Watched again in C5 (18-10-2026; js-dos 8.5.3, KEEN3.EXE 1.00). New game,
on the map one cell up and four right to level 2's entrance (48,45),
G+O+D, then right along the floor to the shaft of the up-and-down platform
of cell (45,17) (columns 45-46, ceiling row 4, a notch in the floor at row
19). Two recordings (25 s and 14 s) while Keen stood at the bottom of the
shaft; the platform's top edge tracked in every frame:

- **Speed: 1.75 px per frame, ~42.4 px/s, 0.71 of our px per tick**
  (Choco 75: 42.7 px/s, 22.8/32). Same both ways. (sure)
- **At the floor it turns up at once**: one frame at the lowest place, then
  up at the same speed. (sure)
- **At the ceiling it waits ~0.55 s** (33 of our ticks; from the time above
  the view and the whole period, 11.5 s, solved for speed and wait); Choco's
  31 ticks plus the turning tick is 32. (likely; the ceiling itself was not
  in view)
- **Coming down on Keen:** Keen stood at the bottom of the shaft against
  its right wall (his box under the platform's right end by ~5 px). The
  platform did **not** stop on him or push him down: it went on to the
  floor past him, turned there and went up again; Keen did not move and
  was not lifted (god mode was on, but carrying is no kill). Our rule
  (gameplay.md): a carrier pushes Keen through the tiles and passes him
  where they hold him.
- Not seen: riding up into the ceiling (Keen could not get onto the
  platform by script), the ball, the jack and the wall guns (levels 3 and 4
  lie beyond the block that opens after level 2; level 9 and on are
  further). Their Choco numbers stay; to check in C11.

Watched again in C6 (18-10-2026; js-dos 8.5.3, KEEN3.EXE 1.00, a new
game on the map; positions found with the tile matcher of the scratchpad
tools, icons matched pixel for pixel against our own tiles):

- **Map Keen: 4 px per frame** (frames ~43 ms apart, ~93-97 px/s), as
  Choco. Walking right from the start he stays at **x 176** on the screen
  once the view starts to move (Choco: the view moves when he would pass 11
  cells); a new game shows (35,44) top left (as in C1). (sure)
- **Teleporter** slot 1 (46,41) → slot 3 (55,41) and back: 16 tile changes
  **71 ms (5 retraces) apart**, 1.14 s in all, then Keen appears 14 ms
  later; **Keen is not drawn** during the animation, neither at the source
  nor at the destination; the view jumps to **(45,35)** top left, the
  destination 10 cells right and 6 down. Slots 1 and 3 lead to each other.
  TELEPORTSND not checked (no sound recorded). (sure)
- **Messie:** recorded 70 s of a new game without moving. She first shows
  in the start view **35.8 s** after "Keens Left" closes, and again at
  39.9, 45.6, 56.5 and 61.3 s; our Messie (start (35,8) heading left, 2 px
  per frame, the column-first neighbour rule, 122 frames before weed)
  shows at 35.9, 40.0, 45.6, 56.6 and 61.3 s. So her start, speed, way and
  the weed wait (one weed lies on the way) match to ~0.1 s. Getting on and
  off was not tried (her loop is far from the start). (sure)
- **Ship** (Keen moved one cell left and down from the start, Ctrl): a
  window of 32x6 cells, x 24-295, y 64-127, four message lines from row 0,
  the prompt line at column 9 of row 5 with a blinking cursor after it; four
  **different** messages in five tries (random). (sure)
- **Status screen** with all keycards (C+T+Space): pistol (216) at
  **(216, 84)**, ankh (214) at (72, 116), keycards 217-220 at **(152, 116),
  (184, 116), (216, 116), (248, 116)**, little Keens (sprite 0) at
  (56 + 16 n, 80): exactly Choco's places (4 px below the rows). The C1
  notes "pistol at y 80" and "keycards from text column 18" were the edges
  of their white boxes, not the icons. (sure)
- **After a death** (level 1 entered from the map, Keen walked into the
  plant) Keen is back where he entered and the map view is the same as
  before; "Keens Left" shows 3. (sure)
- Not seen: a done sign (no level was finished), getting on and off
  Messie, the 30-frame lock, sounds.

Watched again in C7 (18-10-2026; js-dos 8.5.3, KEEN3.EXE 1.00). Level 16
cannot be reached by script, so in a scratch copy of the player's files
`LEVEL16.CK3` was copied over `LEVEL01.CK3` and level 1's entrance was
entered from a new game (G+O+D on). Mortimer does not speak then (he
belongs to level number 16), but the machine runs. A 12-second recording,
the lowest pixel of each arm's column and the top of each foot tracked per
frame:

- **Arms:** 7 positions (rows 10-16), a step down every ~108 ms, up every
  ~271 ms (Choco 15 and 40 clock ticks: 103 and 275 ms); at both ends the
  arm rests ~371 ms before it moves again, which is the turn taking one
  step without moving plus the next step. (sure)
- **Feet:** a step every ~245 ms (Choco 35 clock ticks: 240 ms); under the
  body ~490 ms (the turn's step); on the floor ~1.9 s: the step that finds
  the floor, 200 clock ticks, and a step for the turn (1.85 s). (likely)
- **The first view** of the level is lower than ours: the original shows
  rows from ~5.6 (Mortimer's face at the top, the feet at the bottom),
  ours centres Keen and shows rows 2-14.5. The same kind of difference as
  level 1's first view (C3, gameplay.md "Seen in the original"); for C11.
- Not seen: Mortimer, a spark or the heart being shot, the sweeps, the
  border flash, the ending.

## Only the original can answer

Collect the answers here (js-dos) during C3-C10; C11 finishes the list.

1. Ankh: 9.6 s (Choco), 21 s (CG) or 15 s (KeenWiki)? The halo's look.
2. The raygun's amount (start charges: 5, seen in C1).
3. Hit points: mother 5, ninja 4, the rest 1.
4. The mother turning round before she spits; the fireball's speed.
5. The Meep's wave through walls; the Meep singing in the air at a ledge.
6. The ninja's jumps.
7. The Foob: when it gets scared, its speed (~~that it dies when Keen
   touches it~~: seen in C4).
8. Ball and jack: 121/32 per axis, start direction toward Keen.
9. The wall guns: every 2.75 s, all in step, heard off screen.
10. Platforms: the waits (31 ticks), the vertical one turning at once at the
    floor (~~the up-and-down platform's speed, its turn at the floor and,
    roughly, its wait at the ceiling~~: seen in C5; the sideways one and
    riding into a ceiling are still open).
11. The machine: ~~arm and leg steps~~ (seen in C7, with level 16 copied
    over level 1: see below), the sweeps, how long until the level is won;
    what the border flash looks like.
12. The Mortimer boxes: places, pauses, skipping.
13. ~~Teleporters: the animation and the jump of the view~~ (seen in C6).
14. Messie: ~~start (35,8), speed, the wait at the weed~~ (seen in C6),
    getting on and off.
15. ~~The ship's messages: at random?~~ (yes, seen in C6).
16. The done signs on every kind of entrance.
17. The ending: places, the flashes, the end text.
18. Which of level 9's starts is used.
19. The tile an opened door leaves.
20. ~~The status screen's places~~ (measured in C1).
21. Which enemies enemy shots kill.
22. The 1.00 bugs in level 10 and 13.

## Notes for Keen 1 and Keen 2 (information only)

Chocolate Keen also answers some of the open estimates of Keen 1 and Keen 2.
**Their code is not changed for this** (the user's rule); the list is here
in case the user wants a separate fix milestone for those games later.

- Keen 2 (`docs/keen2/gameplay.md`, "Estimates"): confirmed are most walking
  speeds, the grunt's jump chance, the Elder levels 8 and 10, EARTHPOW when
  the beam arrives, 10,000 points once per machine, the wreck tiles, `TO BE
  CONTINUED` before the end text, 3 start charges. Different are: a city
  counts as saved as soon as anything touches its spark (dying clears it
  again); the status screen's city and keycard columns (0/10, 21/25) and at
  most 9 little Keens; the flights and timed ending texts; "Keens Left" 0.86
  s, GAME OVER 5.1 s, attract screens 16.5 s; no "trapped" rule for grunts;
  the youth's hops; the stun (400 clock ticks, a shot kills); the Elite dies
  after 3 shots and charges only when Keen's feet are level with its own;
  the Guard robot's volleys; the platform waits 31 of our ticks; the Earth
  becomes tile 155; no Elder light rule; the shake is ~3.3 s with up to ±32
  px and an "Oops." box. All numbers: [choco-keen1-keen2.md](choco-keen1-keen2.md).
- Keen 1 (`docs/keen-physics.md`, `docs/enemies.md`): Vorticon 3 HP and the
  commander 104 are confirmed. Different: walk acceleration and ground
  friction, one gravity for rising and falling, the pogo bounce without jump
  (~48 px), the exit walk (18/32, ends 2 cells right of the exit), the ice
  chunks (61/32).
- Sounds: 145.65 Hz in all three games.
