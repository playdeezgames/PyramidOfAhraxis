# Pyramid of Ahraxis

Walk the tomb one step at a time: find **keys** to open doors, **potions** to heal, **shields** to turn a monster's blow aside, **swords** to kill monsters and **jools** for the score. Some floor tiles are traps. Reach the exit to see how you did.

**Play it:** https://playdeezgames.github.io/PyramidOfAhraxis/ (also on itch.io: https://thegrumpygamedev.itch.io/pyramid-of-ahraxis)

**Controls:** S starts, I shows the instructions. Arrow keys move (hold to keep walking), P drinks a potion, F2 resets. Swipe to move on a touch screen.

## What is here

The game began as the TIC-80 cart `pyramid.tic` (September 2023). In October 2026 it was reverse engineered and ported to Odin compiled to WebAssembly (`js_wasm32`), keeping the original's rules and map. The pictures were redrawn with the Urizen tileset, the text uses the DINOBYTE font, and the sounds were made with the Anvil of SPLORR!!. The port was made with Claude Code (generative AI) working alongside TheGrumpyGameDev.

- `src/game`: pure rules, software renderer and generated asset data (no browser imports).
- `src/web`: thin wasm exports. `web/index.html` owns the frame loop, input and audio.
- `tools/test.sh`: native tests and `odin check` for wasm. `tools/build.sh [--size]` builds `build/web`. `tools/pages.sh` refreshes `docs/` (GitHub Pages). `tools/ship.sh` makes the itch.io zip.
- `old/`: an earlier, unrelated GNU COBOL text adventure of the same name (January 2023).

## Credits

- Urizen 1-bit tileset by vurmux, https://vurmux.itch.io/urizen-onebit-tileset (CC0).
- DINOBYTE bitmap font by mby, https://mby.itch.io/dinobyte (CC BY 4.0, used unmodified).
- Sounds made with the Anvil of SPLORR!!.
- Original cart made in TIC-80.
