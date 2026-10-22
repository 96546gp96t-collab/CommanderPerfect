#!/usr/bin/env python3
"""Paints the pictures behind Keen 3's levels into assets/backgrounds/keen3/.

Our own pictures, drawn from code: nothing in them comes from the game files.
Each picture is painted small, in the chunky pixels of the game, and then
blown up without smoothing (tools/background_painter.py), so that it sits well
behind the level's tiles. Only the levels with sky get one (see
Keen3BackdropPictures): 1-11, 13, 14 and 15. Every level has its own scene
that fits what the level shows: a city at dusk behind a city level, a
fortress behind the fortress, a mountain range behind the mountain. What
stands on the land stands on it: the ground runs on behind far buildings,
and houses and castles reach down to the lowest ground under them.

Usage:
    python3 tools/make_keen3_backgrounds.py [OUT_DIR]

Needs Pillow and NumPy. The same picture comes out every time (fixed seeds).
"""

import os
import sys

import numpy as np

from background_painter import BAYER, NARROW, WIDE, Canvas, rgb

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
        y = c.footing(near, x - 6, 13)
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
    c.plain(0.74, 0x5A2E6E)
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
    c.plain(0.74, 0xA088C0, rim=0xB8A0D0)
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
    c.plain(0.7, 0x7A4A80, rim=0x9A5A88)
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
        y = c.footing(near, x, 15)
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
    fy = c.footing(near, fx - 38, 77)
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


def level09(c):
    """The tree, the sign and the waterfall over the deep base: a misty green
    morning in a valley of flat-topped cliffs, with thin waterfalls falling
    from them into a still lake and fir trees on the near shore."""
    c.sky([(0, 0x163C44), (0.45, 0x3E7A68), (0.75, 0xA8C47C), (1, 0xEEE0A4)])
    c.disc(c.w * 0.24, c.h * 0.17, 7, 0xF4F2DC, shade=0xC8CCB0)
    c.clouds(6, 0.08, 0.32, 0xE4EED0, 0x9CB894, size=(16, 36))
    c.birds(6, 0.14, 0.34, 0x22403A)
    cliffs = c.plateaus(0.66, 4, 0.36)
    c.fill_below(cliffs, 0x4A7062, rim=0x78A08A)
    _waterfalls(c, cliffs, 0.66)
    c.haze(0xEEE0A4, 0.45, 0.66, 0.7)
    _lake(c, 0.66, 0.76)
    shore = c.hills(0.8, 1.0, [(31, 0.012), (11, 0.004)])
    c.fill_below(shore, 0x1C3A30, rim=0x2C5444, dark=0x12281F)
    c.pines(shore, 46, 0x16302A, size=(10, 22))


# Picture pixels between two waterfalls at least: one per cliff.
FALLS_APART = 24


def _waterfalls(c, cliffs, lake):
    """Thin white falls over the right edge of each cliff's flat top, down
    into the lake."""
    bottom = int(lake * c.h)
    flat = np.abs(np.diff(cliffs, prepend=cliffs[0])) < 2
    edges = [x for x in range(1, c.w - 4) if flat[x] and cliffs[x + 4] - cliffs[x] > 6]
    falls = []
    for x in edges:
        if not falls or x - falls[-1] > FALLS_APART:
            falls.append(x)
    for x in falls:
        top = int(round(cliffs[x]))
        for y in range(top, bottom):
            shade = 0xE8F6F2 if (y + x) % 3 else 0xA8D4D8
            c._rect(x - 1, y, 2, 1, shade)
        c._rect(x - 3, bottom - 1, 6, 1, 0xE8F6F2)


def _lake(c, top, bottom):
    """A still lake between the cliffs and the shore, with light streaks."""
    # On down to the bottom: the shore in front covers the rest.
    c._rect(0, int(top * c.h), c.w, c.h, 0x5A9A92)
    for _ in range(70):
        x = int(c.rng.integers(0, c.w))
        y = int(c.rng.integers(int(top * c.h) + 1, int(bottom * c.h)))
        c._rect(x, y, int(c.rng.integers(3, 10)), 1, 0xB8DCC4)


def level10(c):
    """The field over the base with the rocket: a hot, hazy afternoon on an
    olive plain, a rocket waiting on its launch tower far away, radar
    dishes and flat-crowned trees."""
    c.sky([(0, 0x0C5470), (0.5, 0x36A0AC), (0.8, 0xC4E0A0), (1, 0xF6F0B0)])
    c.disc(c.w * 0.18, c.h * 0.16, 9, 0xFFFDE8, glow=0xF0F8C8, glow_size=16)
    c.clouds(5, 0.1, 0.36, 0xF4FAF0, 0xB0D4C8, size=(18, 40))
    plain = c.hills(0.7, 1.0, [(43, 0.006)])
    c.fill_below(plain, 0xA8A868, rim=0xC0C080)
    tower = int(c.w * 0.64)
    _launch_tower(c, tower, c.footing(plain, tower - 4, 24) - 2)
    for x in (int(c.w * 0.3), int(c.w * 0.86)):
        _radar(c, x, c.footing(plain, x, 2))
    c.haze(0xF6F0B0, 0.5, 0.7, 0.7)
    near = c.hills(0.8, 1.0, [(59, 0.015), (17, 0.005)])
    c.fill_below(near, 0x6A7A34, rim=0x8C9A48, dark=0x4C5A24)
    for x in (24, 98, 150, 236, 300, 352):
        _flat_tree(c, near, x)


def _launch_tower(c, x, ground):
    """A rocket on its launch tower: girders, a white body, a red nose and
    fins."""
    c.lattice(x, ground - 62, 5, ground, 0x6A6A5A)
    c._rect(x + 5, ground - 50, 4, 1, 0x6A6A5A)
    body = x + 9
    c._rect(body, ground - 52, 6, 46, 0xF0F0E8)
    c._rect(body + 4, ground - 52, 2, 46, 0xC8C8C0)
    for k in range(7):
        c._rect(body + 3 - k // 2, ground - 59 + k, 1 + (k // 2) * 2, 1, 0xC83C30)
    c._rect(body - 3, ground - 10, 3, 10, 0xC83C30)
    c._rect(body + 6, ground - 10, 3, 10, 0xC83C30)
    c._rect(x - 4, ground, 24, 2, 0x6A6A5A)


def _radar(c, x, ground):
    """A radar dish on a short stand, looking up at the sky."""
    c._rect(x, ground - 6, 2, 7, 0x7A7A68)
    for k in range(5):
        c._rect(x - 6 + k, ground - 12 + k, 14 - 2 * k, 1, 0xE0E0D0 if k else 0xFFFFF0)
    c._rect(x, ground - 15, 1, 4, 0x7A7A68)


def _flat_tree(c, line, x):
    """A tree of the plains: a thin trunk and a wide, flat crown."""
    ground = c.footing(line, x - 1, 3)
    c._rect(x - 1, ground - 16, 2, 17, 0x3A3018)
    c._rect(x - 12, ground - 20, 24, 4, 0x3E5A20)
    c._rect(x - 9, ground - 23, 18, 3, 0x4E6A28)
    c._rect(x - 9, ground - 23, 10, 1, 0x6A8A38)


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
    """The prison camp by the sea, with its barbed wire and towers: a clear
    winter night with an aurora over a dark, frozen sea, ice floes, a
    ringed planet low in the sky and a watchtower whose searchlight sweeps
    the sky."""
    c.sky([(0, 0x040714), (0.5, 0x0A1A30), (0.8, 0x123048), (1, 0x1E4858)])
    c.stars(170, 0.0, 0.7)
    c.curtains(0.4, 0.3, [(71, 0.08), (23, 0.03), (9, 0.008)], 0x58F8A8, 0x8848C0)
    c.curtains(0.56, 0.12, [(41, 0.03), (13, 0.01)], 0x38B0A0, 0x3C3C90, strength=0.45)
    c.disc(c.w * 0.83, c.h * 0.22, 11, 0xC8A8D8, shade=0x8C6CA8)
    c.ring(c.w * 0.83, c.h * 0.22, 11, 0xE8D8F0)
    horizon = 0.72
    _icebergs(c, horizon)
    c.plain(horizon, 0x0C2232)
    _ice_floes(c, horizon)
    _watchtower(c, int(c.w * 0.38), horizon)
    shore = c.ridge(0.88, 0.5, 0.02)
    c.fill_below(shore, 0x081420, rim=0x142838)


def _icebergs(c, horizon):
    """Icebergs on the horizon, some flat-topped, some pointed, lit from the
    left and in shadow on the right."""
    x = np.arange(c.w, dtype=float)
    line = np.full(c.w, horizon * c.h)
    for _ in range(8):
        centre = c.rng.random() * c.w
        half = 6 + c.rng.random() * 22
        tall = 4 + c.rng.random() * 16
        slope = 0.8 + c.rng.random() * 2.5
        shape = np.minimum(tall, (half - np.abs(x - centre)) * slope)
        line = np.minimum(line, horizon * c.h - np.clip(shape, 0, None))
    c.fill_below(line, 0xB8D4E4, rim=0xEEF8FF)
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    falling = np.gradient(line) > 0.3
    shade = falling[xs] & (ys > line[xs]) & (ys < horizon * c.h)
    c.px[shade] = rgb(0x7896B0)


def _ice_floes(c, horizon):
    """Flat floes on the sea, small and close together far away, larger
    near; and the aurora's light on the water."""
    top = int(horizon * c.h) + 2
    for _ in range(40):
        y = int(c.rng.integers(top, int(0.9 * c.h)))
        near = (y - top) / (0.9 * c.h - top)
        width = int(4 + near * 26 * c.rng.random())
        x = int(c.rng.integers(0, c.w))
        c._rect(x, y, width, 1 + int(near * 2), 0xA8C4D4)
        c._rect(x + 1, y, max(width - 2, 1), 1, 0xE0F0F8)
    for _ in range(90):
        y = int(c.rng.integers(top, int(0.86 * c.h)))
        x = int(c.rng.integers(0, c.w))
        c._rect(x, y, int(c.rng.integers(2, 7)), 1, 0x2E7A6A)


def _watchtower(c, x, horizon):
    """A tall watchtower on a rock in the sea, its searchlight beam slanting
    up into the sky."""
    ground = int(horizon * c.h) + 8
    c.lattice(x, ground - 64, 9, ground, 0x5A7088)
    # The rock in front of the tower's feet, so that it stands in it.
    c._blob(x + 4, ground, 13, 0x1A2A38, flat_below=ground + 4)
    c._rect(x - 4, ground - 74, 17, 10, 0x4A6078)
    c._rect(x - 2, ground - 71, 13, 4, 0xF0E090)
    c._rect(x - 6, ground - 77, 21, 3, 0x5A7088)
    c._rect(x + 3, ground - 81, 3, 4, 0x5A7088)
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    dx, dy = xs - (x + 4), (ground - 70) - ys
    beam = (dy > 0) & (dx < 0) & (np.abs(dy * 1.6 + dx) < -dx * 0.12 + 1)
    lit = beam & (BAYER[ys % 4, xs % 4] < 0.5 - np.clip(-dx / (c.w * 0.5), 0, 0.45))
    c.px[lit] = (c.px[lit] + rgb(0xF0E8B0)) / 2


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
    9: (level09, NARROW),
    10: (level10, NARROW),
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
