#!/usr/bin/env bash
# Native tests, plus an odin check of every package for js_wasm32 (catches stray core:os).
set -euo pipefail
cd "$(dirname "$0")/.."
odin test src/game -collection:tggd=src -define:ODIN_TEST_THREADS=1 -vet -o:speed
odin check src/game -no-entry-point -vet -target:js_wasm32 -collection:tggd=src
odin check src/web -vet -target:js_wasm32 -collection:tggd=src
echo "tests ok"
