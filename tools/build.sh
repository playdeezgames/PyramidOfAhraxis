#!/usr/bin/env bash
# Builds the browser game into build/web (what gets shipped). Pass --size for the shipping build.
set -euo pipefail
cd "$(dirname "$0")/.."
OPT=-o:speed
[ "${1:-}" = "--size" ] && OPT=-o:size
mkdir -p build/web
odin build src/web -collection:tggd=src -target:js_wasm32 -out:build/web/game.wasm $OPT
cp "$(odin root)/core/sys/wasm/js/odin.js" build/web/
cp web/index.html build/web/
ls -l build/web
