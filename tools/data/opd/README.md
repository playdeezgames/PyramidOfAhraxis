# One Page Dungeon seeds

Dungeon layouts for extra levels, generated with Watabou's One Page Dungeon (https://watabou.itch.io/one-page-dungeon, generator at https://watabou.github.io/one-page-dungeon/). Terms (read October 29, 2026 on the itch page): images created by the generator may be used as you like, including in commercial work; attribution is appreciated but not required. We credit Watabou anyway.

Each file is the generator's own JSON export (Export as > JSON), compacted: `rects` are `[x, y, w, h]` (a fifth `1` marks the `ending` room), `doors` are `[x, y, dirX, dirY, type]`, `notes` are `[ref, x, y, text]`, `water` and `columns` are cell positions. Rooms are the larger rects; the 1x1 rects are door cells. One grid cell is one game tile. To regenerate a file, open `https://watabou.github.io/one-page-dungeon/?seed=N&tags=T`, right-click, Export as > JSON.

## Curated level order (chosen October 29, 2026)

| # | File | Title | Floor cells | Why |
|---|---|---|---|---|
| 1 | `101_small.json` | Hall of the Grey Titan | 93 | **Tutorial.** Six rooms: walk in, find the key under debris, open the gate to the south. One key, one gate. |
| 2 | `202_medium.json` | Chapel of the Black Eye | 139 | A gate with **two keyholes** and two keys in two rooms. First real routing choice. |
| 3 | `201_medium.json` | Tomb of the Blasphemous King | 282 | Long west-east tomb with water, columns, secret-looking openings, a chest with a spear, a gnoll with chainmail. Room for monsters and traps. |
| 4 | `1653868650_default.json` | Pyramid of Ahraxis | 260 | The namesake, the dungeon the old COBOL game was drawn from. Skull-shaped key, ironbound double door. |
| 5 | `302_large.json` | Icespear Abbey | 398 | Long winding abbey, a key on an altar, a gate to the north, a pool, 12 water cells. |
| 6 | `203_medium.json` | Maze of the Cursed Lady | 365 | **Finale.** Four keys, a double door with **three keyholes**, a pond, a maze of corridors. |

Unused candidates scanned: 102 (House of Dreams, 82 cells, one gate), 103 (Hall of the Blind Beast, 67 cells, no key), 204 (Chapel of the White King, 119 cells, one gate, one key), 301 (Lost Catacombs of the Spider Baron, 251 cells, no key note).

Open decision: the cart's original 240x136 map stays in the game, probably as the last level; see coxswain task 335.

## What the generator tells us (read from its script and exports)

- `doors[0]` is the entrance (type 3). A second type-3 door can appear (seed 1653868650 has two).
- Type 5 is the locked **gate** (`buildApproach`), always one per dungeon; the notes call it "a gate with N keyholes" or "a double door with N keyholes". The generator spawns 0 to 4 keys (`spawnKeys`) in leaf rooms; keys show up in the notes ("A key on an altar", "An iron key tucked under some debris").
- The room with `ending` set is the last room, behind the gate. That is where the exit goes.
- Other door codes seen: 0 (the common plain door), 1, 2, 4, 6 (rear entrance), 7 (round stone door), 8, 9 (frequent, probably an open passage or secret door). The meanings of 1, 2, 4, 8 and 9 are not confirmed; resolve them by comparing exports with the rendered map (coxswain task 334).
- Sizes by tag: `small` 3 to 6 rooms, `medium` 6 to 12, `large` 12 to 25. Other tags worth trying: `winding`, `compact`, `no secrets`.
