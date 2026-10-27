#!/usr/bin/env python3
"""Compares a menu frame (P6 PPM from `odin test ... -define:DUMP_MENU=...`) with cover.png.
Usage: python3 -I tools/compare_cover.py menu.ppm [cover.png] [--diff out.png]"""
import sys
from PIL import Image
a = Image.open(sys.argv[1]).convert('RGB')
b = Image.open(sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith('--') else 'cover.png').convert('RGB')
assert a.size == b.size, (a.size, b.size)
pa, pb = a.load(), b.load()
bad = [(x, y) for y in range(a.height) for x in range(a.width) if pa[x, y] != pb[x, y]]
print(f"{len(bad)} of {a.width*a.height} pixels differ")
if bad:
    xs, ys = [p[0] for p in bad], [p[1] for p in bad]
    print("bounding box", min(xs), min(ys), max(xs), max(ys))
if '--diff' in sys.argv:
    d = Image.new('RGB', a.size)
    for x, y in bad: d.putpixel((x, y), (255, 0, 0))
    d.resize((a.width*4, a.height*4), Image.NEAREST).save(sys.argv[sys.argv.index('--diff')+1])
