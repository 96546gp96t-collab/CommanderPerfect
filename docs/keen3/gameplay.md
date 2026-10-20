# Keen 3: the rules of a level in our engine

What playing Keen 3 does in CommanderPerfect so far, and which numbers are
estimates. Written in milestone C3; C4 added the enemies, C5 the ball, the
jack, the platforms and the wall guns, C6 the world map, Messie, the
teleporters and the status screen, C7 Mortimer, the machine and the
ending, C8 the sounds, the title, the menus, saving and the high scores,
C9 the extras, C10 two players (on one keyboard and online); later
milestones add to it. The facts
and their sources are in [research.md](research.md), the code layout in
[architecture.md](architecture.md). Numbers from Chocolate Keen are marked
(Choco) and converted with the table at the top of research.md ("Units").

## The course of the game (C6)

Since C6 the course is the one Keen 2 has since B6: the world map and the
levels (`Keen3LevelPlay`). Since C8 it begins at the title, as Keen 2's
after B7.

| What | Then |
|---|---|
| Keen 3 picked on the start screen | The title with the main menu open (C8) |
| `-- --game=3` | The title (C8) |
| Title / high scores | They take turns every 16.5 s; a key opens the main menu |
| "New Game" / "Continue Game" | A new or saved game on the world map, with "Keens Left" |
| `-- --game=3 --level=80` | A new game on the world map |
| `-- --game=3 --level=N` | Level N (1-16), then the map; another number: the title, with a message |
| `-- --game=3 --ending` | The ending at once (C7), for testing; `--ending` without `--game=3` stays Keen 1's |
| The jump or pogo button on an entrance | That level, unless it is done |
| Keen walks out through an exit | The level is done (its sign on the map), the keycards are taken away, and Keen is back on the map where he entered it, with the same view |
| Level 16 done (anything but a death ends it; the machine ends it 181 ticks after the heart is shot) | The ending (C7), then GAME OVER and the high scores (C8) |
| Keen dies | One life less, back on the map where he entered the level, with "Keens Left" |
| Keen dies without lives left | GAME OVER (the bitmap, bare over the level) for 5.27 s or until a key, then the high scores (C8) |
| The status key (Enter) | The status screen, on the map and in a level |
| Escape | The main menu (C8); while Mortimer speaks it skips him |

Every level starts fresh from its file (its items are back, Keen has no
ankh); the map too, with the done signs put back. Messie and the view are
kept between levels (`Keen3Progress`). Level 16 has no exit: it ends when
the heart of Mortimer's machine is destroyed (C7).

"Keens Left" is a window of 16x4 cells with a little Keen (sprite 35,
MAPKEEND1) per life, at most 6 (Choco); the game waits while it is open;
it closes by itself after 0.87 s (seen in js-dos in C1) or with a button.
Cheats for testing, as in Keen 1 and 2: Shift+N / Shift+P (next / previous
level, wrapping around; from the map level 1 / level 16), Shift+I (all
keycards, 99 charges), Shift+G (god mode, in a level).

Code: `Keen3View` (the scene) on `Keen3EndingScreen` (Mortimer, the
border flash, the ending; C7) on `Keen3SceneScreen` (setup, loading, the
windows, leaving) on `GameScreen`; `Keen3LevelPlay` (the course),
`Keen3Progress` (the game), `Keen3MapSession` (the map),
`Keen3LevelSession` (one attempt at a level), `Keen3Body` (Keen and the
ankh).

## Mortimer (C7)

Every time level 16 starts (`Keen3Mortimer`, Choco
`CVort3_handle_grand_intellect`): the level is drawn with its sprites, then
MORTIMER plays to its end (its length from the sound block, also with the
sound off) and his nine boxes from KEEN3.EXE are typed one after another
(`Keen3TypedBoxes`), a letter every 6 retraces (70.086 a second). Every
stored character takes a letter's time, spaces too, and so does every line
end (seen in the original's ending in C11 and applied to Mortimer too; his
own boxes were not timed, so whether his last line end counts is an
estimate). Keen cannot move meanwhile. Escape, Space
(fire) or a button (jump, pogo, fire) skips everything that is left;
during Mortimer, Escape does not leave the game.

| # | Inside w x h | Middle row | Frame's top left (cells) | Pause after (retraces) |
|---|---|---|---|---|
| 1 | 5 x 1 | 20 | (17, 20) | 180 |
| 2 | 12 x 1 | 20 | (13, 20) | 180 |
| 3 | 18 x 1 | 20 | (10, 20) | 240 |
| 4 | 38 x 5 | 20 | (0, 18) | 240 |
| 5 | 38 x 5 | 20 | (0, 18) | 240 |
| 6 | 31 x 2 | 20 | (4, 19) | 180 |
| 7 | 35 x 4 | 18 | (2, 16) | 180 |
| 8 | 34 x 1 | 20 | (2, 20) | 180 |
| 9 | 38 x 3 | 18 | (0, 17) | 240 |

The frame's top left is (19 − w/2, row − h/2) in 8-pixel text cells of
the 320x200 picture (Choco); in widescreen the picture is the middle 320
pixels (`Keen3Window.open_at`). Only one box shows at a time (estimate:
whether the original leaves the edges of a larger earlier box standing is
not known). A box is never narrower than its longest line.

## The Mangling Machine (C7)

`Keen3Machine` (src/keen3/level/), made by `Keen3LevelSession` when the
info layer has values 12, 13, 16, 17 or 18, stepped after every tick.
Every tile change goes through `LevelSession.set_tile`, so the drawing, also
in xBRZ and HD, follows. Numbers from Choco (clock ticks × 0.412):

- **Sparks** (12, `Keen3Spark`): sprites 114-117, a frame every 3.3 ticks,
  box (2,2)-(13,13). Keen's shot splashes on a spark and destroys it:
  +1000 and the border flash. Touching it does nothing.
- **Heart** (13, `Keen3Heart`): 146/147 in turn every 9.9 ticks. Tile 611
  at (7,8) and (17,8) (solid) stops the shots along its row until the
  sixth spark's sweep. A shot: +1000, the border flash, both legs stop,
  every sprite but Keen (and his ankh halo) is removed (Meeps, waves,
  shots, sparks, the wall guns), a sweep clears columns 8-16, rows 3-18, a
  row every 8.2 ticks, and 181 ticks after the shot the level is done.
- **Arms** (16, `Keen3MachineArm`): the shaft (597) ends in the arm's cell
  with a claw on each side (618, 620, 619 from the top). Start going down,
  a tile every 6.2 ticks; up a tile every 16.5. Going down they turn up
  when the tile 3 below is 471; going up they turn down when the tile
  above is no shaft. A turn takes a step without moving (seen in js-dos,
  below). A move
  clears the cell and the cells beside and below it and draws the shaft
  and the claws again. Level 16: the left arm moves between rows 10 and 16
  (starting at 10), the right one between 10 and 16 (starting at 16, so it
  turns up first).
- **Legs** (17 left, 18 right, `Keen3MachineLeg`): the shaft ends in the
  foot, 621, 623, 623, 622 from left to right; the left foot reaches 3
  tiles left of the leg's cell, the right one 3 tiles right (as level 16
  draws both feet). A step every 14.4 ticks; the left leg starts up, the
  right one down. Going up they turn down when the tile above is no shaft
  (rows 15-18 in level 16); going down onto 430: FOOTSLAM, 82 ticks, a
  step for the turn, then up (seen in js-dos, below).
- **The sixth spark**: both arms stop where they are, and a sweep clears
  columns 5-7 and 17-19, rows 7-18, a row every 12.4 ticks: every tile that
  is not 169 becomes 169, with a splash (105) on it and one SHOTHIT per
  row. That takes 611 away.
- The arms, legs, claws and the body's frame kill by their tiles
  (behaviour 1); the two Meeps and the two wall guns are C4's and C5's.
- **No screen shake** (Choco: the original does not shake; Commander Genius
  does).

Seen in js-dos in C7 (level 16 copied over level 1 in a scratch copy of
the player's files, so the map's first entrance opens it; Mortimer does not
speak there, he belongs to level number 16): both arms move between the
same 7 rows, a step down every ~108 ms (ours 103), up every ~271 ms (ours
275), and rest ~371 ms at each end (ours 378: the turn's step plus the
next); the feet step every ~245 ms (ours 240), rest ~490 ms under the body
(ours 480) and ~1.9 s on the floor (ours 1.85 s: the step that finds the
floor, the 82 ticks, the turning step). Not seen: Mortimer, the sparks and
the heart being shot, the sweeps, the border flash (Keen could not be
steered to a spark by script in the time given).

## The border flash (C7)

The original makes the EGA border blink yellow and cyan (colours 14 and 3,
every 26 ticks for 124 ticks) when a spark or the heart is shot. By the
user's decision (C1) it is a thin frame around the game picture
(`Keen3BorderFlash`, 2 game pixels thick, our choice): in the black bars
around the 4:3 picture when the window has room for it, otherwise over the
outermost pixels of the picture itself (a window of exactly that shape,
and mostly widescreen, where the picture fills the window). Same colours
and timing as the original.

## The ending (C7)

`Keen3Ending` (the logic, in retraces) and `Keen3EndingScreen` (the
drawing), Choco `CVort3_draw_win` and `CVort3_blink_camera_flash`:

1. Map 81 with the view's top left at tile (2,2), a Vorticon (sprite 67) at
   tile (14,6) and Keen (sprite 0) at (15.5,6.5); it fades in (4 steps, 8
   retraces apart; seen in the original, C11: steps ~114 ms apart).
2. The four pages from KEEN3.EXE, typed one after another at 6 retraces a
   letter, 120 retraces after each. Every stored character counts, also
   the trailing spaces KEEN3.EXE keeps after some lines, and every line
   end: page 1 takes 154 letter times, 13.2 s (seen in the original, C11:
   13.1 s; ~1.9 s from a page's last letter to the next one's first).
   Choco gives their frames as (4,18)-(43,23), (4,18)-(43,22) twice and
   (17,18)-(30,20) in the cells of its screen buffer, which starts 4 cells
   left of the picture, on the same rows: on the picture they are (0,18)
   with 38 x 4 inside, (0,18) 38 x 3 twice and (13,18) 12 x 1, every box
   centred (seen in the original, C11, pixel for pixel; C7 had them 4 rows
   higher).
3. Five camera flashes: (19,5) → 58, (3,8) → 60, (5,8) → 60, (20,5) → 58,
   (8,8) → 60; each with CLICKSND and the whole picture lighter for 2
   retraces (`Keen3ScreenTint`, our reading of the camera-flash palette:
   all colours bright), then the tile back to 72 or 61 and a wait of 20,
   10, 5, 10, 15 retraces; then 120 and a fade out.
4. FINALE.CK3 fades in; after 400 retraces (seen: 5.71 s) the box from
   KEEN3.EXE is typed in the frame (18,20)-(29,24), on the picture (14,20)
   with 10 x 3 inside (x 112-207, y 160-199, seen in the original, C11);
   once it is typed (and a letter's time more) a ball spins in the middle
   of its last row, font characters 9-12, the next every 5 retraces (seen
   in the original, C11); a key goes on.
5. The end text (KEEN3.EXE) in the original's reader (`Keen3EndText`,
   seen in the original, C11, pixel for pixel): a window filling the
   picture, 38 columns; lines that start with `~` are red letters on a gray
   bar as wide as the window, their text where it is typed (not centred);
   two spaces after a full stop stay when a paragraph is wrapped again; 21
   lines of text, then the window's bottom edge across it, the footer from
   KEEN3.EXE ("ESC to Exit / ↑ ↓ to Read", red on gray) and the top edge's
   pieces as the screen's bottom row. Scrolled with up and down; at its
   start keensleft plays to its end and then MORTIMER (C8); a key ends it
   (Escape opens our main menu, C8).
6. GAME OVER (the bitmap) on a black screen, 5.27 s or a key, then the
   high scores (C8). The original (seen in C11) shows the hall again with
   a window: the GAMEOVER bitmap at its top, "Score: n", "Congratulations!
   You got first place!" and "Enter your name:" with the spinning ball as
   the cursor; then the table for 16.7 s and the title. Not built yet: it
   needs a name entry inside that window instead of the shared name box.

Map 81 is 24x17; its playable part (20x13 tiles) is as wide as the 4:3
view, so in widescreen black bars show beside it, never its border (the
camera keeps to the playable area). The map layer is hidden while the
picture or the end text shows. Escape opens the main menu at any time
(C8; it left for the start screen in C7).

## The world map (C6)

Map 80, 70x73 cells. All numbers from Chocolate Keen (`game/worldmap.c`,
`episodes/episode3.c`) unless noted; the original moves things per drawn
frame, 24.275 frames a second (`Keen3MapInfo`), which we turn into our 60
ticks a second.

- **Keen** (`Keen3MapKeen extends MapKeen`): sprites 31-34 right, 35-38
  down, 39-42 left, 43-46 up (one lower than Keen 1's and 2's); up and down
  win over left and right; 4 px per frame on each pressed axis, 97 px/s
  (seen in js-dos: 4 px per frame). Keen 1's 127.5 px/s is too fast, so
  Keen 3 has its own speed. A walking frame lasts 6.6 ticks; a step sounds
  every second frame (WLDBLOCKSND when he is held up on either axis). He
  starts on the cell with info 255, (44,47), at its top left.
- **The button** (jump or pogo, pressed anew) uses the info cells under
  Keen's box: column by column, row by row, the last non-zero one counts
  (255 counts as nothing). 1-16 and 0x8000 + n enter level n unless it is
  done (WLDENTERSND); 20 is the ship; 0x0Fsd a teleporter; Messie's cells
  do nothing. The original also acts while the button is held; here it
  must be pressed again, as in Keen 1 (otherwise a held jump button would
  enter the level again right after a death).
- **Blocking:** a cell with 0x8000 + n is a wall until level n is done
  (Keen 1's `MapCollision`, unchanged).
- **Done signs:** the entrance of a level is its first cell (row by row);
  it is 2x2 when the cell right of it belongs to the same level. A done
  level gets 56 on a 1x1 entrance, 52 53 / 54 55 on a 2x2 one, and its info
  cells are cleared. Entrances 2, 4, 5, 10, 12, 13, 14 and 15 are 2x2
  (level 15 has three 0x800F cells and one 0x000F).
- **The ship** (info 20 at (42,48) and (43,48)): one of the four messages
  at random (seen in js-dos: four different ones in five tries) in a
  window of 32x6 cells, the prompt line from KEEN3.EXE in its last
  row (place seen in js-dos: x 24-295, y 64-127); any key closes it.
- **Teleporters** (`Keen3MapTeleport`; 16 slots, research.md §8): the
  source cycles tiles 130-133 twice (TELEPORTSND at each cycle), 134 again;
  the view jumps so that the destination is 10 cells from the left and 6
  from the top; the same at the destination; Keen stands on its top left.
  Seen in js-dos (slot 1 at (46,41) to slot 3 at (55,41) and back): each
  tile 5 retraces (71 ms), 1.14 s in all; Keen is not drawn meanwhile; the
  view shows (45,35) top left. Messie waits meanwhile.
- **The view** (`Keen3MapScroll`, the camera exactly on it): Keen may move
  while his sprite is 9-11 cells from the left of the view and 3-7 from the
  top; beyond, the view moves as far as he does (seen in js-dos: he stays
  at x 176). A new game shows (35,44) top left (Keen 9 cells right and 3
  down of it; seen in js-dos). In widescreen the free stretch stays 2 cells
  wide in the middle. The view never shows the border. After a level the
  view is where it was (seen in js-dos after a death).
- **Messie** (`Keen3Messie`, drawn as an actor): starts at the first row
  whose middle column (35) holds her path, (35,8), heading left; 2 px per
  frame on each axis of her direction, a cell in 8 frames; at each cell the
  first neighbour (column x − 1, x, x + 1, each top to bottom) that is path
  or weed and neither her cell nor the one she came from; before weed she
  waits 122 frames (5.0 s), facing it. Her loop has 256 cells and takes
  104.5 s with the four weeds. Pictures: 130/131 left, down-left and
  standing, 132/133 right, down, down-right, 134/135 up-right, 136/137
  up-left and up; 8 more with Keen; the second picture every other two
  frames. Seen in js-dos: in a new game she first shows in the start view
  35.8 s after "Keens Left" closes, and later at the same times as ours
  (to 0.1 s), so her start, speed, way and weed wait match.
- **Riding:** Keen gets on when the top left of his sprite lies inside her
  32x24 picture (edges included): CRYSTALSND, he is hidden, cannot walk or
  use anything, and the view follows her by the same rule. A pressed
  direction (8 ways) toward a landing (0x2200) next to her cell (the cell
  of her top left) puts him there, one cell from her top left; then she
  cannot be mounted for 30 frames (74 ticks). Her landings are by level
  16's island ((33-34,15), (33,16)) and the Hidden City, level 13
  ((26-28,56)); she is the only way to both.

## The status screen (C6)

`Keen3StatusScreen` in a `Keen3Window` (the Window node of
`keen3_view.tscn`; a `GameWindow` that can also put tiles 4 px below a row
and write in the font's second half). The status key (Enter; the original
uses Space, which is fire here) opens it on the map and in a level; the game
stands still and any key closes it. The box is 28x11 cells, x 40-279,
y 48-151, as in the original. Labels from KEEN3.EXE in red on gray bars
(font characters 0x80-0xFF, as the original draws them), the one-space
lines as gray dividers (row 1 column 12, rows 3-5 column 19, rows 7-9
column 11). Score ends before column 10, the next extra Keen before 26
(row 1); a little Keen (sprite 0) per life from column 1, two apart, at
most 9 (row 3); pistol tile 216 at column 21 and the ankh tile 214 at
column 3, 4 px below rows 3 and 7; charges at (24,4); the ankh time at
(7,8) (0 on the map); keycards 217-220 at columns 13, 17, 21, 25, 4 px
below row 7. Every icon and little Keen was found pixel for pixel in a
status screen of the original (js-dos, C6).

## The HUD on the map

In widescreen the map shows the same two panels as a level (lives and
score; raygun and keycards); the ankh panel only in a level.

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
- **A shot at a wall close by** (fix after C11): the shot starts just in
  front of Keen, so with his front less than 16 px from a wall it would
  start inside the wall, and the sideways sweep only looks at the tiles
  ahead of the shot: it splashed inside a thick wall and flew on behind a
  thin one (a single rock). In the original a shot that starts against a
  wall splashes at once (Choco). `Keen3Shot.fired_by_keen` sweeps the
  shot's box from Keen's middle to its start; a wall on the way puts the
  shot against the wall's near side, where it splashes at once (KEENFIRE,
  then SHOTHIT), standing, jumping or on the pogo stick, both ways
  (`tests/test_keen3_shot_wall.gd`). The enemies' shots needed nothing:
  the mother's fireball starts within her box (only 2 px stick out at her
  left) and already splashes when it starts in a wall; a wall gun's shot
  starts in the gun's own cell, which it is meant to leave; the Meep's
  wave flies through walls on purpose. Keen 1 and 2 have the same bug
  (shared `RaygunShot`, `KeenBody.shot_position`); not changed here.
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
| His feet below its top while he rises, but no further than it rose this tick | put on top as well: it rose into him just after he jumped (he only starts to move the tick after the jump) or a ball rises faster than him; he keeps his place sideways (fix after C11) |
| His head at most 12 px above its bottom, while he rises or it comes down | pushed down (through the tiles); his jump ends: he rises no faster than it (*estimate* of the 12 px) |
| Otherwise | pushed out sideways, to the nearer side (through the tiles) |

**Jumping off** (jump or pogo, fix after C11): Keen leaves from the spot
where he stands, as in Keen 1 and 2. While he stands (also crouching or on
the compressed pogo) the carrier carries him; once he is in the air it
never moves him sideways, also not when it rises after him or he lands back
on it. Before the fix a lift going up (or a ball) overlapped his feet in
the tick he jumped, and as he was rising that counted as "otherwise": he
was thrown to the nearer end of it (`tests/test_keen3_lift_jump.gd`). Only
a Keen who really walks or flies into a carrier's side is pushed out.

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
| Protection per ankh | 577 ticks (1400 clock ticks, 9.6 s); another ankh adds its time | Choco; seen in the original (C11): ~9.8 s at 0.13 s steps, the status screen showed 8 after 1.5 s |
| Sound | ANKH (sound entry 41), played by `Keen3Sounds` on its own speaker | Choco |
| At the start of every level | 0 (every attempt makes a new `Keen3Body`) | Choco |
| Counts down | only while the game runs (one per tick in `Keen3Body.step`; not behind "Keens Left") | Choco |
| Protects against | everything that kills through `KeenBody.kill` (deadly tiles, enemies, fireballs, waves) and the stun (`Keen3Body.is_protected`); not against a push | Choco |
| Does not protect against | falling out of the level | Choco |
| Halo | sprites 61 (GODHALO) and 62 (BYEHALO) in turn every 6.6 ticks, at Keen −8, −8 px (`Keen3AnkhShield`, drawn by the ActorLayer behind Keen; its middle is transparent) | Choco |
| Blink | in the last 103 ticks; every other picture is left out: on and off ~0.11 s | Choco (when); seen in the original (C11): on and off every ~0.12 s in the last ~1.6 s |
| Shown time | whole "seconds" of 144 clock ticks (59.3 of ours): a fresh ankh shows 9, as the status screen | Choco |

The ankh time is Keen's own (`Keen3Body.ankh_ticks`), not part of the
inventory: it never leaves a level. The status screen reads it from
there (0 on the map).

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
Nothing had to change for Keen 3. The map (C6) keeps the border out of
view with its own scrolling (`Keen3MapScroll` clamps to the playable
area). Map 81 in the ending (C7): the camera keeps to its playable area,
black bars in widescreen. Map 90 (C8): the title and high score screens
are cut out of it with their own border (`Backdrops.screen`), so only
their 20x13 cells show, with black bars in widescreen;
`test_keen3_menus_data` checks that no border tile lies on them. Still to
check: two players (C10).

## Masked tiles

Ten tiles have behaviour -2 (108, 329, 398, 411, 479, 492, 505, 524, 526,
565): the fence of level 14, tables, trees and clouds, in levels 1-5, 7,
9, 10, 12, 14, 15 and on map 90. Each is followed by its mask, a
black-and-white tile. Keen and the enemies walk behind them: the tile is
drawn behind the sprites, and in front of them only where the mask is
black (the fence's wires, a table's top and legs), so Keen shows through
the rest. Fixed after C7 in the shared `LevelMap` (architecture.md,
"Masked tiles (fix after C7)"); checked in the app with Keen behind the
fence of level 14 and at a table in level 1, original and xBRZ. None of
them is animated.

## Sounds (C8)

All 45 named sounds of `KEEN3.EXE` are read; besides Keen 1's 41 names the
block has ANKH, MEEP, MORTIMER and FOOTSLAM, which `Keen3Sounds` plays on
a speaker of its own (`Keen2Sounds.find_entry`). Every sound plays at
145.65 Hz since C8 (the shared `SoundFile.STEPS_PER_SECOND`, 1193182 /
8192; for all three games). The original has one speaker: a sound only
cuts off the one that plays when its priority is at least as high. The
shared player keeps that rule among its own sounds; `Keen3Sounds` keeps it
among Keen 3's four and gives way to a shared sound of at least its
priority, and the shared player stops when one of Keen 3's four starts.

Where Keen 3 plays which sound (Choco, `episodes/episode3.c`,
`game/enemies.c`, `game/physics.c`, `game/worldmap.c`; research.md §2):

| Sound | When |
|---|---|
| WLDWALKSND, WLDBLOCKSND | Keen walks on the map, or into something there |
| WLDENTERSND | Keen enters a level |
| KEENWALKSND, KEENWLK2SND, KEENBLOKSND | Walking, and walking into a wall |
| KEENBLOKSND | Also pushing against a wall in the air: every 32 clock ticks (C8) |
| KEENJUMPSND | A jump, and **every pogo bounce** (C8; Keen 3 never plays KEENPOGOSND) |
| KEENLANDSND, BUMPHEADSND | Landing, hitting the ceiling |
| PLUMMETSND | Walking off a ledge (C8), and falling out of the level |
| KEENDIESND | Keen dies |
| KEENFIRESND, GUNCLICK | Firing, without charges |
| SHOTHIT | A shot splashes (also a fireball spat into a wall, after the spit), the machine's sweeps |
| GOTBONUSSND, GOTITEMSND, GETCARDSND, EXTRAMANSND | Points, the raygun and a single charge, a keycard, an extra life |
| ANKH | An ankh |
| DOOROPENSND, LVLDONESND | A door opens, Keen walks out through the exit |
| TANKFIRE | The mother spits; the wall guns fire |
| VORTSCREAM | A grunt, youth, mother, Meep or ninja dies |
| YORPSCREAM | A Foob is scared, or dies |
| MEEP | A Meep sings |
| TELEPORTSND, CRYSTALSND | A teleporter on the map; Keen gets on Messie |
| MORTIMER | Level 16 starts; the end text (after keensleft has played to its end, C8) |
| FOOTSLAM | A foot of the machine on the floor |
| CLICKSND | Each camera flash in the ending |
| KEENSLEFT, GAMEOVERSND | "Keens Left"; GAME OVER |

Not used by Keen 3 (the original does not play them either): KEENPOGOSND,
POGOJUMPSND, GOTPARTSND, CHUNKSMASH, GOINDOORSND, USEKEYSND, CANNONFIRE,
SLAMSND, YORPBUMPSND, YORPBOPSND, GARGSCREAM, KEENCICLE and HISCORESND
(the original's name entry is silent; Keen 2's plays it).

## Title, menus, saving and high scores (C8)

`Keen3MenuScreen`, as Keen 2's after B7 and B10:

- **The title** is the first screen of map 90 (cells 2-21; map row 2 at
  the top) with `TITLE` at (32, 1) and `F1HELP` at **(120, 182)** (Keen 1
  and 2: 96), as seen in js-dos in C1.
- **The high scores** are on cells 84-103 of map 90: `HIGHSCOR` at
  (88, 7), `NAME` at (80, 44), `SCORE` at (192, 44), seven rows from y 64,
  16 apart, names from x 80 and scores ending at x 240, in the font's
  second half (red letters on gray, as the original draws them, Choco
  `CVort_draw_string_80`); **no third column** (seen in js-dos in C1 and
  Choco `CVort3_draw_scores`). A new table has the three names of
  `KEEN3.EXE` in turn in all seven places (Yorpy, Gargile, Zzapp!, Yorpy,
  ...) and 100 points everywhere (seen in the original, C11; title and
  table match it pixel for pixel); a score that gets
  in asks for a name in the shared name box ("first" ... "last" from
  `KEEN3.EXE`), without HISCORESND. The table is Keen 2's
  (`Keen2HighScores`, the cities left at 0) in
  `user://keen3/high_scores.json`.
- **The attract loop:** the title and the high scores take turns, 2400
  clock ticks each, 16.5 s (Choco; seen in the original, C11: title 16.5
  s, high scores 16.4 s; C1's 21.3 s was wrong). The
  original also shows the id Software page and the ordering page with the
  Foob; those are not built (as for Keen 1 and 2).
- **The main menu** is the shared one: New Game, Continue Game, Save Game
  (only on the world map, not while a teleporter runs), Story (from
  `KEEN3.EXE`), High Scores, Controls, Options, Quit to Title, Choose Game
  (back to the start screen), Quit; since C10 also "Add Player 2" /
  "Remove Player 2" during a game and Online Game (see "Two players
  (C10)"). Never Keen 1's "Extra levels" option. The game stands still
  while a menu is open (not while two play online); in the ending its box
  comes back after the menu.
- **GAME OVER** (after the last life, and after the ending) stays 5.27 s
  or until a key, then the high scores (and the name), then the attract
  loop. In the original the game over box itself asks for the name (Choco
  `CVort_game_over`), and "Quit to Title" also passes through GAME OVER
  and the high scores; we keep Keen 2's way (the name over the table,
  Quit to Title straight to the title).
- **Saving:** nine slots in `user://keen3/saves`, the shared format of
  `SaveGames`: the inventory, the done levels, Keen's place on the map and
  the view's corner (the original saves its screenX/Y too). Messie is not
  saved: the original puts her at her start whenever the map starts from
  the menu, also for a loaded game (Choco `CVort_draw_worldmap`). Saved on
  Messie's back, Keen's place is where he got on and the view is left out,
  so the loaded game shows Keen as a new game does. The keys, the display
  settings and the sound setting are shared with Keen 1 and 2.

## Extras (C9)

- **xBRZ (F5), smooth motion (F6), widescreen with the HUD** work for Keen
  3 through the shared code, as for Keen 1 and 2; both extras stay off by
  default. Checked in C9 (code and screenshots with both on, widescreen
  and 4:3): every sprite of Keen 3 is an `Actor` drawn by the shared
  `ActorLayer` (the enemies, shots, splashes, waves, the ball, the jack,
  the platforms with Keen riding them, the ankh's halo, Messie, the
  sparks and the heart, the Vorticon and Keen of the ending) or Keen
  himself, so all move smoothly between ticks; the map's view blends
  between its last two corners (`Keen3MapScroll.center`) with the same
  fraction as Keen's sprite, and a teleporter's or a new map's view jumps
  without blending; the teleporters, the Mangling Machine, the done signs
  and the camera flashes of the ending change tiles of the shared
  `LevelMap`, which takes them from the xBRZ atlas; the HUD's item
  pictures (`Keen3Hud`), the status screen and Mortimer's boxes
  (`Keen3Window`), the title, the high scores and GAME OVER
  (`PictureLayer`, `GameWindow`) and the picture of `FINALE.CK3` take
  their textures from the shared `GraphicsTextures` and are drawn again
  when F5 switches. The border flash and the ending's fades and flashes
  are plain colours. Keen 3 has no screen shake (Choco; see the machine).
  Nothing had to change. Real-ESRGAN (HD) is left out for Keen 3, as for
  Keen 2 (the user's decision of 17-10-2026).
- **Pictures behind the levels** (widescreen, the "Backgrounds" option,
  on by default; never in 4:3): Keen 3's own pictures in
  `assets/backgrounds/keen3/` (fourteen pictures painted by
  `tools/make_keen3_backgrounds.py`, one per level with sky; nothing in
  them comes from the game files), or the player's in
  `game_data/keen3/backgrounds/` (next to the game files; in the builds
  `build/game_data/keen3/backgrounds/`), which win. Keen 1's and Keen 2's
  pictures are never used. **Rule (`Keen3BackdropPictures`): a level
  gets its picture when it has sky (tile 143, light cyan), and the
  picture only ever takes the place of the sky** and of the sky's colour
  around everything drawn on it (`docs/graphics.md`;
  `Keen3BackdropPictures.backdrop_color`, which `Keen3SceneScreen` uses
  for the tiles instead of the shared screen's plain background). The
  other plain background of Keen 3 is the dark gray inside the bases and
  caves (tile 195); its colour is also in the cave rock and the patterned
  walls, so a picture would shine through the rock as well (11-61% of all
  it would show, levels 9, 10, 12, 16): it never lets a picture through.
  The sky's colour only sits around clouds, trees, signs, grass and the
  items in the sky (1-13% of all the picture shows; 11% in levels 9 and
  10), and an item picked up in the sky leaves tile 143 (the first of its
  row), so the picture shows there too. Keen 2's rule (the plain
  background must be the most used tile) would give levels 9 and 10 their
  picture behind the walls of their base and none to levels 8, 11, 13 and
  15, whose sky lies beside a building or above a cave.
  - **Levels with a picture in version 1.00:** 1-11, 13, 14 and 15. In
    levels 9 and 10 the base's dark gray is used more than the sky (882
    and 538 cells against 713 and 422), so until the fix after C11 they
    had none (C9's rule was "the plain background is the sky"); now their
    picture shows through the sky above the base (level 9: the top 17 rows
    with the tree, the sign and the waterfall; level 10: the field with the
    sign and Keen's tree) and never in the base. Not: 12 and 16 (no sky
    at all). The world map, the ending's map 81 and the title's map 90
    never have one.
  - **The pictures** (fix after C11): what stands on the land stands on
    it. Levels 4 and 5: the far city stands on a plain that runs on to
    the hills in front (a light band under the buildings made it float);
    level 2: the far city goes on down behind the near one; levels 1, 6
    and 7: the domes, the houses and the fortress reach down to the
    lowest ground under them (`Canvas.footing`). Level 14 is new: a
    winter night with an aurora over a frozen sea, icebergs, a ringed
    planet and a watchtower with a searchlight, for the prison camp by
    the water. New for levels 9 (a misty green morning in a valley of
    flat-topped cliffs with waterfalls into a lake) and 10 (a hot
    afternoon on an olive plain with a rocket on its launch tower and
    radar dishes, for the base under the field). The others (3, 8, 11,
    13, 15) only have land below a skyline and did not change.
  - **Adding a picture:** a file `levelNN.png` (or `.webp`, `.jpg`), NN
    the level number with two digits (`level01.png` ... `level15.png`), in
    `game_data/keen3/backgrounds/` to try it without building, or in
    `assets/backgrounds/keen3/` to ship it with the game (only our own
    pictures, never anything made from the game files). Any size: the
    picture is scaled to cover the view (in its own shape, 15% larger) with
    its top at the top of the view, and glides from side to side through
    the level, so a wide picture suits a wide level: about 3840x1080 for
    levels 4, 5 and 14 (150-196 cells wide), 1920x1080 for the narrow ones
    (6, 11). It does not move up and down: in the tall levels (13, 15) its
    upper part shows where the sky is. A picture for a level without sky
    is never shown.
  - Checked with a made-up test picture (not committed) in levels 1, 8, 10
    and 15, original and xBRZ, smooth motion on, widescreen and 4:3: shown
    behind the sky of 1, 8 and 15, not in level 10 and not in 4:3. After
    C11, with screenshots: levels 9 and 10 show their picture through the
    sky only, the rooms and walls of the base stay dark gray.

## Two players (C10)

As Keen 1 and Keen 2 have them ([../two-players.md](../two-players.md),
[../online.md](../online.md), Keen 2's B9 in
[../keen2/gameplay.md](../keen2/gameplay.md)); `Keen3OnlineScreen` between
`Keen3MenuScreen` and `Keen3View`.

**On one keyboard.** F7, or "Add Player 2" / "Remove Player 2" in the menu
during a game. Player 2's Keen (blue helmet) appears in the level where
player 1's is; on the map he plays along from the next level. In a level
each has his own keys (player 1 WASD, player 2 the arrows; Enter and
Escape are shared) and the shared split screen (`TwoPlayerView`) splits
when they move apart. The inventory is shared (score, lives, charges,
keycards), one death ends the attempt for both and costs one life, one
exit completes the level for both (levels 12, 13 and 15: either exit, for
both), enemies go after the nearest Keen and wake in either player's view.
Not saved with a game (as Keen 1 and 2).

**Online.** "Online Game" in the main menu: hosting and joining by IP or
through Steam, as Keen 1 and 2. Keen 3 has its own game id
(`commanderperfect-keen3`, now in `OnlineProtocol.GAME_IDS`) and its own
fingerprint (`LEVELxx.CK3`); a player of Keen 1 or 2 who joins a Keen 3
host switches to Keen 3 (and a Keen 3 player who joins a host of Keen 1
or 2 switches to that game), by IP or from the Steam list, where a Keen 3
host is listed with "Keen 3" after his name. The joined player's Keen
appears beside the host's in a level; on the world map only the host
walks; nothing pauses while two play (a window closes by itself after 6
s); an arrow points to the other player when he is out of sight; cheats
and F7 are off for the joined player, F7 for the host while hosting. Each
uses his own game files. The snapshot carries Keen 3's own numbers
(`Keen3OnlineState`, in the new optional `Snapshot.extra`): the done
levels, the ankh time of both Keens, Keen 3's own sounds of the tick
(ANKH, MEEP, MORTIMER, FOOTSLAM, which the shared sounds cannot name), the
middle of the host's view of the map and Messie (place and picture). The
charges and keycards already travel in the shared inventory, the halo of
an ankh as an actor. Events at the end of the shared list: the ship's
message (which of the four), Mortimer starting and ending, the border
flash; "Keens Left" is the shared event.

**Decisions for what only Keen 3 has** (as close to Keen 2's choices as
the game allows):

| What | Two on one keyboard | Online |
|---|---|---|
| **The world map** | One Keen, as in Keen 1 and 2: the keys of playing alone and of both players steer him together | Only the host walks ("Only the host can walk on the world map"); the joined player sees the host's map with the host's view (`Keen3MapScroll`'s middle, blended between ticks) |
| **An entrance** | Whoever presses the button with the one Keen on it: both play that level, player 2 starting where player 1 starts | The host enters; the joined player's Keen appears beside the host's |
| **Messie** | The one Keen rides her: either player's keys take him on (walking into her) and off (a direction toward a landing); nobody is left on the shore | The host's Keen rides; the joined player sees her with Keen on her back (her picture travels in the snapshot) and the view following her |
| **The teleporters** | The one Keen goes, with either player's button | The host goes; the joined player sees both teleporters flicker (tile events) and the view jump with the host's |
| **The ship's messages** | One of the four at random, until any key | The same message on both screens (the event names which), closing by itself after 6 s or with a key |
| **The ankh** | Per Keen: whoever touches it is protected and gets the halo; the other is not. A second ankh adds to the time of whoever takes it. The HUD shows a panel per Keen whose ankh runs ("1:9", "2:4"), the status screen both times ("1:9" on row 8, "2:4" on row 9). When player 2 leaves, his halo goes with him | The halo is an actor and shows on both screens; each player's HUD and status screen show his own Keen's ankh time (the joined player's comes in the snapshot) |
| **Level 16: Mortimer** | Both wait while he speaks; Escape or any player's jump, pogo or fire skips him | The host's level waits; the joined player gets his own Mortimer from his own files when the host's starts, and it ends when the host's ends (the host skips for both; the joined player's skip only clears his own screen). The host keeps sending the still level, so the joined player sees both Keens under the boxes |
| **The Mangling Machine** | Either Keen can shoot the sparks and the heart (the 1000 points go to the shared score); its arms and legs kill either, which ends the attempt for both | Runs at the host; tiles, sprites, FOOTSLAM and the border flash reach the joined player |
| **The ending** | Player 2 stops: one Keen in the hall of map 81, as in Keen 2 | Each watches the ending at his own pace; the host's GAME OVER after it does not cut the joined player's ending short, he waits at his title afterwards |
| **GAME OVER, high scores** | One score, one name (as Keen 1 and 2) | The host's table; the joined player waits at his title |
| **Saving and loading** | As alone, on the map; player 2 is not saved | Only the host saves and loads (the joined player's menu has none) |

## Not yet

- Two players: the controller steers player 1 only; on the world map player
  2's keys only walk left and right (`KeenInput.for_player` has no up and
  down), the keys of playing alone do all directions (as in Keen 1 and 2).
- Online: Steam could not be tried here (no Steam on Linux); the logic is
  shared with Keen 1 and 2 and tested without the plug-in.

## Seen in the original (C3)

Not compared in js-dos in C3 (the comparison is optional and was skipped).
One thing to check: level 1's first view. In C1 the original showed cell
(2,12) in the top-left corner of the 4:3 view; ours shows (2, 11.5),
because our camera centres Keen and stops at the bottom of the playable
area (row 23 ends at pixel 384, the view is 200 high). Either the original
shows 8 pixels of the bottom border row (unlikely), or its view is less
than 200 pixels high, or its first view is placed differently. To check in
C11.

*Answered in C11:* the original's first view of level 1 is the same as
ours now (pixel for pixel, apart from the animation phase of a few
sprites).

## Seen in the original (C11)

Pixel for pixel against the original in js-dos (research.md, "Watched
again in C11"): the title, the high score table (after the fix of its
names), the status screen of a new game, the map's first view, level 1's
first view, the ending's four pages, FINALE.CK3 with its box and ball, and
the end text's reader: no differing pixel apart from the phase of animated
tiles and sprites. Keen 3's jumps were measured but not changed (C12):
jump 53 px, pogo 50 px, pogo with the button 105 px (ours 58, 58, 109).

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

- ~~The halo's blink~~ (seen in C11: on and off ~0.12 s); whether it is
  drawn in front of Keen or behind him (C4: behind foreground tiles).
- The splash sprites per direction (105 right, 106 left).
- The door sinking speed (shared: 1 px per tick; Choco: 1 px per 5 clock
  ticks).
- C6: the 30-frame lock after getting off Messie and getting on/off
  themselves (her course was seen, riding was not); the done signs (no
  level was finished in js-dos); TELEPORTSND per cycle (no sound in the
  recordings); the walking frames' timing and the step sounds; the ankh
  time on the map's status screen (0 here).
- "Keens Left": the window's place (the original: x 88-231, y 72-119) and
  how many little Keens fit.
- ~~The ankh time itself~~: 9.6 s, seen in C11.
- C11 left: the GAME OVER window with the name entry after the ending (and
  probably after the last life with a good score); Mortimer's boxes to the
  pixel and whether his last line end counts; the camera flashes' look;
  the enemies, the ball, the jack, the guns, the doors, the done signs,
  Messie's riding, level 9's start, and the first view of level 16 (the
  original's is lower; research.md, "Only the original can answer", with
  the reasons).
- C8: ~~100 points in a new high score table~~ (seen in C11); that the
  first bump against a wall in the air sounds at once (the original waits
  for an odd window of 16 clock ticks); all sounds by ear, also the 145.65
  Hz rate (no sound was recorded in js-dos). The places of the title and
  the table were seen in js-dos in C1, the colours of the names follow
  Choco.

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
  (exit and death back to the map, game over, level 16 wins), the HUD
  icons.
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
- C6: `tests/test_keen3_map.gd` (hand-made maps,
  `tests/keen3_map_fixtures.gd`: walking speed, sprites and steps,
  entering with jump or pogo, a blocking cell entering its level,
  blocking until done, the done signs 1x1, 2x2 and 2x2 with three blocking
  cells, which info cell counts, the ship, Messie's cells, teleporter
  routes, one-way teleporters, the animation and the view jump, the new
  game's view, the free stretch, the map kept after a level),
  `tests/test_keen3_messie.gd` (her start, speed, loop without going back,
  the weed wait, pictures, getting on, nothing while riding, getting off,
  no landing, the 30-frame lock, standing still for a teleporter, kept
  between levels, the view following her), `tests/test_keen3_status.gd`
  (the box's place, numbers, little Keens, icons, labels, the ship's
  prompt, at most six Keens Left, winning with level 16) and
  `tests/test_keen3_map_data.gd` (real files: every entrance and its sign,
  the 16 teleporters, slot 1 to 3 with the view of js-dos, the start view,
  the ship, Messie's start, closed 256-cell loop, both landings, her timing
  against js-dos, riding to level 16 and to level 13, the course from the
  map into level 1 and back with its done sign).
- C7: `tests/test_keen3_machine.gd` (a hand-made level 16,
  `tests/keen3_machine_fixtures.gd`: the parts found, the sparks' and the
  heart's frames, the arms' steps, speeds and turns and what they draw,
  the legs' steps, FOOTSLAM and its wait, +1000 and the border flash, the
  sixth spark stopping the arms, the side sweep's rows and tile 611, the
  heart removing every sprite, its sweep and the level done after 181
  ticks, the game won), `tests/test_keen3_scenes.gd` (typing, Mortimer's
  sound, his nine boxes with their sizes, places and pauses, skipping, a
  window on its cell also in widescreen, the border flash's colours, time
  and frame, the `--ending` option), `tests/test_keen3_ending.gd` (the
  stages in order, the fades, the four pages and their boxes, the five
  flashes with their tiles and waits, the picture's wait and box, the end
  text) and `tests/test_keen3_machine_data.gd` (real files: level 16's
  machine, the machine moving only in its own cells, the sixth spark and a
  real shot at the heart winning the game, the texts fitting their boxes,
  the sounds, map 81's camera tiles, the ending running to its end).
- C8: `tests/test_keen3_sounds.gd` (145.65 Hz from 1193182 / 8192,
  `Keen3Sounds`' priorities and lengths with a hand-made sound file, no
  sounds without files, a pogo bounce as KEENJUMPSND, PLUMMETSND off a
  ledge but not on a platform, the air bump every 13.2 ticks, the
  mother's spit before its splash), `tests/test_keen3_menus.gd` (the
  title's and the table's places, names and scores only in the font's
  second half, Keen 3's own high score file, a save and load round trip
  in a test folder with the view's corner and without Messie, what a save
  keeps on Messie's back, the menu without online play, a second player
  or extra levels, saving only on the map, the menu's save and load, the
  attract time) and `tests/test_keen3_menus_data.gd` (real files: 45
  named sounds, every shared sound found, Keen 3's four with their
  priorities, map 90's two screens without border tiles, the bitmaps and
  the font's second half, the story and the high score texts).
- C9: `tests/test_keen3_extras.gd` (the rule with hand-made levels: sky
  beside a building suits, a base whose dark gray is larger does not
  although Keen 2's rule would take it, a cave without sky does not;
  Keen 3's folder only, never Keen 1's picture; the player's own picture
  only behind a level with sky; the map's view blended between ticks but
  not across a teleporter's jump; Keen 3's moving things drawn half way
  between ticks by `ActorLayer`; real files: the sky is light cyan and
  levels 1-8, 11, 13, 14, 15 qualify; after C11 also 9 and 10, with the
  sky's colour only).
- C10: `tests/test_keen3_coop.gd` (hand-made levels and maps: player 2 is
  a Keen 3 Keen with his own buttons and his own ankh and halo, which
  leaves with him; one death ends the attempt, his exit completes it; he
  shoots a spark of the machine; on the map either player's keys walk the
  one Keen, take him onto Messie and off at a landing, and into a
  teleporter; the HUD's and the status screen's two ankh times; the game
  screen hands player 2 to the split screen in a level and lets every key
  steer on the map, with a stand-in for the split screen's nodes) and
  `tests/test_keen3_online.gd` (Keen 3 in `GAME_IDS`, the handshake for
  Keen 3, switching to and from Keen 1 and 2, Steam's list, Keen 1's and
  Keen 2's snapshots and events byte for byte as before, Keen 3's events
  at the end, a level's and the map's `Keen3OnlineState` there and back,
  broken numbers refused, a Keen 3 host and joiner over ENet on this
  machine with Keen 3's numbers in a snapshot, a Keen 1 player at a Keen
  3 host told to switch, the fingerprint of the `.CK3` levels).
  The screens were checked with screenshots: two players in levels 1, 3
  and 16 and on the map, and online with a host and a joiner in two
  windows on this machine (level 1 with the joiner's ankh, the status
  screen, the map with Messie and a teleporter, the ship, Mortimer, the
  ending) and a Keen 1 joiner and a Keen 3 joiner switching to a Keen 3
  and a Keen 2 host.
- The screen: `tools/scripted_play.gd` with
  `SCENE=res://src/keen3/keen3_view.tscn -- --game=3 --level=N`. With
  `--fixed-fps 60` the frames run much faster than real time, so a
  screenshot can show a frame from some ticks earlier (it depends on the
  machine and on full screen); take them a little later than the event.
