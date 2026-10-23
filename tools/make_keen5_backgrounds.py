#!/usr/bin/env python3
"""Paints the pictures behind Keen 5's levels into assets/backgrounds/keen5/.

Our own pictures, drawn from code with the canvas of
tools/background_painter.py (as Keen 3's and Keen 4's): nothing in them
comes from the game files. Each picture is painted small, in the chunky
pixels of the game, and blown up without smoothing.

Keen 5 plays inside a space station in orbit around a planet, so its only
plain background is outside: black space (around the station and in its
windows) and the light cyan sky of the planet's base (Keen5BackdropPictures).
Only the maps with open space or sky get a picture: the world map (0) and
levels 1, 3, 4, 6, 10, 11, 12 and 13. The level keeps its own stars, which
sit on the picture, so the space scenes stay dark and calm, with one thing
to look at per level that fits its name: the planet below the station, a
nebula along the long tunnel, a blue star for the energy systems, a ringed
planet, drifting rocks for the Brownian motion, a black hole for the
gravitational damping hub, a star blowing up behind the explosion dynamo.
The planet's base gets a daytime sky with the station high up in it and
no land (the level is tall; it has its own desert at the bottom).

Usage:
    python3 tools/make_keen5_backgrounds.py [OUT_DIR]

Needs Pillow and NumPy. The same picture comes out every time (fixed seeds).
"""

import math
import os
import sys

import numpy as np

from background_painter import BAYER, NARROW, WIDE, Canvas, mix, rgb

# Space ---------------------------------------------------------------------


def _space(c, top, bottom, stars=260):
    """Deep space: a dark gradient with scattered stars of a few sizes."""
    c.sky([(0.0, top), (1.0, bottom)], bands=10)
    c.stars(stars, 0.0, 1.0, colour=0xFFFFFF, bright=0.08)
    c.stars(stars // 3, 0.0, 1.0, colour=0x9FB8FF, bright=0.0)


def _noise(c, cells, seed_shift=0):
    """Smooth noise from 0 to 1 over the canvas: random values on a coarse
    grid of `cells` columns, blended between grid points."""
    rng = np.random.default_rng(int(c.rng.integers(0, 1 << 30)) + seed_shift)
    rows = max(2, int(round(cells * c.h / c.w)) + 2)
    grid = rng.random((rows + 1, cells + 2))
    ys = np.linspace(0, rows - 1, c.h)
    xs = np.linspace(0, cells, c.w)
    y0 = np.floor(ys).astype(int)
    x0 = np.floor(xs).astype(int)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = grid[y0][:, x0]
    b = grid[y0][:, x0 + 1]
    d = grid[y0 + 1][:, x0]
    e = grid[y0 + 1][:, x0 + 1]
    return mix(mix(a, b, fx), mix(d, e, fx), fy)


def _nebula(c, colours, strength, cells=(6, 14, 30), band=None):
    """A cloud of glowing gas: layered noise, dithered into the colours
    (faintest first), optionally kept to a band (centre row, half height,
    slope across the picture)."""
    field = sum(_noise(c, n, i) * w for i, (n, w) in enumerate(zip(cells, (0.55, 0.3, 0.15))))
    if band is not None:
        centre, half, slope = band
        ys, xs = np.mgrid[0 : c.h, 0 : c.w]
        line = centre * c.h + (xs - c.w / 2) * slope
        field = field * np.clip(1 - np.abs(ys - line) / (half * c.h), 0, 1)
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    dither = BAYER[ys % 4, xs % 4]
    for i, colour in enumerate(colours):
        level = strength * (1 - (i + 1) / (len(colours) + 1))
        hit = field + (dither - 0.5) * 0.12 > 1 - level
        c.px[hit] = mix(c.px[hit], rgb(colour), 0.7)


def _planet(c, cx, cy, r, light, dark, bands=None, light_from=(-0.6, -0.5), rim=None):
    """A planet lit from one side: dithered shading from its lit colour to
    its night side, optional bands of colour across it and a thin glowing
    rim of air."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    dx = (xs - cx) / r
    dy = (ys - cy) / r
    d2 = dx * dx + dy * dy
    inside = d2 < 1.0
    if rim is not None:
        halo = (d2 >= 1.0) & (d2 < (1 + 2.5 / r) ** 2) & (BAYER[ys % 4, xs % 4] < 0.6)
        c.px[halo] = mix(c.px[halo], rgb(rim), 0.6)
    z = np.sqrt(np.clip(1 - d2, 0, 1))
    lit = np.clip(dx * light_from[0] + dy * light_from[1] + z * 0.45, 0, 1)
    base = np.repeat(rgb(light)[None, None, :], c.h, 0).repeat(c.w, 1)
    if bands is not None:
        stripe = (np.sin(dy * bands[0] + np.sin(dx * 3.0) * 0.4) + 1) / 2
        base = mix(base, rgb(bands[1])[None, None, :], (stripe > 0.6)[..., None] * 0.7)
    shade = mix(rgb(dark)[None, None, :], base, np.round(lit * 4 + BAYER[ys % 4, xs % 4] - 0.5)[..., None] / 4)
    c.px[inside] = shade[inside]
    return inside


def _cracks(c, inside, cx, cy, r, colour, count):
    """Dry cracks wandering over a desert planet's face."""
    for _ in range(count):
        a = c.rng.random() * math.tau
        x = cx + math.cos(a) * r * c.rng.random() * 0.8
        y = cy + math.sin(a) * r * c.rng.random() * 0.8
        heading = c.rng.random() * math.tau
        for _ in range(int(8 + c.rng.random() * 16)):
            ix, iy = int(round(x)), int(round(y))
            if 0 <= ix < c.w and 0 <= iy < c.h and inside[iy, ix]:
                c.px[iy, ix] = mix(c.px[iy, ix], rgb(colour), 0.6)
            heading += c.rng.normal(0, 0.5)
            x += math.cos(heading)
            y += math.sin(heading) * 0.8


def _glow(c, cx, cy, radius, colour, steps=5, strength=0.22):
    """A soft glow in dithered rings around a bright point."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    d = np.hypot(xs - cx, ys - cy)
    for step in range(steps, 0, -1):
        ring = (d < radius * step / steps) & (BAYER[ys % 4, xs % 4] < 0.85)
        c.px[ring] = mix(c.px[ring], rgb(colour), strength)


def _station(c, cx, cy, size, colour, light):
    """Our own far silhouette of a station in orbit: a hub with a dish on
    top, a long spine and two arms ending in spheres."""
    s = size
    c._rect(cx - 1, cy - 6 * s, 2 + s // 2, 13 * s, colour)
    c._rect(cx - 5 * s, cy, 10 * s + 1, max(1, s), colour)
    for side in (-1, 1):
        c._blob(cx + side * 5 * s, cy, 1.6 * s, colour)
        c._dot(cx + side * 5 * s - 1, cy - 1, rgb(light))
    c._blob(cx, cy, 2.2 * s, colour)
    c._rect(cx - 3 * s, cy - 6 * s, 6 * s + 1, 1, colour)
    c._dot(cx, cy - 6 * s - 1, rgb(light))
    for k in range(3):
        c._dot(cx, cy + 2 * s + 2 * k * s, rgb(light))


# Scenes ----------------------------------------------------------------------


def level00(c):
    """The world map: deep space around the station, a far spiral galaxy,
    a faint blue nebula and a small moon. The map has the planet's
    ground of its own at the bottom."""
    _space(c, 0x05040E, 0x0A0A1E, stars=220)
    _nebula(c, [0x141A3A, 0x1E2C5A], 0.55, band=(0.45, 0.45, -0.15))
    _galaxy(c, c.w * 0.72, c.h * 0.3, 34)
    c.disc(c.w * 0.2, c.h * 0.22, 6, 0xA8A8B8, shade=0x3A3A48)


def _galaxy(c, cx, cy, r):
    """A far spiral galaxy, tilted: two arms of dots and a bright core."""
    for arm in (0, math.pi):
        for k in range(320):
            t = k / 320
            a = arm + t * 3.6
            d = t * r + c.rng.normal(0, 1.6)
            x = cx + math.cos(a) * d
            y = cy + math.sin(a) * d * 0.45
            c._dot(int(round(x)), int(round(y)), mix(rgb(0x6070B0), rgb(0xD0D8FF), 1 - t))
    _glow(c, cx, cy, 6, 0xFFF0D0, steps=3, strength=0.35)
    c._rect(int(cx) - 1, int(cy), 3, 1, 0xFFFFF0)


def level01(c):
    """The Ion Ventilation System: the planet far below the station, a
    desert world of yellow sand and dark cracks, lit from the side, with a
    thin rim of air; a small moon beside it."""
    _space(c, 0x04030C, 0x0C0816)
    cx, cy, r = c.w * 0.62, c.h * 1.18, c.h * 0.62
    inside = _planet(c, cx, cy, r, 0xE8D060, 0x2A1C08, light_from=(-0.7, -0.6), rim=0x8FE0FF)
    _cracks(c, inside, cx, cy, r, 0x8A5418, 40)
    c.disc(c.w * 0.18, c.h * 0.3, 9, 0xB8B0A0, shade=0x403830)
    c.craters(c.w * 0.18 - 2, c.h * 0.3 - 2, 9, 0x8C8478, 4)


def level03(c):
    """Defense Tunnel Vlook: a long band of violet and blue nebula across
    the whole picture (the tunnel is long and its windows are small), with
    star clusters in it."""
    _space(c, 0x060410, 0x0A0618, stars=420)
    _nebula(c, [0x1C1240, 0x34205E, 0x5A3488], 0.75, cells=(10, 24, 48), band=(0.4, 0.5, 0.08))
    for _ in range(6):
        x, y = c.rng.random() * c.w, c.h * (0.2 + 0.4 * c.rng.random())
        for _ in range(18):
            c._dot(int(x + c.rng.normal(0, 3)), int(y + c.rng.normal(0, 2)), rgb(0xE8E0FF))


def level04(c):
    """Energy Flow Systems: a hot blue-white star with a wide glow and
    long rays, the energy the station drinks."""
    _space(c, 0x02040E, 0x060A1A)
    cx, cy = c.w * 0.68, c.h * 0.36
    _glow(c, cx, cy, 70, 0x2050A0, steps=6, strength=0.18)
    _glow(c, cx, cy, 32, 0x80B0FF, steps=4, strength=0.25)
    c.disc(cx, cy, 16, 0xE8F4FF)
    c.disc(cx + 3, cy + 3, 12, 0xFFFFFF)
    for a in (0.0, math.pi / 2, math.pi, math.pi * 1.5):
        for k in range(18, 46):
            if k % 2 == 0 or k < 30:
                c._dot(int(round(cx + math.cos(a) * k)), int(round(cy + math.sin(a) * k)), rgb(0xC0E0FF))
    c.disc(c.w * 0.15, c.h * 0.62, 5, 0x5070A0, shade=0x101830)


def level06(c):
    """The Regulation Control Center: a ringed giant of soft bands with two
    small moons."""
    _space(c, 0x05040C, 0x0A0814)
    cx, cy, r = c.w * 0.4, c.h * 0.48, c.h * 0.24
    _tilted_ring(c, cx, cy, r, 0xC8B090, 0x8C7A60, behind=True)
    _planet(c, cx, cy, r, 0xD8A070, 0x2A1810, bands=(9.0, 0xA86A48), light_from=(-0.6, -0.4))
    _tilted_ring(c, cx, cy, r, 0xC8B090, 0x8C7A60, behind=False)
    c.disc(c.w * 0.82, c.h * 0.2, 6, 0xC0C8D8, shade=0x384050)
    c.disc(c.w * 0.12, c.h * 0.78, 4, 0xB8A890, shade=0x383028)


def _tilted_ring(c, cx, cy, r, colour, shade, behind):
    """A flat ring around a planet, seen from a little above: an ellipse
    band with a gap, its far half (behind the planet) or its near half."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    dx = (xs - cx) / (r * 2.1)
    dy = (ys - cy - (xs - cx) * 0.12) / (r * 0.5)
    d = np.hypot(dx, dy)
    band = ((d > 0.68) & (d < 0.8)) | ((d > 0.84) & (d < 1.0))
    half = (dy < 0) if behind else (dy >= 0)
    on = band & half
    c.px[on & (d < 0.8)] = rgb(colour)
    c.px[on & (d >= 0.8)] = rgb(shade)


def level10(c):
    """The Brownian Motion Inducer: rocks of all sizes drifting every which
    way through a dusty brown haze."""
    _space(c, 0x060406, 0x0E0A0A)
    _nebula(c, [0x1E140E, 0x2E2016], 0.5, cells=(8, 18, 36))
    for _ in range(46):
        x, y = c.rng.random() * c.w, c.rng.random() * c.h
        r = 1.0 + c.rng.random() ** 2.5 * 9
        _rock(c, x, y, r)


def _rock(c, x, y, r):
    """A lumpy rock lit from the top left."""
    for k in range(5):
        dx, dy = c.rng.normal(0, r * 0.25, 2)
        c._blob(x + dx, y + dy, r * (0.6 + 0.3 * c.rng.random()), 0x4A3C30)
    c._blob(x - r * 0.3, y - r * 0.3, r * 0.45, 0x7A6650)
    if r > 4:
        c._blob(x + r * 0.2, y + r * 0.1, r * 0.18, 0x2E241C)


def level11(c):
    """The Gravitational Damping Hub: a black hole with a glowing disk of
    gas swirling into it, the stars behind it bent into a ring."""
    _space(c, 0x04020A, 0x0A0612)
    cx, cy = c.w * 0.6, c.h * 0.42
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    dx, dy = (xs - cx), (ys - cy) * 3.2
    d = np.hypot(dx, dy)
    disk = (d > 18) & (d < 76)
    heat = np.clip(1 - (d - 18) / 58, 0, 1)
    swirl = (np.sin(np.arctan2(dy, dx) * 3 + d * 0.35) + 1) / 2
    on = disk & (heat * 0.8 + swirl * 0.3 > BAYER[ys % 4, xs % 4] + 0.25)
    colour = mix(rgb(0x802010)[None, None, :], rgb(0xFFD080)[None, None, :], heat[..., None])
    c.px[on] = colour[on]
    _glow(c, cx, cy, 26, 0xFFB060, steps=3, strength=0.3)
    c.disc(cx, cy, 14, 0x000000)
    for k in range(80):
        a = k / 80 * math.tau
        c._dot(int(cx + math.cos(a) * 16), int(cy + math.sin(a) * 16), rgb(0xFFE0B0))
    front = disk & (ys > cy) & on
    c.px[front & (d < 40)] = rgb(0xFFE8A0)


def level12(c):
    """The Quantum Explosion Dynamo: a star blowing up, a white flash in
    shells of red and orange gas, its shards flying out."""
    _space(c, 0x080306, 0x10060A)
    cx, cy = c.w * 0.36, c.h * 0.42
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    d = np.hypot(xs - cx, (ys - cy) * 1.1)
    ruffle = _noise(c, 12) * 14
    for radius, colour, strength in ((70, 0x501018, 0.55), (52, 0xA02818, 0.6), (36, 0xF06020, 0.65)):
        shell = (np.abs(d + ruffle - radius) < 5) & (BAYER[ys % 4, xs % 4] < strength)
        c.px[shell] = mix(c.px[shell], rgb(colour), 0.8)
    _glow(c, cx, cy, 26, 0xFFC080, steps=4, strength=0.3)
    c.disc(cx, cy, 6, 0xFFFFF0)
    for _ in range(30):
        a = c.rng.random() * math.tau
        for k in range(int(4 + c.rng.random() * 6)):
            rr = 74 + k * 2 + c.rng.random() * 8
            c._dot(int(cx + math.cos(a) * rr), int(cy + math.sin(a) * rr * 0.9), rgb(0xFF9050))


def level13(c):
    """The base on the planet: a clear daytime sky, deep blue high up and
    pale near the ground, two suns, thin high clouds, the station far up
    in it as a silhouette and a pale moon. No land: the level is tall and
    has its own desert at the bottom."""
    c.sky([(0.0, 0x2A5AB0), (0.55, 0x4C9CE0), (1.0, 0x9ED8F0)], bands=12)
    _glow(c, c.w * 0.78, c.h * 0.24, 30, 0xE0F0FF, steps=4, strength=0.2)
    c.disc(c.w * 0.78, c.h * 0.24, 7, 0xFFFBE8)
    c.disc(c.w * 0.86, c.h * 0.36, 3, 0xFFE8C0)
    c.disc(c.w * 0.14, c.h * 0.2, 8, 0xC8DCF0, shade=0x8CB0D8)
    _station(c, int(c.w * 0.42), int(c.h * 0.22), 2, 0x3060A0, 0xE0F0FF)
    for _ in range(9):
        x, y = c.rng.random() * c.w, c.h * (0.45 + c.rng.random() * 0.45)
        length = int(16 + c.rng.random() * 40)
        c._rect(int(x), int(y), length, 1, 0xC8E8F8)
        c._rect(int(x + length * 0.2), int(y) - 1, int(length * 0.5), 1, 0xB0DCF4)


# Map number: (scene, width). The tunnel (204 cells) gets the wide picture,
# which glides further; the others (42-80 cells) the 16:9 one.
SCENES = {
    0: (level00, NARROW),
    1: (level01, NARROW),
    3: (level03, WIDE),
    4: (level04, NARROW),
    6: (level06, NARROW),
    10: (level10, NARROW),
    11: (level11, NARROW),
    12: (level12, NARROW),
    13: (level13, NARROW),
}


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "assets", "backgrounds", "keen5")
    os.makedirs(out, exist_ok=True)
    for number, (scene, width) in SCENES.items():
        canvas = Canvas(width, seed=5000 + number)
        scene(canvas)
        path = os.path.join(out, "level%02d.webp" % number)
        canvas.save(path)
        print(path)


if __name__ == "__main__":
    main()
