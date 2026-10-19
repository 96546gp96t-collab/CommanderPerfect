#!/usr/bin/env python3
"""Paints the pictures behind Keen 3's levels into assets/backgrounds/keen3/.

Our own pictures, drawn from code: nothing in them comes from the game files.
Each picture is painted small, in the chunky pixels of the game, and then
blown up without smoothing, so that it sits well behind the level's tiles.
Only the levels with sky get one (see Keen3BackdropPictures): 1-8, 11, 13,
14 and 15. Every level has its own scene that fits what the level shows: a
city at dusk behind a city level, castles behind the castles, a mountain
range behind the mountain.

Usage:
    python3 tools/make_keen3_backgrounds.py [OUT_DIR]

Needs Pillow and NumPy. The same picture comes out every time (fixed seeds).
"""

import math
import os
import sys

import numpy as np
from PIL import Image

# One picture pixel becomes this many screen pixels: 216 rows become 1080,
# about the size of a game pixel on a 1080-pixel screen (200 rows).
PIXEL = 5
HEIGHT = 216
# Narrow pictures are 16:9; wide ones twice as wide, for levels much wider
# than the view, so the picture glides further.
NARROW = 384
WIDE = 768
# The 4x4 ordered dither that blends two bands of a gradient, as an old
# palette picture would.
BAYER = (
    np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], dtype=float)
    + 0.5
) / 16.0


def rgb(hex_color):
    """A colour written as 0xRRGGBB, as floats 0-255."""
    return np.array(
        [(hex_color >> 16) & 0xFF, (hex_color >> 8) & 0xFF, hex_color & 0xFF], dtype=float
    )


def mix(a, b, t):
    return a + (b - a) * t


class Canvas:
    """A small picture being painted, with the helpers every scene uses."""

    def __init__(self, width, seed):
        self.w = width
        self.h = HEIGHT
        self.px = np.zeros((self.h, self.w, 3), dtype=float)
        self.rng = np.random.default_rng(seed)
        self.sky_bottom = None

    # The sky ---------------------------------------------------------------

    def sky(self, stops, bands=14):
        """A vertical gradient through (position 0-1, colour) stops, cut into
        bands that are dithered into each other."""
        rows = np.linspace(0.0, 1.0, self.h)
        colours = np.array([self._gradient(stops, t) for t in rows])
        ys, xs = np.mgrid[0 : self.h, 0 : self.w]
        level = rows[ys] * bands + BAYER[ys % 4, xs % 4] - 0.5
        band = np.clip(np.floor(level), 0, bands - 1) / (bands - 1)
        row = np.clip(np.round(band * (self.h - 1)).astype(int), 0, self.h - 1)
        self.px = colours[row]
        self.sky_bottom = colours[-1]

    @staticmethod
    def _gradient(stops, t):
        for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
            if t <= p1:
                return mix(rgb(c0), rgb(c1), (t - p0) / max(p1 - p0, 1e-6))
        return rgb(stops[-1][1])

    def stars(self, count, top, bottom, colour=0xFFFFFF, bright=0.12):
        """Scattered stars, a few of them bright crosses."""
        for _ in range(count):
            x = int(self.rng.integers(0, self.w))
            y = int(self.rng.integers(int(top * self.h), int(bottom * self.h)))
            dim = 0.45 + 0.55 * self.rng.random()
            self._dot(x, y, mix(self.px[y, x], rgb(colour), dim))
            if self.rng.random() < bright:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    self._dot(x + dx, y + dy, mix(self.px[y, x], rgb(colour), 0.5))

    def disc(self, cx, cy, r, colour, glow=None, glow_size=0.0, shade=None):
        """A sun, moon or planet: a round disc, optionally with banded rings
        of glow around it and a darker crescent on one side."""
        ys, xs = np.mgrid[0 : self.h, 0 : self.w]
        d = np.hypot(xs - cx, ys - cy)
        if glow is not None and glow_size > 0:
            for step in range(4, 0, -1):
                ring = d < r + glow_size * step / 4
                self.px[ring] = mix(self.px[ring], rgb(glow), 0.16)
        inside = d < r
        self.px[inside] = rgb(colour)
        if shade is not None:
            off = np.hypot(xs - (cx + r * 0.45), ys - (cy - r * 0.3)) < r
            self.px[inside & ~off] = rgb(shade)

    def craters(self, cx, cy, r, colour, count):
        for _ in range(count):
            a = self.rng.random() * math.tau
            dist = self.rng.random() * r * 0.6
            cr = max(1.0, r * (0.12 + 0.12 * self.rng.random()))
            self._blob(cx + math.cos(a) * dist, cy + math.sin(a) * dist, cr, colour)

    def ring(self, cx, cy, r, colour, tilt=0.28):
        """A flat ring around a planet (the part in front of it)."""
        for x in range(int(cx - r * 2.1), int(cx + r * 2.1) + 1):
            for width in (1.0, 1.7):
                y = cy + (x - cx) * tilt * 0.3
                outer = (x - cx) ** 2 / (r * 2.0 * width / 1.7) ** 2
                if outer <= 1.0:
                    yy = int(round(y + math.sqrt(1 - outer) * r * 0.35))
                    if abs(x - cx) > r * 0.95 or yy > cy:
                        self._dot(x, yy, rgb(colour))

    def clouds(self, count, top, bottom, colour, shadow, size=(10, 26)):
        """Puffy clouds with a flat bottom and a darker underside."""
        for _ in range(count):
            cx = self.rng.integers(0, self.w)
            cy = int(self.rng.integers(int(top * self.h), int(bottom * self.h)))
            width = int(self.rng.integers(size[0], size[1]))
            puffs = [(cx + dx, cy - (width / 2 - abs(dx)) * 0.2, width * 0.3 - abs(dx) * 0.15)
                     for dx in range(-width // 2, width // 2 + 1, max(2, width // 5))]
            for x, y, r in puffs:
                self._blob(x, y + 1, max(r, 2.5), shadow, flat_below=cy + r * 0.45 + 1)
            for x, y, r in puffs:
                self._blob(x, y - 1, max(r - 1, 2.0), colour, flat_below=cy + r * 0.3)

    # The land --------------------------------------------------------------

    def ridge(self, base, rough, amplitude, seed_shift=0, spires=0, spire_height=0.0):
        """A skyline of hills or mountains: a height per column (rows from the
        top), made by midpoint displacement, with optional sharp spires."""
        size = 1
        while size < self.w:
            size *= 2
        heights = np.zeros(size + 1)
        rng = np.random.default_rng(int(self.rng.integers(0, 1 << 30)) + seed_shift)
        heights[0], heights[-1] = rng.normal(0, 0.5, 2)
        step, scale = size, 1.0
        while step > 1:
            half = step // 2
            for i in range(half, size, step):
                heights[i] = (heights[i - half] + heights[i + half]) / 2 + rng.normal(0, scale)
            step, scale = half, scale * rough
        heights = heights[: self.w]
        heights = (heights - heights.mean()) / (heights.std() + 1e-6)
        line = base * self.h - heights * amplitude * self.h
        for _ in range(spires):
            x = int(rng.integers(0, self.w))
            half = int(rng.integers(3, 9))
            tall = spire_height * self.h * (0.5 + 0.5 * rng.random())
            for dx in range(-half, half + 1):
                if 0 <= x + dx < self.w:
                    line[x + dx] = min(line[x + dx], line[x] - tall * (1 - abs(dx) / (half + 1)) ** 1.6)
        return line

    def peaks(self, base, count, height, slope, jitter=0.6):
        """A mountain range of separate pointed peaks with rough sides."""
        x = np.arange(self.w, dtype=float)
        line = np.full(self.w, base * self.h)
        for i in range(count):
            px = (i + 0.5 + (self.rng.random() - 0.5) * jitter) * self.w / count
            tall = height * self.h * (0.55 + 0.45 * self.rng.random())
            line = np.minimum(line, base * self.h - tall + np.abs(x - px) * slope)
        return line + self.rng.normal(0, 0.6, self.w).cumsum() % 2

    def hills(self, base, amplitude, waves, phase=0.0):
        """Gentle rolling hills from a few sine waves."""
        x = np.arange(self.w)
        line = np.full(self.w, base * self.h)
        for i, (length, height) in enumerate(waves):
            line -= np.sin(x / length + phase + i * 1.7) * height * amplitude * self.h
        return line

    def fill_below(self, line, colour, rim=None, dark=None):
        """Paints everything below a skyline, with a lit rim on top and a
        dithered darkening towards the bottom."""
        ys, xs = np.mgrid[0 : self.h, 0 : self.w]
        top = np.round(line).astype(int)
        below = ys >= top[xs]
        self.px[below] = rgb(colour)
        if dark is not None:
            depth = np.clip((ys - top[xs]) / (self.h * 0.35), 0, 1)
            darker = below & (depth + BAYER[ys % 4, xs % 4] * 0.35 > 0.7)
            self.px[darker] = rgb(dark)
        if rim is not None:
            edge = ys == top[xs]
            self.px[edge] = rgb(rim)

    def haze(self, colour, top, bottom, strength):
        """Air between the viewer and the far land: lighter towards the
        horizon, dithered."""
        ys, xs = np.mgrid[0 : self.h, 0 : self.w]
        t = np.clip((ys / self.h - top) / max(bottom - top, 1e-6), 0, 1) * strength
        hit = t > BAYER[ys % 4, xs % 4] + 0.25
        self.px[hit] = mix(self.px[hit], rgb(colour), 0.35)

    # Things on the land ----------------------------------------------------

    def skyline(self, base, colour, window, lit=0.35, heights=(0.08, 0.3), domes=True):
        """A row of buildings standing on a base line, with lit windows,
        antennas and round roofs."""
        x = 0
        top = base * self.h
        while x < self.w:
            width = int(self.rng.integers(8, 22))
            tall = self.h * (heights[0] + (heights[1] - heights[0]) * self.rng.random())
            roof = int(top - tall)
            self._rect(x, roof, width, int(top) - roof + 1, colour)
            if domes and self.rng.random() < 0.3:
                self._blob(x + width / 2, roof, width / 2.2, colour, flat_below=roof)
            elif self.rng.random() < 0.35:
                mast = int(self.rng.integers(4, 12))
                self._rect(x + width // 2, roof - mast, 1, mast, colour)
                self._dot(x + width // 2, roof - mast - 1, rgb(window))
            for wy in range(roof + 3, int(top) - 2, 4):
                for wx in range(x + 2, x + width - 2, 3):
                    if self.rng.random() < lit:
                        self._rect(wx, wy, 1, 2, window)
            x += width + int(self.rng.integers(0, 4))

    def trees(self, line, count, trunk, leaves, light, size=(5, 12)):
        """Round-topped trees standing on a skyline."""
        for _ in range(count):
            x = int(self.rng.integers(0, self.w))
            r = float(self.rng.integers(size[0], size[1]))
            ground = int(line[min(max(x, 0), self.w - 1)])
            stem = int(r * (1.2 + self.rng.random()))
            self._rect(x - 1, ground - stem, 2, stem + 1, trunk)
            self._blob(x, ground - stem - r * 0.6, r, leaves)
            self._blob(x - r * 0.3, ground - stem - r * 0.9, r * 0.45, light)

    def castles(self, base, colour, window, count):
        """Castles with towers, battlements and pointed roofs."""
        top = int(base * self.h)
        spacing = self.w / count
        for i in range(count):
            cx = int(spacing * (i + 0.5) + self.rng.integers(-15, 15))
            wall_w = int(self.rng.integers(30, 50))
            wall_h = int(self.rng.integers(14, 22))
            self._rect(cx - wall_w // 2, top - wall_h, wall_w, wall_h + 1, colour)
            for bx in range(cx - wall_w // 2, cx + wall_w // 2, 4):
                self._rect(bx, top - wall_h - 2, 2, 2, colour)
            for tx in (cx - wall_w // 2, cx + wall_w // 2 - 7, cx - 4):
                tower_h = wall_h + int(self.rng.integers(10, 24))
                self._rect(tx, top - tower_h, 8, tower_h + 1, colour)
                for k in range(6):
                    self._rect(tx + 4 - k, top - tower_h - 8 + k, 1 + 2 * k, 1, colour)
                self._rect(tx + 3, top - tower_h - 13, 1, 5, colour)
                self._rect(tx + 4, top - tower_h - 13, 3, 2, window)
                self._rect(tx + 3, top - tower_h + 5, 2, 3, window)
            self._rect(cx - 3, top - 7, 6, 8, window)

    def birds(self, count, top, bottom, colour):
        for _ in range(count):
            x = int(self.rng.integers(0, self.w))
            y = int(self.rng.integers(int(top * self.h), int(bottom * self.h)))
            for dx, dy in ((-2, -1), (-1, 0), (1, 0), (2, -1)):
                self._dot(x + dx, y + dy, rgb(colour))

    # Pixels ----------------------------------------------------------------

    def _dot(self, x, y, colour):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[int(y), int(x)] = colour

    def _rect(self, x, y, w, h, colour):
        x0, y0 = max(int(x), 0), max(int(y), 0)
        x1, y1 = min(int(x + w), self.w), min(int(y + h), self.h)
        if x0 < x1 and y0 < y1:
            self.px[y0:y1, x0:x1] = rgb(colour)

    def _blob(self, cx, cy, r, colour, flat_below=None):
        ys, xs = np.mgrid[0 : self.h, 0 : self.w]
        inside = np.hypot(xs - cx, (ys - cy) * 1.15) < r
        if flat_below is not None:
            inside &= ys <= flat_below
        self.px[inside] = rgb(colour)

    def save(self, path):
        small = Image.fromarray(np.clip(self.px, 0, 255).astype(np.uint8), "RGB")
        big = small.resize((self.w * PIXEL, self.h * PIXEL), Image.NEAREST)
        big.save(path, "WEBP", lossless=True, quality=100, method=6)


# The scenes, one per level ---------------------------------------------------


def level01(c):
    """The edge of town by the waterfall: a warm sunset over spiky purple
    mountains, with domes on the hills."""
    c.sky([(0, 0x2A1450), (0.45, 0x8C2E6E), (0.7, 0xF0784A), (0.82, 0xFFC46A), (1, 0xFFC46A)])
    c.disc(c.w * 0.7, c.h * 0.62, 16, 0xFFE9A0, glow=0xFFB060, glow_size=26)
    c.stars(40, 0.0, 0.3)
    far = c.ridge(0.66, 0.55, 0.05, spires=9, spire_height=0.16)
    c.fill_below(far, 0x7A3A8C, rim=0xB05AA8)
    c.haze(0xF09060, 0.55, 0.7, 0.9)
    near = c.hills(0.76, 1.0, [(37, 0.02), (13, 0.006)])
    c.fill_below(near, 0x3E2058, rim=0x6E3A7A, dark=0x2C1440)
    for x in (60, 170, 260, 350, 480, 610, 700):
        y = int(near[x])
        c._blob(x, y, 6, 0x6E3A7A, flat_below=y)
        c._rect(x, y - 9, 1, 4, 0x6E3A7A)


def level02(c):
    """The city at dusk: towers with lit windows under a violet sky and a
    big moon."""
    c.sky([(0, 0x120A30), (0.5, 0x4A2068), (0.78, 0xC0507A), (1, 0xE88A6A)])
    c.stars(110, 0.0, 0.45)
    c.disc(c.w * 0.22, c.h * 0.22, 18, 0xF2E6D0, glow=0x9A70B0, glow_size=18, shade=0xC8B8A8)
    c.craters(c.w * 0.22 + 4, c.h * 0.22 - 3, 18, 0xD8CBB8, 5)
    c.skyline(0.74, 0x5A2E6E, 0xE0A0C0, lit=0.15, heights=(0.12, 0.34))
    c.haze(0xC0507A, 0.4, 0.74, 0.6)
    c.skyline(0.8, 0x2A1238, 0xFFD27A, lit=0.4, heights=(0.06, 0.2))
    c._rect(0, int(0.8 * c.h), c.w, c.h, 0x2A1238)


def level03(c):
    """The mountain with the house on top: two moons over a starry blue
    twilight and range after range of violet mountains."""
    c.sky([(0, 0x0A0A2E), (0.55, 0x23306E), (0.85, 0x5A4C9A), (1, 0x8A6AB0)])
    c.stars(150, 0.0, 0.6)
    c.disc(c.w * 0.75, c.h * 0.2, 14, 0xD8F0FF, glow=0x5A70C0, glow_size=14, shade=0xA8C0E0)
    c.disc(c.w * 0.6, c.h * 0.12, 6, 0xFFD0E8, shade=0xD0A0C0)
    for base, colour, rim, amp in ((0.58, 0x4A3C8A, 0x6A5AB0, 0.07),
                                   (0.68, 0x35286A, 0x5040A0, 0.06),
                                   (0.8, 0x22184A, 0x3A2C70, 0.05)):
        c.fill_below(c.ridge(base, 0.52, amp), colour, rim=rim)


def level04(c):
    """The city with the Earth sign: a clear day with clouds, the Earth
    small and blue in the sky, and the city far away."""
    c.sky([(0, 0x2A5AB0), (0.5, 0x58A0E0), (0.8, 0xA8E0F0), (1, 0xD8F4F0)])
    c.disc(c.w * 0.82, c.h * 0.18, 9, 0x3A78E0, glow=0x9AD0F8, glow_size=8, shade=0x2A58B0)
    c.craters(c.w * 0.82, c.h * 0.18, 9, 0x4CB050, 4)
    c.clouds(16, 0.08, 0.5, 0xFFFFFF, 0xC8DCF0)
    c.skyline(0.74, 0x8C9CC8, 0xB8C8E8, lit=0.0, heights=(0.06, 0.24))
    c.haze(0xD8F4F0, 0.5, 0.74, 0.8)
    near = c.hills(0.8, 1.0, [(41, 0.015), (17, 0.006)])
    c.fill_below(near, 0x8A4AA0, rim=0xB070C0, dark=0x6A3088)


def level05(c):
    """The park with the big trees: golden hour, round trees on the hills
    and the towers of the town behind them."""
    c.sky([(0, 0x3A2A70), (0.4, 0xB0508A), (0.7, 0xF8A050), (1, 0xFFE08A)])
    c.disc(c.w * 0.4, c.h * 0.6, 20, 0xFFF4C0, glow=0xFFC870, glow_size=30)
    c.clouds(7, 0.1, 0.35, 0xFFD0A0, 0xE08A80, size=(14, 34))
    c.skyline(0.7, 0xA0507A, 0xFFE0A0, lit=0.1, heights=(0.1, 0.26), domes=False)
    c.haze(0xF8A050, 0.45, 0.7, 0.7)
    near = c.hills(0.78, 1.0, [(53, 0.02), (19, 0.007)])
    c.fill_below(near, 0x40306A, rim=0x6A4A8A, dark=0x2C2050)
    c.trees(near, 26, 0x2A1E40, 0x3A5A40, 0x5A8050)


def level06(c):
    """The little houses: a teal evening turning orange at the horizon,
    with small houses on the hills."""
    c.sky([(0, 0x0E2A40), (0.45, 0x1E6A78), (0.75, 0x80B090), (0.9, 0xF0B070), (1, 0xF89060)])
    c.stars(50, 0.0, 0.3)
    c.disc(c.w * 0.15, c.h * 0.25, 8, 0xF0F8E0, shade=0xC0D0B8)
    far = c.hills(0.68, 1.0, [(61, 0.03), (23, 0.01)], phase=1.0)
    c.fill_below(far, 0x2E5A62, rim=0x4E8A88)
    near = c.hills(0.78, 1.0, [(43, 0.02), (11, 0.004)])
    c.fill_below(near, 0x1E3240, rim=0x36505A, dark=0x14222C)
    for x in range(20, c.w, 64):
        y = int(near[x])
        c._rect(x, y - 12, 15, 13, 0x1E3240)
        for k in range(9):
            c._rect(x + 7 - k, y - 21 + k, 1 + 2 * k, 1, 0x1E3240)
        c._rect(x + 10, y - 22, 2, 5, 0x1E3240)
        c._rect(x + 3, y - 9, 3, 3, 0xFFD27A)
        c._rect(x + 9, y - 9, 3, 3, 0xFFD27A)


def level07(c):
    """The hideout on the hills ("kill Keen"): a red, threatening sky over
    black jagged mountains and a fortress."""
    c.sky([(0, 0x200810), (0.45, 0x601420), (0.75, 0xC03A20), (1, 0xF08030)])
    c.disc(c.w * 0.3, c.h * 0.3, 24, 0xF0C080, glow=0xC05030, glow_size=22, shade=0xC07050)
    c.clouds(9, 0.05, 0.4, 0x5A1A28, 0x3A0E18, size=(20, 44))
    far = c.ridge(0.64, 0.6, 0.06, spires=12, spire_height=0.14)
    c.fill_below(far, 0x3A1220, rim=0x7A2A30)
    c.haze(0xC03A20, 0.5, 0.66, 0.6)
    near = c.ridge(0.78, 0.5, 0.04)
    c.fill_below(near, 0x16060C, rim=0x3A1220)
    fx = int(c.w * 0.62)
    fy = int(near[fx])
    c._rect(fx - 32, fy - 40, 64, 41, 0x16060C)
    for tx in (fx - 38, fx + 26, fx - 6):
        c._rect(tx, fy - 58, 13, 59, 0x16060C)
        c._rect(tx + 4, fy - 50, 4, 5, 0xF06030)
        for k in range(0, 13, 4):
            c._rect(tx + k, fy - 61, 2, 3, 0x16060C)
    for k in range(0, 64, 6):
        c._rect(fx - 32 + k, fy - 44, 3, 4, 0x16060C)
    for wx in range(fx - 26, fx + 26, 9):
        c._rect(wx, fy - 28, 2, 4, 0xC04020)


def level08(c):
    """The big maze house: the sunset the user picked, a sun low over green
    hills, in the game's pixels."""
    c.sky([(0, 0x33196E), (0.55, 0xB0507A), (0.82, 0xF08C4E), (1, 0xF8A050)])
    c.stars(30, 0.0, 0.25)
    c.disc(c.w * 0.73, c.h * 0.37, 12, 0xFFE68A, glow=0xF8B060, glow_size=20)
    far = c.hills(0.66, 1.0, [(97, 0.025), (31, 0.008)], phase=2.0)
    c.fill_below(far, 0x3A6A4A, rim=0x5A8A5A)
    c.haze(0xF08C4E, 0.55, 0.7, 0.6)
    near = c.hills(0.74, 1.0, [(90, 0.035), (23, 0.007)])
    c.fill_below(near, 0x26553A, rim=0x3E7A4E, dark=0x1A3E2A)


def level11(c):
    """The cave and the tall tree: a forest under a full moon at night."""
    c.sky([(0, 0x060818), (0.6, 0x14204A), (1, 0x2E3A6A)])
    c.stars(120, 0.0, 0.55)
    c.disc(c.w * 0.62, c.h * 0.24, 20, 0xF4F0DA, glow=0x4A5A90, glow_size=26, shade=0xD0CCB4)
    c.craters(c.w * 0.62 + 5, c.h * 0.24 - 4, 20, 0xDCD6BC, 6)
    far = c.hills(0.7, 1.0, [(47, 0.025), (13, 0.006)])
    c.fill_below(far, 0x1A2A40, rim=0x2E4460)
    c.trees(far, 30, 0x101A28, 0x1E3A3A, 0x2E5048, size=(6, 13))
    near = c.hills(0.82, 1.0, [(29, 0.015)])
    c.fill_below(near, 0x0C1420, rim=0x1A2A3A)
    c.trees(near, 18, 0x080C14, 0x10201E, 0x1A3230, size=(9, 16))


def level13(c):
    """The great rock face: a pink dawn over tall rock cliffs."""
    c.sky([(0, 0x3A4A9A), (0.45, 0x9A7AC0), (0.75, 0xF0A8B0), (1, 0xFFD8B0)])
    c.disc(c.w * 0.5, c.h * 0.7, 22, 0xFFF0D0, glow=0xFFC0A0, glow_size=34)
    c.clouds(6, 0.1, 0.4, 0xFFE0E0, 0xD0A0C0, size=(16, 36))
    c.birds(7, 0.15, 0.4, 0x4A3A6A)
    mesa = c.ridge(0.6, 0.35, 0.09)
    mesa = np.minimum(mesa, np.round(mesa / 12) * 12)
    c.fill_below(mesa, 0x8A6A8A, rim=0xB896A8)
    c.haze(0xF0A8B0, 0.45, 0.7, 0.7)
    near = c.ridge(0.76, 0.45, 0.06)
    c.fill_below(near, 0x5A4060, rim=0x7A5A80, dark=0x402C48)


def level14(c):
    """The row of castles: castles on the horizon in a sunset, with banners."""
    c.sky([(0, 0x1E1E5A), (0.45, 0x6A3A8A), (0.72, 0xE0704A), (1, 0xF8B060)])
    c.stars(40, 0.0, 0.3)
    c.disc(c.w * 0.5, c.h * 0.7, 18, 0xFFE0A0, glow=0xF89050, glow_size=30)
    far = c.hills(0.72, 1.0, [(71, 0.02)])
    c.fill_below(far, 0x5A2E5A, rim=0x8A4A70)
    c.castles(0.73, 0x3A1E40, 0xFFC060, 5)
    near = c.hills(0.82, 1.0, [(37, 0.012)])
    c.fill_below(near, 0x22122A, rim=0x3A2040)


def level15(c):
    """The big mountain: a cold blue sky and snowy peaks."""
    c.sky([(0, 0x1A3A8A), (0.5, 0x4A80D0), (0.85, 0xA0D0F0), (1, 0xD8F0FF)])
    c.clouds(8, 0.05, 0.35, 0xF8FCFF, 0xC0D8F0, size=(14, 30))
    c.birds(5, 0.12, 0.3, 0x2A3A6A)
    far = c.peaks(0.66, 6, 0.3, 0.9)
    c.fill_below(far, 0x56669C, rim=0x8A9AC8)
    # Snow on the peaks: the higher a column of the range reaches above the
    # snow line, the deeper its snow; the side facing away from the light is
    # in shadow.
    snow_line = c.h * 0.52
    depth = np.clip(snow_line - far, 0, None) * 0.9
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    below = ys - far[xs]
    cap = (below >= 0) & (below < depth[xs] - BAYER[ys % 4, xs % 4] * 3)
    c.px[cap] = rgb(0xF0F6FF)
    falling = np.gradient(far) > 0
    c.px[cap & falling[xs]] = rgb(0xB8C8E8)
    c.haze(0xD8F0FF, 0.5, 0.7, 0.7)
    near = c.ridge(0.74, 0.5, 0.05)
    c.fill_below(near, 0x4A5A8A, rim=0x7A8AB8, dark=0x3A4870)


# Level number: (scene, width). The wide pictures are for the levels much
# wider than the view.
SCENES = {
    1: (level01, WIDE),
    2: (level02, WIDE),
    3: (level03, NARROW),
    4: (level04, WIDE),
    5: (level05, WIDE),
    6: (level06, WIDE),
    7: (level07, WIDE),
    8: (level08, WIDE),
    11: (level11, NARROW),
    13: (level13, NARROW),
    14: (level14, WIDE),
    15: (level15, NARROW),
}


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "assets", "backgrounds", "keen3")
    os.makedirs(out, exist_ok=True)
    for number, (scene, width) in SCENES.items():
        canvas = Canvas(width, seed=3000 + number)
        scene(canvas)
        path = os.path.join(out, "level%02d.webp" % number)
        canvas.save(path)
        print(path)


if __name__ == "__main__":
    main()
