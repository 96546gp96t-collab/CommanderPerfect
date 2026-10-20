"""Convert snapshot .rgb files (from K.snap) to PNG: python3 -I snap2png.py <framesdir> <name> <w> <h>"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frames as F
d, name, w, h = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
rgb = F.load_snap(d, name, w, h)
w, h, rgb = F.downscale(w, h, rgb) if (w, h) != (640, 400) or "--keep" not in sys.argv else (w, h, rgb)
F.save_png(os.path.join(d, name + ".png"), w, h, rgb)
