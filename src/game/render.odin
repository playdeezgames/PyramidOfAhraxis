package game

// Software renderer for a 240x136 screen: palette-indexed pixels, resolved to RGBA for the page.
// Pictures are Urizen 12x12 tiles (gfx.odin), text is the 6x8 DINOBYTE font (font.odin).

SCREEN_W :: 240
SCREEN_H :: 136

TILE :: 12 // pixels per map cell
VIEW_W :: 15 // cells across the play window, centred on the player
VIEW_H :: 11 // cells down
VIEW_Y :: (SCREEN_H - VIEW_H * TILE) / 2
HUD_X :: VIEW_W * TILE + 4 // the statistics column is 56 px (nine glyphs) wide

GLYPH_W :: 6
GLYPH_H :: 8

Frame :: struct {
	px:   [SCREEN_W * SCREEN_H]u8, // palette indices
	rgba: [SCREEN_W * SCREEN_H]u32, // 0xAABBGGRR (little-endian R,G,B,A bytes)
}

// Palette colours the game names.
COLOR_BLACK :: 0
COLOR_BG :: 15

// Order matches PICKS in tools/extract_gfx.py.
Gfx :: enum {
	Wall,
	Door,
	Door_Window,
	Exit,
	Trap,
	Key,
	Potion,
	Jool,
	Shield,
	Sword,
	Monster,
	Player,
	Dead,
	Heart,
	Heart_Empty,
	Wall_Brick,
	Wall_Block,
	Wall_Wood,
	Wall_Round,
	Floor_Dots,
	Floor_Hatch,
	Floor_Weave,
	Floor_Cross,
	Floor_Moss,
	Candle,
	Lantern,
	Brazier,
	Merchant,
	Wraith,
	Kit,
}

// How a level looks: its wall picture and colour, and what its floor is made of.
Theme :: struct {
	wall:        Gfx,
	wall_color:  u8,
	floor_bg:    u8,
	floor:       Gfx,
	floor_color: u8,
	has_floor:   bool,
}

// Indexed by Level.theme (set per level in tools/import_opd.py). Theme 0 is the original look.
THEMES := [?]Theme{
	{wall = .Wall, wall_color = 13, floor_bg = COLOR_BLACK},
	{wall = .Wall_Brick, wall_color = 2, floor_bg = COLOR_BLACK, floor = .Floor_Cross, floor_color = 1, has_floor = true},
	{wall = .Wall_Block, wall_color = 12, floor_bg = COLOR_BLACK, floor = .Floor_Dots, floor_color = 15, has_floor = true},
	{wall = .Wall_Block, wall_color = 4, floor_bg = COLOR_BLACK, floor = .Floor_Hatch, floor_color = 1, has_floor = true},
	{wall = .Wall_Round, wall_color = 10, floor_bg = 8, floor = .Floor_Weave, floor_color = 15, has_floor = true},
	{wall = .Wall_Wood, wall_color = 3, floor_bg = COLOR_BLACK, floor = .Floor_Moss, floor_color = 6, has_floor = true},
}

COLOR_DIM :: 15 // remembered cells

// Cart tile ids with behaviour (see game.odin); anything else is open floor.
tile_gfx :: proc(id: int) -> (g: Gfx, ok: bool) {
	switch id {
	case 1: return .Wall, true
	case 2: return .Door, true
	case 3: return .Door_Window, true
	case 4, 5: return .Door_Window, true // gates with two and three locks
	case 6: return .Brazier, true
	case 133: return .Candle, true
	case 134: return .Lantern, true
	case 7: return .Merchant, true
	case 8: return .Exit, true
	case 41: return .Trap, true
	case 10: return .Trap, true
	case 66: return .Monster, true
	case 67: return .Wraith, true
	case 135: return .Kit, true
	case 128: return .Key, true
	case 129: return .Potion, true
	case 130: return .Jool, true
	case 131: return .Shield, true
	case 132: return .Sword, true
	}
	return {}, false
}

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

// Draws a picture at (x, y); background pixels (index 0) are drawn only when opaque is set.
draw_gfx :: proc(f: ^Frame, g: Gfx, x, y: int, opaque := false) {
	for j in 0 ..< TILE {
		for i in 0 ..< TILE {
			c := GFX[g][j * TILE + i]
			if c != 0 || opaque {
				set_px(f, x + i, y + j, c)
			}
		}
	}
}

// Draws a picture in one colour (a theme recolours walls and floors this way).
draw_gfx_color :: proc(f: ^Frame, g: Gfx, x, y: int, color: u8) {
	for j in 0 ..< TILE {
		for i in 0 ..< TILE {
			if GFX[g][j * TILE + i] != 0 {
				set_px(f, x + i, y + j, color)
			}
		}
	}
}

// The play window. Lit cells are drawn in full, remembered ones dimmed (without monsters),
// and cells never lit stay black.
draw_map :: proc(f: ^Frame, g: ^Game, cx, cy: int) {
	theme := THEMES[LEVELS[g.level].theme]
	for j in 0 ..< VIEW_H {
		for i in 0 ..< VIEW_W {
			x, y := i * TILE, VIEW_Y + j * TILE
			mx, my := cx + i, cy + j
			bg := u8(COLOR_BLACK)
			shown, remembered := false, false
			if mx >= 0 && my >= 0 && mx < g.mw && my < g.mh {
				shown = lit(g, mx, my)
				remembered = !shown && g.seen[my * g.mw + mx]
			}
			if shown {
				bg = theme.floor_bg
			}
			fill_rect(f, x, y, TILE, TILE, bg)
			if !shown && !remembered {
				continue
			}
			t := mget(g, mx, my)
			if remembered {
				if is_monster(t) {
					continue
				}
				if gfx, ok := tile_gfx(int(t)); ok {
					draw_gfx_color(f, t == 1 ? theme.wall : gfx, x, y, COLOR_DIM)
				}
				continue
			}
			if t != 1 && theme.has_floor {
				draw_gfx_color(f, theme.floor, x, y, theme.floor_color)
			}
			if t == 1 {
				draw_gfx_color(f, theme.wall, x, y, theme.wall_color)
			} else if gfx, ok := tile_gfx(int(t)); ok {
				if t == TILE_TRAP_SEEN {
					draw_gfx_color(f, gfx, x, y, 4)
				} else {
					draw_gfx(f, gfx, x, y)
				}
			}
			if n := locks_of(t); n > 1 { // a gate that takes several keys shows how many
				digit := [1]u8{u8('0' + n)}
				shadow(f, string(digit[:]), x + (TILE - GLYPH_W) / 2, y + (TILE - GLYPH_H) / 2, 4)
			}
		}
	}
}

text_width :: proc(text: string, scale: int = 1) -> int {
	return len(text) * GLYPH_W * scale
}

// Monospaced print; returns the width drawn.
print :: proc(f: ^Frame, text: string, x, y: int, color: u8 = 12, scale: int = 1) -> int {
	for i in 0 ..< len(text) {
		bits := FONT[text[i]]
		for row in 0 ..< GLYPH_H {
			for col in 0 ..< GLYPH_W {
				if bits & (1 << uint(row * GLYPH_W + col)) == 0 {
					continue
				}
				for sy in 0 ..< scale {
					for sx in 0 ..< scale {
						set_px(f, x + (i * GLYPH_W + col) * scale + sx, y + row * scale + sy, color)
					}
				}
			}
		}
	}
	return text_width(text, scale)
}

// print with a drop shadow one pixel down and right.
shadow :: proc(f: ^Frame, text: string, x, y: int, fg: u8 = 12, bg: u8 = 0, scale: int = 1) {
	print(f, text, x + 1, y + 1, bg, scale)
	print(f, text, x, y, fg, scale)
}

// Shadowed text centred on the screen.
center :: proc(f: ^Frame, text: string, y: int, fg: u8 = 12, scale: int = 1) {
	shadow(f, text, (SCREEN_W - text_width(text, scale)) / 2, y, fg, 0, scale)
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
	center(f, "\xC9\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xBB", 8, 9, 1)
	center(f, "Pyramid of Ahraxis", 18, 9, 2)
	center(f, "\xC8\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xBC", 36, 9, 1)
	draw_gfx(f, .Player, 114, 52)
	center(f, "S-Start", 74)
	center(f, "I-Instructions", 86)
	center(f, "A Production of", 104, 14)
	center(f, "TheGrumpyGameDev", 112, 6)
	center(f, "September 2023", 122, 14)
}

draw_help :: proc(f: ^Frame) {
	cls(f, COLOR_BG)
	shadow(f, "Instructions", 0, 0, 9, 0, 2)
	shadow(f, "Controls (in-game):", 0, 20, 3)
	shadow(f, "Any key: Back", 120, 20, 12)
	shadow(f, "Arrows: Move  F2: Reset  P: Potion", 0, 29)
	shadow(f, "Pictures:", 0, 38, 3)
	rows := [?]struct {
		g:    Gfx,
		name: string,
	}{{.Player, "You"}, {.Key, "Key"}, {.Potion, "Potion"}, {.Shield, "Shield"}, {.Sword, "Sword"}}
	more := [?]struct {
		g:    Gfx,
		name: string,
	}{{.Jool, "JOOLS!!"}, {.Candle, "Light"}, {.Heart, "Health"}, {.Door, "Door"}, {.Trap, "Trap"}}
	for r, i in rows {
		draw_gfx(f, r.g, 0, 48 + i * 12)
		shadow(f, r.name, 16, 50 + i * 12)
	}
	for r, i in more {
		draw_gfx(f, r.g, 120, 48 + i * 12)
		shadow(f, r.name, 136, 50 + i * 12)
	}
	shadow(f, "Art: Urizen by vurmux (CC0)", 0, 110, 13)
	shadow(f, "Font: DINOBYTE by mby (CC BY 4.0)", 0, 118, 13)
	shadow(f, "Maps: One Page Dungeon by Watabou", 0, 126, 13)
}

// Floating messages: centred on their cell, rising one pixel every three frames, blinking out.
draw_floaters :: proc(f: ^Frame, g: ^Game) {
	cx, cy := g.x - VIEW_W / 2, g.y - VIEW_H / 2
	for &m in g.floats {
		if m.n == 0 || (m.age > FLOAT_LIFE - 18 && m.age / 3 % 2 == 0) {
			continue
		}
		text := string(m.text[:m.n])
		w := text_width(text)
		x := clamp((m.x - cx) * TILE + TILE / 2 - w / 2, 0, VIEW_W * TILE - w)
		y := VIEW_Y + (m.y - cy) * TILE + (TILE - GLYPH_H) / 2 - m.lift - m.age / 3
		shadow(f, text, x, y, m.color)
	}
}

// HUD row: a picture and a count, 14 px apart.
hud_row :: proc(f: ^Frame, g: Gfx, n: int, row: int, color: u8 = 12) {
	y := row * 14
	draw_gfx(f, g, HUD_X, y)
	buf: [16]u8
	print(f, num_text(buf[:], "x", n), HUD_X + 16, y + 2, color)
}

fill_rect :: proc(f: ^Frame, x, y, w, h: int, c: u8) {
	for j in 0 ..< h {
		for i in 0 ..< w {
			set_px(f, x + i, y + j, c)
		}
	}
}

// Breaks text into lines of at most width glyphs at spaces; the lines alias text.
wrap_lines :: proc(text: string, width: int, out: []string) -> int {
	n, start := 0, 0
	for start < len(text) && n < len(out) {
		end := min(start + width, len(text))
		if end < len(text) {
			e := end
			for e > start && text[e] != ' ' {
				e -= 1
			}
			if e > start {
				end = e
			}
		}
		out[n] = text[start:end]
		n += 1
		start = end
		for start < len(text) && text[start] == ' ' {
			start += 1
		}
	}
	return n
}

// The level's name and hint over the top of the play window, until the first step.
draw_banner :: proc(f: ^Frame, g: ^Game) {
	lv := LEVELS[g.level]
	lines: [4]string
	n := wrap_lines(lv.hint, VIEW_W * TILE / GLYPH_W - 2, lines[:])
	h := 6 + 11 + n * 9 + 2
	fill_rect(f, 0, VIEW_Y, VIEW_W * TILE, h, COLOR_BLACK)
	title_x := (VIEW_W * TILE - text_width(lv.title)) / 2
	shadow(f, lv.title, max(title_x, 0), VIEW_Y + 5, 4)
	for line, i in lines[:n] {
		shadow(f, line, 6, VIEW_Y + 5 + 12 + i * 9)
	}
}

draw_play :: proc(f: ^Frame, g: ^Game) {
	cls(f, COLOR_BG)
	draw_map(f, g, g.x - VIEW_W / 2, g.y - VIEW_H / 2)
	draw_gfx(f, alive(g) ? .Player : .Dead, (VIEW_W / 2) * TILE, VIEW_Y + (VIEW_H / 2) * TILE)
	draw_floaters(f, g)
	if g.banner {
		draw_banner(f, g)
	}
	for i in 0 ..< START_HEALTH {
		beat := last_heart(g) && i == 0 && g.clock / 15 % 2 == 1 // last heart blinks about twice a second
		draw_gfx(f, g.h > i && !beat ? .Heart : .Heart_Empty, HUD_X + i * TILE, 0)
	}
	hud_row(f, .Key, g.ks, 1)
	hud_row(f, .Potion, g.ps, 2)
	hud_row(f, .Jool, g.js, 3, 11)
	hud_row(f, .Sword, g.as, 4)
	hud_row(f, .Shield, g.ds, 5)
	hud_row(f, g.lantern ? .Lantern : .Candle, g.fuel, 6, g.fuel == 0 ? 3 : g.fuel <= 30 ? 4 : 12)
	hud_row(f, .Kit, g.ts, 7)
	a, b: [12]u8
	at := num_text(a[:], "Lv ", g.level + 1)
	shadow(f, at, HUD_X, 113, 13)
	shadow(f, num_text(b[:], "/", len(LEVELS)), HUD_X + text_width(at), 113, 13)
	shadow(f, "P:Potion", HUD_X, 123)
}

draw_shop :: proc(f: ^Frame, g: ^Game) {
	cls(f, COLOR_BG)
	draw_gfx(f, .Merchant, 0, 2)
	shadow(f, "Merchant", 16, 0, 4, 0, 2)
	buf: [24]u8
	shadow(f, num_text(buf[:], "Jools x ", g.js), 0, 20, 11)
	for name, i in SHOP_NAMES {
		y := 34 + i * 12
		digit := [1]u8{u8('1' + i)}
		shadow(f, string(digit[:]), 0, y, 4)
		shadow(f, name, 14, y)
		shadow(f, num_text(buf[:], "", SHOP_PRICES[i]), 130, y, 11)
	}
	shadow(f, g.note, 0, 108, 13)
	shadow(f, "1-6: Buy   Any other key: Leave", 0, 124, 14)
}

draw_score :: proc(f: ^Frame, g: ^Game) {
	cls(f, COLOR_BLACK)
	shadow(f, "Score:", 0, 0, 9, 0, 2)
	buf: [48]u8
	shadow(f, line_text(buf[:], "Health x ", g.h, 100), 0, 20)
	shadow(f, line_text(buf[:], "Kills x ", g.ms, 50), 0, 30)
	shadow(f, line_text(buf[:], "Jools x ", g.js, 250), 0, 40)
	shadow(f, line_text(buf[:], "Keys x ", g.ks, 500), 0, 50)
	shadow(f, line_text(buf[:], "Potions x ", g.ps, 75), 0, 60)
	total: [24]u8
	shadow(f, num_text(total[:], "Total = ", score(g)), 0, 112)
	shadow(f, "F2: Reset", 0, 126, 14)
}

draw_game :: proc(f: ^Frame, g: ^Game) {
	switch g.phase {
	case .Menu:
		draw_menu(f)
	case .Help:
		draw_help(f)
	case .Play:
		draw_play(f, g)
	case .Shop:
		draw_shop(f, g)
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
