# Keen 4: the rules of a level in our engine

What a Keen 4 level does in CommanderPerfect so far, and where its numbers
come from. Written in milestone D3 (drawing a level), D4 (Keen moves), D5 (the
creatures), D6 (platforms, the council, under water), D7 (the world map,
the boxes between the levels, the status window), D8 (the title loop,
the demos, the help, the end, the high scores, the cheats), D9 (sound and
music) and D10 (the control panel, the difficulty, saving and loading);
later milestones add to it. The facts and their sources are in
[research.md](research.md), the code layout in
[architecture.md](architecture.md), the files in
[file-formats.md](file-formats.md). Numbers from Omnispeak are marked
(Omni), what was seen in the user's v1.0 in js-dos "(seen)".

All positions are the original's **global units**: 16 per pixel, 256 per
tile. Times are **tics** of 1/70 s.

## The course of the game (D7, D8)

| What | Then |
|---|---|
| Keen 4 picked on the start screen, or `-- --game=4` | The title loop (below); any key opens the control panel (below): New Game on Easy, Normal or Hard starts on the world map, after the box "Keen enters the Shadowlands"; F1: the help |
| `-- --game=4 --level=N` | Map N at once: 0 the world map, 1-19 played (17 swum); another number: a message |
| On the world map: jump, pogo or fire on an entrance | "One moment", then the level's "Keen enters …" box with Keen counting down, a fade, the level |
| Keen walks out of a level (left or right), the Foot carries him off, he rescues a council member or takes the wetsuit | The level is done (the rescue's and the wetsuit's boxes first); the map's box; Keen back on the map where he entered, the level's flag thrown to its holder, its fence gone; after the Foot he flies |
| Keen dies | One life less, the gems gone; the box "You didn't make it past …": Try Again (the level again, with its box) or Exit to Shadowlands (the map); with no life left (fewer than 0): "Game Over!" for 4 s or a key, then the high scores (below) |
| The eighth rescue | The end pages, then the high scores |
| E, N and D held (cheat) | The level counts as the eighth rescue on the map Keen is on: the elder's box, Keen's eighth answer, the end |
| B, A and T held (cheat) | The box "Cheat Option! …" until a key; then all four gems, 99 charges and a life more |
| F1 | The help; the game waits behind it |
| Enter (the shared status key) | The status window drops down, in a level and on the map; a key lifts it |
| Lindsey, the janitor (D6) | Their boxes; the level goes on |
| Shift+N / Shift+P | The next or previous map (0-19, round) |
| Arrows / WASD, jump, pogo, fire | Keen (the shared keys: Ctrl or Z jump, Alt or X pogo, Space or C fire); on the world map the arrows walk in eight directions |
| Shift+G | God mode on/off (the original's debug key F10+G): nothing kills Keen, except falling out of the level |
| Escape | The control panel (the game waits behind it); Return to Game goes on, Choose Game goes back to the start screen |
| Shift+S, Shift+M | The sound (AdLib, PC speaker, off) and the music (on/off), until the menu has them (D11) |
| Shift+F1, F2-F6 | As in Keen 1-3: help line, widescreen, pixel shape, full screen, graphics (original / xBRZ), smooth motion |

A new game starts with 3 lives, 5 stunner charges and the first extra life
at 20,000 points (Omni); what Keen carries goes from level to level.

## The title loop (D8)

Seen in the original (js-dos, the user's v1.0), in this order (Omni
CK_DemoLoop), and round again:

| Step | What (Omni unless marked) |
|---|---|
| Intro credits | The two words of the series name (misc chunks 1 and 2): the second comes in from the left (its left edge 200 pixels into a buffer that pans back), the first from the right a pixel a tic (only its even rows, each twice), both in proportion to the time, 1864 tics (1.0: \|120 − 1664 − 320\|), until the first word's right edge is at x 120. Either word alone dark grey, both light grey. Meanwhile the four credit pictures (17-14 from the end), at x 160 − (bytes / 2) × 8 (seen: centred by whole bytes), fly up from y 240 (their middle) to 100 at 2 pixels a tic, wait 200 tics and fly out at the top, blue / light blue / light cyan from their blue and green planes (seen) |
| Zoom | Both words joined (80 pixels apart, the second without its first dark run) shrink in 30 tics to 33/256 at the top (4 pixels down), dark grey |
| Fizzle | The title picture (12 from the end) appears pixel by pixel: 360 steps of one tic, each row from its own step for 160 steps, two pixels a step, over the zoom's last picture with the words white (seen: 14 ms a step) |
| Title | 420 tics (seen: 6.0 s); then black |
| Demo 0 | Map 1; the box with "DEMO" (over black after a full screen, over the last picture after a demo; seen), the fade, the demo |
| Story | The story text from the program (30 lines) in the large font, squeezed into the distance over the story picture (13 from the end, magenta as dark grey), a row every 4 tics, until it has moved its height and 400 rows more (1.0: 4008 tics); pixel for pixel the original's |
| Demo 1 | Map 9 |
| High scores | Demo 4 on map 19 behind the table, no box (a fade), no DEMO sign; the table stays under the next demo's box (it is part of the map's picture; seen) |
| Demo 2, 3 | Maps 11, 15 |

**Demos** (Omni `ck_inter.c`, `id_in.c`, `ck_play.c`): a new game on
Normal, the random table from its start, 3 tics a frame, no extra life for
points, the DEMO sign (sprite 5) at 128, 8 of the view plus its origin (3
pixels down; D8.1) instead of the score box. The input is the recorded one
through **two-button firing**: both buttons fire, pogo counts only after it
is held more than 8 tics (let go earlier: one frame of pogo). A demo ends
after its last input, or when Keen leaves the level. All five demos play as
in the original, frame for frame (research.md, "Watched in D8"); since
D8.1 whole frames of the 4:3 view are compared too ("Watched in D8.1").

**Keys in the title loop**: F1 the help (then the loop goes on), any other
key or button the control panel (D10, as the original); Return to Demo
goes on with the loop.

## The control panel (D10, D11)

The original's wrist-watch menu (Omni `id_us_2.c`, `ck_us_2.c`), drawn as
v1.0 draws it (seen: 0 pixels differ for the main, new game, load and save
cards, typing a name, the dialogs and the PAUSED box):

- **The look**: the wrist watch (picture 18 from the end) over the whole
  screen; the card's title picture at (80, 48) on a light green line at
  y 55 (from x 77 to 231); the choices in the watch font (font 1) from x
  (card x + 74) rounded up to 8 and y card y + 60, 8 pixels apart, each
  with an 8×8 icon (tiles 92 normal, 93 under the cursor, 96 / 97 cannot be
  picked); dark green (2) on dark grey (8), the choice under the cursor
  light green (10); the footer under a line at y 133: "Arrows move" at x
  78, "Enter selects" ending at 230, "ESC to quit" (main card) or "ESC to
  back out" centred under them. The cursor's icon blinks every 35 tics
  (seen).
- **Cards** (title pictures counted from the end of the picture range,
  the same in v1.0 and 1.4; places Omni): main 33 (32, 4), new game 32
  (8, 0), load 31 and save 30 (4, 3), configure 29 (8, 0; seen, Omnispeak 0, 0),
  sound 28 and music 27 (8, 0), keys ("BUTTON SETUP") 24 (0, 0), options
  22 (8, 0), Paddle War's title 21.
- **Keys**: up and down move the cursor and stop at the ends; it can rest
  on a choice that cannot be picked (nothing happens there); a letter puts
  it on the choice starting with it (1-6 on the slots); Enter, jump or pogo
  picks; Escape backs out, and on the main card asks "REALLY QUIT?". F1
  on a card opens the help; Escape in the help's menu brings back the
  panel on the same card and choice (seen, D11; not in dialogs, while a
  name or a key is typed, or in Paddle War). Configure, Options and the
  keys keep their cursor for the next visit (seen for Configure; Omni
  keeps every card's).
- **Main card** (exactly the original's since D11): NEW GAME, LOAD GAME,
  SAVE GAME, CONFIGURE, RETURN TO GAME (RETURN TO DEMO out of a game), END
  GAME, PADDLE WAR, QUIT. Save and End only in a game; the cursor starts on
  Return to Game in a game, else on New Game.
- **Quit** (and Escape on the main card): "REALLY QUIT?" / "PRESS Y TO
  QUIT" / "PRESS C TO CHOOSE GAME" / "ESC TO BACK OUT", in the original's
  dialog. The third line is ours (the user's decision, 20-10-2026): C goes
  back to the start screen to choose another game; Y or jump quits; any
  other key backs out, as in the original. (D10 had CHOOSE GAME in Paddle
  War's row.)
- **New game**: BEGIN EASY / NORMAL / HARD GAME, the cursor on Normal
  (seen); in a game first "YOU'RE IN A GAME / PRESS Y FOR NEW GAME / ESC TO
  BACK OUT".
- **Dialogs** (Omni USL_CtlDialog): the watch's screen (masked picture 0,
  at x 72: the original puts pictures on whole bytes) dots out the card; a
  box as wide as the longest line + 7 in the middle of the screen
  (74 + (160 − w) / 2, 48 + (102 − h) / 2), framed light green, the first
  line light green, a line under it, the others dark green. Y or jump says
  yes, any other key no. Asked: Quit always; New Game, Load and End Game in
  a game unless it was saved since the panel opened (Omni game_unsaved).
- **Configure**: SOUND, MUSIC, OPTIONS, (gap) KEYBOARD, RESET KEYS.
- **Sound and Music** (D11; 0 pixels differ from v1.0): NO SOUND EFFECTS,
  PC SPEAKER, ADLIB/SOUNDBLASTER, QUIET ADLIB/SOUNDBLASTER; NO MUSIC,
  ADLIB/SOUNDBLASTER. One is checked (icon 92/93), the others show a ring
  (94/95); the cursor starts on the checked one; Enter checks the choice
  under the cursor and the card stays (seen). The choice works at once (the
  original switches when the panel closes; the user wished it at once) and
  is stored: `UserSettings.sound_device` and `music_enabled` (shared with
  Shift+S and Shift+M), the quiet AdLib sounds in Keen 4's own settings.
  Quiet AdLib (Omni sd_quietAdlibSfx; heard in v1.0): every AdLib sound's
  carrier level byte L is written as 0x3F − (x >> 1) − (x >> 2) with x =
  0x3F − L, in bytes, so the sound is 12.75 dB quieter for L = 0 and much
  more (36.75 dB) for the six sounds whose byte has the key-scale bits set;
  the music is not changed.
- **Options**: SCORE BOX (ON/OFF), with the original's message
  "Score box now on/off" over the card, which still shows the old state
  until the key (seen, D11); then the shared display settings WIDESCREEN,
  4:3 PIXELS, FULL SCREEN, SMOOTH MOTION, BACKGROUNDS (only in widescreen),
  GRAPHICS), KEYBOARD (one row per action, its key (first letter capital,
  as the original names keys) in a box at x + 90 in the colour of its text;
  Enter waits for a new key with a blinking cursor, Escape keeps the old
  one) and RESET KEYS. The keys and the picture are shared with Keen 1-3;
  the score box is Keen 4's own (`user://keen4/settings.cfg`), on by
  default.
- **End Game**: the game stops, the map fades, the high scores (nothing
  enters the table) and the title loop (seen).
- **Music**: opening the panel stops the music, in a game and in the title
  loop (heard in v1.0); Return to Game starts the map's song from its
  beginning (Omni CK_PlayLoop), Return to Demo goes on with the title
  loop's next step and its song.

### Paddle War (D11)

The original's paddle game (Omni `ck_us_2.c` USL_PlayPaddleWar, facts
only; seen in v1.0, 0 pixels differ for the start, the serve, the scores and
the end's dialog). `GalaxyPaddleWar` has the rules, `GalaxyPaddleWarView`
draws it.

- **The card**: the wrist watch, the PADDLE WAR picture at (130, 48) (on
  whole bytes: 128), lines at y 60 and 143 from x 77 to 231; "KEEN:" and
  Keen's score at (80, 52), "COMP:" at (182, 52) with the computer's score
  always at x 217 (seen); light green.
- **Time**: one step a tic (70 a second), every tic drawn; at most 4 tics
  a frame.
- **Paddles** (12 × 3, sprite 0): the computer's at y 66, Keen's at y 135,
  both from x 148. Keen's moves 2 pixels a tic on the held left or right
  (78 to 220); the computer's follows the ball 1 pixel on two tics of
  three, only while the ball is in play, aiming its x + 6 at the ball's
  column (an even column made odd by chance). Sprites go on even columns
  (4 shifts): the computer's paddle is drawn in 2-pixel steps.
- **The ball** (5 × 4 visible; sprite 1 on even columns, sprite 2 a pixel
  further right on odd ones) moves in quarter pixels: served 70 tics after
  a point from (153, 99) with x speed 1 − random % 3 and y speed 3
  (towards Keen, or away when Keen won the point); it bounces off x 78 and
  228. A paddle hits it in rows 66-68 / 132-134 from 5 pixels left of the
  paddle to 10 right; the new x speed is (ball x + 5 − paddle x) / 2 − 4
  (0 becomes −1), and every 10th hit on Keen's paddle in a round makes the
  y speed a quarter pixel faster, up to 12.
- **Points**: past y 137 the computer scores, above y 62 Keen; the ball
  goes and is served again 70 tics later. First to 21: "You won!" or "You
  lost!" / "Press any key" in the original's dialog over the field; a key
  brings back the main card on PADDLE WAR. Escape leaves at any time.
- **Drawing**: as the original's screen: every frame the ball's old place
  (6 × 5) and each paddle's (16 × 3, from 3 pixels left) are cleared before
  they are drawn again, so a ball passing a paddle's row next to the
  paddle is wiped where the paddle's bar goes.
- **Sounds**: paddle_keen (47), paddle_wall (48), paddle_computer (49),
  paddle_computer_scores (50), paddle_keen_scores (51), with D9's player.
- **Random numbers**: the original's table, from a place of Paddle War's
  own (the original shares the game's; ours must not change a level's).

## Saving and loading (D10)

- **Six slots** (`user://keen4/saves/slot1.json` … `slot6.json`, apart from
  Keen 1-3), each with a name. Saving: pick a slot, its box empties (or
  keeps the old name), type up to 32 characters (cursor 0x80 on the last
  column of the text), Enter saves ("Untitled" when empty), Escape keeps
  the slot; the panel stays on the save card with the new name (seen).
- **Anywhere in a game**, as the original: on the world map (Keen's place),
  in a level (the level as it was at that moment, below).
- **Loading**: empty slots cannot be picked; black, then the game with the
  box "PAUSED" (8 × 3 cells, the word in its middle; seen) until a key.
- **What is kept** (`Keen4SavedGame`): the difficulty, what Keen carries
  (score, next extra life, lives, charges, drops, gems), the progress
  (rescues, wetsuit, levels done, the place on the map). In a level: those
  as they were when he entered it, the random table's start and every
  logic frame since (keys and tics), plus B+A+T and god mode; loading
  plays the frames again (architecture.md, "Deviations in D10", 3).

## Help (D8)

F1 in the title loop or in a game (seen in the original: 0 pixels differ):

- The menu: light grey, the help picture at (96, 8), the pointing hand at
  (48, 48 + 24 × topic); up and down (not past the ends), Enter, jump or
  pogo open the topic; Escape leaves the help.
- The topics: ComputerWrist (13 pages), The Game (21), The Story (9), Order
  Info (18), About Id (2): texts 0, 2, 1, 6 and 3.
- A page (`GalaxyPageLayout`): light grey, text dark grey unless `^C` says
  otherwise, 18 lines of 10 pixels from (10, 10) to x 310, a space 7
  pixels, pictures with 8 pixels of room; "pg 1 of 13" at (248, 190). Left,
  up and page up go back, right, down and page down on; Escape: the menu
  again, on the same topic.

## The end and the high scores (D8)

- **The end pages** (text 4, 16 pages): laid out as the help pages without
  a page number; timed pictures follow each other after their pauses
  (keys do nothing meanwhile; seen: the same pauses); then the arrow at
  (296, 184) blinks dim / bright every 70 tics (seen: about 1 s) and a key
  goes on. After the last page the high scores follow.
- **The table** (`GalaxyHighScores`, kept in `user://keen4/high_scores.json`):
  8 places, new: the original's (found in the program: "Id Software - '91",
  an empty one, the five of the team, an empty one, 10,000 each, 0
  rescued). A score enters above every lower score, and above an equal
  score with fewer rescued members.
- **On map 19** (`Keen4HighScoreBoard`, seen: 0 pixels differ): rows 16
  pixels apart from y 51 of the view; the name from x 24, one council
  icon (8×8 tile 71) per rescued member from x 152, the score right-aligned
  at x 296 in the font's score digits; all XORed with 15 into the map's
  picture (light grey becomes dark grey).
- **A new name**: when the score made the table, map 19 is shown (Keen
  standing) with the table, the new row empty and a blinking cursor (the
  font's character 0x80, XOR, every 35 tics); typing (at most 57
  characters, while narrower than 112 pixels), Backspace, Delete, left,
  right, Home, End; Enter keeps it, Escape leaves it empty. Then the
  high-score demo, the title picture and the title loop. Without a place
  (as the original with 0 points) straight to the high scores.

## The world map (D7)

Map 0 is played like a level (`Keen4MapSession`), on the same clock, with
the score box; the view follows Keen as the original's map camera (his box
between 144 and 192 pixels from the left and 80 and 112 from the top, at
most 255 units a frame; the same camera as level 17).

| What | How (Omni unless marked) |
|---|---|
| Keen (info 3) | At the info tile in a new game; afterwards where he stood when he entered the last level. Facing west, priority 1 |
| Walking | Eight directions, 24 units a tic on each axis held (a diagonal is faster); clipped by the map's walls and slopes like Keen in a level (he slides along a sloped wall). Every 4 tics the next picture: walking 2, standing, walking 1, standing (seen: 3 pixels a frame, the same pictures) |
| Waving | Standing 360 tics: he waves (two pictures, 5 × 20 tics; seen after about 5.3 s) |
| Entering | Jump, pogo or fire while an info word 0xC001-0xC012 lies under his box: that level (1-18). Done levels have no entrance any more |
| Done levels (1-17) | Every info word whose low byte is the level is cleared; under 0xD0nn the foreground tile goes too (the fences of levels 1 and 2), at 0xF0nn a flag waves (a tile corner + 0x60, −0x1E0; four pictures of 10 tics, each flag from its own point) |
| The thrown flag | The level just finished: its flag leaves Keen (a tile up and left of his place) once the map has faded in, follows 30 points (straight on sideways, in 24 of them, and an arc up and down) at a point every 2 tics, 50 tics at most, flipping (12-tic pictures), and lands 128 units below the end of its path, in its holder (seen: 8.5 pixels a frame up) |
| Water (misc 11-14) | The tile under the middle of his box. Without the wetsuit: the box "I can't swim!" and he is pushed back by what he moved. With it he swims 16 units a tic (two pictures per direction, 6 tics each): first on by himself into the water (from its north side southwards …) for 18 tics, the stick counting again in the think that uses up the last of them (seen); on the next water tile he walks out on by himself (seen) |
| Miragia (info 33) | A 6 × 4 block copied (all three planes) from the template blocks on row 60 (columns 2, 8, 14, 20, 26): hidden 300 tics, three 30-tic steps to the whole city, 300 tics, three steps back (seen: exactly these times). When the hidden time ends with Keen in its place, it stays hidden another round |
| The Foot | A level ended on the Foot: on the map Keen flies on it, not clipped, in front of everything (two pictures of 30 tics): from left of x 0x1400 to the Pyramid of the Forbidden (0x1E00, 0x3700) in 280 tics, otherwise back to (0x1000, 0x2F00) in 140; then he stands. His speed is the distance / the tics + 1, and the think runs twice in a frame in which the picture changes, so he lands a little short (as the original's action loop) |
| Map 18 | The Megarocket: entered like a level; a small level with the ship; walking out ends it; no flag, so it can be entered again (seen) |

## Between the levels (D7)

All boxes are the original's window (`GalaxyWindow`, `Keen4GameBoxes`; seen:
0 pixels differ), drawn over the last picture of the map or level, in the
middle of the picture (also in widescreen); the game stands still.

| Box | What (Omni unless marked) |
|---|---|
| "One moment" | Keen leaves the world map: a window of 26 × 8 cells, the text 25 pixels down, centred (seen; Omnispeak prints it from the left); 28 tics |
| "Keen enters …" | The map's own text, centred in the window beside the count-down picture, 4 pixels above the middle. The picture's fingers count down 4 … 0 (five small pictures at 24, 40). Times (seen, the original's depend on reading the files): 21 tics, 4 × 20, 28; then the screen fades in three steps of 6 tics, 19 tics black (the next map is put on the screen), and three steps back |
| "I can't swim!" | Keen talking on the right, the text 12 pixels down (seen; Omnispeak 6); until a key |
| After a death | A window of 20 × 8 cells: "You didn't make it past", the level's name (4 lower when it is one line), "Try Again", "Exit to Shadowlands"; the choice framed (2 pixels, from 4 inside the window, 14 high) in light red and blue by turns every 16 tics. Up / down choose; jump, pogo, Enter or Space take it; Escape exits. Try Again: the level again with its box; exit: the map with its box. The life is taken first; with none left no box but "Game Over!" |
| "Game Over!" | A window of 16 × 3 cells, the text in its middle; 4 s or a key; then the start screen (D8: the high scores) |

## The status window (D7)

Enter in a level or on the world map (`Keen4StatusWindow`,
`GalaxyStatusDrop`; Omni CK_ShowStatusWindow, CK_DrawStatusWindow; seen: 0
pixels differ). A window of 192 × 152 pixels at (64, 16), framed by the 8×8
tiles 54-62, grey inside; the labels in the menu font with XOR (dark grey
on grey, black on white):

| Row | Left | Right |
|---|---|---|
| 1 | LOCATION and the map's name on a white bar (centred, one or two lines) | |
| 2 | SCORE (8 digit tiles in a black bar) | EXTRA: the next extra life |
| 3 | RESCUED: one icon per rescued member | LEVEL: Easy / Normal / Hard on a white bar |
| 4 | KEYS: the gems held | AMMO (3 digits) |
| 5 | KEENS: lives (2 digits) | DROPS (2 digits) |
| 6 | the wetsuit's word on a white bar ("???" without it) | the window's "press a key" sign |

It hangs from Keen's arm (a masked picture at 40, 0) and a strap (at 136,
0). It drops with its bottom from 16 to 168 pixels, 8 a tic (seen: about
0.3 s), waits for a key, then rises from 152, 8 a tic. The strap shows only
while the whole window is in the picture, the arm once its bottom is 72
down. The game stands still meanwhile.

## Sound and music (D9)

`Keen4Audio` plays them (`GalaxySoundPlayer`, `GalaxySoundLibrary`; Omni
`id_sd.c`, facts only). The setting is AdLib with music unless the player
chose otherwise (Shift+S: AdLib, PC speaker, off; Shift+M: music; stored in
the settings). Since D11 the panel's Sound and Music cards set the same
settings ("The control panel"); Shift+S leaves the quiet AdLib choice as it
is.

- **One sound at a time.** A sound starts only when its priority is at
  least the priority of the sound still playing; a sound counts as playing
  for its number of steps at 140.2 a second, then its priority is 0. The PC
  speaker and AdLib versions of a sound have the same priority (files, 1.0:
  20 for the steps, 50 for the jump, 99 for the death, the extra life, the
  rescue, the status window, the flag; 0 for Paddle War's).
- **One song at a time**, AdLib only, looping. Starting a song starts it
  from its beginning.

| Song (chunk − first song) | Plays | One round (delay sum + 1 ticks at 560.7 Hz) |
|---|---|---|
| 0 | the world map | 11689 ticks, 20.85 s |
| 1 | levels 8-10, 17 | 29942 ticks, 53.40 s |
| 2 | levels 4, 5, 11-16; the story | 9058 ticks, 16.15 s |
| 3 | levels 2, 3, 7, 18; the end pages | 25385 ticks, 45.27 s |
| 4 | levels 1, 6 | 18355 ticks, 32.74 s |
| 5 | the council's and the janitor's boxes | 7188 ticks, 12.82 s |

The high-score map (19) has none; the help and Lindsey's box stop the
music (in a game the map's song starts again after them); the story stops
it at its end.

| Event | Sound (number) | Where |
|---|---|---|
| Jump, pogo from the ground, leap off a pole | keen_jump (2) | `GalaxyKeen` |
| Landing from a jump | keen_land (3) | `GalaxyKeenAir` |
| Pogo bounce | keen_pogo (7) | `GalaxyKeenAir` |
| Head on a ceiling (not a pole hole) | keen_hit_ceiling (15) | `GalaxyKeenAir` |
| Walking: the 1st and 3rd picture of the walk, once each | keen_walk_1, keen_walk_2 (0, 1) | `GalaxyKeen` |
| Falling off a ledge or a pole, through a thin floor | keen_fall (20) | `GalaxyKeen` |
| A shot / no charges / the shot hits | keen_shoot (4) / keen_out_of_ammo (21) / shot_hit (25) | `GalaxyKeenBody`, `GalaxyStunnerShot` |
| Gem / points / extra life / stunner | got_gem (19) / got_item (8) / got_extra_life (17) / got_stunner (9) | `GalaxyKeenBody._collect` |
| A drop; the 100th drop and points over the next extra life also extra life | got_drop (10), got_extra_life (17) | `GalaxyKeenBody` |
| A switch | keen_out_of_ammo (21) | `GalaxyKeen` |
| Into a door | keen_walk_1 (0) | `GalaxyKeen` |
| Gem in its holder | open_gem_door (18) | `GalaxyKeen` |
| Death; falling out of the level | keen_die (23); keen_fall then keen_die | `GalaxyKeenBody`, `GalaxyWorld` |
| A level done (walked out, the Foot, a rescue, the wetsuit) | level_exit (13) | `Keen4View` |
| The council member reached | council_saved (31) | `Keen4Council` |
| Lindsey, the wetsuit | foot_appear (45) | `Keen4Lindsey`, `Keen4Wetsuit` |
| Status window down / up | status_down (34) / status_up (35) | `Keen4PlayScreen`, `Keen4View` |
| Map: steps (2nd and 4th picture), swimming (high, low by turns), the water without the wetsuit, entering a level | keen_walk_1/2, keen_swim_high/low (26, 27), need_key (14), enter_level (12) | `GalaxyMapKeen`, `Keen4MapKeen` |
| Map: a flag thrown (stops the sound playing) / in its holder | flag_flip (43) / flag_land (44) | `GalaxyMapFlag` |
| Slug slimes, Mushroom hops / leaps, Bounder bounces on the screen | slug_slime (46), mushroom_hop (28), mushroom_leap (16) | the creatures |
| Skypest squashed, Wormmouth bites, Lick flames | skypest_squish (22), wormmouth_bite (5), lick_flame (32) | |
| Cloud's bolt, Berkeloid's aimed throw, the fireball lands | lightning_bolt (39), berkeloid_throw (33), fireball_land (40) | |
| Smirky steals / teleports | smirky_steal (29), smirky_teleport (30) | |
| Mimrock lands (twice) | keen_hit_ceiling (15) | |
| The worms become the Foot | foot_appear (45) | |
| Under water: Keen's bubble, the Dopefish burps / eats Keen, the sprite shoots, a mine | keen_bubble (36), dopefish_burp (42), keen_die (23), keen_shoot + sprite_shoot (4, 38), mine_explode (37) | |
| A dart gun | dart_shoot (41) | |

## Keen's moves (D4)

Keen is the original's state machine (`GalaxyKeen`, his actions in
`GalaxyKeenActions` with Omnispeak's numbers): every action has its sprite
facing left and right, a type, a timer in tics, a velocity and three
functions (think, contact, react). A logic frame runs his action for the
frame's tics, then moves him with the tile collision (`GalaxyClip`), then
the contacts, the tiles he touches, and the reacts (`GalaxyWorld`, the
original's order). Speeds are units per tic.

| Move | How (Omni unless marked) |
|---|---|
| Standing | After 200 tics without a key he looks up (60 tics), after 300 more he is bored (two waiting sprites), after 700 more he sits down and reads a book (until left/right, jump or pogo); in level 11 on the moon spot (misc 16) he shows the moon instead of being bored |
| Walking | 24 a tic (frames of 6 tics; the first frame a quarter); on a slope the floor's slope adds +4 (gentle, down to the right) / +8 (steep) per tic, −4 / −8 up to the right: walking up a slope is 20 a tic, down 28 (seen: 30 instead of 36 pixels per 24 tics uphill). His feet stand on the slope's height under the middle of his box. Walking off a ledge he falls with 8 sideways; a wall stops him |
| Jumping | −40 a tic for up to 18 tics while jump is held, then gravity (+4 on every odd tic, at most 70); in the air left/right +2 on odd tics up to 24, without them −1 towards 0; from a walk 16 sideways. **Held: 67 pixels** (seen; Omnispeak's scratch model said 70, see below); a jump held 3 frames 37 pixels (seen) |
| Pogo | First bounce from the ground: −48 and at once 6 × −48 up (at most 239 a frame); every bounce −48 for 24 tics: with jump held (or in the last 9 tics) the speed stays (no gravity, seen), otherwise gravity. **Held: 105 pixels a bounce; not held: 41** (both seen); the first bounce from the ground 50-56. Left/right +1 on odd tics up to 24, without them he keeps his speed. Pogo again: he falls |
| Ceilings | A ceiling stops the jump; a sloped one only slows it by 16; a pole hole lets him through onto the pole's column |
| Looking | Up: look up (the view moves 1 px a tic up to 167 / 33 px); down: look down; down + jump on a thin floor (flat top, nothing else on that tile or the one below) drops him through it |
| Shooting | Standing 9 + 6 tics (also up, then looking up); in the air ahead, up and down (9 + 1 + 6 tics, falling meanwhile); on a pole ahead, up and down. The shot starts at fixed offsets from Keen (Omni CK_KeenSpawnShot) |
| Poles (misc 1) | Up (the pole at his head + 96) or down (the pole under his feet) grabs it: he goes to its column and is not clipped. Climbing 8 a tic, sliding 24 (both seen: the view follows him 1 and 3 px a frame); at the top he stops with his head just over it; at a floor he stands looking down; at the pole's end without a floor he falls. Jump: −20 for 10 tics, sideways −8 / 0 / 8 by left / none / right; no grabbing for 19 tics. Left/right at the bottom (a floor under him) steps off |
| Ledges | Falling with left or right held, when the top of his box passes 64 units under a tile's top where that tile is a wall (side and top) and the tile above it is free: he hangs (12 tics, then waits). Up or towards the wall: four pulling steps of 10 tics (128 units each) and he stands on top, drawn in front of the ledge's tile unless that one is in front anyway; down or away: he falls |
| Doors (misc 2) | Up at a door: he walks to its spot (96 into the door tile, a tile less for a two-wide door) 16 a tic, then 5 × 9 tics walking in (−64 each); then he stands at the info plane's target under the door (x high byte, y low byte), one tile above it; the view is put on him at once, in his own think, so the objects after him in that frame already wake up or fall asleep by the new view (seen in the original, D13); 110 tics nothing hurts him. Seen in level 1: the door at x 77-78 leads to the room with four sodas, the one at 66-67 to the room with the pole, as ours |
| Switches (misc 5, 6, 15) | Up at a switch: he walks to its spot (−64 from the tile), presses it (8 + 8 tics): the switch tile moves on by its animation offset; a bridge switch moves the bridge's two rows (the second from one tile further left) on by their offsets; another switch turns the platform turn point at its target on or off (info XOR 0x1F; the platforms follow it since D6) |
| Dying | A deadly tile (misc 3) under his box, a deadly floor (top 8-15), or falling below the level (also in god mode): one of two death sprites at random, −40 up and 16 sideways under gravity +3, nothing clips him, the view stands still; once he has left the view the level is lost. Nothing kills him for 30 tics after a death started and 110 after a door |

### The frames and the odd tics (seen in the original, D4)

A level's first logic frame covers 3 tics, every other frame 2 (Omni
CK_PlayLoop), so from then on every frame starts on an odd tic: gravity and
acceleration (which act on odd tics) change the speed *before* the frame's
first tic is moved. Omnispeak's numbers in the research (70 px for a jump)
came from a scratch model with frames on even tics; in the original the
held jump rises 5 pixels a frame for 9 frames and then 4, 4, 4, 3, 2, 2, 2,
1, 0, 0: 67 pixels, exactly what our engine does with the odd frames.

## The creatures (D5)

Every creature is its own class with its own action table (rows as for
Keen; `src/keen4/actors/`), numbers from Omnispeak (Omni) unless marked
(seen). A creature is placed by its info value, with its own rise above
the info tile's corner, and faces right or left by a coin toss of the
random table unless said otherwise. "Kills" means touching it kills Keen
in any state (on a pole too); the original does that in the creature's
own contact.

| Creature (info) | What it does | Kills Keen | The stunner |
|---|---|---|---|
| Poison slug (22, 43, 44) | Crawls 64 units every 8 tics, turns at walls, ledges and deadly floors; 16 in 256 at every second step it stops 60 tics facing Keen and leaves slime (kills 300 tics, fades 60); leaving the slime costs it the step back that ends the stop (see "Asleep and awake" below; seen in the original, D13) | touching it, the slime | stunned for good: hops −24, slides 8, stars half a tile above |
| Mad Mushroom (21) | Hops in place under gravity mid, facing Keen: −40, −40, −68 (seen: 31 px hops and a big leap) | touching it | nothing (the shot stops) |
| Egg (13) | Lies still; Keen or a shot breaks it: the shell stays, three bits fly off (−28/−40, 28/−40, 0/−56), the bird hatches facing Keen (seen: an egg on Normal) | no | breaks it |
| Bird (77, 78; hatched) | Stands 120 tics, walks 128 units every 7 tics to Keen (seen), turns at walls; when Keen stands on the ground 3 tiles higher it flies (speeds up 1 on odd tics, at most 16, plain box 1024 × 512) and lands near his height; off a ledge it flies too | touching it walking or flying | 240 tics, blinks 80, walks again |
| Arachnut (20, 73, 74) | Runs 128 units every 6 tics (seen), to Keen every 4th step | touching it | 240 tics (no stars), blinks 80, runs again; stunned again by a shot meanwhile |
| Skypest (8, 45, 46) | Flies at random (1 a tic on odd tics, at most 20; turns with tics in 256 a frame); a ceiling sends it down, a wall turns it; lands on a floor and preens 400 tics (seen: 10-tic pictures, 100-tic rest), takes off at −16 | in the air | only pushed (20 the shot's way); **squashed for good when Keen lands on it on his pogo stick while it preens** |
| Wormmouth (7, 51, 52) | A mound sliding 16 a tic to Keen; far from him (over 3 tiles) it sometimes peeks left and right; close in front (right 128-384 units, left 128-512, within a tile up or down) it bites (8, 8, 16, 8, 8 tics) | only the bite, only in front | as a mound nothing; peeking or biting stunned for good |
| Cloud (9) | Sleeps until Keen touches it, wakes 100 tics, drifts after him (1 on odd tics, at most 10); with Keen under it (his head at most 4 tiles below) it lines up on 8 pixels, flashes 8 × 10 tics and strikes at the 4th; the bolt kills 48 tics; then drifts 60 tics | the bolt | nothing (the shot flies through) |
| Berkeloid (5, 49, 50) | Floats 8 a tic along the ground, turning at walls and ledges; its picture bobs between 0 and a tile up (8 a tic); throws (12 × 6 tics, the ball at the 6th) with 8 in 256 a step, or 64 in 256 when Keen is ahead within a tile up or down. The fireball flies 48 sideways from −8 under gravity mid (seen) and burns 102 tics on the ground | touching it, the fireball (flying and burning) | nothing |
| Lick (14, 47, 48) | Hops after Keen: long (32, −32) when he is more than 3 tiles away, else short (16, −16), resting 10 tics before and after; close in front it breathes fire 8 × 4 tics (seen) | only the flame, only in front | stunned for good (hops −8) |
| Mimrock (19) | A rock that looks every 20 tics; Keen within 5 tiles up or down, more than 3 away and facing away: it sneaks 64 every 6 tics; still behind him within 4 tiles it leaps (20, −40, gravity mid) and bounces once (−20); he turns round: it sits | only the leap | sitting nothing; sneaking or leaping stunned for good (hops −16) |
| Bounder (12) | Bounces −50 (gravity high; seen: 39 px, 24 sideways); three bounces in place, then every other one left (100 in 256), right (100 in 256) or up, 24 sideways; walls turn it | never: it pushes Keen out of its way and knocks him off a pole or ledge | stunned for good (hops −32), and then a platform |
| Smirky (18) | Stands 40 tics, looks: jumps (−48) for item tiles up to 3 above, hops (20, −24) where there is ground 4 tiles ahead, else back; after two misses (no ground, or walls) it vanishes in a puff (4 × 20 tics) and appears at an item still lying in the level; with none left it is gone. It eats item tiles and drops its box touches in the air, and items lying as sprites it touches | no | stunned for good (hops −16) |
| Inchworm (11) | Creeps 128 every 30 tics to Keen, out of step; a worm touching 11 others in one frame becomes the Foot (5 tiles higher, four puffs), the other worms are gone | no | nothing |
| The Foot (10, or from the worms) | Stands; Keen walking into it is carried off: the level is done | no | nothing |
| Dart gun (53-56 all, 79-82 Normal, 83-86 Hard: up, right, down, left) | Unseen (part of the tiles); every 150 tics while near the view a dart, 64 a tic, gone at a wall or off the screen | the dart | nothing |

**Riding the Bounder.** Keen lands on a Bounder (or a stunned one) and
rides it: every frame he moves with it, standing on it (Omni
CK_KeenRidePlatform); he leaves it by jumping, walking off its sides or
bumping his head. While he rides a living Bounder, he steers it: standing
more than 64 units left of its box it goes left, right of it right,
otherwise straight up.

### Asleep and awake (D13)

What the five demos showed (research.md, "Watched in D13: demos"); with
these rules whole frames of all five equal the original's:

- **At the level's start everything sleeps** but Keen, the platforms and
  the other ever-awake objects (Omni CK4_ScanInfoLayer). A creature wakes
  when its box comes within one tile of the view, so one that lies two or
  three tiles beyond the first view stays still (and draws no random
  numbers) until Keen comes near. Awake, it falls asleep again only beyond
  four tiles, with a chance of 2 × tics in 256 a frame (a random number is
  drawn for that every frame it is that far).
- **One shared step.** The original keeps the step of the object whose
  action runs in one place; starting an action on another object (an
  object it makes: a slug's slime, Keen's shot, a bubble; or one it stuns)
  clears it. So an object that does that in its think loses the step it
  had for that frame: a slug leaving its slime stays where it slimed
  instead of stepping back 64.
- **A door moves the view at once** (above, Keen's moves).

## Platforms and switches (D6)

| What (info) | How (Omni unless marked) |
|---|---|
| Platform (27-30: up, right, down, left) | At its tile's corner, always awake, behind everything (priority 0). 12 units a tic (seen: 52 px a second). When its leading edge is about to enter a tile whose info value is a **turn point** (31), it stops on that tile's edge and turns. Going up, a second turn point two tiles below the one ahead holds it there; going down, one two tiles above (it stands still while both are there) |
| The jets (Keen 4) | Going right a side jet at its left; going left one at its right, in front of the platform; going up two jets under it; going down the same two every other 4 tics. Their two pictures change every 4 tics |
| Riding | Keen landing on a platform (walking, jumping, falling, on the pogo) rides it: he moves with it, standing 16 units above its box, his x keeping its lowest bits (D5's riding). A platform that touches him on a pole or ledge makes him fall onto it |
| Falling platform (32) | Floats until Keen stands on it; then sinks 16 a tic; half a tile down it falls under gravity high; its bottom stops on the edge of a turn point below; without Keen it rises 32 a tic to its place and floats; Keen landing on it while it rises makes it fall again. Not clipped by tiles: without a turn point below it falls out of the level |
| Platform switch (misc 5) | Up at it: the switch flips and the turn point at its target (info under the switch: x high byte, y low byte) is turned on or off (info XOR 31), so a platform stops, turns or goes on at once (D4's switch) |
| Bridge switch (misc 15) | The bridge's two rows at its target (the second from a tile further left) move on by their animation offset: the bridge extends or retracts (D4) |
| Mine (69-72, level 17) | Moves like a platform; touching Keen it explodes (two pictures of 30 tics) and kills him; he cannot ride it |

## The council, Lindsey and the wetsuit (D6)

| Who (info) | What (Omni unless marked) |
|---|---|
| Council member (4) | 369 units above his tile, a random facing; shuffles 64 every 10 tics, turning at walls and ledges; at each step he stops to think with a chance of (tics × 8) in 256 (120 tics, then a step of 128). Keen touching him while standing on something (not on a pole, a ledge, in the air) rescues him: the level is done and the boxes follow |
| The janitor (4 in level 14) | Touched like a member: five boxes, then he is gone; he does not count, the level goes on (seen) |
| Princess Lindsey (6) | A tile above her tile, bobbing (1 on odd tics, at most 8 a tic, turning 32 units from her place), four pictures of 20 tics. Keen touching her: her boxes, then she is gone (seen) |
| The wetsuit (35) | A tile above its tile. Keen touching it while standing: his boxes, Keen has the wetsuit (for the world map, D7), the level is done |

## Message windows (D6)

Every box is the original's window (`GalaxyWindow`; seen in the
original: the same pixels): 26 × 8 cells of 8 pixels in the middle of the
320 × 200 screen (inside 56, 64 to 264, 128), white, framed by the masked
8×8 tiles 0-8; the text in the menu font, black, each line centred. The
one who speaks first has his picture at the window's left edge and his
text 6 pixels down beside it; Keen's picture is at the right edge, his
text 12 pixels down. The game stands still while a box shows; every new
key or button press shows the next (F1-F6 still change the picture).

| Box | Screens |
|---|---|
| Council member | The elder's thanks (in level 17 the bubbly version); Keen's answer (eight different ones, by how many were rescued before); the same box with Keen's thumb up |
| The janitor | His first two texts; Keen's reply; his last text; Keen alone with his cross face, no text |
| Lindsey | "Princess Lindsey says:" and her hint (level 7: the wetsuit in Miragia; level 5: the way to the Pyramid of the Forbidden); Keen's thanks; his thumb up |
| The wetsuit | Keen's words; his thumb up |

The texts are the player's own, read from the program; the pictures are
the last ones of the picture range (file-formats.md). In widescreen the
window is in the middle of the wide picture.

## The Well of Wishes (D6)

Level 17 is swum (`Keen4SwimmingKeen`, info 42 at the tile's corner,
facing right, priority 1):

| What | How (Omni unless marked) |
|---|---|
| Moving | Every tic by his speed; every 8th tic the speed relaxes: sideways towards 0 (3 above 12 either way, else 1), up and down towards 4 (3 above 12, 1 above 4, 1 from below 4, 3 below −12); the stick adds 2 the way it is held. Nothing held: he sinks 4 and 5 by turns (seen: 20 px a second) and drifts 2 px a second right (seen); held: about 12 a tic (seen: 50 px a second after a second) |
| Kick | Jump: 18 in each direction held, and his other picture (50 tics each otherwise); with nothing held no change (seen) |
| Clip | A simple box of 640 × 384 units; walls stop him sideways, floors and ceilings up and down |
| Bubbles | One every 60 tics from his head; they rise 24 a tic, wobble, and are gone at the top or off the screen |
| Taking | Items as on land; touching the council member rescues him (the bubbly thanks) |
| Dying | A mine, a sprite or its shot: he flies off in his suit as on land. The Dopefish eats him (not in god mode): he is held in its mouth, swallowed, and 180 tics later the level is lost |
| The view | As on the world map: his box stays between 144 and 192 pixels from the left and 80 and 112 from the top, at most 255 units a frame (seen: the view starts to follow when he sinks below 112) |

| Creature (info) | What it does (Omni) |
|---|---|
| Dopefish (15; 87 from Normal, 88 on Hard) | Three tiles above its tile, priority 2, a box of 1408 × 1024; swims after Keen (1 on odd tics, at most 10 a tic); a wall turns it. Touching a school fish or Keen it eats: swims 32 a tic until its mouth is at the prey (32 beyond its box, a tile above), swallows, rests 60, burps a bubble after 60 more, rests 60, swims back to where it began and on |
| School fish (16) | Swims after Keen like the Dopefish, a box of 256 × 128; harmless |
| Sprite (17; 23 from Normal, 24 on Hard) | Bobs around its place (1 on odd tics, at most 8, turning 32 away); Keen level with it: it faces him, aims 40 tics, and if he is still level shoots (64 a tic sideways, gone at a wall), then rests 30. Touching it or the shot kills |
| Mine (69-72) | See "Platforms and switches" |

## The stun (D5)

A stunner shot that touches a creature calls its contact; the creatures
that can be stunned stop the shot, switch to their stunned action and hop:
their vertical speed −24, at most −48 up (Omni CK_StunCreature; the
Bounder, Mimrock and Smirky add −32 / −16 / −16 themselves, the slug sets
−24 and slides 8, the Lick hops 16 less). A stunned creature counts as
stunned: Keen's checks no longer see the living creature (the stunned
Bounder carries him instead of pushing). Its stunned action falls under
gravity high; when it lands the stunned picture follows. **Stars** turn
over it (sprites 40-42, three frames of 10 tics, in front of everything)
at an offset per kind: slug and Lick half a tile up, Bounder 64 right and
half a tile up, Wormmouth 64 right and 350 up, Smirky half a tile right,
Mimrock none. The Arachnut and the bird show no stars and wake up again
(240 + 80 tics). Stunned creatures give no points. Off the screen a shot
still stuns what sleeps in its way (D4).

## Difficulty (D5, D10)

Chosen on the New Game card (D10); demos and the high-score map are
Normal. It is kept in a saved game and shown in the status window.

- **The info plane** places some creatures only from Normal on and some
  only on Hard (Omni CK4_ScanInfoLayer; research.md §6);
  `Keen4Creatures.PLACED` lists each value with its lowest difficulty. In
  v1.0 the info planes of levels 1-16 hold over 300 creature values; level
  1 has two Bounders and two slugs on Easy, a third slug on Normal, two
  Licks more on Hard.
- **Easy: the stunner** item (sprite or tile, also under water) gives 8
  charges instead of 5 (Omni CK_KeenGetItem).
- **Easy: gravity mid** once a jump's or a pogo bounce's push is over
  (Omni CK_KeenJumpThink, CK_KeenPogoThink): the held jump reaches 75
  pixels instead of 67; seen in v1.0 by the tester, frame for frame the
  same (9 frames of 5 pixels, then 4, 4, 4, 4, 3, 3, 2, 2, 2, 1, 1, four at
  the top, down in 19 frames).

## Items and tiles (D4)

| What | Then (Omni) |
|---|---|
| Point items as sprites (info 61-66: soda 100, gum 200, candy bar 500, jawbreaker 1000, doughnut 2000, ice cream cone 5000) | Two frames of 20 tics; touched: the points, and the item's "shadow" (the number) rises 8 a tic for 40 tics in front of everything |
| Gems (info 57-60: red, yellow, blue, green) | One more gem of its colour; the shadow is a plain gem; no points |
| Extra life (info 67, the lifewater flask), stunner (info 68; info 34 only when Keen has fewer than 5 charges) | A life; 5 charges |
| The same items as tiles (misc 21-26 points, 27 life, 28 stunner) | Taken under any part of his box: the tile is gone (tile 0), the shadow rises from it |
| Lifewater drops (misc 4) | One drop; a splash (3 frames of 10 tics); the 100th drop is a life (the count starts again) with a rising 1UP |
| Extra lives from points | At 20,000, then 40,000, 80,000, … (each threshold doubles) |
| Gem holders (misc 7-10) | Standing on one with a gem of its colour: he walks to its spot (−64 from the tile), puts the gem in (6 tics): the holder becomes tile + 18, and the door at the info target under the holder (the column of equal tiles from there down, and the two tiles under it) moves on by one tile three times, 10 tics apart: it opens |
| Gems at the end | Lost when the level ends, also by dying |

Items lie behind Keen (priority 2) and sleep when they are far from the
view (more than 4 tiles); they wake within one tile of it (Omni). Like the
creatures they sleep from the level's start until the view comes that
near (see "Asleep and awake").

## The neural stunner (D4)

A shot flies 64 units a tic in one of four directions, with four frames of
6 tics, behind everything (priority 0). It stops at the first side of a
solid tile, except a pole hole (top or bottom 17): it moves into the hole's
column and flies on. Where it stops it shows two frames of 12 tics. Off the
screen it still stuns what sleeps in its way (D5); 10 tiles beside or 6
above or below the view it is gone. Without charges nothing comes out (the
original clicks; sound in D9).

## The score box (D4)

The score box is the HUD (decided by the user): the episode's own SCOREBOX
sprite with the numbers drawn into it as the original does (Omni
CK_UpdateScoreBox): the 8×8 digit tiles ('0' is tile 42, a blank 41, so
unused places show the dim "8" of the box), the score right-aligned in 9
places at (8, 4), the lives at (24, 20) and the charges at (64, 20), 2
places each, at most 99. It is drawn 4 pixels from the top-left corner of
the visible picture, in front of everything, in 4:3 and widescreen alike
(in widescreen in the corner of the wide picture). Seen in the original:
the same box, 3 lives and 5 charges at the start.

## Keen at his start

Keen starts where the info plane puts him (`Keen4Start`, `GalaxyKeen.spawn`).

| Info | Keen | Position | Sprite |
|---|---|---|---|
| 1 / 2 | standing, facing right / left | x = tile × 256, y = tile × 256 − 241 (Omni) | 6 / 14 (Omni SPR_KEENSTANDR / L) |
| 3 | on the world map | the tile's corner (Omni, a new game) | 132 (Omni SPR_MAPKEEN_STAND_W) |
| 42 | swimming (level 17) | the tile's corner, facing right (Omni) | 187 (Omni SPR_KEENSWIMR1) |

The standing sprites' hit box ends at 496 units (31 px), so his feet rest
on the last unit of the info tile, on top of the tile below: no fall is
needed. All three are drawn with priority 1 (Omni). In js-dos (seen) Keen
stands at exactly this pixel in levels 1, 4, 11 and 14, and the map Keen
and the swimming Keen too.

## Drawing

- **Three tile layers** (`GalaxyLevelMap`): background tiles; foreground
  tiles behind the sprites; foreground tiles whose TILEINFO misc has bit
  0x80, in front of the sprites. Foreground tile 0 is nothing. Nothing else
  decides what is in front (seen: in level 1 the rock beside Keen's start
  covers his leg when he stands behind it).
- **Sprites** (`GalaxyObjectLayer`) are drawn at position + the sprite's
  origin, where the original draws them (D8.1): pixel = (position +
  origin) >> 4, and x rounded down to 8 / shifts pixels, the shifts being
  the sprite table's count of shifted copies (Omni `id_rf.c`
  RF_AddSpriteDraw, `id_ca.c` CAL_CacheSprite): 2 pixels for 4 shifts
  (most sprites), 4 for 2, 8 for 1 (Keen 4 v1.0: 155, 53 and 189 sprites).
  So Keen jumps 6 pixels left as he steps into a door (sprites 73-76 have
  1 shift), as in the original. The y is the whole pixel. With smooth
  motion (F6, off by default) the shared `Interpolation` draws them
  between the last two logic frames at their exact places, as before D8.1.
- **Draw order** (Omni `RFL_DrawSpriteList`): the tiles, then the sprites of
  priority 0, 1 and 2, then the in-front tiles, then priority 3. Within a
  priority the sprite placed last is drawn first (under the others).
- **The whole map is drawn**, its 2-tile border too; the camera never shows
  the border in 4:3, and widescreen covers it (below).
- **Atlases**: one per tile set and level, with only the tiles the level
  can show (its own tiles and every tile of their animation loops); a tile
  put later by `set_tile` that is not in the atlas makes a new atlas.

## Animated tiles

`GalaxyTileAnimator`, with TILEINFO's times (Omni `RFL_AnimateTiles`):

- every tile number that the map starts with gets one cycle, shared by all
  cells that start with it (they move in step);
- a cycle counts down by the tics of each logic frame; at 0 or below it
  moves on to tile + its animation offset (at most one step per frame) and
  adds the new tile's time;
- a tile with an offset but no time (gem holders, bridges) does not move by
  itself; background and foreground tiles alike;
- the map plane holds the tile shown now, so what Keen touches later (D4)
  is the tile on the screen.

The logic frames are the original's: 2 tics each, 35 a second
(`GalaxyClock`), at most 5 tics piled up (the game slows down instead of
skipping). Seen in js-dos (level 1, recorded 6 s): the drops change every
114 ms (8 tics), the tree's eyes after 571 ms and 2,855 ms (40 and 200
tics), a tree every 286 ms (20 tics), a face after 3,140 ms (220 tics):
exactly TILEINFO's times. Only the phase differs from the original (it
depends on when the level started).

## The camera (`GalaxyCamera`)

The original's view is 20 × 13 tiles (320 × 208 pixels; the top 200 are
shown). Everything in units (Omni `id_rf.c`, `ck_play.c`):

- **Map edges**: the view's top left stays between 2 tiles (the border)
  and map size − view − 2 tiles.
- **Scroll blocks**: info 26 is a column, info 25 a row that the view never
  scrolls over (Omni calls 25 a "vertical" block: it stops vertical
  scrolling). The map's border adds blocks at columns 1 and width − 2 and
  rows 1 and height − 2.
- **Putting the view** (reposition): clamp to the edges; then for the first
  block the view covers: when it lies in the left half (columns 0-10 of the
  view, the middle one included) the view goes right of it, when in the
  right half (11-20) the view ends just before it. The same for rows with a
  half of 6.
- **Moving the view** (smooth scroll): when its leading edge reaches a
  block, the view stops on the tile edge; a move of more than one tile puts
  the view again.
- **Start of a level** (Omni CK_CentreCamera): Keen 152 px from the left,
  the bottom of his hit box 140 px from the top (on the world map his
  position 80 px from the top), then put as above. Seen in js-dos: the
  first view of levels 1, 4, 11, 14 and 17 and of the world map is the
  original's to the pixel.
- **Following Keen** (Omni CK_NormalCamera; used from D4): Keen's x stays
  between 144 and 192 px of the view; his feet stay between 33 and 167 px
  from the top; standing (or not clipped, or hanging), the view settles his
  feet back to their place (an eighth of the distance a tic, at most 48, at
  least 16 units a frame), not while he pulls himself up a ledge; looking
  up or down moves 1 px a tic up to 167 / 33; in the air the place goes
  back to 140. At most 255 units a frame. Used from D4 on: before moving,
  Keen's box left of the left limit or right of the right limit plus the
  view ends the level, his feet below the bottom limit plus the view kill
  him; after a death the view stands still. Through a door the view is put
  on him again as at the start, at once in his think (D13).
- **Drawing the view** (D8.1): the EGA card pans the picture sideways in
  steps of 2 pixels, so the view's left is drawn at the scroll's pixel
  rounded down to even (Omni `RF_Refresh`: the units & 0xef); its top is
  the whole pixel. The in-front tiles are tiles and move with the map; the
  score box and the DEMO sign are sprites placed at the scroll + 4 and +
  128 pixels with 4 shifts and origin x 0, so they keep their place in the
  view. With smooth motion the view moves on whole pixels between the
  frames, as before D8.1. In widescreen the wider view is centred on the
  original's view as drawn.
- **Looking around** (D3, `FreeLook`): the arrows move a point at 240 px/s;
  the view is put on it by the rules above, so it never shows what lies
  beyond a block or the border, and jumps across a block as the original's
  view does when Keen goes through a door.

## Widescreen: covering beyond the scroll area

Decided by the user (19-10-2026): the camera stops at a scroll block as in
4:3, and what the wider view would show beyond it is covered.

- The wide view (426 px with corrected pixels, 356 with square ones) is
  centred on the original's view, then kept inside the **area** between
  the blocks around the view (the nearest block column left of the view's
  middle + 1 to the nearest one right of it, likewise for rows).
- When the area is narrower than the wide view (the Megarocket and the
  high-score map are exactly 320 px wide; level 4 left of its block 416 px)
  the view is centred on the area and the rest is **covered**
  (`GalaxyViewCover`): black, or the picture behind the level when one is
  shown, at the same place as the picture itself, so it runs on.
- The cover is drawn over everything (also the in-front tiles and
  priority-3 sprites). In 4:3 nothing is covered: the picture is the
  original's.

## Pictures behind the levels

An extra, widescreen only, on by default (the shared option). Keen 4's own
pictures are in `assets/backgrounds/keen4/` (ten, painted from code since
D11, below), the player's own in `game_data/keen4/backgrounds/levelNN.png`
(they win). Keen 1-3's pictures
are never used.

A Galaxy level's background is pictures made of tiles (trees, hills,
pyramids, rock), not one plain tile, so a picture may only take the place
of **sky** (`GalaxyBackdropPictures`):

- the sky tiles are Keen 4's plain one-colour tiles 1085-1088, 1104, 1105
  (light cyan) and 478 (light blue);
- a level (1-17) may show a picture when the first row the view can show
  (row 2, inside the border) has sky; the most used sky tile there names
  the sky colour;
- the picture shows through that colour where it touches the edge of a
  background tile (around clouds, palm leaves, hill tops), as Keen 1's do;
  colour inside a shape stays.

In v1.0 that gives **levels 5, 7, 8, 9, 10, 11, 12, 13, 14 and 16**. Not
1-4, 6 and 15 (forest, cave or tree tops at the top; level 15 has sky only
between the palms, inside tree tiles), 17 (under water), nor the world map
(its light blue 478 is the lake), 18 and 19. The light blue 478 is the sky
of level 5 but water in levels 8 and 10: there the top row has the cyan
sky, so their water keeps its colour. In level 9 the glass pillars are
sky-coloured inside and let the picture through as well (looked at with a
test picture, not committed).

**Our pictures (D11 part B, the user's request of 20-10-2026).**
`tools/make_keen4_backgrounds.py` paints one per level with sky, as Keen 3's
are made: from code only (nothing from the game files or their palette),
in chunky pixels (216 rows blown up 5 times, lossless WebP, fixed seeds
4000 + level), on the canvas shared with Keen 3 (`tools/background_painter.py`).
Levels of 100 cells and wider get a wide picture (3840x1080), which glides
further; levels 8, 9 and 10 (58-88 cells) a 16:9 one (1920x1080). The
land stays low in every picture (its horizon is about 75-80% down the
view, where the level has its own ground), so the sky behind the level's
clouds, palm crowns and pyramid steps stays calm.

| Level | Scene |
|-------|-------|
| 5 Chasm of Chills | a cold clear morning: a pale sun, snowy blue peaks, frosted firs on the hills (wide) |
| 7 Hillville | a sunny afternoon: rolling green hills with round huts and palms, fat clouds (wide) |
| 8 Sand Yego | a violet dusk: a big sun setting on far flat-topped buttes, sand dunes (16:9) |
| 9 Miragia | a pastel noon: lavender sky, white sun, buttes with domes and towers mirrored in a mirage (16:9) |
| 10 Lifewater Oasis | a fresh morning: a still lake in the dunes, palms on its far shore, the sun's path on the water (16:9) |
| 11 Pyramid of the Moons | an evening with three moons and the first stars, far pyramids in moonlit dunes (wide) |
| 12 Pyramid of Shadows | a red sunset behind a row of black pyramids whose shadows lie across the sand (wide) |
| 13 Pyramid of the Ancients | a pale gold morning: great pyramids in the haze, broken columns and obelisks on a rise (wide) |
| 14 Pyramid of the Forbidden | a storm in a green sky: a red sun in dark clouds, lightning, a black pyramid (wide) |
| 16 Isle of Fire | dusk over the sea: an erupting volcano with lava and smoke, its glow on the water, a palm islet (wide) |

Looked at in the game in widescreen (scripted shots from the sky of every
level): the level's own white clouds sit on these skies without looking
pasted (the night and storm skies are kept a clear blue or grey-green for
that), the pictures show through level 9's glass domes, and the land of the
picture lines up behind the grass line of level 5 and the palms of 7, 10
and 16. `test_keen4_backgrounds` checks that exactly levels 5, 7-14 and 16
have a picture.

**To paint them again** (after changing a scene): `python3
tools/make_keen4_backgrounds.py` (Pillow and NumPy; or with a folder to
try them elsewhere), then `godot --headless --path . --import` for the
`.import` files. To try a picture without building, put it in
`game_data/keen4/backgrounds/` as above.

## Graphics

- **Original**: the tiles and sprites as decoded, at the original's
  pixel steps (sprites at 8 / shifts, the view at 2; "Drawing").
- **xBRZ** (F5): `GalaxyScaledGraphics` scales the tiles a level shows and
  its sprites six times with the shared `XbrzScaler`, on worker threads
  (~0.6 s for a level on 4 cores), keeps them for the next level, and shows
  the original tiles until they are ready ("Preparing xBRZ graphics...").
- No HD graphics (Real-ESRGAN is skipped for Keen 4).
- D11: tiles a switch, a gem or a gem door puts in the level that are not
  scaled yet get a stand-in (the original tile made larger) until they
  are; the level stays in xBRZ (before, it flashed back to the original
  graphics). The full-screen pictures (title, help, story, end pages), the
  panel, the boxes, the status window, the DEMO sign, the score box and
  the high-score table always keep the original pixels, filtered sharp
  (before, they went soft once a level had shown xBRZ).
- **Smooth motion** (F6): every object goes through `GalaxyObjectLayer`
  and the view through `_place_smooth_view`, so levels, the map, swimming
  and the platforms all move between the logic frames (measured headless
  at 120 frames a second: a running Keen takes 175 different places in 4
  s instead of 26; swimming 420 instead of 77, the view 54 instead of 13).
  The front screens and the panel keep the original's steps.

## Two players (D12)

As Keen 1-3 have them ([../two-players.md](../two-players.md)), on top of
the Galaxy engine. An extra of ours: the original is for one player, and
playing alone stays exactly as it was (the demos still match). The code:
`Keen4CoopScreen` (between `Keen4MenuScreen` and the online screens),
`GalaxySplitView`, the second Keen in `GalaxyWorld` (`partner`,
`partner_camera`; `GalaxyWorldPlayers`) and `Keen4LevelSession`
(`add_player`, `remove_player`, `camera_2`).

**Joining.** F7, or in the control panel Configure > Two Players > Add
Player 2 (Remove Player 2), only in a game (not in the title loop, a
demo, the end or the name entry). The original's cards stay as they
were; Configure gets two rows after a gap: Two Players (adding and
removing player 2, each player's keys) and Online Game. In a level that
is being played his Keen appears where player 1's is, facing the same
way (a walking Keen, or a swimmer in level 17), in player 2's colours
(the shared hue shift: a blue helmet, a green shirt); otherwise (on the
map, behind a box, while player 1 dies) from the next level on.

**Keys.** The shared two-player keys, which got up and down in D12
(approved by the user): player 1 A/D, W/S, Left Shift (jump), ` (pogo),
Z (fire); player 2 the arrows, . (jump), / (pogo), Right Shift (fire).
Enter (status) and Escape (panel) are shared. Each player's keys are on
their own card (Configure > Two Players > Player 1 Keys / Player 2 Keys).

| Question | Decision (D12) |
|---|---|
| Score box | **One**, as the original's, in the top left of the picture: the inventory is shared, so a box per half would show the same numbers |
| Inventory | **Shared** (Keen 1-3's choice): one score, one stock of lives, one stunner with its charges, the drops, the gems. Either Keen picks things up, puts gems in holders and opens gem doors |
| The world map | **One map Keen**, steered by the keys of playing alone and of both players (Keen 3's choice): either player enters a level, swims (wetsuit), meets Miragia and flies with the Foot |
| Under water (level 17) | **Two swimmers**; the Dopefish and the school fish go after the nearer one; one eaten swimmer ends the attempt for both |
| Platforms, Bounders, poles, ledges, doors | Each Keen on his own: both can ride one platform (a falling platform sinks under either), either steers a Bounder he rides; a door takes only the Keen who went in, and puts his own view on him |
| Enemies | Go after the **nearest living Keen** (`GalaxyWorld.nearest_player`), kill the one they touch; they wake up in **either view** and fall asleep only far from both |
| Death | As in Keen 1-3: as soon as one Keen dies, the attempt is over **once his death flight has left his own view**; one life less, gems gone, the "Try Again" box, which either player's keys (and the keys of playing alone) choose |
| The exit | Either Keen walking out to the side completes the level for both, **but not while the other one dies** (Keen 1-3's rule); a rescue, the wetsuit or the Foot completes it at once (that object has already acted) |
| The council, Lindsey, the janitor, the wetsuit | Whoever reaches them; the boxes are shown once, as alone |
| Status window (Enter) | One window (the shared inventory and progress) |
| Saving | Player 2 is **not saved** (Keen 3). A save in a level player 2 played in holds that level's start (no frames), because a saved level is played again from its frames and his cannot be played by one Keen; on the map as alone. Loading starts with player 2 still in (when he was), who joins after the level has been played back |
| The end, high scores | As alone: one entry with the shared score |
| Demos, the title loop | One player; F7 does nothing there |

**The split screen** (`GalaxySplitView`). Each Keen keeps his own
`GalaxyCamera`, which follows him by the original's rules (it wakes the
creatures and ends his death). The picture uses the shared
`SplitScreen` of Keen 1-3: a focus point per Keen with the shared dead
zone, one shared view while both are close enough to its middle, two
halves split by a line at right angles to the line between them when
they are further apart, the views gliding. Galaxy's own rule on top:
each view stays inside its Keen's area between the scroll blocks (or the
map's border), so the split screen never shows what lies beyond a block,
and two Keens in different areas (one in a room behind a block) always
split. In widescreen what a view shows beyond its area is covered as
alone; the second view has a cover of its own (drawn only in `World2`,
by canvas cull masks). The view starts where each player's own camera
looks, so the picture does not jump when player 2 joins; while the
screen is shared the view follows the Keens' middles instead of the
original's resting place of the feet (a few pixels' difference).

## Online (D12)

As Keen 1-3 ([../online.md](../online.md)): Configure > Online Game
opens the shared online pages (Host via Steam, Host via IP, Join via
Steam, Join via IP, Your Name), drawn as a framed box in the panel's
font and colours (`GalaxyOnlinePageView`; the watch's screen is too
small for the addresses). Keen 4's id `commanderperfect-keen4` is in
`OnlineProtocol.GAME_IDS`; a player of Keen 1-3 who joins a Keen 4 host
switches to Keen 4 (and back), by IP or from the Steam list. The
fingerprint is `GalaxyFingerprint`: the one GAMEMAPS file with its map
headers. Each player uses his own game files; nothing of them travels.

| What | Online (D12) |
|---|---|
| Hosting | From the title a new game starts; in a game it goes on. Player 2 on the keyboard leaves, F7 is off while online (for both) |
| The joined player | Player 2 in the host's levels (his Keen appears where the host's is; on the map from the next level), steered by his keys for playing alone (up and down included); **no split screen**: each has his own screen, the joined player's view is the host's camera on his Keen. An arrow at the edge points to the other Keen while he is out of sight (yellow to the host's Keen, blue to the other) |
| The world map | Only the host walks ("Only the host can walk on the world map"); the joined player sees the host's view |
| Boxes | Shown on both screens; the joined player's are made from his own files (`Keen4BoxNames`: the host names each box, the joiner draws the same). They wait for the **host's** key; the game stands still for both meanwhile, as the original stands still behind them |
| The control panel, the status window | The host's panel and status window stop the game for both (as the original's); the joined player's panel (Return to Game, Leave Game, Configure, Quit) does not, and he has no status window of his own (his score box shows the shared numbers) |
| Sounds, music | The sounds of the level (by number) and the song the host plays |
| Death, Try Again, the exit | As two on one keyboard; the host chooses after a death |
| The end | Each reads the end pages at his own pace; the high-score table is the host's; afterwards the joined player sees the title picture until the host plays again |
| Saving, loading | Only the host (player 2 is not saved) |

**On the wire** (appended at the end of `OnlineProtocol.Message`; Keen
1-3's messages are unchanged byte for byte):

- `GALAXY_SCENE` (reliable): the scene number, the kind (`WAITING`: no
  map; `MAP`: a level or the world map is played; `ENDING`), the map's
  number and every tile of the three planes that differs from the map in
  GAMEMAPS (plane, x, y, tile). A new scene is sent for every new session
  of a map (Try Again starts anew), the end, or nothing; the boxes
  between two maps keep the last map behind them.
- `GALAXY_TILE` (reliable): a tile of the background or foreground that
  changed (plane, x, y, tile), with the scene's number.
- `GALAXY_SNAPSHOT` (unreliable, every logic frame, 35 a second): the
  joined player's view (units), every sprite drawn (x, y, sprite,
  priority; the host's and the joined player's Keen marked), the sounds,
  the song, the brightness of a fade, the box shown (its name) and Keen
  4's numbers (`Keen4OnlineState`: score, lives, charges, drops, gems,
  next extra life, rescued, wetsuit, levels done, difficulty).
- The joined player's buttons go as the shared `INPUT` message
  (`OnlineInput`, which already had up and down).

Tried in D12 with a headless host (`--max-fps 60`) and a joined player in
xvfb on one computer by IP (127.0.0.1).
