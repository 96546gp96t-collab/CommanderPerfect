#!/usr/bin/env python3
"""Paints the pictures behind Keen 1's levels into assets/backgrounds/.

Our own pictures, drawn from code with tools/background_painter.py: nothing
in them comes from the game files, and nothing follows a level's shape.
Two kinds (docs/backgrounds/research.md):

- **Skies** (`levelNN.webp`) glide behind the outside levels, as the user's
  own picture behind level 1 does (that one is not painted here and stays as
  it is). The same mood as that picture: a starry Martian night, a range of
  mountains, grey hills with small domes and the flat plain in front, in
  flat colours with dark outlines, finer than the chunky pictures of Keen 3
  and 4. Each city its own: icy mountains and snow behind Ice City and the
  ice shrines, green crystal behind Emerald City, red rock behind the Red
  Maze City, a darker sky with a far castle behind the Vorticon
  Commander's castle, other Martian landscapes behind the rest. The lower
  part sits behind the level's ground.
- **Walls** (`wallNN.webp`) are fixed behind the black of the dark rooms
  (LevelWall), seamless, at one texture pixel per game pixel: red rock for
  the Red Rock Shrines and the Pogo Shrine, cold blue-grey stone for the
  ice shrines, dark rock for the tunnel of the Red Maze City, dark stone and
  iron for the castle. They stay dark, so the rooms still feel dark and the
  grey light cones under the lamps stay the brightest thing in them.

Usage:
    python3 tools/make_keen1_backgrounds.py [OUT_DIR]

Needs Pillow and NumPy. The same pictures come out every time (fixed seeds).
"""

import math
import os
import sys

import numpy as np

from background_painter import Canvas, Tile, rgb

# Walls -----------------------------------------------------------------------

# Every wall texture is this large, a multiple of the 16-pixel tiles.
WALL_SIZE = 256


class Stone:
    """The colours of one kind of stone: a few faces, their lit and shaded
    edges, the joints between the stones and flecks in them."""

    def __init__(self, faces, light, shade, joint, fleck, frost=None):
        self.faces = faces
        self.light = light
        self.shade = shade
        self.joint = joint
        self.fleck = fleck
        self.frost = frost


RED_ROCK = Stone((0x2E1714, 0x281412, 0x341A16), 0x44231D, 0x1C0E0C, 0x0C0606, 0x22110F)
MAZE_ROCK = Stone((0x341411, 0x2E1210, 0x3A1813), 0x4E2019, 0x1E0B0A, 0x0E0506, 0x28100E)
ICE_STONE = Stone(
    (0x1E2530, 0x1B212B, 0x222A36), 0x313C4C, 0x12161E, 0x090B10, 0x181E27, frost=0x4A5E74
)
ICE_ROCK = Stone(
    (0x1C2632, 0x19222C, 0x202B38), 0x2E4050, 0x111820, 0x080B10, 0x161E28, frost=0x48627A
)
DARK_STONE = Stone((0x282422, 0x24211F, 0x2C2826), 0x3C3632, 0x1A1716, 0x0C0B0A, 0x201D1B)
CASTLE_STONE = Stone((0x2A2A32, 0x26262E, 0x2E2E37), 0x40404C, 0x1A1A21, 0x0C0C10, 0x222229)
# The iron bands of the castle wall.
IRON = 0x2C3036
IRON_LIT = 0x4A5058
IRON_DARK = 0x16181C


def _masonry(t, stone, row_height, widths, flecks=0.04, cracks=6):
    """Rows of cut stones of random widths, each row shifted, with lit top
    and left edges, shaded bottom and right edges, chipped corners, flecks
    and a few cracks."""
    for row in range(t.h // row_height):
        y = row * row_height
        x = int(t.rng.integers(0, t.w))
        left = t.w
        while left > 0:
            width = int(t.rng.choice(widths))
            width = left if left - width < min(widths) else width
            face = stone.faces[int(t.rng.integers(0, len(stone.faces)))]
            t.bevel(x, y, width, row_height, face, stone.light, stone.shade, seam=stone.joint)
            t.speckle(x + 1, y + 1, width - 3, row_height - 3, stone.fleck, flecks)
            for cx, cy in ((x, y), (x + width - 2, y), (x, y + row_height - 2)):
                if t.rng.random() < 0.4:
                    t.dot(cx, cy, stone.joint)
            if stone.frost is not None:
                _frost(t, x, y, width, stone)
            x += width
            left -= width
    for _ in range(cracks):
        _crack(t, stone)


def _frost(t, x, y, width, stone):
    """Rime along the top of a stone and a short icicle now and then."""
    for k in range(1, width - 2):
        if t.rng.random() < 0.18:
            t.dot(x + k, y, stone.frost)
    if t.rng.random() < 0.3:
        k = int(t.rng.integers(2, max(3, width - 3)))
        for d in range(int(t.rng.integers(1, 4))):
            t.dot(x + k, y + d, stone.frost)


def _crack(t, stone):
    """A thin crack wandering down through the stones."""
    x, y = int(t.rng.integers(0, t.w)), int(t.rng.integers(0, t.h))
    for _ in range(int(t.rng.integers(6, 16))):
        t.dot(x, y, stone.joint)
        t.dot(x + 1, y, stone.shade)
        x += int(t.rng.integers(-1, 2))
        y += 1


def _spaced_points(t, count, spacing):
    """Up to `count` random points at least `spacing` apart, also across
    the edges of the texture, so that no lump of rock is too small."""
    points = []
    for _ in range(count * 30):
        x, y = t.rng.random() * t.w, t.rng.random() * t.h
        clear = True
        for px, py in points:
            dx = min(abs(x - px), t.w - abs(x - px))
            dy = min(abs(y - py), t.h - abs(y - py))
            if dx * dx + dy * dy < spacing * spacing:
                clear = False
                break
        if clear:
            points.append((x, y))
            if len(points) == count:
                break
    return np.array(points)


def _rough_rock(t, stone, count, spacing, flecks=0.05):
    """Natural rock: rounded lumps of stone (cells around scattered points,
    measured around the edges so that the texture repeats) with dark cracks
    between them, each lump lit on its upper left and shaded on its lower
    right."""
    points = _spaced_points(t, count, spacing)
    count = len(points)
    ys, xs = np.mgrid[0 : t.h, 0 : t.w]
    near = np.full((t.h, t.w), np.inf)
    second = np.full((t.h, t.w), np.inf)
    owner = np.zeros((t.h, t.w), dtype=int)
    for i, (px, py) in enumerate(points):
        dx = np.abs(xs - px)
        dy = np.abs(ys - py)
        d = np.hypot(np.minimum(dx, t.w - dx), np.minimum(dy, t.h - dy) * 1.3)
        closer = d < near
        second = np.where(closer, near, np.minimum(second, d))
        owner = np.where(closer, i, owner)
        near = np.where(closer, d, near)
    edge = second - near
    # A lump's height: rising from its cracks, flat on top.
    height = np.minimum(edge, 6.0)
    faces = t.rng.integers(0, len(stone.faces), count)
    for i in range(count):
        t.mask(owner == i, stone.faces[faces[i]])
    t.speckle(0, 0, t.w, t.h, stone.fleck, flecks)
    toward_light = height - np.roll(np.roll(height, 1, axis=0), 1, axis=1)
    t.mask(toward_light > 0.9, stone.light)
    t.mask(toward_light < -0.9, stone.shade)
    t.mask(edge < 1.0, stone.joint)
    if stone.frost is not None:
        t.mask((toward_light > 0.9) & (t.rng.random((t.h, t.w)) < 0.3), stone.frost)


def _chisel(t, stone, count):
    """Short slanting marks left by the tools that cut the rock."""
    for _ in range(count):
        x, y = int(t.rng.integers(0, t.w)), int(t.rng.integers(0, t.h))
        for k in range(int(t.rng.integers(2, 4))):
            t.dot(x + k, y + k, stone.shade)


def _iron_band(t, y):
    """A riveted iron band across the castle wall."""
    t.rect(0, y, t.w, 6, IRON)
    t.rect(0, y, t.w, 1, IRON_LIT)
    t.rect(0, y + 5, t.w, 1, IRON_DARK)
    for x in range(6, t.w, 16):
        t.dot(x, y + 2, IRON_LIT)
        t.dot(x + 1, y + 3, IRON_DARK)


def shrine_wall(t):
    """The Red Rock Shrines: large blocks hewn from dark red rock, with the
    marks of the chisel on them."""
    _masonry(t, RED_ROCK, 32, (40, 48, 64, 80), flecks=0.05, cracks=8)
    _chisel(t, RED_ROCK, 90)


def pogo_wall(t):
    """The Pogo Shrine and the shrine of 12: rough red rock."""
    _rough_rock(t, RED_ROCK, 130, 15)


def ice_wall(t):
    """The ice shrines: cold blue-grey blocks with rime on them."""
    _masonry(t, ICE_STONE, 16, (32, 40, 48, 56), cracks=4)


def ice_rock_wall(t):
    """The second ice shrine: rough cold rock with rime on it."""
    _rough_rock(t, ICE_ROCK, 110, 16)


def tunnel_wall(t):
    """The tunnel under the Red Maze City: rough dark red rock."""
    _rough_rock(t, MAZE_ROCK, 160, 13)


def stone_wall(t):
    """The dark room of level 15: old grey-brown stone blocks."""
    _masonry(t, DARK_STONE, 16, (16, 24, 32, 40), flecks=0.05)


def castle_wall(t):
    """The castle: even blocks of dark stone in a running bond, with iron
    bands across them."""
    for row in range(t.h // 16):
        offset = 16 if row % 2 else 0
        for x in range(offset, t.w + offset, 32):
            face = CASTLE_STONE.faces[int(t.rng.integers(0, 3))]
            t.bevel(x, row * 16, 32, 16, face, CASTLE_STONE.light, CASTLE_STONE.shade,
                    seam=CASTLE_STONE.joint)
            t.speckle(x + 1, row * 16 + 1, 29, 13, CASTLE_STONE.fleck, 0.04)
    for _ in range(5):
        _crack(t, CASTLE_STONE)
    _iron_band(t, 61)
    _iron_band(t, 189)


# Level number: the wall behind the black of its dark rooms.
WALLS = {
    2: shrine_wall,
    5: pogo_wall,
    6: shrine_wall,
    9: ice_wall,
    10: ice_rock_wall,
    11: shrine_wall,
    12: pogo_wall,
    13: tunnel_wall,
    15: stone_wall,
    16: castle_wall,
}

# Skies -----------------------------------------------------------------------

# The skies are painted finer than Keen 3's and 4's, as level 1's picture
# is: 270 rows blown up 4 times give 1080 screen rows.
SKY_HEIGHT = 270
SKY_PIXEL = 4
# 3840, 2880 and 1920 screen pixels wide: the wider the level, the wider
# its picture, so that it glides further.
SKY_WIDE = 960
SKY_MEDIUM = 720
SKY_NARROW = 480
# Where the plain meets the hills, from the top: the game shows the top 87%
# of the picture, so the horizon sits about three quarters down the view.
HORIZON = 0.63


class Rock:
    """The colours of a mountain range: its peaks lit on the left and in
    shade on the right, the dark body of the range under them, and the
    outline around it all."""

    def __init__(self, lit, shade, body, outline):
        self.lit = lit
        self.shade = shade
        self.body = body
        self.outline = outline


class Hills:
    """The colours of the rounded hills in front of the mountains."""

    def __init__(self, face, lit, dark, outline, pit):
        self.face = face
        self.lit = lit
        self.dark = dark
        self.outline = outline
        self.pit = pit


class Domes:
    """The colours of the domes and towers of a Martian town."""

    def __init__(self, face, lit, dark, outline, window):
        self.face = face
        self.lit = lit
        self.dark = dark
        self.outline = outline
        self.window = window


class Plain:
    """The colours of the flat plain in front."""

    def __init__(self, face, dash, light, edge):
        self.face = face
        self.dash = dash
        self.light = light
        self.edge = edge


# Level 1's own colours: magenta needles on a dark purple range, grey
# hills, grey-blue domes and the brownish-red plain.
NIGHT = 0x020474
MAGENTA = Rock(0xB0088A, 0x7C066A, 0x480064, 0x000008)
GREY_HILLS = Hills(0x707070, 0x8C8C88, 0x4A4A4A, 0x000008, 0x2C2C2C)
DOMES = Domes(0x7A989C, 0xB0CCCC, 0x4A6468, 0x000008, 0xFFE07A)
MARS = Plain(0x683838, 0x7E2A2A, 0x7A4A46, 0x3A1418)


def _night(c, colour, glow=None, glow_from=0.45):
    """A flat night sky, optionally warmer towards the horizon in a few
    dithered steps."""
    c.px[:, :] = rgb(colour)
    if glow is None:
        return
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    t = np.clip((ys / c.h - glow_from) / (HORIZON - glow_from), 0, 1)
    pattern = ((xs + ys) % 2) * 0.5 + (ys % 2) * 0.25
    for step, amount in ((0.25, 0.25), (0.5, 0.5), (0.75, 0.75)):
        band = t + pattern * 0.25 > step + 0.12
        c.px[band] = c.px[band] * (1 - amount * 0.5) + rgb(glow) * amount * 0.5


def _stars(c, count, bottom, colours=(0xFFFFFF, 0x9AE8FF, 0xFF7AD0)):
    """Small stars: single dots in a few colours, some of them four-pointed
    crosses with a white heart."""
    for _ in range(count):
        x = int(c.rng.integers(1, c.w - 1))
        y = int(c.rng.integers(1, int(bottom * c.h)))
        roll = c.rng.random()
        colour = colours[int(c.rng.integers(0, len(colours)))]
        if roll < 0.1:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                c._dot(x + dx, y + dy, rgb(0x9AE8FF))
            c._dot(x, y, rgb(0xFFFFFF))
        elif roll < 0.6:
            c._dot(x, y, rgb(colour))
        else:
            c._dot(x, y, (c.px[y, x] + rgb(colour)) / 2)


def _moon(c, cx, cy, r, face, dark, light=None, craters=5):
    """A moon or planet: a round disc with a dark outline, a lit edge on its
    upper left and craters a little darker than its face."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    d = np.hypot(xs - cx, ys - cy)
    c.px[d < r + 1] = rgb(dark)
    c.px[d < r] = rgb(face)
    if light is not None:
        lit = (d < r - 1) & (np.hypot(xs - cx + r * 0.25, ys - cy + r * 0.25) > r * 0.8)
        lit &= (xs < cx) & (ys < cy + r * 0.2)
        c.px[lit] = rgb(light)
    pit = (rgb(face) * 2 + rgb(dark)) / 3
    for _ in range(craters):
        a = c.rng.random() * math.tau
        dist = c.rng.random() * r * 0.6
        cr = max(1.0, r * (0.1 + 0.12 * c.rng.random()))
        hit = np.hypot(xs - cx - np.cos(a) * dist, ys - cy - np.sin(a) * dist) < cr
        c.px[hit & (d < r - 1)] = pit


def _spires(c, base, clusters, tall, width=(6, 14), sharp=1.35, ridge=0.06):
    """A range of needle peaks, as behind level 1: a low, jagged ridge (the
    body of the range) with clusters of pointed peaks rising from it, the
    middle one of a cluster the tallest. Returns the skyline and the ridge."""
    body = np.minimum(np.round(c.ridge(base - ridge, 0.66, ridge * 0.45)), base * c.h - 2)
    line = body.copy()
    x = np.arange(c.w, dtype=float)
    for _ in range(clusters):
        centre = c.rng.random() * c.w
        top = tall * c.h * (0.4 + 0.6 * c.rng.random())
        peaks = [(centre, top)]
        for _ in range(int(c.rng.integers(2, 6))):
            side = c.rng.uniform(4, 20) * (1 if c.rng.random() < 0.5 else -1)
            peaks.append((centre + side, top * c.rng.uniform(0.25, 0.7)))
        for px, height in peaks:
            half = c.rng.uniform(*width)
            k = np.clip(1 - np.abs(x - px) / half, 0, 1)
            line = np.minimum(line, body - height * k**sharp)
    line = np.round(line)
    # The foot of a peak that hardly rises above the ridge is the ridge.
    return np.where(body - line < 3, body, line), body


def _range(c, line, body, bottom, rock, streaks=0.25):
    """Paints a range of peaks: lit on their left faces, in shade on their
    right, with vertical streaks down them; the body of the range under the
    peaks in its own dark colour; a dark outline around it all."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    land = (ys >= line[xs]) & (ys < bottom * c.h)
    slope = np.roll(line, -1) - np.roll(line, 1)
    c.px[land] = rgb(rock.lit)
    c.px[land & (slope[xs] > 0.5)] = rgb(rock.shade)
    for _ in range(int(c.w * streaks)):
        x = int(c.rng.integers(0, c.w))
        top = int(line[x]) + int(c.rng.integers(2, 8))
        length = int(c.rng.integers(4, 20))
        colour = rock.shade if slope[x] <= 0.5 else rock.lit
        c.px[top : min(top + length, int(body[x])), x] = rgb(colour)
    peaks = land & (ys < body[xs])
    rim = peaks & np.roll(~land, 2, axis=1) & (slope[xs] <= 0.5)
    c.px[rim] = (rgb(rock.lit) * 2 + rgb(0xFFFFFF)) / 3
    c.px[land & (ys >= body[xs])] = rgb(rock.body)
    _outline(c, land, rock.outline)


def _mesas(c, base, count, tall, width=(18, 50)):
    """A skyline of flat-topped buttes with steep, slightly stepped cliffs
    and a slope of fallen stone at their feet."""
    x = np.arange(c.w, dtype=float)
    line = np.full(c.w, base * c.h)
    for _ in range(count):
        px = c.rng.random() * c.w
        half = c.rng.uniform(*width)
        height = tall * c.h * (0.45 + 0.55 * c.rng.random())
        top = base * c.h - height
        out = np.clip(np.abs(x - px) - half, 0, None)
        cliff = top + np.round(out * 5 / 3) * 3
        talus = base * c.h - height * 0.35 + out * 0.5
        line = np.minimum(line, np.minimum(cliff, talus))
    return np.round(line + np.round(c.rng.normal(0, 0.35, c.w)))


def _land(c, line, bottom, face, lit, shade, outline, streaks=0.0, smooth=1):
    """Paints the land under a skyline down to row `bottom`: the faces that
    look to the left lit, those to the right in shade, optional vertical
    streaks of light and shade down the slopes, and a dark outline along the
    top. Returns the mask of the land."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    land = (ys >= line[xs]) & (ys < bottom * c.h)
    slope = np.convolve(np.roll(line, -1) - np.roll(line, 1), np.ones(smooth) / smooth, "same")
    c.px[land] = rgb(face)
    c.px[land & (slope[xs] < -0.5)] = rgb(lit)
    c.px[land & (slope[xs] > 0.5)] = rgb(shade)
    if streaks > 0:
        for _ in range(int(c.w * streaks)):
            x = int(c.rng.integers(0, c.w))
            top = int(line[x]) + int(c.rng.integers(1, 6))
            length = int(c.rng.integers(4, 26))
            colour = lit if c.rng.random() < 0.5 else shade
            c.px[top : min(top + length, int(bottom * c.h)), x] = rgb(colour)
    _outline(c, land, outline)
    return land


def _outline(c, region, colour):
    """A dark line along the edge of `region` where it meets what is around
    it above or beside it."""
    above = np.roll(region, 1, axis=0)
    left = np.roll(region, 1, axis=1)
    right = np.roll(region, -1, axis=1)
    edge = region & ~(above & left & right)
    edge[0, :] = False
    c.px[edge] = rgb(colour)


def _snow(c, line, body, depth, colour, shade):
    """Snow on the peaks of a range: deeper the higher a peak rises above
    the ridge, in shade on the faces that look away from the light."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    cap = np.clip((body - line - 3) * depth, 0, None)
    hit = (ys >= line[xs] + 1) & (ys < line[xs] + 1 + cap[xs])
    jag = (xs * 7 + ys * 3) % 5 == 0
    hit &= ~(jag & (ys > line[xs] + cap[xs] - 3))
    slope = np.roll(line, -1) - np.roll(line, 1)
    c.px[hit] = rgb(colour)
    c.px[hit & (slope[xs] > 0.5)] = rgb(shade)


def _mounds(c, base, count, hills, tall=0.06, width=(18, 42), craters=True):
    """Rounded hills, one behind the other, each with its own outline: lit
    along its top on the left, darker on its lower right, rough with little
    stones and dotted with craters. Returns their skyline."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    line = np.full(c.w, base * c.h)
    ground = int(base * c.h)
    for _ in range(count):
        cx = c.rng.random() * c.w
        half = c.rng.uniform(*width)
        height = tall * c.h * (0.45 + 0.55 * c.rng.random())
        for shift in (-c.w, 0, c.w):
            u = (xs - cx - shift) / half
            inside = np.abs(u) < 1
            prof = height * np.clip(1 - u**2, 0, 1) ** 0.6
            top = np.round(base * c.h - prof)
            mound = inside & (ys >= top) & (ys < ground)
            if not mound.any():
                continue
            depth = (ys - top) / np.maximum(prof, 1)
            c.px[mound] = rgb(hills.face)
            c.px[mound & (u * 0.8 + depth * 0.5 > 0.85)] = rgb(hills.dark)
            c.px[mound & (ys <= top + 2) & (u < 0.15)] = rgb(hills.lit)
            stones = mound & (c.rng.random(mound.shape) < 0.03) & (depth > 0.2)
            c.px[stones] = rgb(hills.dark)
            _outline(c, mound, hills.outline)
            line = np.minimum(line, np.where(inside[0], top[0], line))
            if craters:
                _hill_craters(c, cx + shift, half, base * c.h, height, hills)
    return line


def _hill_craters(c, cx, half, ground, height, hills):
    """A few craters on a hill: a dark hollow with a dark rim above and a
    lit rim below."""
    for _ in range(int(c.rng.integers(1, 4))):
        x = int(cx + c.rng.uniform(-0.6, 0.6) * half)
        reach = height * (1 - ((x - cx) / half) ** 2) ** 0.6
        if reach < 7:
            continue
        y = int(ground - reach * c.rng.uniform(0.3, 0.75))
        w = int(c.rng.integers(5, 10))
        left = x - w // 2
        c._rect(left + 1, y, w - 2, 1, hills.outline)
        c._rect(left, y + 1, w, 2, hills.outline)
        c._rect(left + 1, y + 1, w - 2, 2, hills.pit)
        c._rect(left + 1, y + 3, w - 2, 1, hills.outline)
        c._rect(left + 2, y + 4, w - 3, 1, hills.lit)


def _dome(c, cx, ground, r, domes, mast=True):
    """A dome on a low ring with windows: lit on its left, ribbed, with a
    dark outline and sometimes a mast on top."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    rise = r * 0.75
    foot = ground - 3
    shell = (np.hypot((xs - cx) / r, (ys - foot) / rise) < 1) & (ys <= foot)
    c.px[shell] = rgb(domes.face)
    c.px[shell & (xs < cx - r * 0.3) & (ys < foot - 1)] = rgb(domes.lit)
    c.px[shell & (xs > cx + r * 0.5)] = rgb(domes.dark)
    for rib in (-0.45, 0.0, 0.45):
        rx = int(round(cx + rib * r))
        c.px[shell & (xs == rx) & (ys > foot - rise * math.sqrt(1 - rib * rib) + 1)] = rgb(
            domes.dark
        )
    ring = (np.abs(xs - cx) <= r) & (ys > foot) & (ys <= ground)
    c.px[ring] = rgb(domes.dark)
    c.px[ring & (ys == foot + 2) & ((xs - int(cx)) % 3 == 0)] = rgb(domes.window)
    _outline(c, shell | ring, domes.outline)
    if mast:
        top = int(foot - rise)
        c._rect(int(cx), top - 6, 1, 6, domes.outline)
        c._dot(int(cx), top - 7, rgb(domes.lit))


def _tower(c, x, ground, height, domes):
    """A slim tower with a pointed top and a lit window."""
    c._rect(x - 1, ground - height, 5, height, domes.outline)
    c._rect(x, ground - height + 1, 3, height - 1, domes.face)
    c._rect(x, ground - height + 1, 1, height - 1, domes.lit)
    for k in range(4):
        c._rect(x + 1 - k // 2, ground - height - 4 + k, 1 + (k // 2) * 2, 1, domes.outline)
    c._dot(x + 1, ground - height + 3, rgb(domes.window))


def _town(c, hills, places, domes, sizes=(8, 12), towers=0.5):
    """Domes, and some towers beside them, standing on the hills."""
    for i, x in enumerate(places):
        r = int(c.rng.integers(sizes[0], sizes[1] + 1))
        ground = c.footing(hills, x - r, 2 * r + 1)
        _dome(c, x, ground, r, domes, mast=i % 2 == 0)
        if c.rng.random() < towers:
            tx = x + r + 4
            _tower(c, tx, c.footing(hills, tx - 1, 5), int(c.rng.integers(10, 18)), domes)


def _plain(c, top, plain):
    """The flat plain from the horizon down, with short darker dashes that
    grow longer towards the front, and a few lighter pebbles."""
    y0 = int(top * c.h)
    c._rect(0, y0, c.w, c.h - y0, plain.face)
    c._rect(0, y0, c.w, 1, plain.edge)
    for _ in range(int(c.w * 0.5)):
        y = int(c.rng.integers(y0 + 2, c.h))
        near = (y - y0) / (c.h - y0)
        length = int(2 + near * 8 * c.rng.random())
        c._rect(int(c.rng.integers(0, c.w)), y, length, 1, plain.dash)
    for _ in range(int(c.w * 0.08)):
        y = int(c.rng.integers(y0 + 3, c.h))
        c._rect(int(c.rng.integers(0, c.w)), y, 2, 1, plain.light)


def _spread(c, count, jitter=0.4):
    """`count` places spread across the picture, a little irregular."""
    return [int((i + 0.5 + (c.rng.random() - 0.5) * jitter) * c.w / count) for i in range(count)]


def _martian_front(c, places, hills=GREY_HILLS, domes=DOMES, plain=MARS, count=None):
    """What most skies have in front: grey hills with a town of domes on
    them, and the plain."""
    line = _mounds(c, HORIZON, count or c.w // 45, hills)
    _town(c, line, places, domes)
    _plain(c, HORIZON, plain)
    return line


# The scenes, one per level ----------------------------------------------------

# Red rock buttes.
MESA = 0x84402C
MESA_LIT = 0xA45838
MESA_DARK = 0x5A2A1E
MESA_LAYER = 0x6E3424


def level03(c):
    """Rust-coloured buttes under two small moons; a few domes on the hills
    in front."""
    _night(c, NIGHT, glow=0x3A1A6A)
    _stars(c, c.w // 3, 0.55)
    _moon(c, c.w * 0.18, c.h * 0.16, 8, 0xC8A88A, 0x4A3A3A, 0xE8D0B0, craters=3)
    _moon(c, c.w * 0.72, c.h * 0.26, 4, 0xB09A90, 0x4A3A3A, 0xD8C4B8, craters=1)
    far = _mesas(c, HORIZON - 0.02, c.w // 70, 0.2)
    _land(c, far, HORIZON, MESA, MESA_LIT, MESA_DARK, MAGENTA.outline)
    _strata(c, far, HORIZON, MESA_LAYER)
    _martian_front(c, _spread(c, 5))


def _strata(c, line, bottom, colour):
    """Layers in the rock of the buttes: broken horizontal lines."""
    for y in range(int(line.min()) + 6, int(bottom * c.h) - 2, 7):
        run = 0
        for x in range(c.w):
            if run <= 0:
                run = int(c.rng.integers(-6, 14))
            if run > 0 and line[x] + 2 < y:
                c._dot(x, y, rgb(colour))
            run -= 1


def level04(c):
    """The capital: magenta needle mountains as behind level 1, and a larger
    town of domes and towers with lit windows; the blue-green Earth high in
    the sky."""
    _night(c, NIGHT)
    _stars(c, c.w // 3, 0.6)
    _moon(c, c.w * 0.86, c.h * 0.14, 12, 0x3A70C8, 0x101A40, 0x7AA8E8, craters=0)
    _patches(c, c.w * 0.86, c.h * 0.14, 12, 0x3A9A5A)
    _range(c, *_spires(c, HORIZON - 0.02, c.w // 36, 0.24), HORIZON, MAGENTA)
    hills = _martian_front(c, _spread(c, 11), count=c.w // 36)
    for x in _spread(c, 7):
        _tower(c, x + 16, c.footing(hills, x + 15, 5), int(c.rng.integers(14, 24)), DOMES)


def _patches(c, cx, cy, r, colour):
    """Land on a small planet: a few blots inside its disc."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    disc = np.hypot(xs - cx, ys - cy) < r - 1
    for _ in range(4):
        px = cx + (c.rng.random() - 0.5) * r
        py = cy + (c.rng.random() - 0.5) * r
        c.px[disc & (np.hypot(xs - px, (ys - py) * 1.4) < r * 0.35)] = rgb(colour)


EMERALD = Rock(0x48D890, 0x1A8A5A, 0x0C4A3C, 0x02140E)
GREEN_DOMES = Domes(0x5AA88A, 0x9AE8C0, 0x2E6A54, 0x000008, 0x9AFFB0)
OCHRE = Plain(0x5E4434, 0x4A3226, 0x74584A, 0x2A1A12)


def level07(c):
    """Emerald City: straight-sided crystal spires of green, glinting at
    their tips, with green-lit domes on the hills."""
    _night(c, 0x041060, glow=0x0A3A4A)
    _stars(c, c.w // 3, 0.6, colours=(0xFFFFFF, 0x9AFFD0, 0x9AE8FF))
    _moon(c, c.w * 0.3, c.h * 0.15, 9, 0xB8E8C8, 0x14403A, 0xE0FFF0, craters=4)
    line, body = _spires(c, HORIZON - 0.02, c.w // 30, 0.28, width=(4, 10), sharp=1.0)
    _range(c, line, body, HORIZON, EMERALD, streaks=0.3)
    _glints(c, line, 0xC8FFE0)
    _martian_front(c, _spread(c, 7), domes=GREEN_DOMES, plain=OCHRE)


def _glints(c, line, colour):
    """Light caught on the tips of crystals."""
    for x in range(1, c.w - 1):
        if line[x] < line[x - 1] and line[x] <= line[x + 1] and c.rng.random() < 0.7:
            c._dot(x, int(line[x]) + 1, rgb(colour))
            c._dot(x, int(line[x]) + 2, rgb(colour))


# Ice and snow.
ICE = Rock(0x6A8ACC, 0x4A62A6, 0x2A3A70, 0x0A1030)
SNOW = 0xE8F4FF
SNOW_SHADE = 0xA8C0E0
SNOW_HILLS = Hills(0xB8CCE0, 0xE8F2FC, 0x8AA0C0, 0x1A2440, 0x6A80A0)
ICE_DOMES = Domes(0xD0E0EC, 0xFFFFFF, 0x8AA8C8, 0x1A2440, 0xFFE07A)
SNOWFIELD = Plain(0x9AB0CC, 0x7A90B0, 0xC8D8EA, 0x1A2440)


def level08(c):
    """Ice City: snowy blue mountains, icy white domes and a snowfield."""
    _night(c, 0x04126E, glow=0x1A3A8A)
    _stars(c, c.w // 3, 0.55)
    _moon(c, c.w * 0.62, c.h * 0.18, 11, 0xD8E8F0, 0x2A3A5A, 0xFFFFFF, craters=5)
    line, body = _spires(c, HORIZON - 0.02, c.w // 30, 0.26, width=(8, 18), sharp=1.2)
    _range(c, line, body, HORIZON, ICE, streaks=0.15)
    _snow(c, line, body, 0.45, SNOW, SNOW_SHADE)
    _martian_front(c, _spread(c, 6), hills=SNOW_HILLS, domes=ICE_DOMES, plain=SNOWFIELD)


def level09(c):
    """The first ice shrine: two small moons over broad glacier peaks, with
    shards of ice standing in the snow."""
    _night(c, 0x04126E)
    _stars(c, c.w // 3, 0.55)
    _moon(c, c.w * 0.2, c.h * 0.2, 7, 0xC8D8E8, 0x2A3A5A, 0xF0F8FF, craters=2)
    _moon(c, c.w * 0.32, c.h * 0.1, 3, 0xB8C8D8, 0x2A3A5A, craters=0)
    line, body = _spires(c, HORIZON - 0.02, c.w // 70, 0.22, width=(16, 34), sharp=1.0)
    _range(c, line, body, HORIZON, ICE, streaks=0.1)
    _snow(c, line, body, 0.6, SNOW, SNOW_SHADE)
    shards, _ = _spires(c, HORIZON, c.w // 40, 0.1, width=(2, 5), sharp=1.0, ridge=0.0)
    _land(c, shards, HORIZON + 0.01, 0x8AD0F0, 0xD0F4FF, 0x4A90C0, ICE.outline)
    _plain(c, HORIZON, SNOWFIELD)


def level10(c):
    """The second ice shrine: a big pale moon over sharp ice peaks and a
    frozen lake at their feet."""
    _night(c, 0x030A5A, glow=0x18306E)
    _stars(c, c.w // 3, 0.5)
    _moon(c, c.w * 0.7, c.h * 0.22, 18, 0xE0E8F0, 0x2A3450, 0xFFFFFF, craters=7)
    line, body = _spires(c, HORIZON - 0.06, c.w // 30, 0.26, width=(8, 18), sharp=1.3)
    _range(c, line, body, HORIZON - 0.04, ICE, streaks=0.15)
    _snow(c, line, body, 0.5, SNOW, SNOW_SHADE)
    lake_top = int((HORIZON - 0.04) * c.h)
    c._rect(0, lake_top, c.w, int(0.04 * c.h) + 1, 0x284C8A)
    for _ in range(c.w // 6):
        y = int(c.rng.integers(lake_top + 1, int(HORIZON * c.h)))
        c._rect(int(c.rng.integers(0, c.w)), y, int(c.rng.integers(2, 8)), 1, 0x6A9AD8)
    _plain(c, HORIZON, SNOWFIELD)


def level12(c):
    """The shrine in the red rock: buttes and a natural arch of red stone
    under a reddish horizon."""
    _night(c, NIGHT, glow=0x5A1A4A)
    _stars(c, c.w // 3, 0.5)
    _moon(c, c.w * 0.8, c.h * 0.12, 7, 0xD8B8A8, 0x4A2A2A, 0xF8E0D0, craters=3)
    far = _mesas(c, HORIZON - 0.02, c.w // 90, 0.22, width=(12, 30))
    _land(c, far, HORIZON, MESA, MESA_LIT, MESA_DARK, MAGENTA.outline)
    _strata(c, far, HORIZON, MESA_LAYER)
    _arch(c, int(c.w * 0.62), int(HORIZON * c.h), MESA, MESA_LIT, MESA_DARK)
    _plain(c, HORIZON, MARS)


def _arch(c, cx, ground, face, lit, shade):
    """A natural arch of rock standing on the plain."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    outer = (((xs - cx) / 34.0) ** 2 + ((ys - ground) / 46.0) ** 2 < 1) & (ys <= ground)
    inner = ((xs - cx) / 22.0) ** 2 + ((ys - ground) / 34.0) ** 2 < 1
    arch = outer & ~inner
    c.px[arch] = rgb(face)
    c.px[arch & (xs < cx - 24)] = rgb(lit)
    c.px[arch & (xs > cx + 26)] = rgb(shade)
    _outline(c, arch, MAGENTA.outline)


CRIMSON = Rock(0xD0402C, 0x9A1C1C, 0x4E0C1A, 0x140004)
RED_HILLS = Hills(0x8A5A50, 0xA87A6A, 0x6A4038, 0x140004, 0x4A2A24)
RED_PLAIN = Plain(0x7A2E2A, 0x5E1E1C, 0x904440, 0x3A0C10)


def level13(c):
    """The Red Maze City: crimson spires of rock, the domes of the city on
    red hills, a red plain."""
    _night(c, 0x080560, glow=0x5A1030)
    _stars(c, c.w // 3, 0.55, colours=(0xFFFFFF, 0xFFB0A0, 0x9AE8FF))
    _moon(c, c.w * 0.15, c.h * 0.18, 9, 0xE0A090, 0x4A1A1A, 0xFFD0C0, craters=4)
    _range(c, *_spires(c, HORIZON - 0.02, c.w // 34, 0.26), HORIZON, CRIMSON)
    _martian_front(c, _spread(c, 8), hills=RED_HILLS, plain=RED_PLAIN)


VIOLET = Rock(0x6A5AC8, 0x4A3AA0, 0x2A2068, 0x06041A)


def level14(c):
    """The hidden city: a great ringed planet rising over blue-violet
    mountains, a few domes in a fold of the hills."""
    _night(c, NIGHT)
    _stars(c, c.w // 3, 0.6)
    cx, cy, r = c.w * 0.62, c.h * 0.3, 28
    _moon(c, cx, cy, r, 0xC89A6A, 0x3A2A2A, 0xE8C090, craters=0)
    _bands(c, cx, cy, r, 0xA87A52)
    _planet_ring(c, cx, cy, r, 0xE0C8A0, 0x3A2A2A)
    _range(c, *_spires(c, HORIZON - 0.02, c.w // 34, 0.22, width=(7, 16), sharp=1.3), HORIZON,
           VIOLET)
    _martian_front(c, _spread(c, 4))


def _bands(c, cx, cy, r, colour):
    """Cloud bands across a gas planet."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    disc = np.hypot(xs - cx, ys - cy) < r - 1
    c.px[disc & (((ys - cy + r) // 5) % 3 == 0)] = rgb(colour)


def _planet_ring(c, cx, cy, r, colour, outline):
    """A flat ring round a planet: the front half over it, the back half
    hidden behind it."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    e = ((xs - cx) / (r * 2.0)) ** 2 + ((ys - cy) / (r * 0.4)) ** 2
    ring = (e < 1) & (e > 0.62)
    front = ys >= cy
    behind = np.hypot(xs - cx, ys - cy) < r + 1
    show = ring & (front | ~behind)
    c.px[show] = rgb(colour)
    c.px[show & (e > 0.9)] = rgb(outline)


# The shield volcano of level 15: how wide (of the picture) and how tall
# (of its height), and how much of its top is the crater.
VOLCANO_HALF = 0.3
VOLCANO_TALL = 0.2
VOLCANO_TOP = 0.97
VOLCANO = Rock(0xA04070, 0x742A58, 0x4A1A44, 0x000008)


def level15(c):
    """A great shield volcano, wide with gentle slopes and a crater on top,
    two small moons, and craters on the plain."""
    _night(c, NIGHT, glow=0x2A1660)
    _stars(c, c.w // 3, 0.55)
    _moon(c, c.w * 0.12, c.h * 0.14, 6, 0xC8B0A0, 0x4A3A3A, 0xF0E0D0, craters=2)
    _moon(c, c.w * 0.55, c.h * 0.08, 3, 0xB0A098, 0x4A3A3A, craters=0)
    x = np.arange(c.w, dtype=float)
    centre = c.w * 0.4
    k = np.clip(1 - np.abs(x - centre) / (c.w * VOLCANO_HALF), 0, 1)
    rise = 1 - (1 - k) ** 2.5
    crater = rise > VOLCANO_TOP
    volcano = HORIZON * c.h - VOLCANO_TALL * c.h * np.minimum(rise, VOLCANO_TOP) + crater * 3
    line, body = _spires(c, HORIZON - 0.01, c.w // 70, 0.12)
    line = np.minimum(np.round(volcano), line)
    _range(c, line, np.maximum(body, line + 6), HORIZON, VOLCANO, streaks=0.05)
    _martian_front(c, _spread(c, 6))
    for cx in _spread(c, 7):
        cy = int(HORIZON * c.h) + int(c.rng.integers(12, 70))
        w = 6 + (cy - HORIZON * c.h) * 0.25
        c._rect(int(cx - w / 2), cy, int(w), 2, MARS.dash)
        c._rect(int(cx - w / 2) + 1, cy + 2, int(w) - 1, 1, MARS.light)


# The castle of level 16 and the land around it, in the dark.
DUSK = Rock(0x4A3460, 0x302246, 0x1C1230, 0x06030C)
DUSK_HILLS = Hills(0x4A4450, 0x625A68, 0x34303A, 0x06030C, 0x24202A)
DUSK_PLAIN = Plain(0x3E2830, 0x2C1A22, 0x523640, 0x1A0C12)
CASTLE = 0x100818
CASTLE_WINDOW = 0xF0B050


def level16(c):
    """The Vorticon Commander's castle: a dark sky with a red moon, black
    jagged mountains and the castle far away on a crag, a few windows lit."""
    _night(c, 0x060330, glow=0x3A0A2A)
    _stars(c, c.w // 4, 0.55)
    _moon(c, c.w * 0.82, c.h * 0.17, 13, 0xC86050, 0x3A0A10, 0xF09078, craters=5)
    line, body = _spires(c, HORIZON - 0.02, c.w // 34, 0.22, sharp=1.4)
    crag_x = int(c.w * 0.42)
    xs = np.arange(c.w, dtype=float)
    k = np.clip(1 - np.abs(xs - crag_x) / 110, 0, 1)
    rough = c.ridge(0.0, 0.75, 0.015)
    crag = HORIZON * c.h - 0.3 * c.h * np.minimum(k * 1.5, 1) ** 1.2 + rough * (k > 0) * (k < 0.66)
    line = np.minimum(np.round(crag), line)
    _range(c, line, np.maximum(body, np.where(k > 0, HORIZON * c.h, body)), HORIZON, DUSK)
    _castle(c, crag_x, int(line[crag_x - 20 : crag_x + 21].max()) + 2)
    _mounds(c, HORIZON, c.w // 45, DUSK_HILLS, craters=False)
    _plain(c, HORIZON, DUSK_PLAIN)


def _castle(c, cx, ground):
    """Our own castle: a broad hall with battlements, a tall keep with a
    pointed roof and a mast in the middle, a round-topped tower on each
    side, and a few lit windows."""
    c._rect(cx - 36, ground - 28, 72, 29, CASTLE)
    for bx in range(cx - 36, cx + 36, 5):
        c._rect(bx, ground - 32, 3, 4, CASTLE)
    for tx, tall in ((cx - 44, 50), (cx + 32, 44)):
        c._rect(tx, ground - tall, 12, tall + 1, CASTLE)
        c._blob(tx + 6, ground - tall, 7, CASTLE)
        c._rect(tx + 6, ground - tall - 14, 1, 8, CASTLE)
        c._rect(tx + 4, ground - tall + 10, 3, 4, CASTLE_WINDOW)
    c._rect(cx - 9, ground - 64, 18, 65, CASTLE)
    for k in range(20):
        c._rect(cx - 9 + k // 2, ground - 84 + k, 18 - (k // 2) * 2, 1, CASTLE)
    c._rect(cx, ground - 96, 1, 12, CASTLE)
    c._rect(cx + 1, ground - 96, 4, 2, CASTLE)
    c._rect(cx - 2, ground - 54, 4, 5, CASTLE_WINDOW)
    for wx in (cx - 26, cx - 16, cx + 14, cx + 24):
        if c.rng.random() < 0.7:
            c._rect(wx, ground - 20, 2, 4, CASTLE_WINDOW)
    c._rect(cx - 4, ground - 11, 8, 11, 0x000000)


# Level number: (scene, width).
SKIES = {
    3: (level03, SKY_MEDIUM),
    4: (level04, SKY_WIDE),
    7: (level07, SKY_WIDE),
    8: (level08, SKY_MEDIUM),
    9: (level09, SKY_NARROW),
    10: (level10, SKY_NARROW),
    12: (level12, SKY_NARROW),
    13: (level13, SKY_WIDE),
    14: (level14, SKY_MEDIUM),
    15: (level15, SKY_WIDE),
    16: (level16, SKY_WIDE),
}


def paint_wall(number):
    tile = Tile(WALL_SIZE, WALL_SIZE, seed=1200 + number)
    WALLS[number](tile)
    return tile


def paint_sky(number):
    scene, width = SKIES[number]
    canvas = Canvas(width, seed=1000 + number, height=SKY_HEIGHT)
    scene(canvas)
    return canvas


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "assets", "backgrounds")
    os.makedirs(out, exist_ok=True)
    for number in SKIES:
        path = os.path.join(out, "level%02d.webp" % number)
        paint_sky(number).save(path, pixel=SKY_PIXEL)
        print(path)
    for number in WALLS:
        path = os.path.join(out, "wall%02d.webp" % number)
        paint_wall(number).save(path)
        print(path)


if __name__ == "__main__":
    main()
