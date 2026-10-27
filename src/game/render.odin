package game

// Software renderer for TIC-80's 240x136 screen: palette-indexed pixels, resolved to RGBA
// for the page. Mirrors the cart's cls/spr/map/print calls.

SCREEN_W :: 240
SCREEN_H :: 136

Frame :: struct {
	px:   [SCREEN_W * SCREEN_H]u8, // palette indices
	rgba: [SCREEN_W * SCREEN_H]u32, // 0xAABBGGRR (little-endian R,G,B,A bytes)
}

// Palette colours the cart names.
COLOR_BLACK :: 0
COLOR_BG :: 15

cls :: proc(f: ^Frame, c: u8) {
	for &p in f.px {
		p = c
	}
}

set_px :: proc(f: ^Frame, x, y: int, c: u8) {
	if x < 0 || y < 0 || x >= SCREEN_W || y >= SCREEN_H {
		return
	}
	f.px[y * SCREEN_W + x] = c
}

// spr(id, x, y, colorkey): colorkey < 0 draws every pixel.
spr :: proc(f: ^Frame, id: int, x, y: int, colorkey: int = -1) {
	for j in 0 ..< 8 {
		for i in 0 ..< 8 {
			c := TILES[id * 64 + j * 8 + i]
			if int(c) != colorkey {
				set_px(f, x + i, y + j, c)
			}
		}
	}
}

// map(cx, cy, w, h) at screen (0,0), no colour key. Cells off the map read as tile 0.
draw_map :: proc(f: ^Frame, g: ^Game, cx, cy, w, h: int) {
	for j in 0 ..< h {
		for i in 0 ..< w {
			spr(f, int(mget(g, cx + i, cy + j)), i * 8, j * 8)
		}
	}
}

// Lit column range of a glyph: leftmost column and width. TIC-80 draws a proportional glyph
// starting at its leftmost lit column. A space (nothing lit) is 3 wide.
glyph_extent :: proc(ch: u8) -> (left, size: int) {
	if ch == ' ' {
		return 0, 3
	}
	lo, hi := 8, -1
	for row in FONT[ch & 127] {
		for c in 0 ..< 8 {
			if row & (1 << uint(c)) != 0 {
				lo = min(lo, c)
				hi = max(hi, c)
			}
		}
	}
	if hi < 0 {
		return 0, 0
	}
	return lo, hi - lo + 1
}

glyph_size :: proc(ch: u8) -> int {
	_, size := glyph_extent(ch)
	return size
}

// print(text, x, y, color, false, scale): proportional, one blank column between glyphs.
print :: proc(f: ^Frame, text: string, x, y: int, color: u8 = 15, scale: int = 1) -> int {
	cx := x
	for i in 0 ..< len(text) {
		ch := text[i]
		left, size := glyph_extent(ch)
		for row, j in FONT[ch & 127] {
			for c in 0 ..< 8 {
				if row & (1 << uint(c)) == 0 {
					continue
				}
				for sy in 0 ..< scale {
					for sx in 0 ..< scale {
						set_px(f, cx + (c - left) * scale + sx, y + j * scale + sy, color)
					}
				}
			}
		}
		cx += (size + 1) * scale
	}
	return cx - x
}

// shadow(text, x, y, fg=12, bg=0, scale=1)
shadow :: proc(f: ^Frame, text: string, x, y: int, fg: u8 = 12, bg: u8 = 0, scale: int = 1) {
	print(f, text, x + 1, y + 1, bg, scale)
	print(f, text, x, y, fg, scale)
}

hline :: proc(f: ^Frame, s: int, l: int, x, y: int) {
	for i in 0 ..< l {
		spr(f, s, x + i * 8, y, 0)
	}
}

// Writes palette indices through the palette into rgba.
resolve :: proc(f: ^Frame) {
	for p, i in f.px {
		c := PALETTE[p & 15]
		f.rgba[i] = 0xFF000000 | (c & 0xFF) << 16 | (c >> 8 & 0xFF) << 8 | (c >> 16 & 0xFF)
	}
}

draw_menu :: proc(f: ^Frame) {
	cls(f, COLOR_BG)
	shadow(f, "============================", 8, 6, 9, 0, 2)
	shadow(f, "==Pyramid of Ahraxis==", 6, 18, 9, 0, 2)
	shadow(f, "============================", 8, 30, 9, 0, 2)
	shadow(f, "S-Start", 101, 63)
	shadow(f, "I-Instructions", 82, 75)
	shadow(f, "A Production of", 79, 118, 14)
	shadow(f, "TheGrumpyGameDev", 73, 124, 6)
	shadow(f, "September 2023", 80, 130, 14)
}

draw_help :: proc(f: ^Frame) {
	cls(f, COLOR_BG)
	shadow(f, "Instructions", 0, 0, 9, 0, 2)
	shadow(f, "Controls(in-game):", 0, 18, 3)
	shadow(f, "Arrows: Move", 0, 24)
	shadow(f, "F2: Reset", 24, 30)
	shadow(f, "Q: Quaff(potion)", 30, 36)
	shadow(f, "Sprites:", 0, 48, 3)
	spr(f, 64, 0, 56)
	shadow(f, "You", 9, 57)
	spr(f, 128, 0, 64)
	shadow(f, "Key", 9, 65)
	spr(f, 129, 0, 72)
	shadow(f, "Potion", 9, 73)
	spr(f, 131, 0, 80)
	shadow(f, "Shield", 9, 81)
	spr(f, 132, 0, 88)
	shadow(f, "Sword", 9, 89)
	spr(f, 130, 60, 56)
	shadow(f, "JOOLS!!", 69, 57)
	spr(f, 1, 60, 64)
	shadow(f, "Wall", 69, 65)
	spr(f, 192, 60, 72)
	shadow(f, "Health", 69, 73)
	spr(f, 2, 60, 80)
	shadow(f, "Door", 69, 81)
	spr(f, 41, 60, 88)
	shadow(f, "Trap", 69, 89)
	shadow(f, "Press Any Key to go Back", 0, 130, 14)
}

draw_play :: proc(f: ^Frame, g: ^Game) {
	cls(f, COLOR_BG)
	draw_map(f, g, g.x - 8, g.y - 8, 17, 17)
	spr(f, alive(g) ? 64 : 65, 64, 64)
	hline(f, 192, g.h, 136, 0)
	hline(f, 128, g.ks, 136, 8)
	hline(f, 129, g.ps, 136, 16)
	spr(f, 130, 136, 24, 0)
	buf: [16]u8
	print(f, num_text(buf[:], "x", g.js), 144, 24, 11)
	hline(f, 132, g.as, 136, 32)
	hline(f, 131, g.ds, 136, 40)
	if mget(g, g.x, g.y) == TRAP_SPRUNG {
		print(f, "TRAP!", 136, 48, 12)
	}
	shadow(f, "Arrows: Move", 136, 112)
	shadow(f, "F2: Reset", 136, 120)
	shadow(f, "Q: Quaff Potion", 136, 128)
}

draw_score :: proc(f: ^Frame, g: ^Game) {
	cls(f, COLOR_BLACK)
	shadow(f, "Score:", 0, 0, 9, 0, 2)
	buf: [48]u8
	shadow(f, line_text(buf[:], "Health x ", g.h, 100), 0, 16)
	shadow(f, line_text(buf[:], "Kills x ", g.ms, 50), 0, 24)
	shadow(f, line_text(buf[:], "Jools x ", g.js, 250), 0, 32)
	shadow(f, line_text(buf[:], "Keys x ", g.ks, 500), 0, 40)
	shadow(f, line_text(buf[:], "Potions x ", g.ps, 75), 0, 48)
	total: [24]u8
	shadow(f, num_text(total[:], "Total = ", score(g)), 0, 120)
	shadow(f, "F2: Reset", 0, 128, 14)
}

draw_game :: proc(f: ^Frame, g: ^Game) {
	switch g.phase {
	case .Menu:
		draw_menu(f)
	case .Help:
		draw_help(f)
	case .Play:
		draw_play(f, g)
	case .Score:
		draw_score(f, g)
	}
}

// "<prefix><n>" without an allocator; the result aliases buf.
num_text :: proc(buf: []u8, prefix: string, n: int) -> string {
	k := copy(buf, prefix)
	digits: [20]u8
	m, v := 0, abs(n)
	for {
		digits[m] = u8('0' + v % 10)
		m += 1
		v /= 10
		if v == 0 {
			break
		}
	}
	if n < 0 {
		buf[k] = '-'
		k += 1
	}
	for i := m - 1; i >= 0; i -= 1 {
		buf[k] = digits[i]
		k += 1
	}
	return string(buf[:k])
}

// "Label x N = N*mult"
line_text :: proc(buf: []u8, label: string, n, mult: int) -> string {
	a := num_text(buf, label, n)
	k := len(a)
	k += copy(buf[k:], " = ")
	b := num_text(buf[k:], "", n * mult)
	return string(buf[:k + len(b)])
}
