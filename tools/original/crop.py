"""Crop and enlarge a snapshot with an 8-pixel grid: crop.py <framesdir> <snap> x0 y0 x1 y1 scale"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frames as F
d, name = sys.argv[1], sys.argv[2]
x0, y0, x1, y1, sc = map(int, sys.argv[3:8])
rgb = F.load_snap(d, name, 320, 200)
W, H = (x1 - x0) * sc, (y1 - y0) * sc
out = bytearray(W * H * 3)
for y in range(H):
    for x in range(W):
        sx, sy = x0 + x // sc, y0 + y // sc
        p = rgb[(sy * 320 + sx) * 3:(sy * 320 + sx) * 3 + 3]
        if (sx % 8 == 0 and x % sc == 0) or (sy % 8 == 0 and y % sc == 0):
            p = bytes([0, 200, 0]) if (sx % 40 == 0 and x % sc == 0) or (sy % 40 == 0 and y % sc == 0) else bytes([200, 200, 0])
        out[(y * W + x) * 3:(y * W + x) * 3 + 3] = p
F.save_png(os.path.join(d, name + "_crop.png"), W, H, bytes(out))
