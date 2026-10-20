"""Contact sheet of a recording: python3 -I sheet.py <framesdir> <rec> <first> <last> <step> [cols]"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frames as F

d, rec, a, b, step = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
cols = int(sys.argv[6]) if len(sys.argv) > 6 else 4
w, h, ts, fr = F.load_rec(d, rec)
sel = list(range(a, min(b, len(fr)), step))
W, H, img = F.montage([F.downscale(w, h, fr[i])[2] for i in sel], cols)
F.save_png(os.path.join(d, "%s_sheet_%d_%d.png" % (rec, a, b)), W, H, img)
print([(i, round(ts[i] - ts[0])) for i in sel])
