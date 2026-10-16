#!/usr/bin/env python3
"""Draws the app icon of CommanderPerfect: the letters "CP", yellow with red
depth and a black edge like the title on the start screen picture, in front
of a starry Mars sky with purple mountains, on a rounded square.

Everything is drawn here from shapes and numbers; nothing comes from the
original game files. The picture is pixel art on a 64x64 grid, enlarged
without smoothing. Writes:
  assets/icon/app_icon.png   1024x1024, for the macOS build
  assets/icon/app_icon.ico   16-256 pixels, for the Windows build
  icon.svg                   the project icon (window, editor)

Usage: python3 tools/make_app_icon.py   (needs Pillow: pip install pillow)
"""

import pathlib
import random

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
GRID = 64
PNG_SIZE = 1024
ICO_SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
# The same stars every time the icon is drawn.
STAR_SEED = 1990
STAR_COUNT = 26

EDGE = (12, 10, 40)
SKY_TOP = (22, 18, 110)
SKY_BOTTOM = (48, 36, 170)
STAR = (240, 240, 255)
STAR_DIM = (130, 200, 255)
PLANET = (70, 130, 235)
PLANET_DARK = (40, 80, 180)
MOUNTAIN = (170, 40, 170)
MOUNTAIN_LIGHT = (220, 80, 210)
GROUND = (120, 110, 120)
GROUND_DARK = (90, 82, 92)
OUTLINE = (16, 12, 20)
YELLOW = (255, 225, 40)
YELLOW_LIGHT = (255, 250, 170)
YELLOW_DARK = (225, 170, 20)
RED = (215, 35, 30)
RED_DARK = (150, 20, 25)

# The rounded square: its corner radius, in grid pixels.
CORNER = 11
# How far the letters stick out towards the bottom right.
DEPTH = 3
# The tops of the purple mountains, from left to right.
PEAKS = [(1, 47), (9, 40), (14, 46), (21, 37), (27, 45), (33, 41), (40, 47), (47, 36), (54, 44), (62, 39)]
GROUND_TOP = 52


def rounded_box(x0, y0, x1, y1, radius):
    """The grid pixels of a rectangle with rounded corners (x1, y1 excluded)."""
    cells = set()
    for y in range(y0, y1):
        for x in range(x0, x1):
            dx = max(x0 + radius - x - 0.5, 0, x - (x1 - radius) + 0.5)
            dy = max(y0 + radius - y - 0.5, 0, y - (y1 - radius) + 0.5)
            if dx * dx + dy * dy <= radius * radius:
                cells.add((x, y))
    return cells


def letter_c(left, top):
    """A thick C, 22 wide and 30 high, open to the right."""
    return rounded_box(left, top, left + 22, top + 30, 9) - rounded_box(
        left + 7, top + 7, left + 30, top + 23, 4
    )


def letter_p(left, top):
    """A thick P, 22 wide and 30 high."""
    stem = rounded_box(left, top, left + 7, top + 30, 2)
    bowl = rounded_box(left, top, left + 22, top + 19, 8) - rounded_box(
        left + 7, top + 6, left + 15, top + 13, 2
    )
    return stem | bowl


def put(image, cells, color):
    for cell in cells:
        image.putpixel(cell, color + (255,))


def ridge_at(x):
    """The height of the mountains at column x, and whether that is a left flank."""
    for (xa, ya), (xb, yb) in zip(PEAKS, PEAKS[1:]):
        if xa <= x <= xb:
            return round(ya + (yb - ya) * (x - xa) / (xb - xa)), yb < ya
    return PEAKS[-1][1], False


def background():
    image = Image.new("RGBA", (GRID, GRID), (0, 0, 0, 0))
    put(image, rounded_box(0, 0, GRID, GRID, CORNER), EDGE)
    inside = rounded_box(1, 1, GRID - 1, GRID - 1, CORNER - 1)
    for x, y in inside:
        t = y / GRID
        sky = tuple(round(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_BOTTOM))
        put(image, [(x, y)], sky)
    stars = random.Random(STAR_SEED)
    for _ in range(STAR_COUNT):
        cell = (stars.randrange(4, GRID - 4), stars.randrange(4, 44))
        if cell in inside:
            put(image, [cell], STAR if stars.random() < 0.5 else STAR_DIM)
    put(image, rounded_box(47, 5, 58, 16, 5), PLANET)
    put(image, [(50, 8), (51, 8), (54, 11), (55, 11), (55, 12), (51, 13)], PLANET_DARK)
    for x in range(1, GRID - 1):
        ridge, left_flank = ridge_at(x)
        for y in range(ridge, GRID - 1):
            if (x, y) in inside:
                put(image, [(x, y)], MOUNTAIN_LIGHT if left_flank and y < ridge + 3 else MOUNTAIN)
    for x in range(1, GRID - 1):
        for y in range(GROUND_TOP, GRID - 1):
            if (x, y) in inside:
                rough = (x * 7 + y * 3) % 11 == 0 or y > GRID - 6
                put(image, [(x, y)], GROUND_DARK if rough else GROUND)
    return image


def draw_letters(image):
    face = letter_c(7, 15) | letter_p(34, 15)
    depth = {}
    for step in range(DEPTH, 0, -1):
        for x, y in face:
            cell = (x + step, y + step)
            if cell not in face:
                depth[cell] = RED_DARK if step == DEPTH else RED
    shape = face | set(depth)
    edge = {(x + dx, y + dy) for x, y in shape for dx in (-1, 0, 1) for dy in (-1, 0, 1)} - shape
    put(image, edge, OUTLINE)
    for cell, color in depth.items():
        put(image, [cell], color)
    for x, y in face:
        if (x, y - 1) not in face or (x - 1, y) not in face:
            color = YELLOW_LIGHT
        elif (x, y + 1) not in face or (x + 1, y) not in face:
            color = YELLOW_DARK
        else:
            color = YELLOW
        put(image, [(x, y)], color)


def svg(image):
    rects = []
    for y in range(GRID):
        for x in range(GRID):
            r, g, b, a = image.getpixel((x, y))
            if a:
                rects.append(f'<rect x="{x}" y="{y}" width="1" height="1" fill="#{r:02x}{g:02x}{b:02x}"/>')
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" '
        f'viewBox="0 0 {GRID} {GRID}" shape-rendering="crispEdges">\n' + "\n".join(rects) + "\n</svg>\n"
    )


def main():
    small = background()
    draw_letters(small)
    big = small.resize((PNG_SIZE, PNG_SIZE), Image.NEAREST)
    big.save(ROOT / "assets/icon/app_icon.png")
    big.save(ROOT / "assets/icon/app_icon.ico", sizes=ICO_SIZES)
    (ROOT / "icon.svg").write_text(svg(small))
    print("Wrote assets/icon/app_icon.png, assets/icon/app_icon.ico and icon.svg")


if __name__ == "__main__":
    main()
