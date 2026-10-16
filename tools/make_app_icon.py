#!/usr/bin/env python3
"""Draws the app icon of CommanderPerfect: our own pixel-art Keen (yellow
helmet, purple shirt, blue jeans, as on the start screen picture) with the
letters "CP" beside him, on a gray rounded square.

Everything is drawn here from the grids below; nothing comes from the
original game files. Writes:
  assets/icon/app_icon.png   1024x1024, for the macOS build
  assets/icon/app_icon.ico   16-256 pixels, for the Windows build
  icon.svg                   the project icon (window, editor)

Usage: python3 tools/make_app_icon.py   (needs Pillow: pip install pillow)
"""

import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
GRID = 32
PNG_SIZE = 1024
ICO_SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]

COLORS = {
    "K": (16, 16, 24),  # outline
    "Y": (255, 221, 51),  # helmet, letters
    "y": (214, 170, 20),  # helmet shade
    "W": (250, 250, 250),  # helmet stripe, shoes
    "S": (255, 200, 160),  # skin
    "E": (40, 90, 220),  # eyes
    "P": (150, 40, 190),  # shirt
    "p": (110, 25, 145),  # shirt shade
    "B": (40, 70, 200),  # jeans
    "b": (25, 45, 150),  # jeans shade
    "R": (215, 30, 30),  # letter shadow
    "M": (190, 70, 70),  # mouth
    "G": (128, 128, 136),  # background
    "g": (96, 96, 104),  # background edge
    "L": (150, 150, 158),  # background light
}

# The background: a gray rounded square, one pixel of edge.
BACKGROUND = [
    "................................",
    "...gggggggggggggggggggggggggg...",
    "..gLLLLLLLLLLLLLLLLLLLLLLLLLLg..",
    ".gLGGGGGGGGGGGGGGGGGGGGGGGGGGGg.",
] + [".gGGGGGGGGGGGGGGGGGGGGGGGGGGGGg."] * 24 + [
    ".gGGGGGGGGGGGGGGGGGGGGGGGGGGGGg.",
    "..gGGGGGGGGGGGGGGGGGGGGGGGGGGg..",
    "...gggggggggggggggggggggggggg...",
    "................................",
]

# Keen, standing, facing the player. Drawn at KEEN_AT.
KEEN = [
    "...KKKKKK...",
    "..KYYWWYYK..",
    ".KYYYWWYYYK.",
    ".KYYYWWYYYK.",
    "KyYYYWWYYYYK",
    "KyYYYWWYYYYK",
    "KKKKKKKKKKKK",
    ".KSSSSSSSSK.",
    ".KSWESSWESK.",
    ".KSWESSWESK.",
    ".KSSSMMSSSK.",
    "..KSSSSSSK..",
    "...KKKKKK...",
    ".KKPPPPPPKK.",
    "KPPPPPPPPPPK",
    "KPKPPPPPPKPK",
    "KPKPPPPPPKPK",
    "KSKpPPPPpKSK",
    "KKKKBBBBKKKK",
    "...KBBBBK...",
    "...KBbKBK...",
    "...KBbKBK...",
    "..KWWWKWWWK.",
    "..KKKKKKKKK.",
]
KEEN_AT = (2, 4)

# The letters "CP": yellow, with a red shadow and a black edge, like the
# title on the start screen. Drawn at LETTERS_AT.
LETTERS = [
    ".YYYY..YYYY.",
    "YYYYY..YYYYY",
    "YY.....YY.YY",
    "YY.....YY.YY",
    "YY.....YYYYY",
    "YY.....YYYY.",
    "YYYYY..YY...",
    ".YYYY..YY...",
]
LETTERS_AT = (16, 12)


def draw(image: Image.Image, grid: list, left: int, top: int) -> None:
    for y, row in enumerate(grid):
        for x, cell in enumerate(row):
            if cell in COLORS:
                image.putpixel((left + x, top + y), COLORS[cell] + (255,))


def draw_letters(image: Image.Image, left: int, top: int) -> None:
    body = {
        (left + x, top + y)
        for y, row in enumerate(LETTERS)
        for x, cell in enumerate(row)
        if cell == "Y"
    }
    shadow = {(x + 1, y + 1) for x, y in body} - body
    shape = body | shadow
    edge = {
        (x + dx, y + dy)
        for x, y in shape
        for dx in (-1, 0, 1)
        for dy in (-1, 0, 1)
    } - shape
    for cells, color in ((edge, "K"), (shadow, "R"), (body, "Y")):
        for cell in cells:
            image.putpixel(cell, COLORS[color] + (255,))


def main() -> None:
    small = Image.new("RGBA", (GRID, GRID), (0, 0, 0, 0))
    draw(small, BACKGROUND, 0, 0)
    draw(small, KEEN, *KEEN_AT)
    draw_letters(small, *LETTERS_AT)
    big = small.resize((PNG_SIZE, PNG_SIZE), Image.NEAREST)
    big.save(ROOT / "assets/icon/app_icon.png")
    big.save(ROOT / "assets/icon/app_icon.ico", sizes=ICO_SIZES)
    (ROOT / "icon.svg").write_text(svg(small))
    print("Wrote assets/icon/app_icon.png, assets/icon/app_icon.ico and icon.svg")


def svg(image: Image.Image) -> str:
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


if __name__ == "__main__":
    main()
