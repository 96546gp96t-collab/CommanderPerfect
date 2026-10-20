"""The canvas that the pictures behind the levels are painted on, shared by
tools/make_keen3_backgrounds.py and tools/make_keen4_backgrounds.py.

Our own drawing helpers, nothing from the game files: a small picture in the
chunky pixels of the game (dithered gradients, discs, clouds, hills, ridges,
buildings, trees, castles), blown up without smoothing when it is saved.
Things that stand on the land are put on their footing (the lowest ground
under them), so that no part of them hangs in the air.
"""

import math

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

    def plain(self, base, colour, rim=None, dark=None):
        """Flat land from the horizon at `base` down: what far buildings stand
        on, so that the ground runs on behind them up to the hills in front."""
        self.fill_below(np.full(self.w, base * self.h), colour, rim=rim, dark=dark)

    def plateaus(self, base, count, height, seed_shift=0):
        """A row of flat-topped cliffs with steep sides, as a skyline."""
        rng = np.random.default_rng(int(self.rng.integers(0, 1 << 30)) + seed_shift)
        line = np.full(self.w, base * self.h)
        for i in range(count):
            centre = (i + 0.5 + (rng.random() - 0.5) * 0.5) * self.w / count
            half = self.w / count * (0.25 + 0.2 * rng.random())
            top = base * self.h - height * self.h * (0.5 + 0.5 * rng.random())
            x = np.arange(self.w)
            side = np.clip((np.abs(x - centre) - half) * 2.5, 0, None)
            line = np.minimum(line, top + side)
        return line + np.round(rng.normal(0, 0.4, self.w))

    def footing(self, line, x, width):
        """The row on which something `width` wide whose left side is at `x`
        stands on `line`: the lowest ground under it (fill_below starts the
        land on the rounded line), so that none of it hangs in the air."""
        x0 = min(max(int(x), 0), self.w - 1)
        x1 = min(max(int(x + width), x0 + 1), self.w)
        return int(np.round(line[x0:x1]).max())

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

    def pines(self, line, count, colour, size=(6, 14)):
        """Pointed fir trees standing on a skyline."""
        for _ in range(count):
            x = int(self.rng.integers(0, self.w))
            tall = int(self.rng.integers(size[0], size[1]))
            ground = self.footing(line, x - 1, 3)
            for k in range(tall):
                half = (k * 0.42) if k < tall - 1 else 0.5
                self._rect(x - int(half), ground - tall + k, 1 + 2 * int(half), 1, colour)
            self._rect(x, ground - 1, 1, 2, colour)

    def lattice(self, x, top, width, bottom, colour):
        """A framework tower of girders: two legs and crossed braces."""
        self._rect(x, top, 1, bottom - top + 1, colour)
        self._rect(x + width - 1, top, 1, bottom - top + 1, colour)
        for y in range(top, bottom, width):
            for k in range(width):
                self._dot(x + k, y + k, rgb(colour))
                self._dot(x + width - 1 - k, y + k, rgb(colour))

    def curtains(self, base, length, waves, low, high, strength=0.9):
        """Aurora curtains: streaks of light that hang above a wavy lower
        edge, `low` at the bottom fading to `high` and into the sky."""
        ys, xs = np.mgrid[0 : self.h, 0 : self.w]
        edge = np.full(self.w, base * self.h)
        for i, (wave, height) in enumerate(waves):
            edge += np.sin(np.arange(self.w) / wave + i * 2.1) * height * self.h
        noise = np.convolve(self.rng.random(self.w + 6), np.ones(4) / 4, "same")[3:-3]
        streaks = 0.35 + 0.65 * noise * (0.7 + 0.3 * np.sin(np.arange(self.w) / 11.0))
        reach = length * self.h * (0.5 + 0.5 * np.sin(np.arange(self.w) / 29.0 + 1.0) ** 2)
        up = edge[xs] - ys
        t = np.clip(up / reach[xs], 0, 1)
        light = np.where((up >= 0) & (up < reach[xs]), (1 - t) * streaks[xs] * strength, 0)
        hit = light > BAYER[ys % 4, xs % 4]
        colour = mix(rgb(low)[None, None, :], rgb(high)[None, None, :], t[..., None])
        self.px[hit] = mix(self.px[hit], colour[hit], 0.6)
        return edge

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
