# Graphics: xBRZ, HD and smooth motion

The original game draws 320x200 pixels at about 60 frames per second. These
extras of milestone 7 change only how that picture is drawn, never how the
game plays. They are all **off by default**, so the game looks like the
original until the player switches them on:

| Option (Options menu) | Key | Values |
|---|---|---|
| Graphics | F5 | `ORIGINAL`, `XBRZ`, `HD` (HD only once the player has made it) |
| Smooth motion | F6 | `OFF`, `ON` |

Both are stored in `settings.cfg` (`graphics`, `smooth_motion`). Widescreen
(F2) is on by default, with the HUD in the top corners.

## How the picture is drawn

Everything is drawn in game pixels into the `World` viewport (`LevelView`).

- **The original picture** (original graphics, no smooth motion): the
  viewport has the size of the game picture (for example 356x200), Godot
  snaps everything to whole game pixels, and textures are filtered nearest.
  This is how it always was.
- **Otherwise** the viewport is `K` times larger, with `K` the whole number
  that makes it about as tall as the picture on screen (2 to 8). Its 2D
  contents still use game pixels (`size_2d_override` with stretch), so no
  game code needs to know `K`. Snapping is switched off: Godot snaps in game
  pixels, which would undo smooth motion. Every game pixel is still exactly
  `K` screen pixels, only the whole picture can shift by part of a pixel.

The viewport is then stretched to the window by `even_pixels.gdshader`:
inside a game pixel the color is flat, and only the one screen pixel where
two game pixels meet is mixed. Plain nearest filtering would make some game
pixels a screen pixel wider than others when the window is not a whole
multiple of the picture (very visible with the 4:3 correction of 1.2).

## Scaled graphics

`GraphicsTextures` hands out every texture (font, tiles, sprites, bitmaps,
the tile atlas, door pictures, the picture of Keen's house). With
`ScaledGraphics` it makes them from the larger images, with
`set_size_override` to the original size: the game draws them exactly where
and as large as before, the viewport just has more pixels to show them with.
Scaled textures are filtered linearly.

Images that the game makes from the originals (tiles with the gray
background removed, font characters without the white) are scaled with
xBRZ; for HD graphics they keep the HD colors and take only the
transparency from xBRZ (`ScaledGraphics.derive`).

The tile atlas (`LevelTileSet`) gives every tile a border of one pixel that
repeats its edge, so that linear filtering never picks up the neighbouring
tile in the atlas. Godot's own texture padding is off, because it would be
made from the larger image.

Masked tiles (behavior -2, Keen 2 and 3; see `docs/file-formats.md`) are
drawn by `LevelMap` on three layers: the whole tile behind the sprites, and
on a layer in front of them (`masked()`, the z index of the foreground) the
same tile through `masked_tiles.gdshader`. The shader reads the mask from
the next cell of the same atlas (after the last column: the first cell of
the next row) and keeps a pixel where the mask is darker than half. That
works for the original, xBRZ and HD atlases alike, because the mask tile is
scaled with the others. In the atlas behind a picture (below) a mask loses
its black or white where that is the level's background color; the shader
then counts those holes as black when the background is dark
(`MaskedTiles`). A level without masked tiles leaves the third layer empty.

`GraphicsLoader` makes xBRZ or reads HD graphics on worker threads (xBRZ:
one image per job, all cores, under a second); the game keeps running with
the current graphics until they are ready. What it made is kept, so
switching back is instant.

## xBRZ

`XbrzScaler` is our own implementation of the idea of xBRZ (by Zenju). It
works on the images one by one (6 times larger), with the edge pixels
repeated outside the image, so tiles still fit together.

1. **Corners.** For every 2x2 square of pixels it adds up how much the
   colors differ along each diagonal in the 4x4 pixels around it (the two
   middle pixels count 4 times). If one diagonal is clearly more alike, it
   forms a line, and the two pixels on the other diagonal get the corner
   that touches it marked for blending: *dominant* when it is at least 3.6
   times more alike, otherwise *normal*. Flat squares and edges that run
   along the pixels are skipped.
2. **Blending.** A marked corner is mixed with the neighbour color across
   the line (the one closest to the pixel itself). The neighbours decide
   the shape:
   - only a small cut off the corner (21 % of a quarter, as xBRZ does at
     2x), when another corner of the same pixel blends too (a lone pixel)
     or the corner is the inside of an L shape, unless the corner is
     dominant;
   - a shallow line (1:2, from the bottom left corner to the middle of the
     right side) or a steep one, when the colors along that direction are
     at least 2.2 times more alike; or both;
   - otherwise a 45 degree line from the middle of one side to the middle
     of the other.

   How much of each output pixel the shape covers is worked out once per
   factor (by sampling 4x4 points per pixel).

Colors are compared in YCbCr (weights of ITU-R BT.2020); colors closer than
30 (of 255) count as equal. All transparent pixels are one color, and a
difference in transparency counts fully. Because EGA has 16 colors, the
distance between every pair of colors in an image is worked out once.

## HD graphics (Real-ESRGAN)

The player makes these on their own computer; they are derived from the
original files, stay next to them in `game_data/keen1/hd/` (ignored by git)
and are never shared.

```sh
REALESRGAN=path/to/realesrgan-ncnn-vulkan tools/make_hd_graphics.sh
```

The script (needs the portable `realesrgan-ncnn-vulkan` from the Real-ESRGAN
releases on GitHub, with its `models` folder):

1. runs `tools/export_hd_sheets.gd`, which puts the graphics on sheets
   (`HdPack.write_sheets`, layout by `GraphicsSheet`): `font.png`,
   `tiles.png`, `bitmaps.png`, `sprites.png`, `sprites_mask.png` and
   `finale.png`. Each image gets a border of 4 pixels that repeats its
   edges, so the upscaler sees the image continue instead of its neighbour.
   The sheets are opaque: transparent sprite pixels take the color of the
   nearest visible one, and the transparency itself is the white-on-black
   `sprites_mask.png`, because upscalers handle color best;
2. upscales every sheet 4 times with the model `realesrgan-x4plus-anime`
   (`MODEL=` picks another one) into `game_data/keen1/hd/`, keeping the
   names;
3. copies the result next to the Mac app in `build/` as well.

`HdPack.load_from` works out the layout again from the original images
(the same images always give the same layout), checks that each sheet is a
whole multiple of it, cuts the images out and turns the upscaled mask into
transparency (soft between 0.3 and 0.7). If the folder is missing or does
not fit the game files, the game says so and stays with the original
graphics. Making the HD graphics again simply replaces the folder.

## Smooth motion

The game runs at a fixed 60 ticks per second. Without smooth motion
everything is drawn where it was at the last tick, on whole pixels. With it,
`Interpolation` keeps the positions of the last two ticks of Keen, the
actors, the ship and its marks, and every frame draws them part of the way
in between (as far as the time since the last tick goes). The camera
follows the drawn position of Keen. This makes motion smooth on 120 Hz
screens and when frames and ticks do not line up, at the cost of showing
everything one tick (17 ms) late. A move of more than 24 pixels in one tick
is a jump (a new level, a teleporter) and is not drawn in between.

## Pictures behind the levels

In widescreen a level can show a picture behind it instead of its plain
background (option *Backgrounds* in Options; on by default, by decision of
the user; on the original 4:3 screen it is always off, so the original
stays as it was). A level without a picture looks as in the original.

- **Where the pictures are.** `assets/backgrounds/levelNN.png` (or `.webp`,
  `.jpg`), NN being the level number: `level01.webp` for level 1. To try
  another picture without building the game, put one of the same name in a
  folder `backgrounds` next to the game files (such as
  `game_data/keen1/backgrounds/level01.png`, or next to the app): that one
  wins (`BackdropPictures`).
- **Which tiles it shows through.** The level's plain background is the
  tile used most that is one color only, with nothing to stand on or touch
  (in level 1 tile 143, light gray). That color is left out of every tile
  where it touches the edge of the tile, directly or through more of it, so
  the gray around candy, pillars and platforms goes and gray inside things
  stays (`GraphicsTextures.backdrop_tile_atlas`). With xBRZ or HD graphics
  the holes of the original tiles are cut out of the larger ones.
- **How it moves.** The picture covers the view in its own shape, 15%
  larger, with its top at the top of the view, so its sky and horizon are
  always in sight. From side to side it glides with the view through the
  level: the left edge of the picture at the left end of the level, its
  right edge at the right end (`LevelBackdrop`). A wider picture glides
  more and looks deeper; 3840x1080 or so suits a level like level 1 well.
  In a split screen each half has its own.
- **Keen 2, Keen 3 and Keen 4** have their own folders,
  `assets/backgrounds/keen2/`, `assets/backgrounds/keen3/` and
  `assets/backgrounds/keen4/` (Keen 3's painted by
  `tools/make_keen3_backgrounds.py`, Keen 4's by
  `tools/make_keen4_backgrounds.py`), and the player's
  `game_data/keen2/backgrounds/`, `game_data/keen3/backgrounds/` and
  `game_data/keen4/backgrounds/`, with the same file names; Keen 1's
  pictures are never shown behind their levels. Each game decides which
  levels may show one, because a picture shows through the background
  color in every tile: Keen 3 where the level has sky, and then only
  through the sky, never the dark gray of a base (levels 1-11, 13, 14 and
  15; `docs/keen3/gameplay.md`, "Extras (C9)"), Keen 4 where the top row
  of the level is sky, and then only through the sky colour (levels 5, 7-14
  and 16; `docs/keen4/gameplay.md`, "Pictures behind the levels"). Keen 2
  has no gliding pictures since AB2 (its rooms have no sky): it has walls,
  below. The painters are `tools/make_keen3_backgrounds.py` and
  `tools/make_keen4_backgrounds.py`, with their shared canvas in
  `tools/background_painter.py`.

**Keen 1's and Keen 2's pictures and walls (AB3).** Painted by our own
tools on the same canvas: `tools/make_keen1_backgrounds.py` writes Keen 1's
skies `assets/backgrounds/levelNN.webp` (levels 3, 4, 7, 8, 9, 10, 12, 13,
14, 15 and 16, in the mood of level 1's picture, which it leaves alone;
3840, 2880 or 1920 by 1080 pixels) and its walls
`assets/backgrounds/wallNN.webp` (levels 2, 5, 6, 9, 10, 11, 12, 13, 15
and 16); `tools/make_keen2_walls.py` writes Keen 2's walls
`assets/backgrounds/keen2/wallNN.webp` (levels 1-16, a wall per kind of
room). A wall is 256x256, one texture pixel per game pixel, seamless in
both directions (`Tile` in the painter), and dark enough to read both at
full light and dimmed. Running a tool again writes the same files.

### The wall fixed to the level (Keen 1 and 2, AB2)

Behind a closed room the picture is not a sky that glides but a wall that
moves 1:1 with the tiles (the user's choice of 22-10-2026; the research is
in [backgrounds/research.md](backgrounds/research.md)). Same option, same
rules: only in widescreen, on by default, 4:3 always the original, and a
level without a wall texture keeps its own background.

- **Where the textures are.** `assets/backgrounds/wallNN.webp` for Keen 1,
  `assets/backgrounds/keen2/wallNN.webp` for Keen 2 (or `.png`, `.jpg`);
  the player's `backgrounds/` folder next to the game files wins
  (`BackdropPictures.walls`). A texture repeats (seamless, any size), one
  texel per game pixel, drawn without smoothing.
- **Which pixels are wall** (`BackdropHoles`, per level, by
  `Keen1Walls` and `Keen2Walls`):
  - Keen 1: the black of the dark rooms (tile 155) by the colour rule.
    The grey (143) is the sky only outside: a grey region (cells joined
    through grey on their shared edge) under a blue lamp (tile 156) is a
    cone of light and keeps its grey, drawn from a second source of the
    tile set without the sky's holes (`LevelMap.use_wall`,
    `LevelTileSet.SKY_KEPT_SOURCE_ID`). So levels 2, 5, 6 and 11 keep every
    cone, 9, 10, 12, 13, 15 and 16 show the sky only outside, and level 1
    is exactly as before.
  - Keen 2: the lattice (tile 143) by the pattern rule (`LatticeWalls`): a
    pixel is wall where it equals the lattice at the same place, lit; where
    it equals the lattice one EGA step darker it is a wall's shadow (drawn
    at 45 %), where it equals the lattice in the dark (tile 147, levels 5
    and 14; next to a cone of light its lines sit two pixels to the right)
    the wall in the dark (35 %). A group of such pixels only counts when it
    looks like the lattice (2x2 thick, touching the tile's edge, both kinds
    of line in it, its field pixels next to its own lines), so a grey box,
    a white board or a dithered roof stays whole. The teal of level 12
    (tile 276) is wall by the colour rule.
- **How it is drawn.** `LevelWall`, a tile layer behind the tiles with the
  same cells (a child of `LevelMap`, z index -1), draws per cell the wall's
  mask of its tile (`GraphicsTextures.wall_mask_atlas`: grey as bright as
  the wall is drawn there), filled by `level_wall.gdshader` with the
  texture at the pixel's place in the level (`MODEL_MATRIX`, before the
  camera), so it never swims. It is on the level's canvas: Keen 2's
  darkness dims it, and the second half of a split screen shows it. The
  tiles get their holes from `GraphicsTextures.holes_tile_atlas` (xBRZ: the
  same holes cut from the larger tiles).
- **Only what lies behind the drawing is a hole** (fixes of 22-10, after
  the user's test). A pixel of the sky's or the wall's colour that belongs
  to a tile's own drawing stays:
  - Keen 1, grey and black shut in by the level's drawing
    (`ColorGroups`): the pixels of the colour at a tile's edge fall apart
    in groups, the groups of neighbouring cells join where they meet on the
    shared edge, and a join is open when it holds a plain cell of that
    colour (143, 155) or reaches the level's edge. A tile's group that is
    open nowhere in the level stays (`BackdropHoles.shut_in`, worked out
    per level, about 0.1 s): the grey shading under the snow platforms
    (384-386), the glass of the ice blocks, the "ID" panel of level 1, the
    black specks along a sand platform.
  - Keen 1, black is wall only where it is 2x2 thick
    (`BackdropHoles.thick_wall`): outlines of platforms, blocks and
    mushrooms stay black.
  - Keen 1, the grey triangles where a dark room's wall slants down next to
    the sky (levels 9, 10, the edges of the wide area in 16) are sky: a
    grey cell next to the dark on one side only (no dark within 4 grey
    cells on the opposite side; a block stops the search) is sky when it is
    joined to the sky, however far (`Keen1Walls`); narrow grey strips
    between dark walls stay grey, as before.
  - Keen 2, items (`TileProperties.is_item`): the lattice around them is
    every pixel equal to the lattice at its place and joined to the tile's
    edge (`LatticeWalls.item_background`); items have a dark outline, so it
    stops there. Other tiles with lattice wall lose the lattice along their
    edge the same way, up to 2 pixels in (`LatticeWalls.edge_strip`).
  - Keen 2, windows (masked tiles whose next tile is their mask; in the
    levels 403-422, in levels 6, 7 and 9): the wall shows through the glass
    (the user's choice of 22-10, `BackdropHoles.windows`,
    `window_kinds`). The pixels the mask draws in front of Keen (the white
    glass streaks and the frame) stay, behind and in front of Keen; every
    other pixel that equals the lattice at its place is the wall, lit or,
    in the frame's shadow under its top edge, shadowed
    (`LatticeWalls.pixel_kinds`; a pixel that is lit by chance in that
    shadow joins it). So the wall layer fills the glass with the same
    texture as the cells around it, Keen is seen through the glass in front
    of the wall, and the streaks pass over him. The mask tiles themselves
    are never cut (the masked layer reads them), and a masked tile whose
    see-through part is mostly not the lattice is drawn whole. With xBRZ
    the holes are cut from the larger tile as everywhere; the masked layer
    then draws where the scaled mask is black and the tile is not cut. In
    4:3, and with the pictures off, the window is the original: the lattice
    behind the glass. Before (964f9a8) the speck rule took the one-pixel
    streaks for lattice and the glass vanished; then the window was drawn
    whole, with the old lattice behind the glass.
  - The second round of 22-10 (the user's next test), for every tile:
    - Keen 2, a strip of lattice (lit or shadowed, at least 4 pixels, at
      most 2 pixels from the edge, touching it) with only black or wall
      around it inside the tile is the wall (`LatticeWalls.framed_strips`):
      the two columns at the ends of the thick red beam (225, 227).
    - Keen 2, a thin shadow that holds no darkened white line joins the
      shadow beside it, and then the black pixels it surrounds (counting
      grey wall only): the right end of the shadow under the small
      platforms (177-181).
    - Keen 2, a straight line (row or column, at least 6 pixels) of one
      colour that goes on past a place where it is not the lattice, up to
      another such place or the tile's edge, is the drawing and never wall
      (`LatticeWalls.drawing_runs`, inside the pattern rule and after the
      item, edge and strip rules): the exit door's frame (160, 162-164)
      stays straight, the bands of level 12's machine and the white
      pillars stay whole. A field run that meets a thing of its colour on
      one side only stays lattice.
    - Keen 2, a lone pixel becomes wall only in a kind whose colours it has
      and that at least two of its neighbours have: the black arms of the
      zapper (169-172) are no lit lattice.
    - Every frame of an animation gets the holes of the other frames where
      it shows the same pixel (`BackdropHoles.share_between_frames`, in
      `GraphicsTextures.hole_kinds`): the lattice between the zapper's arms
      is the wall also in the frames where the spark shuts it in.
    - Keen 1, the black a block's drawing holds (a solid tile: more than
      half of the group has another colour on both sides in its row or
      column) or a black face held almost all round (90 %, at least 64
      pixels) stays black (`BackdropHoles.block_tiles`, `_without_held`):
      the bottom triangle of the dark studded blocks (290), the exit sign
      (167, 168). Fire and the dark around things are not held.
    - Shut-in pixels per animation step (`ColorGroups.shut_in_every_step`):
      each frame of an animated tile gets its own groups (the exit sign's
      second frame, the "ID" panel's frames, the vines of levels 7 and 14);
      Keen 1 level start now ~0.3-0.4 s with the pictures on.
    - Keen 2 level 12: teal that the level shuts in stays (the exit door).
    - Keen 1, the light that falls through a gap in a wall of blocks into a
      dark room (`Keen1Walls._close_inside_gaps`): a gap is grey of at most
      3 cells between two blocks that end a thin wall; the grey beyond it
      that lies mostly next to the dark and turns grey somewhere is grey
      from the wall on, the gap itself and the step just outside it show
      the sky (level 16, the castle's outer wall at x 86).
  - The HUD (`Hud.background_tile`, Keen 2: 143) leaves out the lattice
    around the raygun and the keycards the same way
    (`GraphicsTextures.clear_tile_on`); Keen 1 keeps its grey rule, Keen 3
    its own (`Keen3Hud`).

## Still open

- The camera scrolls in parts of a game pixel whenever the picture is not
  the original one, also with smooth motion off.
- Whether xBRZ at 6 times needs to be larger for screens taller than 1200
  pixels (the viewport is then scaled up a little more, smoothly).
- Real-ESRGAN (`realesrgan-x4plus-anime`, v0.2.5.0 in `tools/realesrgan/`)
  has been tried on 14-10-2026: it works in the game, but looks "painted",
  and flat colors differ slightly per tile, so faint squares show on the
  world map and around items. The user finds it ugly and prefers xBRZ, but
  misses new details. See the plan below.

## Plan: HD with new details (parked)

Real-ESRGAN only sharpens what is there; it cannot add details. For new
details (texture in stone, shine on pipes, folds in Keen's clothes) a
generative model is needed. The user parked this on 14-10-2026; the plan
for when we pick it up again:

1. **Base:** the xBRZ images (the user likes those; the shapes are clean).
2. **Add detail:** Stable Diffusion img2img on top of the base, with a
   ControlNet "tile" model so that shapes, colors and positions stay put,
   a low denoise strength (about 0.3-0.45) and a prompt per kind of image
   (for example "cartoon sci-fi metal pipes, clean outlines"). Run locally
   with PyTorch on Apple's MPS (torch 2.8 is installed; 16 GB RAM, so SD 1.5
   rather than SDXL; SDXL only if 1.5 falls short).
3. **Into the game:** write the results as the sheets of the HD folder
   (`HdPack`), so the game needs no change. The sprite transparency comes
   from the xBRZ mask, not from the model.

Known problems to solve:

- **Animation:** each walking frame of Keen or a Yorp would get different
  details and flicker. Use a fixed seed, low denoise, and perhaps all frames
  of one animation side by side in one image.
- **Tiles that meet:** details must run on across the edges. Generate each
  tile with copies of itself around it (3x3) and keep the middle, so walls
  and floors stay seamless; tiles that belong together (big objects of
  several tiles) as one piece.
- **Colors:** keep them close to the EGA palette, so flat areas do not get
  the faint squares Real-ESRGAN gave.
- **Cost:** about 6 GB of models (SD 1.5 + ControlNet Tile, from Hugging
  Face, into a folder git ignores, like `tools/realesrgan/`), and probably a
  few hours for the 611 tiles and 119 sprites.

First step: ask the user to approve the download, then a trial of about ten
images (Keen standing and walking, a Yorp, a few tiles of level 1 and the
world map) shown side by side with xBRZ, before doing everything.
