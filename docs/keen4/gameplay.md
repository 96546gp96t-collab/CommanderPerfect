# Keen 4: the rules of a level in our engine

What a Keen 4 level does in CommanderPerfect so far, and where its numbers
come from. Written in milestone D3 (drawing a level); later milestones add
to it (D4 Keen moves, D5 enemies, …). The facts and their sources are in
[research.md](research.md), the code layout in
[architecture.md](architecture.md), the files in
[file-formats.md](file-formats.md). Numbers from Omnispeak are marked
(Omni), what was seen in the user's v1.0 in js-dos "(seen)".

All positions are the original's **global units**: 16 per pixel, 256 per
tile. Times are **tics** of 1/70 s.

## The course of the game (D3)

| What | Then |
|---|---|
| Keen 4 picked on the start screen | Level 1 (Border Village); there is no title or menu yet (D8, D10) |
| `-- --game=4` | Level 1 |
| `-- --game=4 --level=N` | Map N: 0 the world map, 1-17 the levels, 18 the Megarocket, 19 the high-score map; another number: a message |
| Shift+N / Shift+P | The next or previous map (0-19, round) |
| Arrows / WASD | Look around (below) |
| Escape | Back to the start screen |
| F1-F6 | As in Keen 1-3: help line, widescreen, pixel shape, full screen, graphics (original / xBRZ), smooth motion |

The "coming soon" screen of D2 is gone: without `--level` the view opens
level 1 straight away, as Keen 2 and 3 did before they had a title.

## Keen at his start

Keen stands still where the info plane puts him (`Keen4Start`); he moves
from D4 on.

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
  from the top; standing, the view settles his feet back to their place (an
  eighth of the distance a tic, at most 48, at least 16 units a frame);
  looking up or down moves 1 px a tic up to 167 / 33; in the air the place
  goes back to 140. At most 255 units a frame. Leaving the level at the
  sides and falling out of it are D4's.
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
