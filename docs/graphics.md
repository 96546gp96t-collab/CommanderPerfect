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

## Still open

- The camera scrolls in parts of a game pixel whenever the picture is not
  the original one, also with smooth motion off.
- Whether xBRZ at 6 times needs to be larger for screens taller than 1200
  pixels (the viewport is then scaled up a little more, smoothly).
- Real-ESRGAN results have not been looked at yet; another model may suit
  the pixel art better.
