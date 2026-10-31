# Itch.io page text

Page: https://thegrumpygamedev.itch.io/pyramid-of-ahraxis
Pasted in by hand; nothing here is published by the repo.

## Short description

A deathtrap in seven levels: find keys, dodge traps, outrun wraiths, spend your jools, and reach the exit.

## Paste this as the page description

Into the pyramid you go. Seven levels wait: a short tutorial, five dungeons laid out by Watabou's One Page Dungeon generator, and the original map from the TIC-80 cart.

Walk the tomb one step at a time. Pick up **keys** to open doors, **potions** to heal, **shields** to turn a monster's blow aside, **swords** to kill monsters, and **jools**, which you can spend: every level has a **merchant** (walk into one, then press 1 to 6) who sells potions, shields, swords, disarm kits, light, and the **trap amulet**. Spending jools costs you score, so choose.

The dungeon is trying to kill you. Many floor tiles are hidden **traps**, some in corridors you cannot walk around; the amulet shows the ones near you and a **disarm kit** defuses one when you step on it. A **monster** beside you strikes when you step away from it, and **wraiths** hunt you through the halls (they rest now and then, so you can outrun them). Kill them with a sword or turn the blow with a shield. You carry a **light** that burns one step at a time; pick up torches and lanterns to keep it going, because in the dark you see almost nothing and it bites. Fixed braziers light the rooms they stand in. Find each level's exit to go deeper; some gates have more than one lock and want a key for every keyhole. The last exit shows how you did. When you are down to one heart, it blinks.

Health is score too: the final tally counts your health, kills, jools, keys and spare potions.

**Controls:** S starts and I shows the instructions (two pages) on the title screen. Arrow keys move (hold to keep walking), P drinks a potion to restore your health to full, 1 to 6 buy from a merchant, F2 resets the game. On a phone or tablet, swipe to move.

**Credits:** Dungeon layouts from One Page Dungeon by Watabou, https://watabou.itch.io/one-page-dungeon. Urizen 1-bit tileset by vurmux, https://vurmux.itch.io/urizen-onebit-tileset (CC0). DINOBYTE bitmap font by mby, https://mby.itch.io/dinobyte, licensed CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/), used unmodified. Sounds made with the Anvil of SPLORR!!.

**Made with:** the original was made in TIC-80 (September 2023). This version is a port to Odin, compiled to WebAssembly and drawn to a plain 2D canvas, with the original's rules kept as they were and its own map as the last level. The pictures are redrawn with the Urizen 1-bit tileset and the text uses the DINOBYTE font (credits below). The port was made with Claude (generative AI) working alongside TheGrumpyGameDev.

## Notes (not for the page)

- Push target: `thegrumpygamedev/pyramid-of-ahraxis:html`. `shippit.sh` wraps `tools/ship.sh`, which tests, builds with `-o:size` and zips; it only pushes with `--push`. The old `shippit.sh` (export, push, commit) is replaced. **The live page's channel names were not checked and the author was unsure an `html` channel exists**; confirm `html` exists before the first push (a new channel name is a separate upload, see the Release standard in the bok).
- **AI disclosure (decided October 27, 2026):** remove the "No generative AI was used" tag from the live page if present; the "made with Claude" line stays. Nothing here changes the page until a ship.
- **The seven-level update is booked in Coxswain for October 31, 2026** (release #6; one release a day, check `ship_today`). The first port shipped October 29; the merchants, wraiths and trap update is part of release #6. `git push` and GitHub Pages are separate and do not use the ship slot.
- After shipping the update: replace the cover with `assets/cover.png`, the screenshots with `assets/screenshots/` (seven now), and post `devlog/20261031/devlog.md`. Tick Graphics only if the user decides the tile mapping counts; Sounds, Text & Dialog and Code are already ticked.
- On the Edit game screen: "Kind of project" HTML, "This file will be played in the browser" ticked, and an embed of 480 by 272 (the game is 240 by 136 and scales to fit).
- The cover is `assets/cover.png` (630 by 500) and the screenshots are `assets/screenshots/`, both made by `tools/make_assets.sh` from the real renderer.
- Sound: the effects and stingers are Anvil-made square-wave sounds (`assets/pyramid.world.json`, WAVs in `assets/sfx/`), not the cart's own sfx and music.
- The page text above was written from the cart's code, not from the live itch page (not read).
