"""Helpers to read frames recorded by index.html (raw RGB) and write PNGs.

Usage as a script: python3 -I frames.py <framesdir> <recname> [every]  -> writes PNGs
of unique frames into <framesdir>/<recname>_png/ and prints a timeline.
"""
import glob
import json
import os
import struct
import sys
import zlib

EGA = [(0, 0, 0), (0, 0, 170), (0, 170, 0), (0, 170, 170), (170, 0, 0), (170, 0, 170),
       (170, 85, 0), (170, 170, 170), (85, 85, 85), (85, 85, 255), (85, 255, 85),
       (85, 255, 255), (255, 85, 85), (255, 85, 255), (255, 255, 85), (255, 255, 255)]


def load_rec(d, name):
    idx = json.load(open(os.path.join(d, name + ".json")))
    w, h = idx["w"], idx["h"]
    size = w * h * 3
    data = b"".join(open(p, "rb").read() for p in sorted(glob.glob(os.path.join(d, name + ".[0-9][0-9][0-9].rgb"))))
    if "wh" in idx:
        # mixed sizes: convert every frame to 320x200
        frames, pos = [], 0
        for fw, fh in idx["wh"]:
            f = data[pos:pos + fw * fh * 3]
            pos += fw * fh * 3
            frames.append(downscale(fw, fh, f)[2])
        return 320, 200, idx["t"][:len(frames)], frames
    frames = [data[i * size:(i + 1) * size] for i in range(len(data) // size)]
    return w, h, idx["t"][:len(frames)], frames


def load_snap(d, name, w, h):
    return open(os.path.join(d, name + ".rgb"), "rb").read()[: w * h * 3]


def save_png(path, w, h, rgb):
    raw = b"".join(b"\x00" + rgb[y * w * 3:(y + 1) * w * 3] for y in range(h))
    def chunk(t, b):
        c = struct.pack(">I", len(b)) + t + b
        return c + struct.pack(">I", zlib.crc32(t + b) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b"")
    open(path, "wb").write(png)


def to_index(w, h, rgb):
    """Map to EGA colour numbers (nearest)."""
    cache = {}
    out = bytearray(w * h)
    for i in range(w * h):
        px = rgb[i * 3:i * 3 + 3]
        v = cache.get(px)
        if v is None:
            r, g, b = px
            v = min(range(16), key=lambda k: (EGA[k][0] - r) ** 2 + (EGA[k][1] - g) ** 2 + (EGA[k][2] - b) ** 2)
            cache[px] = v
        out[i] = v
    return out


def downscale(w, h, rgb):
    """640x400 -> 320x200 by taking every other pixel (DOSBox doubles some modes)."""
    if (w, h) == (320, 200):
        return w, h, rgb
    fx, fy = w // 320, h // 200
    out = bytearray()
    for y in range(0, h, fy):
        row = rgb[y * w * 3:(y + 1) * w * 3]
        for x in range(0, w, fx):
            out += row[x * 3:x * 3 + 3]
    return 320, 200, bytes(out)


if __name__ == "__main__":
    d, name = sys.argv[1], sys.argv[2]
    w, h, ts, frames = load_rec(d, name)
    outd = os.path.join(d, name + "_png")
    os.makedirs(outd, exist_ok=True)
    prev = None
    t0 = ts[0] if ts else 0
    for i, (t, f) in enumerate(zip(ts, frames)):
        if f == prev:
            continue
        prev = f
        sw, sh, s = downscale(w, h, f)
        save_png(os.path.join(outd, "%04d.png" % i), sw, sh, s)
        print("%4d %8.1f ms" % (i, t - t0))


def montage(paths_rgb, cols, w=320, h=200, scale=2):
    """Grid of frames, each shrunk by `scale`, returns (W, H, rgb)."""
    sw, sh = w // scale, h // scale
    rows = (len(paths_rgb) + cols - 1) // cols
    W, H = cols * (sw + 2), rows * (sh + 2)
    out = bytearray(W * H * 3)
    for k, rgb in enumerate(paths_rgb):
        ox, oy = (k % cols) * (sw + 2), (k // cols) * (sh + 2)
        for y in range(sh):
            for x in range(sw):
                s = ((y * scale) * w + x * scale) * 3
                d = ((oy + y) * W + ox + x) * 3
                out[d:d + 3] = rgb[s:s + 3]
    return W, H, bytes(out)
