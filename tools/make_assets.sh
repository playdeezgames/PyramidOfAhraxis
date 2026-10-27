#!/usr/bin/env bash
# Renders the real frames natively and builds assets/cover.png and assets/screenshots/ (needs Pillow).
set -euo pipefail
cd "$(dirname "$0")/.."
D="$(mktemp -d)"
odin test src/game -define:ODIN_TEST_THREADS=1 -define:DUMP_MENU="$D/menu.ppm" -define:DUMP_PLAY="$D/play.ppm" \
	-define:DUMP_HELP="$D/help.ppm" -define:DUMP_SCORE="$D/score.ppm" >/dev/null
python3 -I tools/make_assets.py "$D"
rm -rf "$D"
