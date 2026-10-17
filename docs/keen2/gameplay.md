# Keen 2: the rules of a level in our engine

What playing Keen 2 does in CommanderPerfect so far, and which numbers are
estimates. Written in milestone B3, the enemies in B4, the switches, the
Tantalus Ray and the Earth exploding in B5, the world map, the cities, the
status screen and the ending in B6; later milestones add to it.
The facts and their sources are in [research.md](research.md), the code
layout in [architecture.md](architecture.md).

## The course of the game (B6, B7)

| What | Then |
|---|---|
| Keen 2 picked on the start screen | The title with the main menu open (B7) |
| `-- --game=2` | The title |
| Title / high scores | They take turns every 8 seconds; a key opens the main menu |
| "New Game" / "Continue Game" | A new or saved game on the world map (map 80), with "Keens Left" |
| `-- --game=2 --level=N` | Level N (1-16) at once; after it the map. Another number: the title, with a message |
| On the map | Keen walks as on Keen 1's map (`MapSession`, unchanged): the jump or pogo button on an entrance enters its level |
| Keen walks out through the exit | The level is done: back on the map where he went in; its entrance shows the "DONE" sign (77, or 78-81 for 2x2) and cannot be entered again. Entrances with 0x8000 (levels 1 and 5) block the way until their level is done |
| A city level is done | That city is saved (levels 4, 6, 7, 9, 11, 13, 15, 16: London, Cairo, Sydney, New York, Paris, Rome, Moscow, Washington) |
| All eight cities saved | The ending (below), then the high scores |
| Keen dies | One life less, back on the map with "Keens Left" |
| Keen dies without lives left | GAME OVER (the bitmap) for 4 seconds or until a key, then the high scores |
| Keen presses the switch of an intact Tantalus Ray machine | The Earth explodes, GAME OVER whatever the lives, then the high scores (B5) |
| Enter | The status screen (below); Enter or a button closes it |
| Escape | The main menu (B7) |

"Keens Left" is Keen 1's window (`MapMessages`, unchanged): a little Keen
per life, it closes by itself after 3 seconds or with a button. A city is
saved when its level is done, as in Commander Genius; how the original
keeps Keen from leaving a city before its machine is destroyed is still to
be seen (research.md, question 14). Cheats for testing, as in Keen 1, on
the map and in a level: Shift+N / Shift+P (next / previous level; from
the map level 1 / 16), Shift+I (all keycards, 99 charges), Shift+G (god
mode).

Code: `Keen2View` (the scene), `Keen2SpaceScreen` (what it shows on map
81), `Keen2LevelPlay` (the course of the game), `Keen2Progress` (the
cities), `Keen2LevelSession` (one attempt at a level).

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
| 22 | Vorticon Elder's message, only with tile 429 right below (B5, below); not Keen 1's statue |
| 23, 25, 26 | Switches: touching does nothing; the pogo button uses them (B5, below) |
| 24 | Keen 1's teleporter: nothing in Keen 2 |

A picked-up item leaves tile 276 when its tile number is 305 or more,
otherwise tile 143, as in Keen 1. The levels agree: the items 306-311 lie
between 276 tiles, the others between 143 tiles.

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
| 7 | The spark of a Tantalus Ray machine (B5, below) | `Keen2Spark` |
| 8 and up | Nothing | |

Nothing spawns at a switch tile (behaviour 23, 25 or 26), whatever its
info value: there the value is the switch's bridge offset (below). That a
value under 0x100 (a bridge in the switch's own row) would otherwise make an
enemy is our reading; Commander Genius does not say.

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
| Elite | Walks at 31/32 (88-91 left, 92-95 right, 7 ticks a frame), turns at walls, walks off ledges. When Keen's feet are less than 2 tiles above or below its own it turns to him (9 times out of 10), and when he is also less than 6 tiles away sideways it charges at 62/32. On the ground, with the lights on: jumps (chance 15; 90-149/32; 98 left, 99 right), or, at least 26 ticks after its last shot, aims (chance 8): faces Keen 4 times out of 5, holds the raygun out (96 left, 97 right) for 23 ticks, fires (KEENFIRESND), holds it 21 more ticks. Trapped (a wall less than 150 ticks after the last) it jumps. | deadly | 4; the Guard robots' shots do not hurt it | frame 100 for 46 ticks, then 101; VORTSCREAM |
| Scrub | Crawls at 25/32 along floors, walls and ceilings (two frames each, 12 ticks a frame: 102-103 left on a floor, 104-105 up a wall on its left, 106-107 right along a ceiling, 108-109 down a wall on its right). An inside corner turns it to the next way, an outside corner takes it round the edge; when that edge is not solid (a floor that is only solid on top) it falls (frame 102), and crawls left again where it lands. | harmless: Keen rides it; it pushes him aside | 1 | pops up (10/32) as frame 110, lies as 111; SHOTHIT |
| Guard robot | Floats (never falls) at 31/32, starting to the right (112-115 left, 116-119 right, as `EGAHEAD.CK2` names them; 7 ticks a frame). At a wall it looks around for 26 ticks (120-121, 5 ticks each) and goes back. Volleys: the first after 200 ticks, then after 31-199 ticks (counted from the last volley or look). It stops for 25 ticks, fires 4 shots 13 ticks apart while it floats on (TANKFIRE; it holds a shot back while it touches a wall), and stops 25 ticks again. Looking around ends a volley. Shots leave 5 pixels below its top, 4 pixels in front. | deadly | invincible; it stops Keen's shots | never |
| Platform | Floats sideways at 23/32, starting to the right (126-127, 16 ticks a frame). At a wall or the map edge it waits 51 ticks and goes back. Always awake. | harmless: Keen rides it | swallows every shot | never |

The collision boxes inside the sprites come from `EGAHEAD.CK2`'s sprite
table (it holds the last pixel inside the box, so a box is one pixel wider
and higher than right − left and bottom − top): (2, 1, 20, 31) for the
grunt and the Elite, (0, 0, 16, 16) for the Scrub, (0, 0, 16, 24) for the
Guard robot, (0, 0, 32, 16) for the platform and (2, 2, 12, 12) for the
spark. The youth's left-running frames have (1, 6, 14, 18), its
right-running frames (4, 4, 8, 20), which is exactly Keen 1's Yorp box and
most likely left over. We give the youth the left box both ways (an
estimate): a box that changes with the direction would push a youth that
turns at a wall into it.

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

## Switches

Keen uses a switch with the **pogo button** (`Keen2Switches`, through
`Keen2Body`). When the button goes down and a tile with behaviour 23, 25 or
26 is in the column through the middle of Keen's box, checked from the
lowest pixel row inside his box (the floor under him does not count)
upwards in steps of 8 pixels, the button presses that switch instead of
taking out the pogo stick. The pogo stick is put away, and holding the
button does nothing more until it is let go. Every press plays CLICKSND. A
lever flips: tile 493 becomes 480 and 480 becomes 493 (by tile number,
from Commander Genius). What else happens depends on the switch's info
value and behaviour:

| Info | Behaviour | Press |
|---|---|---|
| not 0 | any | A bridge (below) |
| 0 | 23 | The lights go off, or on again |
| 0 | 25, 26 | The Tantalus Ray fires: the Earth explodes (below) |

A stunned Keen cannot press a switch (the stun takes all buttons).

### Bridges

The info value of a bridge switch holds the offset from the switch to the
bridge's first cell, in tiles: the low byte is the column offset, the high
byte the row offset, both signed (0x0103 is 3 right and 1 down, 0xFF03 3
right and 1 up). A press lays the bridge (`Keen2Bridge`): one tile 270
every 4 ticks, the first 4 ticks after the press. It runs to the right,
unless the tile right of the start is solid on its left side; then it runs
to the left. It stops at the first tile that is solid on the side it comes
from (or the edge of the level), and lays over anything else. Tile 270 is
solid on top, so Keen stands on the bridge, also while it grows (it grows
faster than he walks). The bridge remembers the tile its first cell had;
pressing again takes it in, one tile every 4 ticks from the far end, and
puts that one tile back in every cell. A press while it moves turns it
round. A bridge that already lies in the level when the switch is first
pressed is taken in, and gets back the tile next to its start on the other
side (as in Commander Genius).

### Lights

A light switch (behaviour 23, info 0) turns the lights of the level off or
on (`Keen2LevelSession.is_dark()`, announced with `lights_changed`). Every
level, also a level started again, begins lit. In the dark grunts and
Elites do not jump (and Elites do not aim; B4). The picture of the level
(tiles in every graphics style, Keen, the enemies) is dimmed to 30 %
(`Keen2Darkness.DARK_BRIGHTNESS`, a `CanvasModulate`), in 4:3 and in
widescreen; the HUD and the windows stay bright. Commander Genius darkens
the palette; how the original looks is not known (B10).

## The Vorticon Elder

A tile with behaviour 22 speaks only when tile 429 (the Elder's light) is
right below it; the light then becomes tile 182 and that Elder never speaks
again. Commander Genius notes that the original has behaviour 22 elsewhere,
where nothing should happen. The session announces it
(`elder_message_touched`), and `Keen2View` shows the message in a window
like Keen 1's statues, with "Press ENTER:" below it unless the message says
ENTER itself; the game waits until Enter closes it. Only levels 8 and 10
have an Elder: tile 559 (behaviour 22) with the light, tile 429, below it
(checked in the level files; Commander Genius's game code agrees, its
patcher's 8 and 12 does not). Tiles 375 and 376 also have behaviour 22,
in many levels, but never with 429 below: those are the ones that must stay
silent. Level 8 has the first message ("never jumps in the dark"), level 10
the second (`Keen2LevelPlay.FIRST_ELDER_MESSAGE_LEVEL`; which is which is
an estimate). The light 429-432 is a glowing blue floor (animated, and
deadly by its behaviour); 182 is the same floor without the glow. A message
that is not found in `KEEN2.EXE` (file-formats.md) shows no window.

## The Tantalus Ray machine

Each city level has a machine. Its spark (info 7, `Keen2Spark`) flickers
through sprites 128-131, one every 6 ticks, and is harmless to touch. One
shot from Keen destroys it; the enemies' shots fly through it. The machine
then falls apart around the spark's cell (mx, my), one step every 26 ticks
(`Keen2Tantalus`):

| Step | Tiles |
|---|---|
| at once | (mx-2 … mx+2, my) become 492, 546, 547, 548, 492 (the glass); (mx-1 … mx+1, my-1) become 143 (the dome); the machine's switch at (mx-3, my+4) becomes 506 (broken: no switch any more) |
| 1-3 | (mx, my+3), (mx, my+4), (mx, my+5) become 505, each with a ZAP/ZOT splash and **10,000 points** |
| 4-7 | the column mx+3, then mx+4, mx+5, mx+6, rows my+3 … my+5, becomes 549, with splashes |
| 8 | (mx-7 … mx-5, my+2 … my+4) become 533 (the targeting display) |

The session counts the sparks of the level and the destroyed ones
(`machine_count`, `machines_destroyed`, `all_machines_destroyed()`), for
B6 to tell that a city was saved. How the original keeps Keen from leaving
before the machine is destroyed is not known (research.md, open question
14); nothing stops him yet.

## The wrong switch: the Earth explodes

A switch with behaviour 25 or 26 and info 0 is the switch of a machine.
While the machine is intact, pressing it fires the Tantalus Ray
(`Keen2LevelSession.fire_tantalus_ray`): the lights come on, the level
stops, Keen is gone, and `Keen2LevelPlay` ends the game
(`State.EARTH_EXPLODED`, `earth_exploded`), **whatever the lives**. After
the machine is destroyed its switch is tile 506 and the button takes out
the pogo stick again. `Keen2View` then:

1. shakes the screen for 2 seconds;
2. shows map 81 with the scene `Keen2EarthExplosion`: the beam (sprites 58
   and 59 in turn, a frame per tick) starts at tile (4, 9) and flies 252/32
   pixels right and 108/32 down per tick, the view following it, until it
   reaches column 47 (KEENFIRESND at its start). Then the explosion runs in
   steps of 6 ticks: in steps 0-15 an explosion (sprites 60-63, 6 ticks
   each) bursts at a random spot within 32 pixels of the middle of the
   Earth and leaves tile 155 (space) in its middle cell, except on the
   Earth itself; step 5 throws ten small chunks (68 or 70, with the next
   sprite as second frame) in eight directions (20/32 and 10/32 pixels per
   tick), steps 6-8 one more each in a random direction; step 10 sends four
   big chunks (64 or 66) off diagonally at 16/32 and turns the Earth's 3x3
   tiles at (47, 22) into tile 561 (black). After step 32 the scene ends. EARTHPOW
   plays when the beam hits (our choice; Commander Genius plays none);
3. shows GAME OVER (the `GAMEOVER` bitmap, or the text when there is none)
   with GAMEOVERSND, and after 4 seconds or a key the start screen (the
   high scores come in B6/B7).

Where we differ from Commander Genius: it shows a box "Uh-Oh" (its own
text) and sends all ten chunks of step 5 the same way; ours shows no box
and spreads them. Its explosions burst around the end of the beam, which
with its speeds ends about four tiles below the Earth's middle; ours burst
around the middle of the Earth, and the view moves there once the beam has
arrived. It also blanks 4x4 tiles from (47, 21); in `LEVEL81.CK2` the Earth
is the 3x3 tiles at (47, 22) (572-574, 585-587, 598-600), the rest is black
space anyway.

## The HUD (widescreen)

Lives, score, raygun charges and keycards; no ship parts. The raygun and
keycard icons are the first tile with that behaviour in the tile
properties (`Keen2Icons`): the pictures Keen picks up, as in Keen 1's HUD.
In version 1.31 these are 175 and 190-193, the same numbers as Keen 1.
On the map the HUD shows the same, never Keen 1's ship parts.

## The status screen (B6)

Enter opens it on the map and in a level (`Keen2StatusScreen`). The box is
28x12 cells inside its border, and its text comes from `KEEN2.EXE` (one
record per line, file-formats.md): `SCORE` / `EXTRA KEEN AT`, `KEENS` /
`PISTOL`, `TARGETS SAVED` / `KEYS`, `PLEASE PRESS A KEY`. Into it go:

| What | Where (inside the border) |
|---|---|
| The score / the next extra life | row 1, ending before column 12 / 28 |
| A little Keen (sprite 0) per life, at most 7 | from (1, 3), two columns each |
| The raygun (tile 414) and its charges | (19, 3); the charges end before column 27, row 4 |
| The saved cities | London (0, 7), Cairo (7, 7), Sydney (0, 8), Rome (7, 8), Paris (0, 9), New York (7, 9), Moscow (0, 10), Washington (7, 10) |
| The keycards Keen has (424-427) | (20, 7), (24, 7), (20, 9), (24, 9) |

The places come from Commander Genius's status screen (shifted by the
border); they are estimates. Without the lines from `KEEN2.EXE` the same
labels are written in their place.

## The ending (B6)

As soon as the map loads with all eight cities saved, the ending runs
(`Keen2Ending`); a button (jump, pogo, fire) or Enter closes a text or
turns a page:

1. **Map 81:** Keen's small ship (sprite 132) starts where tile 593 is (part
   of the mothership's picture, (6, 5)), waits 10 ticks, flies 672 ticks at
   32/32 right and 12.8/32 down, then 150 ticks at 8/32 down: it lands on
   the Earth. The first text ("After disabling the weaponry...") is shown at
   the bottom; the stage ends when the ship is there and the text is closed.
   The view follows the ship.
2. **Map 81 again:** the mothership (sprite 72) from tile (8, 26), the view's
   top left at (0, 300), waits 10 ticks and flies 80 ticks at 32/32 left
   and 12.8/32 up, with the second text ("The Vorticon ship limps back...").
3. **`FINALE.CK2`** with the four pages at home, one per press, at the
   bottom, then `TO BE CONTINUED....` as a fifth page (it follows the pages
   in `KEEN2.EXE`; Commander Genius does not show it).
4. **The end text** of `KEEN2.EXE` (it starts with "TO BE CONTINUED..."),
   scrolled with up and down as Keen 1's; a press ends it (Commander Genius
   shows no end text; our reading of the original).
5. The start screen (B7 adds the high scores).

The flights' numbers come from Commander Genius; with the real map 81 the
ship lands right on the Earth, which suggests they are right. Texts that
are not found are left out. Keen 2 has no light in the window of the
picture (Keen 1's `WINDON`/`WINDOFF` are not used).

## Title, menus, saving and high scores (B7)

`Keen2MenuScreen`, as Keen 1 has them:

- **The title** is the title screen of map 90 (space with the mothership and
  the Earth) with the `TITLE` bitmap: map 90 has Keen 1's layout, so Keen
  1's `Backdrops` cuts it out and draws it unchanged.
- **The high scores** are the frame of map 90 with `HIGHSCOR`, the `NAME`
  and `SCORE` headings and the `SAVED` bitmap ("Cities saved"), and per
  place a name, a score and the number of cities (`Keen2HighScores`, drawn
  by `Keen2Screens`). A new table has the names of `KEEN2.EXE` (Yorpy,
  Gargile, Zzapp!) and 100 points everywhere; a score that gets in asks for
  a name ("first" ... "last" from `KEEN2.EXE`), with HISCORESND. The places
  follow Keen 1's table, 4 pixels lower for the headings and the rows (as
  Commander Genius moves Keen 2's); the number of cities at x 260
  (estimates).
- **The main menu** is the shared one: New Game, Continue Game, Save Game
  (only on the world map), Story (from `KEEN2.EXE`), High Scores, Controls,
  Options, Quit to Title, Choose Game, Quit. No Online Game, no second
  player and no "Extra levels" option (Keen 1's) until co-op comes (B9).
- **Saving**: nine slots in `user://keen2/saves`, Keen 1's format
  (`SaveGames`) in Keen 2's own folder; a loaded game becomes a
  `Keen2Progress`. The high scores are in `user://keen2/high_scores.json`.
  The keys, the display settings and the sound setting are shared with
  Keen 1 (`user://settings.cfg`).
- The sounds come from `KEEN2.EXE` since B3; EARTHPOW plays when the Earth
  is hit (B5), HISCORESND for a new high score.

## Extras (B8)

- **xBRZ (F5), smooth motion (F6), widescreen with the HUD** work for Keen 2
  as for Keen 1: they are shared ([GameScreen], [ActorLayer]), and every
  Keen 2 actor, Keen on the map and the ending's ships are interpolated.
  The Real-ESRGAN HD graphics are left out for Keen 2 (the user's choice:
  they did not look good enough for Keen 1 either).
- **Pictures behind the levels** (widescreen, the "Backgrounds" option):
  Keen 2's own pictures in `assets/backgrounds/keen2/` (none yet), or the
  player's in `game_data/keen2/backgrounds/` (`level01.png` ... `level16.png`,
  also .webp or .jpg); Keen 1's pictures are never used. A picture shows
  through the level's plain background, and through that color in every
  other tile. Most Keen 2 levels have a patterned background (the gray
  diamonds) whose dots have the plain tiles' color, so a picture would
  shine through the dots all over the level: a level gets its picture only
  when its plain background is also its most used tile
  (`Keen2BackdropPictures`). In version 1.31 that is level 12. In the dark
  the picture darkens with the level.

## Two players on one keyboard (B9)

As in Keen 1 ([../two-players.md](../two-players.md)): F7, or "Add Player
2" / "Remove Player 2" in the menu during a game. Player 2's Keen (blue
helmet) appears in the level where player 1 is; on the map he plays along
from the next level. Each has his own keys in a level (player 1 WASD,
player 2 the arrows); on the world map and in the ending the keys of both
steer the one Keen. Shared inventory, one death ends the attempt for both,
one exit completes the level for both. The split screen is Keen 1's
(`TwoPlayerView`). What is Keen 2's own works for both Keens: either can be
stunned by a youth, ride a platform or a Scrub, press a switch (also the
Tantalus Ray's) or wake an Elder; the darkness covers both halves of the
screen. The Earth exploding and the ending end player 2's part.

## Playing online (B9)

As in Keen 1 ([../online.md](../online.md)): "Online Game" in the main
menu, hosting and joining by IP or through Steam, the joined player's Keen
next to the host's in a level, only the host walking on the world map,
nothing pausing while two play, an arrow to the other player. What Keen 2
adds:

- **Its own game id** (`commanderperfect-keen2`): a Keen 1 host and a Keen 2
  player do not meet; the player reads "The host plays another game:
  another Keen". Steam lists only lobbies of the same game. The fingerprint
  is made of Keen 2's own `LEVELxx.CK2`.
- **The saved cities** travel in every snapshot (8 bits in the inventory's
  flags, which are 0 in Keen 1), so the joined player's status screen
  shows them.
- **Events:** an Elder's message (as Keen 1's statues), "Keens Left", and
  the lights going off or on (also sent when the level starts dark).
- **The Earth exploding** is a scene of its own: the joined player sees the
  shaking, the beam and the explosion on his own screen, then GAME OVER.
- GAME OVER and the ending: as Keen 1; the joined player watches the ending
  at his own pace and then waits at his title. The high scores are the
  host's.

## Not yet

Comparing everything with the original (B10). Not built, as for Keen 1: the intro
(the Apogee and id screens), the demo, "About ID...", "Ordering Info",
"Previews!" and the help text.

## Estimates to check against the original (B10)

- Starting raygun charges: 0.
- World map and ending (B6):
  - A city is saved when its level is done (also without destroying the
    machine).
  - The places on the status screen; at most 7 little Keens.
  - The flights: 10 ticks of waiting; Keen's ship 672 ticks at (32, 12.8)/32
    and 150 at (0, 8)/32; the mothership from (8, 26), view (0, 300), 80
    ticks at (−32, −12.8)/32.
  - `TO BE CONTINUED....` as the last page and the end text after it.
  - "Keens Left" for 3 seconds (Keen 1's value).
- Title and high scores (B7): 8 seconds each; the table's places (headings
  at 50, rows from 68, the number of cities at 260); 100 points in a new
  table.
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
  - The youth's collision box: the left frames' box both ways.
- Switches and the Tantalus Ray (B5), from Commander Genius unless noted:
  - The tile numbers that are put in: 270 (bridge), 182 (Elder's light
    off), 492, 505, 506, 533, 546-549 (the machine's wreck) and 561 (the
    Earth gone). Their pictures fit; that the original uses exactly these
    is Commander Genius's word.
  - Switch search: 8-pixel steps from the lowest row inside Keen's box.
  - Bridge: a tile every 4 ticks, the first after 4 ticks.
  - Darkness: the picture at 30 % (`DARK_BRIGHTNESS`); how the original
    looks is unknown.
  - Elder messages: level 8 the first, level 10 the second.
  - Spark: 6 ticks a frame. Only Keen's shots destroy it.
  - Machine wreck: 26 ticks a step; 10,000 points three times (CG; maybe
    10,000 once in the original).
  - Shake: 2 seconds, 2 pixels.
  - Beam: from (4, 9), 252/32 right and 108/32 down per tick, to column 47.
  - Explosion: steps of 6 ticks, explosions in steps 0-15 within 32 pixels
    of the Earth's middle, 6 ticks a frame, an 8-pixel half size; chunks in
    steps 5 (ten), 6-8 (one each) and 10 (four big); chunk frames (the
    sprite and the next) 6 ticks each; the end after step 32.
  - EARTHPOW when the beam hits (our choice).

## Testing without Keen 2's files

- `tests/test_keen2_level.gd`: hand-made levels (`tests/keen2_fixtures.gd`).
- `tests/test_keen2_enemies.gd` and `tests/test_keen2_riding.gd`: the
  enemies, the stun, the shots and riding, in hand-made levels.
- `tests/test_keen2_switches.gd` and `tests/test_keen2_tantalus.gd`: the
  switches, bridges, lights, the Elder, the machine and the Earth exploding
  (on a small hand-made map 81), in hand-made levels.
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
- Keen 1's levels have no Keen 2 switches. For the B5 screenshots a
  throwaway driver script (in the scratchpad, not in the repository) put
  Keen 1's tile 271 (behaviour 23) next to Keen with a bridge offset in the
  info layer, pressed the pogo action, then set the offset to 0 (a light
  switch) and pressed again, and finally called
  `fire_tantalus_ray()`. With the stand-in data the bridge is Keen 1's tile
  270 (a gray girder), and the beam, explosions and chunks show Keen 1's
  pictures for those sprite numbers.

## Testing with Keen 2's files (B5.1)

With the player's own files in `game_data/keen2`, `tests/test_keen2_data.gd`
also checks the city names, the Elder messages, the sprite names of the
enemies, the collision boxes against the sprite table, the levers' and
icons' tiles, that only levels 8 and 10 have an Elder, that every city has
one machine with its lever at (mx-3, my+4), and the Earth and the ship's
tile on map 81. Played by hand (with a throwaway driver script that puts
Keen next to things): level 1, 4 (London: the spark shot, the machine
falling apart, 30,000 points, the dead lever, the wrong lever and the
Earth exploding, the lights), 5 (the bridge over the fire), 8 (the Elder's
message) and 12 (platforms).

On macOS a new window can stay white for a varying number of frames, so
`tools/scripted_play.gd` has `WAIT_FOR_WINDOW=1`: it loads the scene and
counts frames only once the window shows a picture.
