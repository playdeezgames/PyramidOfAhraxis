#!/usr/bin/env python3
"""Turns the curated One Page Dungeon seeds in tools/data/opd/ into src/game/levels.odin
(generated; do not hand-edit). Usage: python3 -I tools/import_opd.py

One grid cell is one game tile. Everything outside the dungeon's rectangles is wall. The
entrance (doors[0]) is the player start, the one type-5 door is the locked gate (the number
of keyholes in its note, or the config value, sets how many keys it takes), and the exit is
the cell of the `ending` room farthest from the gate. Other door codes are plain openings.
Keys, side locks, rewards, monsters and traps are placed by a seeded generator and checked
for solvability; see LEVELS for the per-level numbers (chosen by hand).
"""
import json, os, re, sys
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'tools/data/opd')
OUT = os.path.join(ROOT, 'src/game/levels.odin')

# Tile ids, same as game.odin.
FLOOR, WALL, DOOR, GATE1, GATE2, GATE3 = 0, 1, 2, 3, 4, 5
EXIT, TRAP, MONSTER = 8, 9, 66
KEY, POTION, JOOL, SHIELD, SWORD = 128, 129, 130, 131, 132
BRAZIER, TORCH, LANTERN = 6, 133, 134
GATES = {1: GATE1, 2: GATE2, 3: GATE3}
LOCK_TILES = {DOOR, GATE1, GATE2, GATE3}

# `fuel` is the light granted on arrival, `theme` indexes THEMES in render.odin, and torches, lanterns
# and braziers are scattered in rooms (braziers are fixed lights and solid). In play order. `guards` = how many of the monsters stand beside a key (a monster strikes when you step
# away from it, so a guard is a toll on every key). `side` = extra locked doors on dead-end rooms (each costs one more key and
# guards a few rewards); keys placed = locks + side.
LEVELS = [
    dict(file='101_small.json', locks=1, side=0, potions=1, jools=2, swords=1, monsters=1, guards=1, shields=0, traps=0,
         torches=0, lanterns=0, braziers=1, fuel=250, theme=0),
    dict(file='202_medium.json', locks=2, side=0, potions=1, jools=2, swords=2, monsters=3, guards=2, shields=1, traps=1,
         torches=1, lanterns=0, braziers=1, fuel=220, theme=1),
    dict(file='201_medium.json', locks=1, side=1, potions=2, jools=4, swords=3, monsters=5, guards=2, shields=2, traps=3,
         torches=2, lanterns=0, braziers=2, fuel=300, theme=2),
    dict(file='1653868650_default.json', locks=1, side=1, potions=3, jools=4, swords=4, monsters=6, guards=2, shields=2, traps=3,
         torches=2, lanterns=1, braziers=2, fuel=300, theme=3),
    dict(file='302_large.json', locks=1, side=1, potions=3, jools=5, swords=4, monsters=7, guards=1, shields=3, traps=4,
         torches=3, lanterns=1, braziers=2, fuel=350, theme=4),
    dict(file='203_medium.json', locks=3, side=1, potions=4, jools=6, swords=6, monsters=9, guards=4, shields=4, traps=5,
         torches=3, lanterns=1, braziers=3, fuel=400, theme=5),
]

NUMBER_WORDS = {'two': 2, 'three': 3, 'four': 4}


class Rng:
    """Park-Miller; stable across Python versions."""

    def __init__(self, seed):
        self.s = seed % 2147483646 + 1

    def below(self, n):
        self.s = self.s * 48271 % 2147483647
        return self.s % n

    def pick(self, items):
        return items[self.below(len(items))]

    def take(self, items):
        return items.pop(self.below(len(items)))


def neighbors(c):
    x, y = c
    return ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))


def flood(start, passable):
    seen = {start}
    q = deque([start])
    dist = {start: 0}
    while q:
        c = q.popleft()
        for n in neighbors(c):
            if n not in seen and passable(n):
                seen.add(n)
                dist[n] = dist[c] + 1
                q.append(n)
    return seen, dist


def keyholes(notes):
    for n in notes:
        m = re.search(r'(\w+) keyholes', n[3])
        if m and m.group(1) in NUMBER_WORDS:
            return NUMBER_WORDS[m.group(1)]
        if 'keyhole' in n[3]:
            return 1
    return None


def hint_of(notes):
    for n in notes:
        if 'keyhole' in n[3]:
            return n[3]
    for n in notes:
        if re.search(r'\b(gate|door)\b', n[3]):
            return n[3]
    return notes[0][3] if notes else ''


def build(cfg, attempt):
    j = json.load(open(os.path.join(DATA, cfg['file'])))
    rects, doors, notes = j['rects'], j['doors'], j['notes']
    floor, room_of = set(), {}
    rooms = []  # (x, y, w, h) of rooms (not corridors, not door cells)
    for r in rects:
        cells = [(x, y) for x in range(r[0], r[0] + r[2]) for y in range(r[1], r[1] + r[3])]
        floor.update(cells)
        if r[2] >= 2 and r[3] >= 2:
            for c in cells:
                room_of[c] = len(rooms)
            rooms.append(tuple(r[:4]))
    door_cells = {(d[0], d[1]) for d in doors}
    start = (doors[0][0], doors[0][1])
    gates = [d for d in doors if d[4] == 5]
    assert len(gates) == 1, (cfg['file'], 'gates', len(gates))
    gate = (gates[0][0], gates[0][1])  # replaced below if it is not a choke point
    ending = [r for r in rects if len(r) > 4]
    assert len(ending) == 1
    end_cells = {(x, y) for x in range(ending[0][0], ending[0][0] + ending[0][2])
                 for y in range(ending[0][1], ending[0][1] + ending[0][3])}

    n_notes = keyholes(notes)
    locks = cfg['locks']
    assert n_notes is None or n_notes == locks, (cfg['file'], 'keyholes', n_notes, locks)

    # The gate: the generator's own type-5 door when every route to the ending room passes it,
    # otherwise the door cell nearest the ending room that every route passes (the generator adds
    # loops and back doors, so its gate is not always a choke point).
    in_floor = lambda c: c in floor
    _, dist_end = flood(next(iter(sorted(end_cells))), in_floor)

    def separates(cell):
        seen, _ = flood(start, lambda c: in_floor(c) and c != cell)
        return not (end_cells & seen)

    gate_note = None
    if separates(gate):
        gate_note = True
    else:
        chokes = [c for c in sorted(door_cells) if c != start and separates(c)]
        if not chokes:
            raise ValueError('no choke point')
        gate = min(chokes, key=lambda c: dist_end[c])
    reach_a, dist_a = flood(start, lambda c: in_floor(c) and c != gate)
    assert not (end_cells & reach_a), (cfg['file'], 'gate does not gate')

    in_floor = lambda c: c in floor
    reach_a, dist_a = flood(start, lambda c: in_floor(c) and c != gate)
    assert not (end_cells & reach_a), (cfg['file'], 'gate does not gate')

    # Exit: the ending-room cell farthest from the gate.
    _, dist_g = flood(gate, in_floor)
    exit_cell = max(sorted(end_cells), key=lambda c: dist_g[c])

    # Areas: floor components with door cells removed; doors are the edges.
    comp = {}
    ncomp = 0
    for c in sorted(floor):
        if c in comp or c in door_cells:
            continue
        seen, _ = flood(c, lambda n: in_floor(n) and n not in door_cells)
        for n in seen:
            comp[n] = ncomp
        ncomp += 1
    comp_doors = {i: set() for i in range(ncomp)}
    door_comps = {}
    for dc in door_cells:
        cs = {comp[n] for n in neighbors(dc) if n in comp}
        door_comps[dc] = cs
        for i in cs:
            comp_doors[i].add(dc)
    comp_cells = {i: [c for c in comp if comp[c] == i] for i in range(ncomp)}

    def comp_has_room(i):
        return any(c in room_of for c in comp_cells[i])

    start_comp = {comp[n] for n in neighbors(start) if n in comp}
    end_comp = {comp[c] for c in end_cells if c in comp}
    region_a_comps = {comp[c] for c in reach_a if c in comp}
    leaves = [i for i in sorted(region_a_comps)
              if len(comp_doors[i]) == 1 and len(comp_cells[i]) >= 6 and comp_has_room(i)
              and i not in start_comp and i not in end_comp]
    key_pool = [i for i in sorted(region_a_comps) if comp_has_room(i) and i not in start_comp]

    rng = Rng(int(cfg['file'].split('_')[0]) * 1000 + attempt)

    near_door = lambda c: any(n in door_cells for n in neighbors(c))
    near_exit = lambda c: abs(c[0] - exit_cell[0]) <= 1 and abs(c[1] - exit_cell[1]) <= 1
    far_start = lambda c: abs(c[0] - start[0]) + abs(c[1] - start[1]) >= 3

    def spots(i):
        return [c for c in comp_cells[i] if c in room_of and not near_door(c) and not near_exit(c)
                and c != exit_cell and c != start]

    tiles = {c: FLOOR for c in floor}
    used = set()

    def put(c, t):
        tiles[c] = t
        used.add(c)

    # Side locks on dead-end rooms in the part before the gate, with rewards inside.
    side_rooms = []
    leaves_left = list(leaves)
    for _ in range(cfg['side']):
        if not leaves_left:
            break
        i = rng.take(leaves_left)
        side_rooms.append(i)
        (door,) = comp_doors[i]
        tiles[door] = DOOR
    # Keys: one per lock, in different unlocked rooms before the gate, far from the start.
    n_keys = cfg['locks'] + len(side_rooms)
    pool = [i for i in key_pool if i not in side_rooms]
    pool.sort(key=lambda i: -min(dist_a[c] for c in comp_cells[i] if c in dist_a))
    key_rooms = pool[:n_keys]
    while len(key_rooms) < n_keys:
        key_rooms.append(rng.pick(pool))  # more keys than rooms: share rooms
    key_cells = []
    for i in key_rooms:
        free = [c for c in spots(i) if c not in used]
        key_cells.append(rng.take(free))
        put(key_cells[-1], KEY)
    tiles[gate] = GATES[locks]

    everywhere = [c for i in range(ncomp) for c in spots(i)]
    # Guards: a monster right beside a key (never on it, never in a doorway).
    spot_set = set(everywhere)
    guarded = 0
    for kc in key_cells[:cfg['guards']]:
        cand = [n for n in neighbors(kc) if n in spot_set and n not in used]
        if cand:
            put(rng.take(cand), MONSTER)
            guarded += 1

    def scatter(count, tile, among=None, extra=lambda c: True):
        cand = [c for c in (among if among is not None else everywhere) if c not in used and extra(c)]
        for _ in range(count):
            if not cand:
                raise ValueError('no room for %s' % tile)
            c = rng.take(cand)
            put(c, tile)

    # Rewards behind each side lock first (a potion or a shield and two jools).
    for i in side_rooms:
        inside = [c for c in spots(i) if c not in used]
        scatter(1, rng.pick([POTION, SHIELD]), inside)
        scatter(2, JOOL, inside)
    scatter(cfg['potions'], POTION)
    scatter(cfg['jools'], JOOL)
    scatter(cfg['swords'], SWORD)
    scatter(cfg['shields'], SHIELD)
    scatter(cfg['torches'], TORCH)
    scatter(cfg['lanterns'], LANTERN)
    scatter(cfg['braziers'], BRAZIER)
    scatter(cfg['monsters'] - guarded, MONSTER, extra=far_start)
    scatter(cfg['traps'], TRAP, extra=far_start)
    tiles[exit_cell] = EXIT
    used.add(exit_cell)

    # Solvability: keys reachable with locks and monsters in the way, then everything
    # reachable with the locks open.
    blocked = lambda c: tiles.get(c) in LOCK_TILES or tiles.get(c) in (MONSTER, BRAZIER)
    reach0, _ = flood(start, lambda c: c in tiles and not blocked(c))
    keys = [c for c, t in tiles.items() if t == KEY]
    total_locks = sum({DOOR: 1, GATE1: 1, GATE2: 2, GATE3: 3}[t] for t in tiles.values() if t in LOCK_TILES)
    assert len(keys) == total_locks, (cfg['file'], len(keys), total_locks)
    if not all(k in reach0 for k in keys):
        raise ValueError('key not reachable')
    reach1, _ = flood(start, lambda c: c in tiles and tiles[c] not in (MONSTER, BRAZIER))
    if any(c not in reach1 for c, t in tiles.items() if t in (KEY, POTION, JOOL, SHIELD, SWORD, EXIT, TORCH, LANTERN)):
        raise ValueError('something not reachable with the locks open')
    # Monsters must never be needed to get through.
    reach2, _ = flood(start, lambda c: c in tiles and tiles[c] not in (MONSTER, BRAZIER, WALL))
    assert exit_cell in reach2

    hint = hint_of(notes) if gate_note else 'A locked gate bars the way to the exit.'
    xs = [c[0] for c in floor]
    ys = [c[1] for c in floor]
    ox, oy = min(xs) - 1, min(ys) - 1
    w, h = max(xs) - min(xs) + 3, max(ys) - min(ys) + 3
    grid = [WALL] * (w * h)
    for (x, y), t in tiles.items():
        grid[(y - oy) * w + (x - ox)] = t
    return dict(title=j['title'], hint=hint, fuel=cfg['fuel'], theme=cfg['theme'], w=w, h=h, sx=start[0] - ox, sy=start[1] - oy,
                grid=grid, counts={t: sum(1 for v in grid if v == t) for t in sorted(set(grid))})


def odin_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def main():
    out = ["// Generated by tools/import_opd.py from tools/data/opd/*.json. Do not hand-edit.",
           "package game\n"]
    entries = []
    for n, cfg in enumerate(LEVELS):
        for attempt in range(60):
            try:
                lv = build(cfg, attempt)
                break
            except ValueError:
                continue
        else:
            sys.exit('could not place level ' + cfg['file'])
        name = 'LEVEL_%d_TILES' % n
        out.append("%s := [%d]u8{" % (name, len(lv['grid'])))
        for i in range(0, len(lv['grid']), lv['w']):
            out.append("\t" + ", ".join(str(v) for v in lv['grid'][i:i + lv['w']]) + ",")
        out.append("}\n")
        entries.append("\t{title = %s, hint = %s, w = %d, h = %d, start_x = %d, start_y = %d, fuel = %d, theme = %d, "
                       "tiles = %s[:]}," % (odin_str(lv['title']), odin_str(lv['hint']), lv['w'], lv['h'], lv['sx'],
                                          lv['sy'], lv['fuel'], lv['theme'], name))
        print(cfg['file'], lv['title'], '%dx%d' % (lv['w'], lv['h']), lv['counts'], file=sys.stderr)
    entries.append('\t{title = "The Old Pyramid", hint = "The map of the original cart.", w = MAP_W, h = MAP_H, '
                   'start_x = 21, start_y = 11, fuel = 450, theme = 0, tiles = MAP_INITIAL[:]},')
    out.append("// Play order; the last entry is the cart's own map.")
    out.append("LEVELS := [?]Level{")
    out.extend(entries)
    out.append("}\n")
    open(OUT, 'w').write("\n".join(out))
    print('wrote', OUT)


main()
