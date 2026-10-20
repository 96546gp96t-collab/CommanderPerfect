# Keen 4: the rules of a level in our engine

What a Keen 4 level does in CommanderPerfect so far, and where its numbers
come from. Written in milestone D3 (drawing a level) and D4 (Keen moves);
later milestones add to it (D5 enemies, …). The facts and their sources are in
[research.md](research.md), the code layout in
[architecture.md](architecture.md), the files in
[file-formats.md](file-formats.md). Numbers from Omnispeak are marked
(Omni), what was seen in the user's v1.0 in js-dos "(seen)".

All positions are the original's **global units**: 16 per pixel, 256 per
tile. Times are **tics** of 1/70 s.

## The course of the game (D4)

| What | Then |
|---|---|
| Keen 4 picked on the start screen | Level 1 (Border Village), played; there is no title or menu yet (D8, D10) |
| `-- --game=4` | Level 1 |
| `-- --game=4 --level=N` | Map N: 1-16, 18 (the Megarocket) and 19 (the high-score map) are played; 0 (the world map) and 17 (the Well of Wishes) are only shown, with the D3 look-around (D7, D6); another number: a message |
| Keen walks out of the level (left or right) | The next level (after 16, and after 18 and 19, level 1 again: 17 is swum, D6); the world map comes in D7 |
| Keen dies | One life less; the level starts again (fresh, without the gems); with no lives left (fewer than 0): "Game over" and the start screen |
| Shift+N / Shift+P | The next or previous map (0-19, round) |
| Arrows / WASD, jump, pogo, fire | Keen (the shared keys: Ctrl or Z jump, Alt or X pogo, Space or C fire); on maps 0 and 17 the arrows look around |
| Escape | Back to the start screen |
| F1-F6 | As in Keen 1-3: help line, widescreen, pixel shape, full screen, graphics (original / xBRZ), smooth motion |

A new game starts with 3 lives, 5 stunner charges and the first extra life
at 20,000 points (Omni); what Keen carries goes from level to level.

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
| Doors (misc 2) | Up at a door: he walks to its spot (96 into the door tile, a tile less for a two-wide door) 16 a tic, then 5 × 9 tics walking in (−64 each); then he stands at the info plane's target under the door (x high byte, y low byte), one tile above it; the view is put on him again; 110 tics nothing hurts him. Seen in level 1: the door at x 77-78 leads to the room with four sodas, the one at 66-67 to the room with the pole, as ours |
| Switches (misc 5, 6, 15) | Up at a switch: he walks to its spot (−64 from the tile), presses it (8 + 8 tics): the switch tile moves on by its animation offset; a bridge switch moves the bridge's two rows (the second from one tile further left) on by their offsets; another switch turns the platform turn point at its target on or off (info XOR 0x1F; platforms come in D6) |
| Dying | A deadly tile (misc 3) under his box, a deadly floor (top 8-15), or falling below the level (also in god mode): one of two death sprites at random, −40 up and 16 sideways under gravity +3, nothing clips him, the view stands still; once he has left the view the level is lost. Nothing kills him for 30 tics after a death started and 110 after a door |

### The frames and the odd tics (seen in the original, D4)

A level's first logic frame covers 3 tics, every other frame 2 (Omni
CK_PlayLoop), so from then on every frame starts on an odd tic: gravity and
acceleration (which act on odd tics) change the speed *before* the frame's
first tic is moved. Omnispeak's numbers in the research (70 px for a jump)
came from a scratch model with frames on even tics; in the original the
held jump rises 5 pixels a frame for 9 frames and then 4, 4, 4, 3, 2, 2, 2,
1, 0, 0: 67 pixels, exactly what our engine does with the odd frames.

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
view (more than 4 tiles); they wake within one tile of it (Omni).

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
  origin, on whole pixels: pixel = (position + origin) >> 4 (Omni). With
  smooth motion (F6, off by default) the shared `Interpolation` draws them
  between the last two logic frames.
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
  on him again as at the start.
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
pictures go in `assets/backgrounds/keen4/` (none yet), the player's own in
`game_data/keen4/backgrounds/levelNN.png` (they win). Keen 1-3's pictures
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

## Graphics

- **Original**: the tiles and sprites as decoded, on whole pixels.
- **xBRZ** (F5): `GalaxyScaledGraphics` scales the tiles a level shows and
  its sprites six times with the shared `XbrzScaler`, on worker threads
  (~0.6 s for a level on 4 cores), keeps them for the next level, and shows
  the original tiles until they are ready ("Preparing xBRZ graphics...").
- No HD graphics (Real-ESRGAN is skipped for Keen 4).
