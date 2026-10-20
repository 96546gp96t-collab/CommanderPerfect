#!/usr/bin/env python3
"""Paints the pictures behind Keen 4's levels into assets/backgrounds/keen4/.

Our own pictures, drawn from code with the canvas of
tools/background_painter.py (as Keen 3's): nothing in them comes from the
game files. Each picture is painted small, in the chunky pixels of the
game, and blown up without smoothing. Only the levels whose top row has
plain sky get one (GalaxyBackdropPictures): 5, 7, 8, 9, 10, 11, 12, 13, 14
and 16. The picture shows through the level's sky colour, around clouds,
palm leaves and pyramid steps, so every scene keeps its land low (the
level has its own) and its sky calm behind the clouds of the level. Each
scene fits its level: icy peaks behind the Chasm of Chills, a hill village
behind Hillville, buttes and dunes behind Sand Yego, a mirage behind
Miragia, palms on a lake behind the oasis, desert pyramids behind the four
pyramids and a volcano across the sea behind the Isle of Fire.

Usage:
    python3 tools/make_keen4_backgrounds.py [OUT_DIR]

Needs Pillow and NumPy. The same picture comes out every time (fixed seeds).
"""

import math
import os
import sys

import numpy as np

from background_painter import BAYER, NARROW, WIDE, Canvas, mix, rgb

# Things in the desert -----------------------------------------------------


def _pyramid(c, cx, ground, half, tall, lit, shade, courses=0, course=None, sun_left=True):
    """A pyramid standing on `ground`: one face in the light, the other in
    shadow, with optional rows of stone blocks (`courses` rows apart)."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    up = ground - ys
    inside = (up >= 0) & (up <= tall) & (np.abs(xs - cx) <= half * (1 - up / tall))
    left = xs < cx
    c.px[inside & (left == sun_left)] = rgb(lit)
    c.px[inside & (left != sun_left)] = rgb(shade)
    if courses and course is not None:
        rows = inside & (up % courses == courses - 1) & (up > 0)
        c.px[rows] = mix(c.px[rows], rgb(course), 0.6)


def _dunes(c, base, waves, colour, rim, shade, phase=0.0, sun_left=True):
    """A row of dunes: sharp crests, the side away from the sun in shadow
    just below the crest. Returns the skyline."""
    x = np.arange(c.w, dtype=float)
    line = np.full(c.w, base * c.h)
    for i, (length, height) in enumerate(waves):
        wave = np.sin(x / length + phase + i * 2.3)
        # Steeper on one side: a dune's slip face.
        line -= (np.abs(wave) ** 0.7 * np.sign(wave) + 1) * 0.5 * height * c.h
    c.fill_below(line, colour, rim=rim)
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    slope = np.gradient(line)
    away = slope > 0.05 if sun_left else slope < -0.05
    depth = np.clip(np.abs(slope) * 40, 0, 12)
    below = ys - np.round(line).astype(int)[xs]
    lee = away[xs] & (below > 0) & (below < depth[xs] - BAYER[ys % 4, xs % 4] * 3)
    c.px[lee] = rgb(shade)
    return line


def _palm(c, x, ground, tall, lean, colour, fronds=7):
    """A palm tree as a silhouette: a curved trunk and drooping fronds."""
    top_x = x
    for k in range(tall):
        t = k / tall
        top_x = x + lean * t * t * tall * 0.35
        c._rect(int(round(top_x)), ground - k, 2 if t < 0.7 else 1, 1, colour)
    top_y = ground - tall
    length = tall * 0.5
    for i in range(fronds):
        angle = math.pi * (1.05 + 0.9 * i / max(fronds - 1, 1))
        dx, dy = math.cos(angle), math.sin(angle)
        steps = int(length * 1.4)
        for s in range(steps):
            t = s / steps
            fx = top_x + dx * length * t
            fy = top_y + dy * length * t * 0.7 + length * 0.55 * t * t
            c._rect(int(round(fx)), int(round(fy)), 2 if t < 0.5 else 1, 1, colour)
            if 0.2 < t < 0.9 and s % 2 == 0:
                c._dot(int(round(fx)), int(round(fy)) + 1, rgb(colour))


def _mirage(c, horizon, depth, tint, strength=0.45):
    """The sky and what stands on the horizon mirrored below it, in
    wavering bands, as a mirage over hot sand."""
    top = int(horizon * c.h)
    for k in range(int(depth * c.h)):
        y = top + k
        if y >= c.h:
            break
        source = top - 1 - k
        if source < 0:
            break
        shift = int(round(math.sin(k * 0.9) * (1 + k * 0.08)))
        row = np.roll(c.px[source], shift, axis=0)
        fade = strength + (1 - strength) * k / (depth * c.h)
        c.px[y] = mix(row, rgb(tint)[None, :], fade)
        if k % 3 == 2:
            c.px[y] = mix(c.px[y], rgb(tint)[None, :], 0.5)


def _column(c, x, ground, tall, colour, light, broken=False):
    """An old stone column with a capital; broken ones end in a jagged top."""
    c._rect(x - 2, ground - tall, 5, tall + 1, colour)
    c._rect(x - 2, ground - tall, 1, tall + 1, light)
    c._rect(x - 4, ground - 2, 9, 3, colour)
    if broken:
        for k in range(5):
            c._rect(x - 2 + k, ground - tall - (k * 3) % 4, 1, (k * 3) % 4, colour)
    else:
        c._rect(x - 4, ground - tall - 3, 9, 3, colour)
        c._rect(x - 4, ground - tall - 3, 9, 1, light)


def _obelisk(c, x, ground, tall, colour, light):
    """A tall needle of stone with a pointed tip."""
    c._rect(x - 3, ground - tall, 7, tall + 1, colour)
    c._rect(x - 3, ground - tall, 2, tall + 1, light)
    for k in range(4):
        c._rect(x - 3 + k, ground - tall - 4 + k, 7 - 2 * k, 1, colour)


def _sea(c, horizon, colour, glints, glint_colour, rim=None):
    """Flat water from the horizon down, with short light streaks."""
    c.plain(horizon, colour, rim=rim)
    top = int(horizon * c.h) + 1
    for _ in range(glints):
        y = int(c.rng.integers(top, c.h))
        near = (y - top) / max(c.h - top, 1)
        x = int(c.rng.integers(0, c.w))
        c._rect(x, y, int(2 + near * 8 * c.rng.random()), 1, glint_colour)


def _path_of_light(c, cx, horizon, colour, width):
    """The reflection of a sun or a fire on water: streaks under it that
    widen towards the viewer."""
    top = int(horizon * c.h) + 1
    for y in range(top, c.h):
        near = (y - top) / max(c.h - top, 1)
        half = width * (0.4 + near)
        for _ in range(2):
            x = cx + (c.rng.random() - 0.5) * 2 * half
            c._rect(int(x), y, int(1 + c.rng.integers(1, 5)), 1, colour)


# The scenes, one per level ---------------------------------------------------


def level05(c):
    """The Chasm of Chills: a cold, clear morning over icy mountains, a pale
    sun low in a blue sky, glaciers on the peaks and frosted firs on the
    hills in front."""
    c.sky([(0, 0x1A3C8C), (0.45, 0x4C7CD0), (0.75, 0xA8C8EC), (1, 0xE4ECF4)])
    c.disc(c.w * 0.18, c.h * 0.42, 10, 0xFFF8E8, glow=0xD8E4F4, glow_size=20)
    far = c.peaks(0.68, 9, 0.32, 1.1)
    c.fill_below(far, 0x6A7EB4, rim=0x9AACD8)
    snow_line = c.h * 0.54
    depth = np.clip(snow_line - far, 0, None) * 1.1
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    below = ys - far[xs]
    cap = (below >= 0) & (below < depth[xs] - BAYER[ys % 4, xs % 4] * 3)
    c.px[cap] = rgb(0xF4F8FF)
    c.px[cap & (np.gradient(far) > 0)[xs]] = rgb(0xB4C4E4)
    c.haze(0xE4ECF4, 0.5, 0.7, 0.8)
    near = c.hills(0.78, 1.0, [(47, 0.02), (17, 0.006)])
    c.fill_below(near, 0x3C5A8A, rim=0xC8D8F0, dark=0x2C466E)
    c.pines(near, 34, 0x24405E, size=(8, 18))
    # Frost on the firs' tips.
    tips = (c.px == rgb(0x24405E)).all(axis=2) & (np.roll(c.px, 1, axis=0) != rgb(0x24405E)).any(axis=2)
    c.px[tips] = rgb(0xC8D8F0)


def level07(c):
    """Hillville: a sunny afternoon over rolling green hills with the round
    huts of a village on them, a warm sun high up and fat clouds."""
    c.sky([(0, 0x1E50B4), (0.5, 0x4C94E0), (0.8, 0x9CD4F0), (1, 0xD8F0E8)])
    c.disc(c.w * 0.62, c.h * 0.17, 12, 0xFFF6C8, glow=0xFFF0A0, glow_size=18)
    c.clouds(9, 0.12, 0.42, 0xFFFFFF, 0xB8D4EC, size=(16, 40))
    c.birds(6, 0.15, 0.4, 0x1E3C70)
    far = c.hills(0.66, 1.0, [(83, 0.03), (29, 0.01)], phase=0.7)
    c.fill_below(far, 0x6AA86A, rim=0x8AC47A)
    c.haze(0xD8F0E8, 0.5, 0.68, 0.7)
    near = c.hills(0.74, 1.0, [(61, 0.035), (19, 0.008)])
    c.fill_below(near, 0x3C8A44, rim=0x5CAA54, dark=0x2C6A34)
    for x in range(30, c.w, 52):
        x += int(c.rng.integers(-10, 10))
        _hut(c, near, x, int(c.rng.integers(5, 8)))
    for _ in range(9):
        x = int(c.rng.integers(0, c.w))
        _palm(c, x, c.footing(near, x - 1, 3), int(c.rng.integers(14, 22)),
              c.rng.choice([-1, 1]) * 0.5, 0x24502C)


def _hut(c, line, x, r):
    """A round hut of the village with a dark door, standing on the hill."""
    ground = c.footing(line, x - r, 2 * r)
    c._blob(x, ground, r, 0xE8D8A0, flat_below=ground)
    c._blob(x - r * 0.3, ground - r * 0.3, r * 0.5, 0xFFF0C0, flat_below=ground)
    c._rect(x - 1, ground - 3, 3, 4, 0x5A3A20)
    c._rect(x - r, ground, 2 * r + 1, 1, 0x5A3A20)


def level08(c):
    """Sand Yego: a violet dusk over the sand sea, a big low sun sinking
    behind far flat-topped buttes, pale dunes in front."""
    c.sky([(0, 0x34206A), (0.4, 0x74388C), (0.68, 0xC8648A), (0.85, 0xF8A070), (1, 0xFFD090)])
    c.stars(12, 0.0, 0.18)
    c.disc(c.w * 0.66, c.h * 0.4, 18, 0xFFE8A0, glow=0xF8A060, glow_size=26)
    buttes = c.plateaus(0.67, 5, 0.22)
    c.fill_below(buttes, 0x6A3058, rim=0x9A4A6A)
    c.haze(0xF8A070, 0.5, 0.68, 0.6)
    _dunes(c, 0.72, [(53, 0.05), (19, 0.012)], 0xC88A5A, 0xF0C080, 0x8A5A4A, phase=0.3,
           sun_left=False)
    _dunes(c, 0.8, [(37, 0.06), (13, 0.012)], 0xA86A48, 0xE0A070, 0x6A4038, phase=1.4,
           sun_left=False)


def level09(c):
    """Miragia: a shimmering pastel noon in the desert, a white-hot sun, and
    on the horizon a mirage: far buttes and domes floating over a false lake
    that mirrors them in wavering bands."""
    c.sky([(0, 0x6A5AB8), (0.45, 0xA88CD0), (0.72, 0xE8B8D8), (1, 0xFFE4D8)])
    c.disc(c.w * 0.3, c.h * 0.2, 11, 0xFFFFF4, glow=0xFFE8F0, glow_size=22)
    horizon = 0.64
    buttes = c.plateaus(horizon, 4, 0.18)
    c.fill_below(buttes, 0x9A70A8, rim=0xC898C8)
    # The far city of the mirage: domes and thin towers on the buttes.
    for x in (int(c.w * 0.14), int(c.w * 0.4), int(c.w * 0.66), int(c.w * 0.88)):
        y = c.footing(buttes, x - 8, 16)
        c._blob(x, y, 8, 0xB088C0, flat_below=y)
        c._rect(x, y - 13, 1, 5, 0xB088C0)
        c._rect(x + 10, y - 16, 2, 16, 0xB088C0)
        c._rect(x + 9, y - 18, 4, 2, 0xC8A0D0)
    c.haze(0xFFE4D8, 0.46, horizon, 0.5)
    _mirage(c, horizon, 0.1, 0xF4D4DC, strength=0.3)
    sand = c.hills(0.76, 1.0, [(71, 0.01), (23, 0.004)])
    c.fill_below(sand, 0xE8C8A0, rim=0xFFE8C8, dark=0xD8B090)


def level10(c):
    """Lifewater Oasis: a fresh morning over the oasis, a still lake in the
    dunes with palms on its far shore, the sun just up."""
    c.sky([(0, 0x1C5AA0), (0.45, 0x4CA0C8), (0.75, 0xB8E0C0), (1, 0xFFF0B8)])
    c.disc(c.w * 0.74, c.h * 0.36, 11, 0xFFF8D0, glow=0xFFE8A0, glow_size=22)
    c.clouds(4, 0.1, 0.3, 0xFFFFFF, 0xC0DCE0, size=(18, 36))
    far = _dunes(c, 0.64, [(61, 0.04), (23, 0.01)], 0xE0C088, 0xF8E0A8, 0xB8946C)
    shore = int(0.7 * c.h)
    c._rect(0, shore, c.w, c.h, 0x3A9AA8)
    _path_of_light(c, c.w * 0.74, 0.7, 0xD8F4E8, 6)
    for _ in range(14):
        x = int(c.rng.integers(0, c.w))
        _palm(c, x, shore, int(c.rng.integers(12, 20)), c.rng.choice([-1, 1]) * 0.6, 0x1E4A3A)
    c._rect(0, shore - 1, c.w, 2, 0x2A6A4A)
    c.haze(0xFFF0B8, 0.52, 0.7, 0.4)
    near = _dunes(c, 0.82, [(43, 0.04), (13, 0.008)], 0xC8A06A, 0xE8C890, 0x9A7850, phase=2.0)
    del far, near


def level11(c):
    """The Pyramid of the Moons: three moons in a deep blue evening sky with
    the first stars, two far pyramids and moonlit dunes."""
    c.sky([(0, 0x16245C), (0.5, 0x2E4E98), (0.8, 0x6A8CC4), (1, 0xA8BCD8)])
    c.stars(60, 0.0, 0.36)
    c.disc(c.w * 0.24, c.h * 0.24, 16, 0xF0ECD8, glow=0x4C64A8, glow_size=14, shade=0xC4C0B0)
    c.craters(c.w * 0.24 + 4, c.h * 0.24 - 3, 16, 0xDCD6C0, 5)
    c.disc(c.w * 0.58, c.h * 0.14, 8, 0xE8D0F0, shade=0xB8A0C8)
    c.disc(c.w * 0.83, c.h * 0.3, 5, 0xD0F0E8, shade=0xA0C8C0)
    horizon = 0.68
    for cx, half, tall in ((0.4, 50, 46), (0.66, 30, 28), (0.12, 20, 19), (0.88, 16, 15)):
        _pyramid(c, c.w * cx, horizon * c.h + 2, half, tall, 0x7A86B0, 0x3E4A7A,
                 courses=4, course=0x5A6696)
    c.haze(0x9AB0D0, 0.5, horizon, 0.5)
    _dunes(c, horizon + 0.04, [(59, 0.04), (19, 0.01)], 0x4A5A88, 0x8A9AC4, 0x323E6A)
    _dunes(c, 0.82, [(41, 0.05), (13, 0.01)], 0x34406E, 0x6A7AAA, 0x222A50, phase=1.1)


def level12(c):
    """The Pyramid of Shadows: the sun setting red behind a row of far
    pyramids, whose long shadows lie across orange dunes under a purple
    sky."""
    c.sky([(0, 0x2A1448), (0.45, 0x6A2460), (0.72, 0xC0404A), (0.9, 0xF08040), (1, 0xF8B060)])
    c.stars(20, 0.0, 0.22)
    sun_x = c.w * 0.5
    horizon = 0.68
    c.disc(sun_x, c.h * horizon - 6, 20, 0xFFD080, glow=0xF07040, glow_size=30)
    tops = []
    for k in range(5):
        cx = c.w * (0.1 + 0.2 * k) + c.rng.integers(-12, 12)
        half = int(c.rng.integers(14, 30))
        _pyramid(c, cx, horizon * c.h, half, half, 0x3A1430, 0x2A0C24)
        tops.append((cx, half))
    # Long shadows from the low sun, falling towards the viewer.
    ground = c.hills(horizon + 0.02, 1.0, [(37, 0.008)])
    c.fill_below(ground, 0xD07040, rim=0xF0A060)
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    for cx, half in tops:
        # A pyramid's shadow is a triangle on the sand, its point towards
        # the viewer (down in the picture) and away from the sun.
        down = ys - horizon * c.h
        length = half * 1.6
        lean = (cx - sun_x) / c.w * down * 2.2
        width = half * np.clip(1 - down / length, 0, 1)
        shadow = (ys > ground[xs]) & (down < length) & (np.abs(xs - cx - lean) < width)
        c.px[shadow & (BAYER[ys % 4, xs % 4] < 0.8)] = rgb(0x6A2834)
    c.haze(0xF08040, 0.6, 0.72, 0.4)
    _dunes(c, 0.84, [(47, 0.04), (17, 0.01)], 0x8A3C34, 0xC0604A, 0x5A2028, phase=0.6)


def level13(c):
    """The Pyramid of the Gnosticene Ancients: an ancient morning, a pale
    gold sky over great pyramids in the haze, and the broken columns and an
    obelisk of an old temple on the rise in front."""
    c.sky([(0, 0x2A5AA0), (0.45, 0x78A8D0), (0.75, 0xE8D8A8), (1, 0xFFE8B0)])
    c.disc(c.w * 0.14, c.h * 0.5, 14, 0xFFF8D8, glow=0xFFE8A8, glow_size=24)
    c.clouds(6, 0.1, 0.35, 0xFFF8F0, 0xD8C8B0, size=(14, 34))
    c.birds(5, 0.15, 0.38, 0x3A4A6A)
    horizon = 0.68
    for cx, half in ((0.34, 46), (0.56, 30), (0.82, 38)):
        _pyramid(c, c.w * cx, horizon * c.h, half, half * 0.95, 0xE8C890, 0xB8946C,
                 courses=5, course=0xC8A878)
    c.plain(horizon, 0xD8B888)
    c.haze(0xFFE8B0, 0.45, horizon, 0.8)
    rise = c.hills(0.78, 1.0, [(67, 0.025), (23, 0.008)])
    c.fill_below(rise, 0xB89060, rim=0xE0C088, dark=0x9A7448)
    # The temple's ruins in a few groups along the rise, columns side by
    # side, some still whole.
    for group in (0.08, 0.45, 0.63, 0.93):
        for k in range(int(c.rng.integers(2, 5))):
            x = int(c.w * group) + k * 12
            tall = int(c.rng.integers(18, 30))
            _column(c, x, c.footing(rise, x - 4, 9), tall, 0xC8B088, 0xF0E0B8,
                    broken=c.rng.random() < 0.6)
    for x in (int(c.w * 0.27), int(c.w * 0.78)):
        _obelisk(c, x, c.footing(rise, x - 3, 7), 44, 0xB09068, 0xE8D0A0)


def level14(c):
    """The Pyramid of the Forbidden: a storm in a sickly green sky, a red
    sun swallowed by dark clouds and lightning over a black pyramid on the
    horizon."""
    c.sky([(0, 0x24363A), (0.45, 0x44624E), (0.75, 0x8AA070), (1, 0xC8C888)])
    c.disc(c.w * 0.76, c.h * 0.3, 14, 0xE84030, glow=0x8A3A30, glow_size=14, shade=0xA02828)
    c.clouds(14, 0.02, 0.3, 0x3A4A44, 0x24302C, size=(24, 56))
    horizon = 0.7
    _bolt(c, c.w * 0.22, c.h * 0.12, horizon * c.h - 30)
    _bolt(c, c.w * 0.58, c.h * 0.08, horizon * c.h - 20)
    _pyramid(c, c.w * 0.4, horizon * c.h, 52, 50, 0x2A2A2A, 0x141414, courses=5,
             course=0x3A3A34)
    _pyramid(c, c.w * 0.86, horizon * c.h, 24, 23, 0x2A2A2A, 0x141414)
    c.haze(0xC8C888, 0.55, horizon, 0.5)
    _dunes(c, horizon, [(61, 0.03), (19, 0.008)], 0x6A6A44, 0x9A9A64, 0x4A4A30)
    _dunes(c, 0.82, [(43, 0.04), (13, 0.01)], 0x4A4A30, 0x707048, 0x30301E, phase=1.7)


def _bolt(c, x, top, bottom):
    """A lightning bolt from a cloud down to the land, zigzagging, with a
    soft glow around it."""
    points = []
    y = top
    while y < bottom:
        points.append((x, y))
        x += c.rng.integers(-5, 6)
        y += c.rng.integers(4, 9)
    points.append((x, bottom))
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for s in range(steps):
            t = s / steps
            px, py = int(round(x0 + (x1 - x0) * t)), int(round(y0 + (y1 - y0) * t))
            for dx in (-1, 1):
                if 0 <= px + dx < c.w and 0 <= py < c.h:
                    c.px[py, px + dx] = mix(c.px[py, px + dx], rgb(0xE8F0FF), 0.35)
            c._dot(px, py, rgb(0xFFFFFF))


def level16(c):
    """The Isle of Fire: a volcano erupting on an island across the sea at
    dusk, smoke over it, lava down its sides and its glow on the water."""
    c.sky([(0, 0x2A0C1C), (0.45, 0x6A1A28), (0.75, 0xD04A28), (1, 0xF89048)])
    c.stars(25, 0.0, 0.2)
    horizon = 0.72
    cx = c.w * 0.58
    x = np.arange(c.w, dtype=float)
    # The cone, with a flat crater on top and a wider foot.
    peak = horizon * c.h - 56
    cone = np.maximum(peak, horizon * c.h - (66 - np.abs(x - cx) * 0.9))
    cone = np.minimum(cone, horizon * c.h - np.clip(40 - np.abs(x - cx), 0, None) * 0.4)
    _smoke(c, cx, peak)
    _crater_glow(c, cx, peak)
    c.fill_below(cone, 0x2A1018, rim=0x5A2020)
    _lava(c, cx, cone, horizon)
    _sea(c, horizon, 0x4A1A2A, 60, 0x8A3A3A)
    _path_of_light(c, cx, horizon, 0xF08040, 10)
    # A low islet in front: a mound whose foot is below the picture's
    # visible part.
    mound = np.clip(1 - ((x - c.w * 0.18) / (c.w * 0.14)) ** 2, 0, None)
    islet = np.where(mound > 0, c.h * 0.9 - mound * 20, c.h + 1)
    c.fill_below(islet, 0x1A0A10, rim=0x3A1418)
    for px in (int(c.w * 0.1), int(c.w * 0.18), int(c.w * 0.26)):
        _palm(c, px, c.footing(islet, px - 1, 3), int(c.rng.integers(16, 24)), 0.6, 0x1A0A10)


def _crater_glow(c, cx, top):
    """The fire in the crater lighting the smoke above it, in dithered
    rings, and glowing bits thrown up out of it."""
    ys, xs = np.mgrid[0 : c.h, 0 : c.w]
    d = np.hypot(xs - cx, (ys - top) * 1.3)
    for radius, strength in ((22, 0.25), (14, 0.45), (8, 0.7)):
        ring = (d < radius) & (ys <= top) & (BAYER[ys % 4, xs % 4] < strength)
        c.px[ring] = mix(c.px[ring], rgb(0xFF9040), 0.6)
    for _ in range(14):
        speed = 0.6 + c.rng.random() * 0.8
        aim = (c.rng.random() - 0.5) * 1.2
        for step in range(int(10 + c.rng.random() * 12)):
            fx = cx + aim * step * 1.5
            fy = top - speed * step * 2.0 + step * step * 0.06
            if step % 3 == 0 and fy <= top:
                c._dot(int(round(fx)), int(round(fy)), rgb(0xFFC040))


def _smoke(c, cx, top):
    """A column of dark smoke rising from the crater, widening and drifting
    aside with the wind, lit red from below."""
    for k in range(60):
        t = (k / 59) ** 0.8
        spread = 3 + t * 22
        x = cx + t * t * c.w * 0.22 + c.rng.normal(0, spread * 0.5)
        y = top - 4 - t * c.h * 0.34 + c.rng.normal(0, 2)
        r = 3 + t * 8 + c.rng.random() * 3
        c._blob(x, y + 1, r, 0x5A2024 if t < 0.25 else 0x3A1A20)
        c._blob(x - r * 0.3, y - r * 0.3, r * 0.5, 0x4E2A2C)


def _lava(c, cx, cone, horizon):
    """Glowing lava running down from the crater in thin, wandering
    streams."""
    for k in range(5):
        x = cx + (k - 2) * 3
        y = int(cone[int(cx)]) + 1
        while y < horizon * c.h - 1:
            c._dot(int(round(x)), y, rgb(0xFF8030 if y % 3 else 0xFFC040))
            x += (k - 2) * 0.35 + c.rng.normal(0, 0.4)
            y += 1


# Level number: (scene, width). Levels of 100 cells and wider get the wide
# picture, which glides further; the narrower ones (58-88 cells) the 16:9
# one.
SCENES = {
    5: (level05, WIDE),
    7: (level07, WIDE),
    8: (level08, NARROW),
    9: (level09, NARROW),
    10: (level10, NARROW),
    11: (level11, WIDE),
    12: (level12, WIDE),
    13: (level13, WIDE),
    14: (level14, WIDE),
    16: (level16, WIDE),
}


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "assets", "backgrounds", "keen4")
    os.makedirs(out, exist_ok=True)
    for number, (scene, width) in SCENES.items():
        canvas = Canvas(width, seed=4000 + number)
        scene(canvas)
        path = os.path.join(out, "level%02d.webp" % number)
        canvas.save(path)
        print(path)


if __name__ == "__main__":
    main()
