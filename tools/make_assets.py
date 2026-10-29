#!/usr/bin/env python3
"""Builds assets/cover.png (630x500) and assets/screenshots/ from frame dumps (PPM) made by
tools/make_assets.sh. Usage: python3 -I tools/make_assets.py DUMP_DIR"""
import sys, os
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = sys.argv[1]
frame = lambda n: Image.open(os.path.join(d, n + '.ppm')).convert('RGB')
shots = os.path.join(ROOT, 'assets/screenshots')
os.makedirs(shots, exist_ok=True)
for old in os.listdir(shots):
    os.remove(os.path.join(shots, old))
for i, n in enumerate(['menu', 'banner', 'play', 'help', 'score'], 1):
    frame(n).resize((960, 544), Image.NEAREST).save(os.path.join(ROOT, f'assets/screenshots/0{i}-{n}.png'))
# Cover: the title screen at 2x over a strip of the dungeon at 2x, integer scaling only.
cover = Image.new('RGB', (630, 500), (26, 28, 44))
cover.paste(frame('menu').resize((480, 272), Image.NEAREST), (75, 8))
cover.paste(frame('play').crop((0, 0, 240, 104)).resize((480, 208), Image.NEAREST), (75, 288))
cover.save(os.path.join(ROOT, 'assets/cover.png'))
