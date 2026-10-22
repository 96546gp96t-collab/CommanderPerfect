#!/usr/bin/env python3
"""Paints the back walls of Keen 2's rooms into assets/backgrounds/keen2/.

Keen 2 is played inside the Vorticon Mothership. In widescreen the light
grey lattice behind its rooms makes way for a wall that is fixed to the
level (LevelWall): one texture per level, repeated in both directions at one
texture pixel per game pixel, like the tiles. So every texture here is
seamless (tools/background_painter.py, Tile) and painted in the game's
chunky pixels with a small palette. Our own drawing, nothing from the game
files, and nothing that follows a level's shape.

A wall per kind of room (the user's choice): steel panels with rivets and
pipes in the corridors and halls (1, 2, 3); a control room with cable runs,
small dark screens and warning lights in the Tantalus Centers (4, 6, 7, 9,
11, 13, 15, 16), each a little different in tint; the crew's quarters with
warm panels and lamps in Home A and B (8, 10); dark machinery, hazard
stripes and red lamps in the weaponry and the dark shaft (5, 12, 14).

Every wall is quiet and darker than the items, so Keen, the enemies and the
items stand out as they do on the original lattice. The game darkens the
wall to 45% in the shadow of a wall, and in levels 5 and 14 shows it at 35%
in the dark parts, so the main shapes are drawn in clear steps of
brightness that still read when dimmed.

Usage:
    python3 tools/make_keen2_walls.py [OUT_DIR]

Needs Pillow and NumPy. The same textures come out every time (fixed seeds).
"""

import os
import sys

import numpy as np

from background_painter import Tile, rgb

# Every texture is this large: a multiple of the 16-pixel tiles, large
# enough that its repeats are not seen at a glance.
SIZE = 256
# The steel plates of the corridors and the control rooms.
PLATE = 32
# Rows of plates between two pipes or cable runs.
RUN_ROWS = 4


def _tinted(colour, tint):
    """`colour` (0xRRGGBB) with its channels scaled by `tint`, as 0xRRGGBB."""
    r, g, b = np.clip(np.round(rgb(colour) * np.array(tint)), 0, 255).astype(int)
    return (int(r) << 16) | (int(g) << 8) | int(b)


class Palette:
    """The handful of colours of one wall, all tinted alike."""

    def __init__(self, tint, **colours):
        for name, colour in colours.items():
            setattr(self, name, _tinted(colour, tint))


# Plates and pipes ------------------------------------------------------------


def _plate_row(t, y, height, widths, p, rivets=True):
    """A row of riveted steel plates of the given widths, starting at a
    random place so that the seams of the rows do not line up."""
    x = int(t.rng.integers(0, t.w // PLATE)) * PLATE // 2
    for width in widths:
        face = p.face_alt if t.rng.random() < 0.3 else p.face
        t.bevel(x, y, width, height, face, p.light, p.shade, seam=p.seam)
        t.speckle(x + 2, y + 2, width - 4, height - 4, p.grain, 0.03)
        if rivets:
            for rx, ry in ((3, 3), (width - 5, 3), (3, height - 5), (width - 5, height - 5)):
                t.dot(x + rx, y + ry, p.rivet)
                t.dot(x + rx + 1, y + ry + 1, p.seam)
        x += width


def _plate_widths(t, total, choices):
    """Plate widths from `choices` that add up to `total` exactly."""
    widths = []
    while sum(widths) < total:
        left = total - sum(widths)
        fits = [c for c in choices if c <= left]
        widths.append(int(t.rng.choice(fits)) if fits else left)
    return widths


def _pipe(t, y, p, thick=6, clamp_every=64, flange_every=128):
    """A horizontal pipe across the whole texture: a round shade from its
    lit top to its dark bottom, held by clamps, with a flange now and then."""
    shades = [p.pipe_edge, p.pipe_lit, p.pipe_mid, p.pipe_mid, p.pipe_dark, p.pipe_edge]
    shades = shades[:2] + [p.pipe_mid] * (thick - 4) + shades[-2:]
    for k, colour in enumerate(shades):
        t.rect(0, y + k, t.w, 1, colour)
    for x in range(8, t.w, clamp_every):
        t.rect(x, y - 2, 3, thick + 4, p.seam)
        t.rect(x, y - 2, 1, thick + 4, p.pipe_dark)
    for x in range(40, t.w, flange_every):
        t.rect(x, y - 1, 2, thick + 2, p.pipe_lit)
        t.rect(x + 2, y - 1, 1, thick + 2, p.pipe_edge)


def _conduit(t, x, p, thick=3):
    """A thin pipe running up the whole texture."""
    t.rect(x, 0, 1, t.h, p.pipe_edge)
    t.rect(x + 1, 0, 1, t.h, p.pipe_lit)
    t.rect(x + 2, 0, thick - 2, t.h, p.pipe_dark)
    t.rect(x + thick, 0, 1, t.h, p.pipe_edge)
    for y in range(20, t.h, 64):
        t.rect(x - 1, y, thick + 3, 2, p.seam)


def _vent(t, x, y, w, h, p):
    """A grille of horizontal slats in a plate."""
    t.inset(x, y, w, h, p.seam, p.light, p.shade)
    for k in range(1, h, 2):
        t.rect(x, y + k, w, 1, p.shade)


def _hatch(t, x, y, p):
    """A small service hatch in a plate: a sunken door with a handle."""
    t.inset(x, y, 18, 14, p.shade, p.face, p.seam)
    t.rect(x + 1, y + 1, 16, 1, p.face_alt)
    t.rect(x + 7, y + 6, 4, 2, p.rivet)
    t.dot(x + 7, y + 8, p.seam)


def _tag(t, x, y, p):
    """A little striped tag riveted to a plate (no writing on it)."""
    t.rect(x - 1, y - 1, 14, 6, p.seam)
    for k in range(12):
        t.rect(x + k, y, 1, 4, p.tag if (k // 2) % 2 == 0 else p.tag_dark)


def _plates(t, p, choices, rivets=True):
    """The whole texture as rows of plates."""
    for row in range(t.h // PLATE):
        _plate_row(t, row * PLATE, PLATE, _plate_widths(t, t.w, choices), p, rivets)


# Corridors and halls (1, 2, 3) -----------------------------------------------


def _steel(tint):
    return Palette(
        tint,
        face=0x3E4450, face_alt=0x3A404B, light=0x545C6A, shade=0x30353F, seam=0x23262E,
        grain=0x383E49,
        rivet=0x6C7584, pipe_edge=0x23262E, pipe_lit=0x7C8492, pipe_mid=0x5A616E,
        pipe_dark=0x3A3F49, tag=0x8C7A3A, tag_dark=0x2C2A26,
    )


def corridor01(t):
    """Steel plates, two wide ones to a narrow one, and one big pipe."""
    p = _steel((1.0, 1.0, 1.0))
    t.fill(p.face)
    _plates(t, p, (32, 64, 64))
    _pipe(t, 3 * PLATE - 7, p, thick=8)
    _vent(t, 2 * PLATE + 6, 5 * PLATE + 8, 20, 9, p)
    _vent(t, 6 * PLATE + 6, 1 * PLATE + 8, 20, 9, p)
    _hatch(t, 4 * PLATE + 7, 6 * PLATE + 9, p)
    _tag(t, 0 * PLATE + 10, 3 * PLATE + 5, p)
    _tag(t, 5 * PLATE + 10, 3 * PLATE + 5, p)


def corridor02(t):
    """Square steel plates in a cooler grey, a thin pipe pair and a pipe
    running up."""
    p = _steel((0.94, 1.02, 1.06))
    t.fill(p.face)
    _plates(t, p, (32, 32, 64))
    _pipe(t, 2 * PLATE - 5, p, thick=4, clamp_every=128)
    _pipe(t, 2 * PLATE + 1, p, thick=4, clamp_every=128)
    _pipe(t, 6 * PLATE - 7, p, thick=6)
    _conduit(t, 5 * PLATE + 13, p)
    _hatch(t, 1 * PLATE + 7, 4 * PLATE + 9, p)
    _vent(t, 3 * PLATE + 6, 0 * PLATE + 9, 20, 9, p)
    _tag(t, 6 * PLATE + 10, 6 * PLATE + 4, p)


def corridor03(t):
    """Long steel plates in a warmer grey, a pipe and two vents."""
    p = _steel((1.05, 1.0, 0.95))
    t.fill(p.face)
    _plates(t, p, (64, 64, 96))
    _pipe(t, 4 * PLATE - 7, p, thick=6)
    _conduit(t, 2 * PLATE + 13, p)
    for vx, vy in ((4 * PLATE + 6, 1 * PLATE + 9), (6 * PLATE + 6, 6 * PLATE + 9)):
        _vent(t, vx, vy, 20, 9, p)
    _hatch(t, 0 * PLATE + 7, 6 * PLATE + 9, p)
    _tag(t, 5 * PLATE + 10, 4 * PLATE + 12, p)


# Tantalus Centers: control rooms (4, 6, 7, 9, 11, 13, 15, 16) ---------------


def _control(tint):
    return Palette(
        tint,
        face=0x3A4044, face_alt=0x363C40, light=0x4E565C, shade=0x2E3337, seam=0x1E2225,
        grain=0x343A3E, rivet=0x666E74, tray=0x182024, tray_lit=0x3A4A50,
        cable_a=0x6A2A26, cable_b=0x285A3E, cable_c=0x6A5E24, cable_d=0x2C3E66,
        screen=0x0C1416, glow=0x2E8A5E, glow_dim=0x1E5440,
        red=0xC8382C, amber=0xD0962C, green=0x3CA05A, off=0x3A3030,
        pipe_edge=0x1E2225, pipe_lit=0x6E767C, pipe_mid=0x4E565C, pipe_dark=0x30363A,
        dial=0x8A9296,
    )


def _cable_run(t, y, p, cables):
    """A tray of cables across the whole texture, held by clips."""
    height = 2 * len(cables) + 2
    t.rect(0, y, t.w, height, p.tray)
    t.rect(0, y - 1, t.w, 1, p.tray_lit)
    for k, colour in enumerate(cables):
        t.rect(0, y + 1 + 2 * k, t.w, 1, colour)
        t.rect(0, y + 2 + 2 * k, t.w, 1, p.tray)
    for x in range(12, t.w, PLATE):
        t.rect(x, y - 1, 2, height + 2, p.tray_lit)


def _cable_drop(t, x, y0, y1, p, cables):
    """Cables leaving the tray and running down to an instrument."""
    for k, colour in enumerate(cables):
        t.rect(x + 2 * k, y0, 1, y1 - y0, colour)


def _screen(t, x, y, p):
    """A small dark screen with a dim trace on it: a wave, bars or a dot."""
    w, h = 18, 11
    t.inset(x, y, w, h, p.screen, p.light, p.seam)
    kind = int(t.rng.integers(0, 3))
    if kind == 0:
        for k in range(w):
            t.dot(x + k, y + 4 + int(round(2.4 * np.sin(k * 0.9 + t.rng.random()))), p.glow)
    elif kind == 1:
        for k in range(1, w - 1, 3):
            tall = int(t.rng.integers(1, h - 2))
            t.rect(x + k, y + h - 1 - tall, 2, tall, p.glow_dim)
            t.dot(x + k, y + h - 1 - tall, p.glow)
    else:
        t.rect(x, y + h // 2, w, 1, p.glow_dim)
        t.rect(x + w // 2, y, 1, h, p.glow_dim)
        t.dot(x + 3 + int(t.rng.integers(0, w - 6)), y + 2 + int(t.rng.integers(0, h - 4)), p.glow)


def _lights(t, x, y, p, count):
    """A row of small warning lights, some of them off."""
    for k in range(count):
        colour = (p.red, p.amber, p.green, p.off)[int(t.rng.integers(0, 4))]
        t.rect(x + 4 * k - 1, y - 1, 4, 4, p.seam)
        t.rect(x + 4 * k, y, 2, 2, colour)


def _dial(t, x, y, p):
    """A round gauge with its needle."""
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            d = dx * dx + dy * dy
            if d <= 20:
                t.dot(x + dx, y + dy, p.seam if d > 12 else p.screen)
    angle = t.rng.random() * np.pi
    for k in range(4):
        t.dot(x - round(k * np.cos(angle)), y - round(k * np.sin(angle)), p.dial)
    t.dot(x, y, p.red)


def _switches(t, x, y, p, count):
    """A row of small toggle switches."""
    for k in range(count):
        up = t.rng.random() < 0.5
        t.rect(x + 3 * k, y, 2, 3, p.seam)
        t.dot(x + 3 * k, y + (0 if up else 2), p.rivet)


def tantalus(tint, seed_cables):
    """A control room: plates, two cable runs, and instruments on some of
    the plates (screens, warning lights, switches)."""

    def paint(t):
        p = _control(tint)
        t.fill(p.face)
        _plates(t, p, (32, 32, 64), rivets=False)
        cables = [p.cable_a, p.cable_b, p.cable_c, p.cable_d]
        order = np.random.default_rng(seed_cables).permutation(4)
        first = [cables[i] for i in order[:3]]
        second = [cables[i] for i in order[1:]]
        _cable_run(t, PLATE - 5, p, first)
        _cable_run(t, 5 * PLATE - 5, p, second)
        for row in range(t.h // PLATE):
            if row in (0, 4):
                continue
            for col in range(t.w // PLATE):
                _instrument(t, col * PLATE, row * PLATE, p)
        for x in (3 * PLATE + 20, 7 * PLATE + 20):
            _cable_drop(t, x, PLATE + 3, 2 * PLATE + 6, p, first[:2])

    return paint


def _instrument(t, x, y, p):
    """Maybe something on the plate at (x, y): most plates stay plain."""
    roll = t.rng.random()
    if roll < 0.18:
        _screen(t, x + 6, y + 7, p)
    elif roll < 0.3:
        _lights(t, x + 7, y + 13, p, 5)
    elif roll < 0.38:
        _switches(t, x + 8, y + 12, p, 5)
    elif roll < 0.46:
        _dial(t, x + 10, y + 14, p)
        _dial(t, x + 21, y + 14, p)


# Home A and B: the crew's quarters (8, 10) -----------------------------------


def _quarters(tint):
    return Palette(
        tint,
        face=0x4E3C34, light=0x664E40, shade=0x3E2F29, seam=0x2A1F1B, grain=0x473630,
        low=0x3A2C27, low_light=0x4C3A32, low_shade=0x2C211D,
        trim=0x7A5A40, trim_lit=0x9A7650, trim_dark=0x4A3626,
        lamp=0xF0D890, lamp_rim=0xB89A5A, glow=0x6A5240, glow_far=0x5C4638,
        rivet=0x7A6050,
    )


def _lamp(t, cx, cy, p):
    """A small wall lamp: a warm bulb under a shade, with a soft halo on
    the wall around it."""
    for r, colour, every in ((14, p.glow_far, 2), (9, p.glow_far, 1), (6, p.glow, 1)):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy * 1.5 <= r * r and (dx + dy) % 2 == 0 and dy % every == 0:
                    t.dot(cx + dx, cy + dy, colour)
    t.rect(cx - 5, cy - 4, 11, 3, p.trim_dark)
    t.rect(cx - 4, cy - 4, 9, 1, p.trim)
    t.rect(cx - 3, cy - 1, 7, 3, p.lamp_rim)
    t.rect(cx - 2, cy - 1, 5, 2, p.lamp)
    t.rect(cx - 1, cy - 8, 3, 4, p.trim_dark)


def home(tint, upper_width, slat, lamp_every):
    """The crew's quarters: warm panels above, a dark wainscot of slats
    below, a trim rail between them with lamps above it."""

    def paint(t):
        p = _quarters(tint)
        t.fill(p.face)
        rail = 160
        for x in range(0, t.w, upper_width):
            for y, h in ((0, 80), (80, 80)):
                t.bevel(x, y, upper_width, h, p.face, p.light, p.shade, seam=p.seam)
                t.speckle(x + 2, y + 2, upper_width - 4, h - 4, p.grain, 0.03)
                t.inset(x + 6, y + 8, upper_width - 13, h - 17, p.face, p.light, p.shade)
        t.rect(0, rail, t.w, t.h - rail, p.low)
        for x in range(0, t.w, slat):
            t.rect(x, rail, 1, t.h - rail, p.low_light)
            t.rect(x + slat - 1, rail, 1, t.h - rail, p.low_shade)
        t.speckle(0, rail, t.w, t.h - rail, p.low_shade, 0.02)
        t.rect(0, rail - 6, t.w, 6, p.trim)
        t.rect(0, rail - 6, t.w, 1, p.trim_lit)
        t.rect(0, rail - 1, t.w, 1, p.trim_dark)
        t.rect(0, t.h - 6, t.w, 6, p.trim_dark)
        t.rect(0, t.h - 6, t.w, 1, p.trim)
        for x in range(lamp_every // 2, t.w, lamp_every):
            _lamp(t, x, rail - 22, p)
        for x in range(upper_width // 2, t.w, upper_width):
            t.dot(x, 3, p.rivet)
            t.dot(x, 83, p.rivet)

    return paint


# Weaponry and the dark shaft (5, 12, 14) -------------------------------------


def _machinery(tint):
    return Palette(
        tint,
        face=0x34343A, face_alt=0x313136, light=0x48484F, shade=0x28282D, seam=0x18181C,
        grain=0x2E2E33,
        rivet=0x60606A, stripe=0xA8862A, stripe_dark=0x1E1C1A,
        red=0xE0402E, red_core=0xFFA080, red_glow=0x5A2A28,
        pipe_edge=0x18181C, pipe_lit=0x707078, pipe_mid=0x50505A, pipe_dark=0x34343C,
        gear=0x404048, gear_lit=0x5C5C66,
    )


def _hazard(t, y, p, height=8):
    """A band of yellow and black diagonal stripes across the texture."""
    for k in range(height):
        for x in range(t.w):
            t.dot(x, y + k, p.stripe if ((x + k) // 4) % 2 == 0 else p.stripe_dark)
    t.rect(0, y - 1, t.w, 1, p.seam)
    t.rect(0, y + height, t.w, 1, p.seam)


def _red_lamp(t, cx, cy, p):
    """A red warning lamp in a dark housing, with a little glow around it."""
    for dy in range(-5, 6):
        for dx in range(-5, 6):
            if dx * dx + dy * dy <= 25 and (dx + dy) % 2 == 0:
                t.dot(cx + dx, cy + dy, p.red_glow)
    t.rect(cx - 2, cy - 2, 5, 5, p.seam)
    t.rect(cx - 1, cy - 1, 3, 3, p.red)
    t.dot(cx - 1, cy - 1, p.red_core)


def _piston(t, x, y0, y1, p):
    """A hydraulic piston: a wide cylinder with a bright rod coming out."""
    mid = (y0 + y1) // 2
    t.rect(x - 1, y0, 9, mid - y0, p.seam)
    t.rect(x, y0, 2, mid - y0, p.pipe_lit)
    t.rect(x + 2, y0, 4, mid - y0, p.pipe_mid)
    t.rect(x + 6, y0, 1, mid - y0, p.pipe_dark)
    t.rect(x + 2, mid, 3, y1 - mid, p.pipe_lit)
    t.rect(x + 4, mid, 1, y1 - mid, p.pipe_dark)
    t.rect(x - 2, y0 - 2, 11, 2, p.light)
    t.rect(x - 2, y1, 11, 2, p.light)


def _gear(t, cx, cy, r, p):
    """A cog wheel: teeth round a disc with a hub."""
    ys, xs = np.mgrid[0 : t.h, 0 : t.w]
    dx = (xs - cx + t.w // 2) % t.w - t.w // 2
    dy = (ys - cy + t.h // 2) % t.h - t.h // 2
    d = np.hypot(dx, dy)
    angle = np.arctan2(dy, dx)
    teeth = (np.cos(angle * 10) > 0.2) & (d < r + 2)
    t.mask((d < r) | teeth, p.seam)
    t.mask(d < r - 1, p.gear)
    t.mask((d < r - 1) & (dx + dy < -r * 0.6), p.gear_lit)
    t.mask(d < r * 0.45, p.seam)
    t.mask(d < r * 0.3, p.gear_lit)


def weaponry(tint, lamp_cols, gears, pistons):
    """Dark machinery: heavy riveted plates, a hazard band, red lamps,
    pistons and cog wheels."""

    def paint(t):
        p = _machinery(tint)
        t.fill(p.face)
        _plates(t, p, (32, 64))
        _hazard(t, 4, p)
        _hazard(t, 132, p, height=4)
        _pipe(t, 96, p, thick=6)
        for x in lamp_cols:
            _red_lamp(t, x, 28, p)
            _red_lamp(t, x + 128, 156, p)
        for x, y0, y1 in pistons:
            _piston(t, x, y0, y1, p)
        for cx, cy, r in gears:
            _gear(t, cx, cy, r, p)

    return paint


# Level number: (painter, seed). The Tantalus Centers differ in tint (each
# city a little) and in where their instruments are.
WALLS = {
    1: corridor01,
    2: corridor02,
    3: corridor03,
    4: tantalus((0.95, 1.04, 1.06), 1),
    5: weaponry((0.95, 0.85, 0.78), (40, 168), [(200, 200, 13)], [(76, 150, 236)]),
    6: tantalus((1.24, 0.98, 0.74), 2),
    7: tantalus((0.84, 1.08, 1.08), 3),
    8: home((1.0, 1.0, 1.0), 64, 8, 128),
    9: tantalus((0.9, 0.98, 1.16), 4),
    10: home((1.0, 0.9, 1.06), 32, 6, 64),
    11: tantalus((1.06, 0.92, 1.12), 5),
    12: weaponry((0.9, 1.04, 1.0), (88, 216), [(40, 200, 11), (176, 72, 9)], [(140, 150, 236)]),
    13: tantalus((1.14, 0.98, 0.86), 6),
    14: weaponry((0.92, 0.95, 1.08), (24, 152), [(110, 210, 14)], [(200, 40, 92), (40, 150, 236)]),
    15: tantalus((1.16, 0.92, 0.92), 7),
    16: tantalus((1.0, 1.0, 1.02), 8),
}


def paint(number):
    """The wall of level `number`, painted."""
    tile = Tile(SIZE, SIZE, seed=2200 + number)
    WALLS[number](tile)
    return tile


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "assets", "backgrounds", "keen2")
    os.makedirs(out, exist_ok=True)
    for number in WALLS:
        path = os.path.join(out, "wall%02d.webp" % number)
        paint(number).save(path)
        print(path)


if __name__ == "__main__":
    main()
