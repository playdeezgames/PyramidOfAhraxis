# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Pyramid of Ahraxis (itch.io: `thegrumpygamedev/pyramid-of-ahraxis`) is a small tile-map dungeon game written as a **TIC-80 Lua cartridge**. The goal of working here is to **reverse engineer it and port it to the Odin/WASM stack** (Odin compiled to `js_wasm32`), the same way `/home/yermom/git/wandermaze` was ported. That repo is the closest precedent: copy its layout (`tools/`, `src/game` + `src/web`, `web/index.html`) and its `CLAUDE.md` conventions rather than inventing new ones.

The game is the single cartridge `pyramid.tic` (68 KB, 240x136 map plus tiles, palette, sfx and music). There is no source tree. Treat these as non-source:

- `pub-*/` (git-ignored): platform exports of the cart with the TIC-80 runtime embedded.
- `.local/59ab359/`: TIC-80 IDE settings.
- `old/`: an **earlier, unrelated GNU COBOL text adventure** of the same name (room-based, N/S/E/W, character sheet; Jan 2023, IF Game Jam). The `README.md` log, TODOs, commands and inventory describe that COBOL game, not the cart. Do not port it unless asked.
- `help.md`: the TIC-80 1.1.2736 manual (API, RAM layout, key codes). Use it to look up `mget`, `fget`, `keyp`, `music`, `sfx`, `print` semantics.
- `cover.png`, `screen.png`, `mapimg.png`, `music.wav`, `map.map`: reference captures and exports (the cover is the pixel-parity target; `map.map` is a TIC-80 map export; `music.wav` is a recording of the music).

## Working agreements

- **Coxswain:** register as agent `araxis` (`agent_register` takes `agent`, not `agent_id`) and track work in the coxswain project `pyramid-of-ahraxis`.
- **Bok guidance:** the vault at `/home/yermom/git/bok-of-splorr` (added as a working directory) is the rulebook. Read `splorr/Home.md` (standing rules), `splorr/Tech/Odin wasm recipe.md`, `splorr/Tech/Release standard.md`, `splorr/Gotchas.md` and `splorr/Games/Wandermaze.md`. Key rules: never `git push` and never run `shippit.sh --push` / `butler push` unless the user says so ("push" = `git push`, "ship" = itch.io); an itch.io game is a "Metaphor" in user-facing copy; anything an AI posts on itch.io must say so; the port needs a vault game note (`Games/Pyramid of Ahraxis.md`, linked from `Home.md`, plus a row in `Strategy/Steam pivot evaluation.md`) once it is real.
- **Anvil** (`anvil-prod` MCP) is for structuring sprites, palette, map, and sound (square-wave sfx, WAV export) when the port needs generated assets. Use it for the sound and any redrawn graphics; recovering the original tiles and map is done straight from the cart.
- **AI-disclosure decision:** the live itch page may be tagged "No generative AI was used" (as Wandermaze's was). Decided October 27, 2026: remove that tag and keep the "made with Claude" line in the copy (applied only at ship time).
- **Ship hold:** do not ship to itch (`tools/ship.sh --push`, `shippit.sh --push`, `butler push`) before **October 29, 2026**; the user does not want to spam itch feeds. `git push` to origin is fine. The live page's `html` channel is unconfirmed.
- **Audio decision:** replace the placeholder blips with Anvil-made sounds (not a TIC-80 replayer, not `music.wav`).

## Commands

Original cart (TIC-80 is not installed here; both scripts hardcode `/E/tic80-v1.1-win/tic80`, a Windows path from the author's machine):

- `launch.sh`: opens `pyramid.tic` in the TIC-80 IDE.
- `shippit.sh`: exports linux/win/mac/html, `butler push`es to itch, then `git add -A` and commits. **It publishes and commits; never run it unasked.** The Release standard replaces this with a `tools/ship.sh` plus a one-line wrapper that pushes only with `--push`; do that migration only as part of port work, never ship as part of it.

Extracting the cart without TIC-80: `.tic` is a sequence of chunks `[type(low 5 bits)|bank(high 3 bits)][size u16 LE][reserved byte][data]`. The Lua is the code chunk (type 5, ~4 KB, about 240 lines); the map chunk is 32640 bytes. Parse with a few lines of `python3 -I` (the Wandermaze `tools/extract_cart.py` is the model). `python3 -I tools/extract_cart.py [--dump DIR]` regenerates `src/game/assets.odin` (do not hand-edit; palette is Sweetie-16, tiles, flags and the post-BOOT map; all art is in the tiles chunk, the sprites chunk is absent). Sfx, music and waveform chunks (types 9, 10, 14, 15) are only dumped with `--dump`, not yet converted. `tools/test.sh`: native tests (19) plus `odin check` of both packages for `js_wasm32`. One test: `odin test src/game -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_NAMES=game.<test_name>`. `tools/ship.sh` (tests, size build, zip in `build/`; pushes to itch only with `--push`, which needs the user's say-so; `shippit.sh` is a wrapper) and `tools/make_assets.sh` (regenerates `assets/cover.png` and `assets/screenshots/`, needs Pillow) follow the bok Release standard; page copy is `ITCH_DESCRIPTION.md`. `tools/build.sh [--size]` builds `build/web` (git-ignored; serve with `python3 -m http.server -d build/web`). Pixel parity: `odin test src/game -define:ODIN_TEST_THREADS=1 -define:DUMP_MENU=m.ppm` (also `DUMP_PLAY`, `DUMP_HELP`, `DUMP_SCORE`) then `python3 -I tools/compare_cover.py m.ppm cover.png`; the menu matches `cover.png` with 0 differing pixels. `python3 -I tools/extract_font.py` regenerates `src/game/font.odin` from the vendored MIT `tools/data/font.inl` (TIC-80 built-in font). `src/game/game.odin` holds the rules (`command(&g, cmd)` is the single entry point; sounds are queued and drained with `take_sounds`).

TIC-80 `print` rules (verified against the cover): proportional glyphs are drawn starting at their leftmost lit column, advance = lit width + 1, a space advances 4; `shadow` draws the text at +1,+1 in the bg colour first. `spr`/`map` have no colour key by default (opaque, so the player and tile 0 cover what is below); `hline` and the jool icon use colour key 0. The page (`web/index.html`) owns key repeat (cart: `keyp(code, 10, 10)`) and currently plays **placeholder blips**, not the cart's sfx/music (the cart's sfx, waveform, pattern and music chunks are not yet replayed).

The Odin toolchain is `odin` on PATH (`~/.local/bin/odin`). Web builds: `odin build src/web -target:js_wasm32 -out:build/web/game.wasm -o:size`, copy `odin.js` from `$(odin root)/core/sys/wasm/js/`, and serve over http (not `file://`).

## Game design (recovered from the cart's Lua)

A top-down tile game on one 240x136 map; the screen shows a 17x17 window of cells centred on the player (`map(x-8, y-8, 17, 17)`, player sprite drawn at 64,64) beside a HUD at x=136. State machine via the global `tf` (current screen function, `TIC()` just calls `tf()`): `Menu` -> `Help` or `Play` -> `Score` (reached by stepping on tile 8, the exit).

- **Tile index is behaviour.** Flags are read with `fget`: flag 7 = solid; solid + flag 6 = door (opens with a key, `mset` to 0). Special tile ids: 66 monster (solid; sword kills it, shield blocks a hit, else -1 health), 8 exit, 9 hidden trap (becomes tile 41 when sprung, -1 health), 128 key, 129 potion, 130 jool, 131 shield, 132 sword. Pickups are `mset(nx,ny,0)` on the live map, so the map is mutated in play and is restored only by `reset()` (F2).
- **BOOT** rewrites every map tile in 32..63 to `t-32` (a second, hidden layer of the map that is revealed as normal tiles at start). The port must apply the same transform to the extracted map.
- Player (`g.cs[1]`): start (21,11), health 3, keys, potions, jools, shields (`ds`), swords (`as`), kills (`ms`). Moves use `keyp(.., 10, 10)` (arrow codes 58 up, 59 down, 60 left, 61 right; hold 10, period 10 frames, so key repeat). Q (code 17) quaffs a potion: health back to 3. F2 (68) resets, F4 (70) exits. Menu: S starts, I opens help.
- Score = health*100 + kills*50 + jools*250 + keys*500 + potions*75. A dead player (health <= 0) sees sprite 65 and cannot move.
- Quirk to decide, not silently fix: a sword kill on a monster also lets the same bump resolve the shield/health branch afterwards (the monster does not skip its attack). Check this against the cart before changing it, and log such quirks as coxswain notes (see Wandermaze: faithful first, deliberate deviations recorded).
- Audio: `sfx` ids 0-3 for bumps/pickups/hits, `music` tracks 0-7 played as stingers (no loop) for death, shield, start, sword, jools, potion, quaff, exit. The cart's music and sfx data are in the cart; `music.wav` is a reference recording. Original sprites and map are 8x8 on the Sweetie-16 default or the cart's own palette: read the palette chunk, do not assume.

## Port architecture (follow Wandermaze)

`src/game` is pure Odin with no browser imports (rules, a 240x136 software framebuffer, TIC-80 `print` rules and font, generated asset data) and is imported via `-collection:tggd=src`; `src/web` (`#+build js`) only exports `proc "c"` functions; `web/index.html` owns `requestAnimationFrame`, input, `putImageData` and audio. Tests are `#+build !js` and run natively (`core:testing` breaks on wasm). Generated asset files are produced by a tool script and are not hand-edited. Seed the RNG yourself if any randomness is added (the original has none). `int` is 32 bits on `js_wasm32`. The built-in TIC-80 font is not in the cart; Wandermaze vendored MIT-licensed `font.inl` from the TIC-80 repo in `tools/data/`.

Verification target: render the menu/play/score screens with the real renderer and compare against `cover.png` and `screen.png` pixel for pixel before any deliberate restyle.
