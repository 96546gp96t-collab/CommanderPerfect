"""Track moving things against the per-pixel mode background of a recording.
track.py <dir> <rec> [first last] -> per frame: index, ms, vsync-estimate, bbox of changed pixels."""
import os
import sys
from collections import Counter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frames as F
d, rec = sys.argv[1], sys.argv[2]
w, h, ts, fr = F.load_rec(d, rec)
a = int(sys.argv[3]) if len(sys.argv) > 3 else 0
b = int(sys.argv[4]) if len(sys.argv) > 4 else len(fr)
x0, y0, x1, y1 = (map(int, sys.argv[5:9]) if len(sys.argv) > 8 else (0, 0, 320, 200))
sample = fr[::max(1, len(fr) // 40)]
bg = bytearray(320 * 200 * 3)
for p in range(320 * 200):
    if not (x0 <= p % 320 < x1 and y0 <= p // 320 < y1):
        continue
    c = Counter(f[p * 3:p * 3 + 3] for f in sample).most_common(1)[0][0]
    bg[p * 3:p * 3 + 3] = c
t0 = ts[a]
for i in range(a, b):
    f = fr[i]
    xs, ys = [], []
    for y in range(y0, y1):
        row = (y * 320) * 3
        for x in range(x0, x1):
            k = row + x * 3
            if f[k:k + 3] != bg[k:k + 3]:
                xs.append(x)
                ys.append(y)
    box = (min(xs), min(ys), max(xs), max(ys)) if xs else None
    print("%4d %7.1f ms %6.1f vs  %s" % (i, ts[i] - t0, (ts[i] - t0) * 70.086 / 1000, box))
