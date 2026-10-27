# Itch.io page text

Page: https://thegrumpygamedev.itch.io/pyramid-of-ahraxis
Pasted in by hand; nothing here is published by the repo.

## Short description

Walk the Pyramid of Ahraxis: find keys, dodge traps, fight monsters, grab the jools, and reach the exit.

## Paste this as the page description

Into the pyramid you go.

Walk the tomb one step at a time. Pick up **keys** to open doors, **potions** to heal, **shields** to turn a monster's blow aside, **swords** to kill monsters, and **jools** for the score. Watch your step: some floor tiles are **traps**. Find the exit to see how you did.

Health is score too: the final tally counts your health, kills, jools, keys and spare potions.

**Controls:** S starts and I shows the instructions on the title screen. Arrow keys move (hold to keep walking), Q quaffs a potion to restore your health to full, F2 resets the game. On a phone or tablet, swipe to move.

**Made with:** the original was made in TIC-80 (September 2023). This version is a port to Odin, compiled to WebAssembly and drawn to a plain 2D canvas, with the original's rules, map, pixel art and look kept as they were. The port was made with Claude (generative AI) working alongside TheGrumpyGameDev.

## Notes (not for the page)

- Push target: `thegrumpygamedev/pyramid-of-ahraxis:html`. `shippit.sh` wraps `tools/ship.sh`, which tests, builds with `-o:size` and zips; it only pushes with `--push`. The old `shippit.sh` (export, push, commit) is replaced. **The live page's channel names were not checked and the author was unsure an `html` channel exists**; confirm `html` exists before the first push (a new channel name is a separate upload, see the Release standard in the bok).
- **AI disclosure (decided October 27, 2026):** remove the "No generative AI was used" tag from the live page if present; the "made with Claude" line stays. Nothing here changes the page until a ship.
- **Do not ship before October 29, 2026** (avoid spamming itch feeds). `git push` is fine.
- On the Edit game screen: "Kind of project" HTML, "This file will be played in the browser" ticked, and an embed of 480 by 272 (the game is 240 by 136 and scales to fit).
- The cover is `assets/cover.png` (630 by 500) and the screenshots are `assets/screenshots/`, both made by `tools/make_assets.sh` from the real renderer.
- **Sound is placeholder:** the page plays simple square-wave blips, not the cart's own sfx and music. Replace before shipping if you want the original sound.
- The page text above was written from the cart's code, not from the live itch page (not read).
