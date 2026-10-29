#+build !js
package game

import "core:os"
import "core:strings"
import "core:testing"

// Not a real test: `odin test src/game -define:DUMP_MENU=a.ppm` (also DUMP_PLAY, DUMP_HELP,
// DUMP_SCORE) writes frames for tools/compare_cover.py and the marketing images.
DUMP_MENU :: #config(DUMP_MENU, "")
DUMP_PLAY :: #config(DUMP_PLAY, "")
DUMP_HELP :: #config(DUMP_HELP, "")
DUMP_SCORE :: #config(DUMP_SCORE, "")
DUMP_SHOP :: #config(DUMP_SHOP, "") // the merchant's shop
DUMP_BANNER :: #config(DUMP_BANNER, "") // level 1 with its title banner
DUMP_PLAY_LEVEL :: #config(DUMP_PLAY_LEVEL, 0) // which level DUMP_PLAY shows (no banner)
DUMP_LEVELS :: #config(DUMP_LEVELS, "") // path prefix: writes <prefix>0.ppm, <prefix>1.ppm ... one per level

write_ppm :: proc(t: ^testing.T, path: string, f: ^Frame) {
	resolve(f)
	out := make([dynamic]u8)
	defer delete(out)
	append(&out, "P6\n240 136\n255\n")
	for px in f.rgba {
		append(&out, u8(px), u8(px >> 8), u8(px >> 16))
	}
	testing.expect_value(t, os.write_entire_file(path, out[:]), nil)
}

@(test)
dump_frames :: proc(t: ^testing.T) {
	if DUMP_MENU == "" && DUMP_PLAY == "" && DUMP_HELP == "" && DUMP_SCORE == "" && DUMP_LEVELS == "" && DUMP_BANNER == "" && DUMP_SHOP == "" {
		return
	}
	f := new(Frame)
	defer free(f)
	g: Game
	init_game(&g)
	if DUMP_MENU != "" {
		draw_game(f, &g)
		write_ppm(t, DUMP_MENU, f)
	}
	if DUMP_HELP != "" {
		g.phase = .Help
		draw_game(f, &g)
		write_ppm(t, DUMP_HELP, f)
		g.help_page = 1
		draw_game(f, &g)
		write_ppm(t, strings.concatenate({DUMP_HELP, ".2.ppm"}), f)
	}
	if DUMP_BANNER != "" {
		g.phase = .Play
		draw_game(f, &g)
		write_ppm(t, DUMP_BANNER, f)
	}
	if DUMP_PLAY != "" {
		g.phase = .Play
		load_level(&g, DUMP_PLAY_LEVEL)
		g.banner = false
		draw_game(f, &g)
		write_ppm(t, DUMP_PLAY, f)
	}
	if DUMP_LEVELS != "" {
		g.phase = .Play
		for n in 0 ..< len(LEVELS) {
			load_level(&g, n)
			g.banner = false
			draw_game(f, &g)
			buf: [256]u8
			path := strings.concatenate({num_text(buf[:], DUMP_LEVELS, n), ".ppm"})
			write_ppm(t, path, f)
			delete(path)
		}
	}
	if DUMP_SHOP != "" {
		g.phase, g.js, g.note = .Shop, 3, "Welcome, adventurer."
		draw_game(f, &g)
		write_ppm(t, DUMP_SHOP, f)
	}
	if DUMP_SCORE != "" {
		g.phase = .Score
		g.h, g.ms, g.js, g.ks, g.ps = 2, 3, 4, 1, 2
		draw_game(f, &g)
		write_ppm(t, DUMP_SCORE, f)
	}
}

@(test)
number_text :: proc(t: ^testing.T) {
	buf: [32]u8
	testing.expect_value(t, num_text(buf[:], "x", 0), "x0")
	testing.expect_value(t, num_text(buf[:], "x", 1250), "x1250")
	testing.expect_value(t, line_text(buf[:], "Jools x ", 4, 250), "Jools x 4 = 1000")
}

@(test)
glyph_widths :: proc(t: ^testing.T) {
	testing.expect_value(t, text_width("Key"), 18)
	testing.expect_value(t, text_width("Hi", 2), 24)
}

@(test)
resolve_uses_palette :: proc(t: ^testing.T) {
	f := new(Frame)
	defer free(f)
	cls(f, 0)
	resolve(f)
	// Sweetie-16 colour 0 is 0x1a1c2c; bytes are R,G,B,A in memory.
	testing.expect_value(t, f.rgba[0], u32(0xFF2C1C1A))
}

@(test)
health_hearts :: proc(t: ^testing.T) {
	f := new(Frame)
	defer free(f)
	g: Game
	init_game(&g)
	g.phase = .Play
	g.h = 1
	draw_game(f, &g)
	// Heart pixels sit at the same place in every slot; slot 0 is lit, slot 1 is darkened.
	lit, dark := -1, -1
	for i in 0 ..< TILE * TILE {
		if GFX[Gfx.Heart][i] != 0 {
			x, y := i % TILE, i / TILE
			lit = int(f.px[y * SCREEN_W + HUD_X + x])
			dark = int(f.px[y * SCREEN_W + HUD_X + TILE + x])
			break
		}
	}
	testing.expect_value(t, lit, 2)
	testing.expect_value(t, dark, 14)
}
