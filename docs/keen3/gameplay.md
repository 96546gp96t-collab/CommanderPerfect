# Keen 3: the rules of a level in our engine

What playing Keen 3 does in CommanderPerfect so far, and which numbers are
estimates. Written in milestone C3; C4 added the enemies, C5 the ball, the
jack, the platforms and the wall guns; later milestones add to it. The facts
and their sources are in [research.md](research.md), the code layout in
[architecture.md](architecture.md). Numbers from Chocolate Keen are marked
(Choco) and converted with the table at the top of research.md ("Units").

## The course of the game (C3, provisional)

Until the world map (C6) and the menus (C8) come, the course is the one
Keen 2 had in B3.

| What | Then |
|---|---|
| Keen 3 picked on the start screen | Level 1 |
| `-- --game=3` | Level 1 |
| `-- --game=3 --level=N` | Level N (1-16); another number: level 1, with a message |
| Keen walks out through an exit | The next level; the keycards are taken away. After level 16 (which has no exit; only reachable with the cheat) "That was the last level" and the start screen |
| Keen dies | One life less, the same level again from its file, with "Keens Left" over it |
| Keen dies without lives left | GAME OVER (the bitmap, bare over the level) for 5.27 s or until a key, then the start screen |
| Escape | Back to the start screen |

"Keens Left" is a window of 16x4 cells with a little Keen (sprite 35,
MAPKEEND1) per life, at most 7; the game waits while it is open; it closes
by itself after 0.87 s (seen in js-dos in C1) or with a button. Cheats for
testing, as in Keen 1 and 2: Shift+N / Shift+P (next / previous level,
wrapping around), Shift+I (all keycards, 99 charges), Shift+G (god mode).

Code: `Keen3View` (the scene) on `Keen3SceneScreen` (setup, loading, the
windows, leaving) on `GameScreen`; `Keen3LevelPlay` (the course),
`Keen3LevelSession` (one attempt at a level), `Keen3Body` (Keen and the
ankh).

## Start values

| Value | Keen 3 | Status |
|---|---|---|
| Lives | 4 | certain (Choco; seen in js-dos) |
| Raygun charges | 5 (`Keen3Inventory.START_CHARGES`) | certain (Choco; seen in js-dos) |
| Pogo stick | from the start; Keen 3 has no pogo item | certain |
| Score | 0; an extra life every 20,000 (EXTRAMANSND) | certain |
| Ankh time | 0 at the start of every level | certain (Choco) |

Keen starts at the cell with info 255, 8 pixels down (Choco); he drops
onto the floor below as in Keen 1 and 2. **Level 9 has two starts**, (2,10)
and (63,17): the original scans row by row and keeps the last one, so Keen
starts at (63,17) (`Keen3LevelPlay.start_cell`; `LevelData.find_info`
would give the first).

## Keen

Keen moves with the shared `KeenBody` physics, unchanged (the user decided
that the jumps, a little too high in all three games, stay as they are for
now). Sprites 0-27 have the same numbers as in Keen 1 and 2; dying shows
22 and 23 (KEENISDEAD1/2, checked). A youth stuns him with Keen 3's own
stun (below, "The stun").

## What Keen touches

Everything goes by the tile's behaviour in the tile table of `KEEN3.EXE`.

| Behaviour | Keen 3 in our engine |
|---|---|
| 1 | Deadly (unless the ankh protects him) |
| 2-5 | Doors yellow, red, green, blue: open with the keycard of their color (used up). The door's cells get **the tile left of the door's top cell** (Choco); the door sinks as in Keen 1 (1 px per tick; the original: 1 px per 5 clock ticks, 2 of ours) |
| 6-10 | Points from the table: candy bar 500, burger 100, Vorta-Cola 200, cake 1000, stuffed ninja 5000 (the help text swaps the first two) |
| 15 | Raygun: +5 charges, GOTITEMSND |
| 17 | Exit: any exit tile ends the level, so the two exits of levels 12, 13 and 15 both work. Not while riding a ball or a platform |
| 18-21 | Keycards; taken away at the end of every level |
| 22 | Turns into tile 143, nothing else (Choco); used in no level |
| 27 | **The ankh** (below) |
| 28 | Single charge: +1 charge, GOTITEMSND |

A picked up item leaves **the first tile of its row** in the tile table,
`(tile / 13) * 13` (Choco): each row (143, 156, 169, 182, 195, 208) has its
own background. Keen 1's ship parts, teleporters and statues and Keen 2's
switches and Elders do nothing.

The info layer spawns the enemies of C4 and the objects of C5 (below); the
machine (12, 13, 16-18) comes in C7. Keen's shots use KEENSHOT (102)
and splash with SHOTSPLASHR (105) when flying right, SHOTSPLASHL (106) when
flying left (*estimate*: the original picks one at random).

## Enemies (C4)

All numbers are Chocolate Keen's (Choco), converted with research.md
"Units"; speeds in n/32 pixels per tick, times in our ticks (60 per second).
Each enemy sets off toward Keen's start (the original compares the left
sides of the sprites). Code: `src/keen3/actors/` (`Keen3Enemy` and one class
per kind), the rules in `Keen3LevelSession`.

| Info | Enemy | What it does | Touch | Hits |
|---|---|---|---|---|
| 1, 11 | Grunt (`Keen3Grunt`) | Walks 27.3; every tick a chance of 2 to jump (up-speed random 0-167) and, if not, a chance of 2 to switch between 27.3 and 36.4. Turns at a wall (back to 27.3), walks off ledges. After every landing it looks around 33 ticks (71-74, every 13.2) and then walks toward Keen, however far. Walking 63-66 / 67-70 every 6.6; in the air 73 moving right, 74 moving left | kills | 1; also enemy shots |
| 2 | Youth (`Keen3Youth`) | Runs 76; chance 3 to hop (0-222). Turns at a wall, falls off ledges; 47-50 / 51-54 every 6.6, in the air 50 / 54 | stuns | 1 |
| 3 | Mother (`Keen3Mom`) | Walks 15.2, 85-86 / 87-88; never off a ledge (once off, she is put back and steps back 2 × her speed the other way); turns at a wall. Chance 1 to spit: she turns round and stands with 89 (left) / 90 (right); after 12.4 ticks TANKFIRE and a fireball, after 20.6 she walks on the new way | pushes | 5 |
| 4 | Meep (`Keen3Meep`) | Starts 8 px down in its cell. Walks 19.7, 118-119 / 120-121; turns at a wall. Chance 1 to sing, and it also sings whenever it is not on the ground after a step (the original's bug: at a ledge it hangs in the air, sings, drops a little, sings again). Singing 122 (right) / 123 (left): after 24.7 ticks MEEP and a wave, after 33 it walks on the same way | pushes | 1 |
| 5 | Ninja (`Keen3Ninja`) | Stands facing Keen (77-78 / 79-80 every 13.2), does not fall. When Keen's sprite is at most 5 tiles above or below its own: chance 3 to jump, up 0-195, sideways 76 toward Keen (81 left / 82 right); stands when it lands | kills | 4 (the original's 3, counted before it checks) |
| 6 | Foob (`Keen3Foob`) | Walks 15.2 (93-94 / 95-96 every 13.2), turns at a wall, walks off ledges. On the screen a chance of 2 to get scared: YORPSCREAM, yells 97-98 (every 4.1) for 9.9 ticks, then runs away from Keen at 76 (frames every 3.3); at a wall it stops facing it and keeps running on the spot. Woken again while it flees, it walks away from Keen | **the Foob dies**, Keen nothing | 1; also enemy shots (not waves) |

- **Projectiles.** The fireball (`Keen3Fireball`): from the mother's left
  side, 12 px below her top, 45.5, no gravity, 57-58 (left) / 59-60 (right)
  every 3.3; splashes (SHOTHIT) on a wall, at once when it starts in one, and
  on any sprite but a mother or a corpse: so Keen can shoot it down (both
  splash); it kills Keen (also a stunned one), grunts and Foobs, and only
  splashes on youths, Meeps and ninjas. The wave (`Keen3SoundWave`): from the
  Meep's left side or 16 px right of it, 4 px down, 60.7, **through walls**,
  126-127 (right) / 128-129 (left) every 3.3; kills Keen; Keen's shot
  splashes on it and it flies on; it touches no enemy.
- **Keen's shot** (`Keen3Shot`): 121 (Keen 1 and 2: 124), splashes on every
  awake sprite but Keen and the corpses; a splash stays 8 ticks (20 clock
  ticks). SHOTHIT whenever a shot splashes.
- **Dying:** the first dying frame, the next after 16.5 ticks (alternately 17
  and 16 of ours), the last stays as the corpse, which falls. Grunt 75-76,
  youth 55-56, mother 91-92, Meep 124-125, ninja 83-84 (all vortscream),
  Foob 99-100-101 (YORPSCREAM). **Enemies give no points.**
- **Pushing** (mother, Meep): Keen is moved sideways out of the enemy's box
  at once, at most 15 px, through the tiles; it never hurts him and the
  ankh does not stop it.
- **Chances:** "chance k" is a random byte below 6k once per original frame,
  so 9.5·k in 1000 per tick of ours (`Keen3Enemy.chance`).
- **Falling:** gravity 4.05 per tick, at most 111 (Choco: 3 per clock tick,
  at most 200, through the falling helper). Not Keen's, which stays shared.

## Ball, jack, platforms and wall guns (C5)

All numbers are Chocolate Keen's (Choco), converted as above; the
up-and-down platform was also watched in js-dos (research.md). Code:
`Keen3Ball`, `Keen3Jack`, `Keen3Platform` (on `Keen3Carrier`),
`Keen3WallGun`, `Keen3GunShot` in `src/keen3/actors/`; the hits in
`Keen3Hits`, the guns' clock and the riding in `Keen3LevelSession`.

| Info | Object | What it does | Touch | Shots |
|---|---|---|---|---|
| 7 | Ball (`Keen3Ball`) | Sets off diagonally toward Keen's start (the top left corners compared; right and down when level), 121 on each axis, no gravity; an axis that hits a tile turns round (walls, floors, ceilings). One picture, 109. Wakes and sleeps as the enemies | **carries** Keen (solid, below) | splash on it; never breaks |
| 8 | Jack (`Keen3Jack`) | The same flight; 110-113 every 3.3 | **kills** Keen (not through the ankh) | splash on it; never breaks |
| 9 | Platform, sideways (`Keen3Platform.sideways`) | 4 px above its cell; sets off right at 22.8; at a wall it stands still 31 ticks, then goes back. 107-108 every 13.2 | carries | splash on it; never breaks |
| 10 | Platform, up and down (`Keen3Platform.up_and_down`) | In its cell; sets off **down** at 22.8; at a floor it turns up at once, at a ceiling it stands still 31 ticks, then goes down | carries | splash on it; never breaks |
| 14 | Wall gun → (`Keen3WallGun`) | Invisible; every 165 ticks a shot (103) from 3 px below the top left of its cell, 121 to the right | — | — |
| 15 | Wall gun ↓ | The same, its shot (104, 8x16) from 4 px right of the top left, 121 down | — | — |

- **Platforms always move**, also far out of sight; balls and jacks wake
  and sleep as the enemies do ([Waking and sleeping](#waking-and-sleeping-c4)).
- **One clock for all guns** (Choco): it starts with the level, and every
  165 ticks (400 clock ticks, 2.75 s) every gun of the level fires, with
  one TANKFIRE, heard wherever the guns are. A shot that would start where
  sprites are deleted (outside -8 … +28 / -8 … +18 tiles) is not made: the
  original deletes it at once. So a gun far away is heard but its shot
  never splashes there.
- **The gun's shot** (`Keen3GunShot`): straight until a wall (SHOTHIT and
  a splash, 105); it **flies through every sprite**, and kills on its way
  Keen (also a stunned one; not through the ankh), grunts and Foobs. Keen's
  shot splashes on it and it flies on; a fireball splashes on it too.
- **Keen's shot** splashes on balls, jacks and platforms as on every other
  sprite (C4 rule); none of them can be hurt. A fireball splashes on them
  as well.

### Riding (`Keen3Carrier`)

Balls and platforms are solid, as the original's "carry" (Choco). Standing
and riding are Keen 2's (`Keen2RidingCollision`: their tops are floors for
Keen; the session moves a Keen who stands on one along with it, through the
tiles). What happens when Keen and a carrier overlap:

| Where Keen is | Then |
|---|---|
| His feet at most 8 px below its top, not rising | put on top (lifted, through the tiles) |
| His head at most 12 px above its bottom, while he rises or it comes down | pushed down (through the tiles); his jump ends: he rises no faster than it (*estimate* of the 12 px) |
| Otherwise | pushed out sideways, to the nearer side (through the tiles) |

Every push goes through the tiles, so Keen is never put inside a wall.
**When the tiles hold him, the carrier passes him** and nothing else
happens: a platform that comes down on Keen standing on the floor goes on
to the floor past him and turns up there; a ball that runs into Keen against
a wall goes on to the wall and bounces there. That is what the original did
in level 2 (js-dos, C5; research.md). If the platform then rises under him,
he is put on top and rides up.

**Carried up into a ceiling** (*estimate*, not seen in the original;
Commander Genius pushes Keen down through the platform): when the session
moves a rider up and a ceiling stops his head, the carrier stops under his
feet and reacts as if it had hit the ceiling itself: the up-and-down
platform waits 31 ticks and goes down, a ball bounces down. Keen is never
squeezed into a tile and never killed by it.

- **No exit while riding** (Keen 2's rule, inherited): Keen cannot walk out
  through an exit tile while he stands on a ball or a platform.
- **The 32x8 platform** (Keen 2's is 32x16): its box is the whole sprite,
  so Keen's feet stand on its top line, as in the original's pictures.
- A wall or a ceiling at Keen's height scrapes him off a moving platform
  (level 14: the pole at column 110 over the spikes).

## Waking and sleeping (C4)

`Keen3ActiveArea` (Choco): a sleeping sprite wakes when the cell of its top
left corner is more than 2 tiles left of / above the view's top left tile
and less than 23 tiles right / 12 down of it; an awake one falls asleep
outside -8 … +28 / -8 … +18 (inclusive). Shots, splashes, waves and corpses
are deleted there instead. Asleep, an enemy neither moves nor touches
anything. "On screen" for the Foob: more than 0 and less than 19 / 12.

**Widescreen (decision of C4):** the limits on the right and at the bottom
grow with the view (the margins around the visible area stay the
original's): a view of 27 tiles across wakes up to 23 + 7, one of 15 rows
down to 12 + 3. With two views a sprite counts in either. Without a view
(tests) an original 320x200 view around each Keen. A wave is also deleted
as soon as its picture leaves the playable area: beyond the walls lies only
the border (never shown) and, in a view wider than level 16, the black bars.

## The stun (C4)

`Keen3Body` replaces Keen 2's stun (Choco): a youth gives Keen its speed,
sideways cut to 66.7 (the original's 120 through its steering helper);
he slides to a stop (4.05 per tick, also in the air) and falls with
gravity 4.05; he ignores every button for 165 ticks lying (28 and 29 every
13.2), then 16.5 ticks getting up (30, KEENMELT). He cannot walk out
through an exit while stunned. Unlike Keen 2 he is not knocked up and a
shot does not cut the stun short: **any enemy shot kills a stunned Keen**,
and so do grunts, ninjas, waves and deadly tiles. The ankh prevents the
stun (`is_protected()`), and every kill goes through `KeenBody.kill`, which
`Keen3Body` stops while the ankh runs; god mode prevents both.

## The ankh

| What | Value | Source |
|---|---|---|
| Protection per ankh | 577 ticks (1400 clock ticks, 9.6 s); another ankh adds its time | Choco |
| Sound | ANKH (sound entry 41), played by `Keen3Sounds` on its own speaker | Choco |
| At the start of every level | 0 (every attempt makes a new `Keen3Body`) | Choco |
| Counts down | only while the game runs (one per tick in `Keen3Body.step`; not behind "Keens Left") | Choco |
| Protects against | everything that kills through `KeenBody.kill` (deadly tiles, enemies, fireballs, waves) and the stun (`Keen3Body.is_protected`); not against a push | Choco |
| Does not protect against | falling out of the level | Choco |
| Halo | sprites 61 (GODHALO) and 62 (BYEHALO) in turn every 6.6 ticks, at Keen −8, −8 px (`Keen3AnkhShield`, drawn by the ActorLayer behind Keen; its middle is transparent) | Choco |
| Blink | in the last 103 ticks; every other picture is left out (*estimate* of the look) | Choco (when), estimate (how) |
| Shown time | whole "seconds" of 144 clock ticks (59.3 of ours): a fresh ankh shows 9, as the status screen | Choco |

The ankh time is Keen's own (`Keen3Body.ankh_ticks`), not part of the
inventory: it never leaves a level. The status screen (C6) reads it from
there.

## The HUD (widescreen)

`Keen3Hud` (a subclass of the shared `Hud`): the lives with Keen 3's map
Keen (sprite 35) and the score on the left; the raygun with its charges and
the keycards on the right; while the ankh runs, a third panel under the
right one with the ankh (the first tile with behaviour 27, tile 149) and
its time in whole seconds. The raygun, keycard and ankh pictures are the
first tiles with that behaviour (`Keen2Icons`): 151, 152-155, 149. Since
C4 they leave out the background colour of their row (the colour of the
row's first tile, wherever it touches the tile's edge), so the panel shows
through as in Keen 1 and 2 (`Keen3Hud.without_row_background`; the shared
HUD only leaves out Keen 1's gray).

## The border

Every Keen 3 level has a border of 2 cells of tile 245, an "OH no!"
picture that must never be seen. Checked in C3: the shared `LevelMap`
only draws the playable area, and the camera's limits (`LevelCamera`) never
go past it; where a level is narrower than the view (level 16 in
widescreen, 21 cells wide) black bars show, not the border. xBRZ and HD
scale the same tiles, so they show no more. `tests/test_keen3_play.gd`
checks for every level 1-16 that no border cell is drawn and that the
camera keeps to the playable area for views of 320, 426 and 480 pixels.
Nothing had to change for Keen 3. Still to check in later milestones: the
map (C6), map 81 (C7), map 90 (C8) and two players (C10).

## Not yet

The world map and the status screen (C6), level 16's machine (C7), title, menus, saving and
high scores (C8), the pictures behind levels (C9; never Keen 1's or 2's),
two players (C10).

## Seen in the original (C3)

Not compared in js-dos in C3 (the comparison is optional and was skipped).
One thing to check: level 1's first view. In C1 the original showed cell
(2,12) in the top-left corner of the 4:3 view; ours shows (2, 11.5),
because our camera centres Keen and stops at the bottom of the playable
area (row 23 ends at pixel 384, the view is 200 high). Either the original
shows 8 pixels of the bottom border row (unlikely), or its view is less
than 200 pixels high, or its first view is placed differently. To check in
C11.

## Estimates to check against the original

- C5: the head reach of 12 px (from below), the carrier that stops under a
  Keen carried into a ceiling, which splash picture a gun's shot shows
  (105), that a far gun's shot is not made at all. Seen in js-dos: the
  up-and-down platform's speed, its turn at the floor and its wait at the
  ceiling (roughly), and that it passes a Keen held by the floor. Not
  seen: the sideways platform, the ball, the jack, the guns.

- C4: the youth's one box for both directions (the right-running frames
  carry a smaller box in EGAHEAD.CK3; Choco would use it); which splash
  sprite (the original picks at random); the widescreen waking area; the
  enemies drop onto the floor below them when the level starts, as in Keen
  1 and 2 (the original lets them fall in their first frames); the wave
  deleted at the edge of the playable area. Everything else of the enemies
  is Choco's and only partly seen in js-dos (research.md, "Watching the
  original").

- The halo's blink (which pictures are left out) and whether it is drawn
  in front of Keen or behind him.
- The splash sprites per direction (105 right, 106 left).
- The door sinking speed (shared: 1 px per tick; Choco: 1 px per 5 clock
  ticks).
- "Keens Left": the window's place (the original: x 88-231, y 72-119) and
  how many little Keens fit.
- The ankh time itself: 9.6 s (Choco) against 15 s (KeenWiki) and 21 s (CG)
  (research.md, "Only the original can answer", 1).

## Testing

- `tests/test_keen3_level.gd` and `tests/test_keen3_keen.gd`: hand-made
  levels (`tests/keen3_fixtures.gd`, with a border of tile 245): points per
  behaviour, the candy bar and the burger, what an item leaves, raygun,
  single charge, keycards, doors (the left tile, sinking, shut without the
  card), the exit, two exits, deadly tiles, behaviour 22, no enemies,
  shots, keycards gone after a level, the start values, the pogo stick
  from the first tick, level 9's later start, dying and stun frames, and
  the ankh (protects from a deadly tile, not from falling out, adds up,
  reset per level, counts down only while playing, no stun, the shown
  seconds, the halo's frames and blink).
- `tests/test_keen3_play.gd` with the player's files (skipped without
  them): every level starts with Keen inside it and no enemies, level 1
  plays (and the plant right of the start kills, as in js-dos), level 9
  starts at (63,17), exits per level, the item rows of the real table,
  the ankhs of levels 3, 10 and 14, the border is never drawn, the course
  (next level, death, game over, after level 16), the HUD icons.
- C4: `tests/test_keen3_enemies.gd` (each enemy: spawning per info value,
  walking, turning, ledges, touching Keen, hits, dying frames, the
  fireball, the wave through a wall, the Meep at a ledge, the ninja's jump,
  the Foob scared and fleeing), `tests/test_keen3_enemy_rules.gd` (the
  stun, the ankh against enemies, no points, dying frames, waking and
  sleeping also in widescreen, far shots, Keen's shot and the wave, the
  chances, the HUD's row background) and `tests/test_keen3_enemy_census.gd`
  (real files: every level spawns the enemies of research.md §5).
- C5: `tests/test_keen3_objects.gd` (ball and jack: spawning toward Keen,
  the diagonal flight, bouncing on every side, riding the ball, its push,
  passing a Keen held by a wall, the jack's touch and the ankh, shots that
  splash on both; the guns: one clock every 165 ticks, the shots' start and
  speed, far guns heard without a shot, the splash at a wall, what the shot
  kills and passes, Keen's shot on it) and `tests/test_keen3_riding.gd`
  (both platforms: spawning, the waits and turns, always moving, stopping
  shots; riding both, carried into a ceiling, a platform coming down on
  Keen, bumping the head from below, no exit while riding). The census
  suite also counts the objects of every level (research.md §5).
- The screen: `tools/scripted_play.gd` with
  `SCENE=res://src/keen3/keen3_view.tscn -- --game=3 --level=N`. With
  `--fixed-fps 60` the frames run much faster than real time, so a
  screenshot can show a frame from some ticks earlier (it depends on the
  machine and on full screen); take them a little later than the event.
