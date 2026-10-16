# Keen 2: the rules of a level in our engine

What playing a Keen 2 level does in CommanderPerfect so far, and which
numbers are estimates. Written in milestone B3, the enemies in B4; later
milestones add to it.
The facts and their sources are in [research.md](research.md), the code
layout in [architecture.md](architecture.md).

## The course of the game (temporary, B3)

There is no title, menu or world map yet (B6, B7). Until then:

| What | Then |
|---|---|
| Keen 2 picked on the start screen | Level 1 |
| `-- --game=2 --level=N` | Level N (1-16); another number starts level 1 with a message |
| Keen walks out through the exit | The next level; after level 16 the start screen |
| Keen dies | One life less and the same level again, fresh from its file; "Keens left: N" |
| Keen dies without lives left | "Game over", then the start screen |
| Escape | The start screen |

Levels 80, 81 and 90 (world map, space, title) are not played yet. Cheats
for testing, as in Keen 1: Shift+N / Shift+P (next / previous level),
Shift+I (all keycards, 99 charges), Shift+G (god mode). Enter (status
screen) does nothing yet; Keen 2's status screen comes with the cities in
B6.

Code: `Keen2View` (the scene) and `Keen2LevelPlay` (the course of the
levels), `Keen2LevelSession` (one attempt at a level).

## Start values

| Value | Keen 2 | Status |
|---|---|---|
| Lives | 4 | certain (same as Keen 1) |
| Extra life | every 20,000 points | certain (same as Keen 1) |
| Pogo stick | from the start; Keen 2 has no pogo item | certain |
| Raygun charges | **0** (`Keen2Inventory.START_CHARGES`) | **estimate**: Commander Genius reads them from a code byte of `KEEN2.EXE`, which we do not read. Check in the original. |
| Ship parts | none (Keen 2 has cities instead, B6) | certain |

## What Keen touches

Everything goes by the tile's behaviour in the tile properties of
`KEEN2.EXE`, never by tile number.

| Behaviour | Keen 2 in our engine |
|---|---|
| 1 | Deadly |
| 2-5 | Doors yellow, red, green, blue: open with the keycard of their color (used up), sink into the floor, leave tile 143 |
| 6-10 | Points 500, 100, 200, 1000, 5000 |
| 11-14 | Keen 1's ship parts: **not items** in Keen 2 (nothing happens) |
| 15 | Raygun: +5 charges |
| 16 | Pogo stick: as in Keen 1 (Keen has it anyway; no Keen 2 level is known to have one) |
| 17 | Exit |
| 18-21 | Keycards yellow, red, green, blue; they only count in the current level |
| 22 | Vorticon Elder's message: **nothing yet** (B5/B6), and not Keen 1's statue |
| 23, 25, 26 | Switches: nothing yet (B5) |
| 24 | Keen 1's teleporter: nothing in Keen 2 |

A picked-up item leaves tile 276 when its tile number is 305 or more,
otherwise tile 143, as in Keen 1. Whether 276 is right for every Keen 2 item
is uncertain (research.md §3).

## Enemies and the info layer

Built in B4 (`src/keen2/actors/`). The info layer of a level says where
each enemy starts, with its sprite's top left at the top left of the cell:

| Info | Enemy | Class |
|---|---|---|
| 1 | Vorticon grunt | `Keen2Grunt` |
| 2 | Vorticon youth | `Keen2Youth` |
| 3 | Vorticon Elite | `Keen2Elite` |
| 4 | Scrub | `Keen2Scrub` |
| 5 | Guard robot | `Keen2GuardRobot` |
| 6 | Moving platform, 4 pixels above its cell | `Keen2Platform` |
| 7 | The spark of the Tantalus Ray machine: **nothing yet** (B5) | |
| 8 and up | Nothing; from 0x100 on, at a switch, the bridge offset (B5) | |

As in Keen 1, an enemy drops onto the floor below it when the level starts
(not the Guard robot and the platform: they float), and it wakes up when it
comes into view (one tile around the screen counts). The platform is always
awake. Chances are rolled as in Commander Genius: a chance of n is n + 1 in
1000 per tick, from the session's seeded random numbers, so that every
attempt at a level goes the same way. Enemies fall with 4/32 pixels per
tick per tick, at most 104/32. Speeds are in pixels per tick.

| Enemy | What it does | Touch | Shots | Dies |
|---|---|---|---|---|
| Grunt | Looks around (frames 82-83, 16 ticks each), then walks at 28/32 (74-77 left, 78-81 right, 5 ticks a frame), towards Keen if he is within 8 tiles sideways, away from a wall it stands against. Jumps at random (chance 20; 90-149/32 up; frames 84 left, 85 right) and looks around when it lands. At a wall it looks around; if it hit the last wall less than 160 ticks ago it is trapped and jumps (90/32 or 150/32). Walks off ledges. No jumping in the dark (`Keen2LevelSession.is_dark()`, false until B5). | deadly | 1 | frame 86 for 26 ticks, then 87; VORTSCREAM |
| Youth | Runs at 77/32 (48-51 left, 52-55 right, 7 ticks a frame), starting left or right at random; turns at walls; runs off ledges. On the ground it hops (chance 100; at a wall chance 200), 80/32 or 200/32 up at random. | **stuns** Keen | 1 | frame 56 for 21 ticks, then 57; slides on at 20/32, 1/32 slower every 11 ticks; VORTSCREAM |
| Elite | Walks at 31/32 (88-91 left, 92-95 right, 7 ticks a frame), turns at walls, walks off ledges. When Keen's feet are less than 2 tiles above or below its own it turns to him (9 times out of 10), and when he is also less than 6 tiles away sideways it charges at 62/32. On the ground, with the lights on: jumps (chance 15; 90-149/32; 98 right, 99 left), or, at least 26 ticks after its last shot, aims (chance 8): faces Keen 4 times out of 5, holds the raygun out (96 left, 97 right) for 23 ticks, fires (KEENFIRESND), holds it 21 more ticks. Trapped (a wall less than 150 ticks after the last) it jumps. | deadly | 4; the Guard robots' shots do not hurt it | frame 100 for 46 ticks, then 101; VORTSCREAM |
| Scrub | Crawls at 25/32 along floors, walls and ceilings (two frames each, 12 ticks a frame: 102-103 left on a floor, 104-105 up a wall on its left, 106-107 right along a ceiling, 108-109 down a wall on its right). An inside corner turns it to the next way, an outside corner takes it round the edge; when that edge is not solid (a floor that is only solid on top) it falls (frame 102), and crawls left again where it lands. | harmless: Keen rides it; it pushes him aside | 1 | pops up (10/32) as frame 110, lies as 111; SHOTHIT |
| Guard robot | Floats (never falls) at 31/32, starting to the right (112-115 right, 116-119 left, 7 ticks a frame). At a wall it looks around for 26 ticks (120-121, 5 ticks each) and goes back. Volleys: the first after 200 ticks, then after 31-199 ticks (counted from the last volley or look). It stops for 25 ticks, fires 4 shots 13 ticks apart while it floats on (TANKFIRE; it holds a shot back while it touches a wall), and stops 25 ticks again. Looking around ends a volley. Shots leave 5 pixels below its top, 4 pixels in front. | deadly | invincible; it stops Keen's shots | never |
| Platform | Floats sideways at 23/32, starting to the right (126-127, 16 ticks a frame). At a wall or the map edge it waits 51 ticks and goes back. Always awake. | harmless: Keen rides it | swallows every shot | never |

The collision boxes inside the sprites are estimates until we can read
`EGAHEAD.CK2`'s sprite table: Keen 1's Vorticon for the grunt and the
Elite, 12x14 for the youth, 16x16 for the Scrub, Keen 1's tank for the
Guard robot, 32x8 for the platform.

### The stun (Vorticon youth)

A youth that runs into Keen stuns him (`Keen2Body.stun`): he is knocked up
as high as a full jump (120/32), puts the pogo stick away, faces the way
the youth runs, and ignores every button for 250 ticks; he still falls and
slows down (friction keeps working). He lies dazed, frames 28 and 29 in
turn (26 ticks each), and gets up in the last 20 ticks (frame 31). A youth
leaves a stunned Keen alone; once he is up it can stun him again. An enemy
shot does not kill a stunned Keen: it cuts the stun short, to at most 20
more ticks. Other enemies kill a stunned Keen as usual. In god mode there is
no stun. Keen 1's ice freeze is not used for it: its frames change every 25
ticks, it plays a sound and it pushes Keen.

### Riding

Keen can stand on a platform and on a Scrub: their tops are floors for him
(he jumps up through them and lands on them from above), and every tick he
moves along as far as they moved, through the tiles. When he runs into
their side, or they into his, he is pushed out sideways; when his feet are
at most 8 pixels below the top (it rose into him), he is put on top. While
he rides he cannot walk out through an exit door. Only Keen rides; enemies
do not.

### Where we differ from Commander Genius

Commander Genius is our documentation, not our code; where it has an
obvious slip we do the sensible thing (to be checked in B10):

- An Elite that charges keeps charging in CG, also when Keen is gone, and
  never jumps or fires again. Ours charges only while it sees Keen close.
- CG resets an Elite's "trapped" count only in the dark, so after its first
  150 ticks it never jumps out of a pit again. Ours resets it at every
  wall, as the grunt does.
- CG's youth can start a hop in mid-air when it turns at a wall. Ours hops
  only from the ground.
- CG starts an Elite's shot to the left one pixel inside the Elite; ours
  starts in front of it on both sides (it would fly through its own kind
  anyway).
- The Scrub's corner rules are our own: CG's nudge the Scrub by fixed
  pixel amounts round a corner; ours go round the tile edge it holds on to.

## Shots

Keen's raygun shot flies and splashes exactly as in Keen 1; it uses Keen
2's sprites: 122 (Keen's shot), 123 (enemy shot), 124/125 (splash). It
kills grunts, youths and Scrubs with one hit and Elites with four; the
Guard robot and the platform stop it unharmed. A hit plays SHOTHIT, a death
the enemy's own sound.

The enemies' shots (`Keen2EnemyShot`, sprite 123) fly at 108/32. One kills
Keen, unless he is stunned (see above). They fly through enemies of the
kind that fired them. Whether they hurt other enemies is
`Keen2LevelSession.ENEMY_SHOTS_HURT_ENEMIES` (true, as in Commander Genius;
uncertain for the original; a session can switch it off with
`enemy_shots_hurt_enemies`). With it on, a Guard robot's shot kills
grunts, youths and Scrubs, and an Elite's shot hurts grunts, youths and
Scrubs. An Elite stops a Guard robot's shot unharmed, the Guard robot stops
an Elite's shot unharmed, and the platform swallows every shot.

## The HUD (widescreen)

Lives, score, raygun charges and keycards; no ship parts. The raygun and
keycard icons are the first tile with that behaviour in the tile
properties (`Keen2Icons`), because Keen 2's status screen tile numbers
(414, 424-427 in Commander Genius) are not certain.

## Not yet

Switches, bridges, darkness, the Tantalus Ray and its spark (B5);
the world map, cities, status screen, the Elder's messages and the ending
(B6); menus, saving and high scores (B7); pictures behind the levels (B8;
Keen 1's pictures are never shown behind Keen 2's levels); two players (B9).

## Estimates to check against the original (B10)

- Starting raygun charges: 0.
- The background tile 276 for items from tile 305 on.
- Enemies (B4), all from Commander Genius (research.md §5):
  - Chances: n + 1 in 1000 per tick for a chance of n.
  - Grunt: 1 HP; walk 28/32, 5 ticks a frame; look 2 x 16 ticks; jump
    chance 20, 90-149/32; trapped below 160 ticks, then jumps 90/32 or
    150/32; turns to Keen within 8 tiles after a look; dying frame 26
    ticks.
  - Youth: 1 HP; run 77/32, 7 ticks a frame; hop chance 100 on the ground,
    200 at a wall; hops 80/32 and 200/32; frying 21 ticks; the corpse
    slides at 20/32, 1/32 slower every 11 ticks.
  - Stun: 250 ticks; knocked up 120/32; frames 26 ticks; getting up 20
    ticks; a shot leaves 20 ticks.
  - Elite: 4 HP (CG also has an unused 3); walk 31/32, charge 62/32, 7
    ticks a frame; sees Keen within 2 tiles of height, charges within 6
    tiles; turns to him 9 in 10, aims at him 4 in 5; jump chance 15,
    90-149/32; trapped below 150 ticks; fire chance 8, at least 26 ticks
    apart, gun out 23 + 21 ticks; shot 9 pixels below its top, 1 in front;
    dying frame 46 ticks.
  - Scrub: crawl 25/32, 12 ticks a frame; dies popping up at 10/32. Its
    corner rules are our own (CG's are messy).
  - Guard robot: 31/32, 7 ticks a frame; look 26 ticks, 5 a frame; first
    volley after 200 ticks, later 31-199; 4 shots 13 ticks apart; 25 ticks
    still before and after; shot 5 pixels below its top, 4 in front.
  - Platform: 23/32, waits 51 ticks, 16 ticks a frame; 4 pixels above its
    cell (certain in CG's loader, but still to be seen).
  - Riding: feet up to 8 pixels below a carrier's top count as on it.
  - Enemy shots: 108/32; they hurt other enemies
    (`ENEMY_SHOTS_HURT_ENEMIES`).
  - The collision boxes of all enemies (`EGAHEAD.CK2`'s sprite table).
  - Sprites 84/85: VORTJUMPL/VORTJUMPR as Chocolate Keen names them (CG has
    them the other way round).

## Testing without Keen 2's files

- `tests/test_keen2_level.gd`: hand-made levels (`tests/keen2_fixtures.gd`).
- `tests/test_keen2_enemies.gd` and `tests/test_keen2_riding.gd`: the
  enemies, the stun, the shots and riding, in hand-made levels.
- `tests/test_keen2_stand_in.gd`: the Keen 1 shareware files copied under
  Keen 2's names (`KEEN1.EXE` → `KEEN2.EXE`, `*.CK1` → `*.CK2`): loading
  and the course of the levels; every level is also played for a while
  with the enemies that Keen 1's info values become. Keen 1's `SOUNDS.CK1` becomes `SOUNDS.CK2`,
  which `Keen2GameData` uses when `KEEN2.EXE` has no sound block.
- The game screen needs a running scene tree, so it is checked with
  screenshots: make such a copy in a temporary folder, then
  `SCENE=res://src/keen2/keen2_view.tscn STEPS=... OUT=... xvfb-run -a godot
  --rendering-driver opengl3 --fixed-fps 60 --path . --script
  res://tools/scripted_play.gd -- --game=2 --level=1
  --data-dir-keen2=<copy>`. Delete the copy afterwards; it never goes into
  the repository. With the stand-in data the enemies show Keen 1's
  pictures for Keen 2's sprite numbers (a grunt looks like a Vorticon, a
  youth like a Yorp, a Guard robot like ice), and sprites from 119 on (the
  platform, Guard robot frames 119-121, the enemy shot) are not drawn at
  all: Keen 1 has no such sprites.
