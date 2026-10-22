# Pictures behind the levels of Keen 1 and Keen 2: research

Milestone `milestone-a-b-backgrounds` (the user's wish of 19-10-2026: "we
moeten ook een keer de backgrounds voor keen 1 en 2 gaan maken"). Keen 3
(C9) and Keen 4 (D11) already have their own pictures; Keen 1 has one, for
level 1; Keen 2 has none. This file is what the architect found by looking
at every level of both episodes (exported with `tools/export_graphics.gd`
into the scratchpad, never into git) and by measuring which pixels a
picture would replace. The plan is in [roadmap.md](roadmap.md).

## 1. What the plain backgrounds are

Counted per level: the share of the level's cells (including the border
around the playable area) that each tile takes.

### Keen 2: everything is inside the Vorticon Mothership

Keen 2 is played on board the Mothership; the world map is its plan, with
the hull all around (dark blue) and the border of space (cyan). The levels
are its rooms:

| Level | Name (fan names, KeenWiki) | Back wall | Kind |
|---|---|---|---|
| 1, 2, 3 | (no names known) | tile 143, 36-48% | corridors and halls |
| 4, 6, 7, 9, 11, 13, 15, 16 | Tantalus Centers: London, Cairo, Sydney, New York, Paris, Rome, Moscow, Washington | tile 143, 22-43% | each with the Tantalus Ray machine and the city on its screen |
| 5 | (no name known) | tile 147, 35% (dark) and 143 | a dark shaft with brick ladders, lit spots |
| 8, 10 | Home A, Home B | tile 143 | the crew's quarters |
| 12 | Weaponry B | tile 276, 43% (plain teal) | a teal hall with grey girders |
| 14 | Weaponry A | tile 147, 46% (dark) | a dark shaft with brick ladders |

- **Tile 143 is not a plain colour but a pattern**: light grey with a white
  lattice of diagonal lines (a grille or mesh). It is the back wall of every
  room; the solid hull and walls are dark blue (tiles 182-186, 235). Tiles
  148-152 are the same lattice with the shadow of a wall on it (darker
  grey), tile 147 the lattice in the dark (black with dark grey lines),
  156-158 the dark one with shadows.
- **The pattern is baked into the items** (burgers, bottles, the sign
  boards, platforms): their tiles carry the lattice around them, pixel for
  pixel in the same place, because tiles are 16×16 and the lattice repeats
  every 16 pixels.
- That is why B8 found that a picture "through the background colour"
  shines through the lattice's dots all over a level, and only allowed
  level 12 (whose teal is plain).
- **There is nothing outside to see**: no level has a window, a sky or a
  horizon. The only views of the outside are the city pictures on the
  Tantalus Ray machines (tiles, drawn by the game) and the world map's
  border.

### Keen 1: outside on Mars, and dark rooms

| Level | Name (KeenWiki; "?" not sure) | Plain backgrounds | Kind |
|---|---|---|---|
| 1 | Border Town | grey 143 (51%) | outside (has a picture since 16-10) |
| 3 | Treasury? | grey (59%) | outside |
| 4 | Capital City | grey (47%) | outside |
| 7 | Emerald City | grey (67%) | outside |
| 8 | Ice City | grey (56%) | outside, ice |
| 13 | Red Maze City | grey (36%), black (10%) | outside, a dark tunnel along the bottom |
| 14 | Secret City? | grey (60%) | outside |
| 15 | ? | grey (40%), black (5%) | outside, a dark room at the right end |
| 16 | Vorticon Commander's Castle | grey (45%), black (17%) | outside on the left, the castle (dark) on the right |
| 2, 6, 11 | Red Rock Shrines | black 155 (42-50%), grey | dark rooms |
| 5 | Pogo Shrine | black (50%), grey | dark room |
| 9, 10 | Ice Shrines | grey (33-36%), black (20%) | half outside (ice), half dark room |
| 12 | Red Rock Shrine? | black (24%), grey (22%) | dark room and outside |

- **Grey is two things in Keen 1.** Outside it is the sky (Mars' sky is
  plain light grey in the original). **Inside the dark rooms the grey is
  light**: every grey triangle in a shrine or in the castle hangs under a
  blue lamp at the ceiling. It is a cone of light, not sky. A sky picture
  through all grey (today's rule) would put the sky inside every lamp's
  light, and in level 16 inside the castle.
- **Black is the dark of a room.** Its colour is also in the corners of
  the grey and cyan blocks (tiles 290, 291, 333, 401), but there it is the
  room behind the block, so a picture may show there as well.

## 2. Measured: where a picture would show

Every pixel that a picture would replace was painted magenta on the
exported levels (scratchpad `ab/leak/`), with two rules:

- **Colour rule** (today's, `GraphicsTextures.backdrop_tile_atlas`): the
  background colour where it touches a tile's edge, directly or through
  more of it.
- **Pattern rule** (new): a pixel shows the picture where it is exactly the
  pixel of the pattern tile at the same place (143, or 147 in the dark),
  again only where that touches the tile's edge.

| | Rule | From other tiles than the plain one | Looks |
|---|---|---|---|
| Keen 2, 143 (levels 1, 4, 7, 8, 16) | colour | 10-33% | the lattice's dots let it through everywhere |
| Keen 2, 143 | pattern | 10-30%, all of it the lattice around items and the lit half of the shadow tiles | clean: items keep their shape, nothing inside them goes |
| Keen 2, 147 (levels 5, 14) | pattern | 13-16% (the brick ladders' gaps) | clean |
| Keen 2, 276 (level 12) | colour | 97% (the teal around girders) | clean (as B8) |
| Keen 1, grey (outside levels) | colour | 1-9% (around mushrooms, signs, platforms) | clean, as level 1 today |
| Keen 1, black (dark rooms) | colour | 9-52% (the corners of blocks, slopes of ice) | clean: those corners are the room behind |

**Shadows.** Where a wall's shadow falls on the lattice (tiles 148-152,
178, 179 and the bevels along every dark blue wall), the lattice is drawn
one step darker: white becomes light grey, light grey dark grey, dark grey
black (measured pixel for pixel against tile 143). So a shadow pixel is a
pixel that equals the lattice *one step darker* at the same place. Those
pixels become the wall, darkened (a mockup used 45 % brightness), so the
walls still cast their shadow on the new wall, **without the lattice**:
the user saw the lattice left in the shadows of a first mockup and asked
for the shadow to fall on the new wall (22-10-2026). Found in the
mockup: a plain grey block (the riveted box of level 4) equals the dark
lattice along the lattice's white lines and became an X. So a group of
shadow pixels only counts when it holds dark grey where the lattice is
light grey (the real shadow's main colour), not only the darker lines.
Single stray pixels at a few wall corners stay to be checked. A few sign
boards hold a lattice pixel in their own edge (seen in the Tantalus Center
sign of level 4): the tester checks the boards one by one.

## 3. How it should move: a wall, not a sky

Today's `LevelBackdrop` is made for a sky: one picture, top at the top of
the view, gliding slower than the level (far away), its horizon always in
sight. That fits Keen 1's outside levels (and Keen 3 and 4).

**Keen 2's rooms are closed.** The lattice is the wall right behind Keen:
in the original it moves exactly with the level, and the walls cast their
shadow on it. A picture that glides behind it would look like a sky seen
through holes in the ship, which there are none of. So, as the user
expected, the back wall in Keen 2 should be **fixed to the level**: it
moves 1:1 with the tiles, has no top or horizon, and covers a level of any
size by repeating. The same holds for **Keen 1's dark rooms** (shrines,
the castle, the tunnel of 13): closed rooms, a wall behind them.

This gives two kinds of picture:

| Kind | Where | Moves | Size |
|---|---|---|---|
| **Sky** (exists) | Keen 1 outside (grey), and Keen 3 and 4 as now | glides with the view, slower than the level | one picture per level, 16:9 or wider |
| **Wall** (new) | Keen 2's rooms (lattice 143 and 147, teal 276), Keen 1's dark rooms (black 155) | fixed to the level, 1:1 | a texture that repeats (seamless), e.g. 256×256 game pixels, one per level or per kind of room |

A wall texture is drawn in the level's own pixels (one texture pixel per
game pixel, like the tiles), so it fits the chunky look; with xBRZ the
holes are cut out of the larger tiles as today.

A level can have both (Keen 1's levels 9, 10, 12, 13, 15 and 16: sky
outside, wall inside). Inside a dark room the light cones stay as they are
(grey), or let the wall show through brightened (a choice for the user).

## 4. How it can be built

Without changing Keen 1-3's other code (only additive, as before):

1. **A second kind of hole.** `GraphicsTextures` gets a backdrop atlas
   that knows two sets of holes: the sky's (colour rule, as now) and the
   wall's (colour rule for black and teal, pattern rule for Keen 2's
   lattice). The tiles keep being drawn by the shared `LevelMap`.
2. **A wall layer** (new, e.g. `LevelWall`): a `TileMapLayer` just below the
   tiles with the same cells, whose atlas holds, per tile, the wall's holes
   as a mask (and the shadow pixels as a half-dark mask). A shader fills
   the mask with the wall texture by world position (repeating), so the
   texture is fixed to the level and nothing of it is drawn outside the
   holes. Keen 2's darkness (`Keen2Darkness`, a `CanvasModulate`) darkens
   it with the level, since it is on the level's canvas.
3. **Which hole is sky and which is wall** per level: Keen 2 all wall.
   Keen 1: black is wall; grey is sky only where it is outside. Outside is
   decided per level (a short table in code, checked by a test), because a
   grey cone of light and grey sky are the same tile; for the mixed levels
   (16: the castle's cones) the grey region is the sky when it is joined to
   the top of the level without passing a lamp, and the tester checks every
   mixed level by its picture.
4. **Pictures and textures** are painted by our own tool, as Keen 3's and
   4's (`tools/background_painter.py`): nothing from the game files is in
   them. The wall textures do not follow the shape of a level (that would
   be derived from the level data); they only repeat.
5. **Options** as today: only in widescreen, the "Backgrounds" option (on
   by default, the user's decision for all pictures behind levels); 4:3
   always the original. The player's own folder (`backgrounds/`) also
   takes wall textures (e.g. `wall05.png`).

## 5. Ideas for the content (to choose with the user)

- **Keen 2, wall per kind of room**: corridors and halls (1-3): steel
  panels, rivets, a pipe; Tantalus Centers: a control room (screens,
  cables, warning lights); Home A and B: the crew's quarters (warmer
  panels, lamps, doors); Weaponry A and B and the dark shaft (5): dark
  machinery, hazard stripes, red lamps. Colours kept quiet, darker than the
  items, so Keen, the enemies and the items stand out as they do on the
  grey lattice.
- **Keen 2, optional**: round windows in the wall showing stars and the
  Earth (the ship is in orbit around it). These are not in the original;
  in a fixed wall the stars would move with the wall.
- **Keen 1, sky**: Mars as in level 1's picture, per city its own: ice
  mountains for Ice City (8) and the ice shrines, green for Emerald City
  (7), red rock for the Red Maze City (13), the castle's dark sky for 16.
- **Keen 1, wall**: carved rock or old stone in the shrines, cold blue
  stone in the ice shrines, metal or dark stone in the castle.
- **Level 1's picture** (16-10) is smoother than the chunky style of Keen
  3's and 4's painters: keep it, or paint it again with the others.

## 6. The user's choices (22-10-2026, as a menu)

1. **Keen 2's wall is fixed to the level** (1:1, as the lattice), and the
   walls' shadows fall on it as dark bands without the lattice.
2. **A wall per kind of room** (corridors and halls, Tantalus Centers,
   Home A and B, Weaponry and the dark shaft), quiet and dark, so Keen and
   the items stand out. No windows.
3. **Keen 1: a sky outside that glides (as level 1), a fixed stone wall
   behind the black of the dark rooms; the grey light cones stay as in the
   original.**
4. **Level 1's picture stays** (the user's own Mars picture of 16-10); the
   other Keen 1 skies get the same mood, per city.

## 7. Deviations and decisions in AB2

Built as planned (holes of two kinds, `LevelWall`, Keen 2 walls in every
level, Keen 1's sky only outside); what differs from sections 2-4, or was
decided on the way:

- **The pattern rule needed more than "equal and joined to the edge".**
  Plain colours equal the lattice wherever its field is, so the first rule
  ate a riveted box (an X), the edges and dots of the white sign boards and
  the dithered roof of London's tower. A group now counts only when, in one
  kind (lit, dark, shadow), it is at least 2x2 pixels thick, touches the
  tile's edge, holds both kinds of line (the white and the dark grey one)
  and its field pixels have its own line pixels next to them at least three
  times as often as not (`LatticeWalls.LINE_RATIO`); real lattice tiles
  score ten times or more, the false ones about two. The lit groups are
  found first; where a shadow or the dark meets them, their lines count.
  The boxes (tiles 385, 386, 400), the boards and the roof stay whole.
- **Thin shadows** (two pixels under a platform, the bevels) join a wall
  next to them when they hold a darkened white line; their black pixels
  (the darkened dark line) only with three wall neighbours, so a black
  outline is never taken. Stray groups of up to four grey pixels with only
  wall around them become wall (the corners where two tiles' lines do not
  meet, a white corner pixel of tile 148).
- **The dark lattice next to a cone of light** (tiles 157, 158) has its
  lines two pixels to the right of tile 147's; both count as the dark wall.
  Tile 147 has no shadow kind: one step darker it is black.
- **Brightness:** the wall in the dark at 35 %, in a shadow at 45 %
  (`BackdropHoles`), lit at 100 %.
- **Keen 1's sky is always tile 143's grey.** The old rule (the level's most
  used plain tile) gives black in the dark rooms (levels 2, 5, 6, 11, 12).
- **Keen 1's cones by the lamp:** a grey region (cells joined through grey
  on their shared edge) is a cone when one of its cells hangs right under a
  lamp (tile 156), instead of "joined to the top of the level"; that also
  finds the courtyard of level 12, which is closed at the top. The grey
  diagonals inside the castle of level 16 and the grey corners at the
  bottom of level 9 are joined to the outside and have no lamp: they show
  the sky. Every level checked by a picture (scratchpad `verify/k1_LNN.png`:
  magenta sky, yellow kept grey, green wall).
- **Keen 2 has no gliding pictures any more.** `Keen2BackdropPictures`
  stays (Keen 3's docs and tests compare with its rule) but `Keen2View`
  no longer uses it.
- **`LevelWall` is a child of `LevelMap`** (z index -1) rather than a
  sibling in the scene, so every screen that draws a level has it without
  a scene change, and it follows every tile change (items, animation,
  online). Keen 3 and 4 get an empty one that draws nothing.
- **Left as in the original:** the lattice inside small gaps that do not
  pass the test (between the Yorp statues of levels 5 and 14, the glass of
  the Tantalus machines and the windows of the big white machine), and with
  xBRZ a faint edge of lattice colour around items (as around the sky's
  holes since 16-10).
- **Cost:** sorting Keen 2's 689 tiles takes about 0.6 s the first time a
  kind of level is entered (three kinds: lattice, lattice in the dark, with
  teal); Keen 1's colour rules are quick.
