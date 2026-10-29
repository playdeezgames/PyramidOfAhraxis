package game

// Pure rules of the TIC-80 cart (Mv, Qf, Score and the Menu/Help/Play/Score
// screens), ported faithfully from its Lua, plus a sequence of levels: dungeons made from
// Watabou's One Page Dungeon seeds (levels.odin) and then the cart's own map. No browser
// imports, no clock, no RNG.

Phase :: enum {
	Menu,
	Help,
	Play,
	Score,
}

Command :: enum {
	Up,
	Down,
	Left,
	Right,
	Quaff,
	Start, // menu: S
	Instructions, // menu: I
	Back, // help: any key
	Reset, // F2
}

// One entry per sfx()/music() call of the Lua. The page maps these to audio.
Sound :: enum {
	Bump, // sfx 0 D-1
	Key, // sfx 1 A-4
	Door, // sfx 2 D-1
	Sword_Kill, // sfx 2 D-2
	Shield_Block, // sfx 2 G-1
	Monster_Hit, // sfx 2 C-2
	Trap, // sfx 3 G-1
	Music_Death, // music 0
	Music_Shield, // music 1
	Music_Start, // music 2
	Music_Sword, // music 3
	Music_Jool, // music 4
	Music_Potion, // music 5
	Music_Quaff, // music 6
	Music_Exit, // music 7
}

START_HEALTH :: 3
TRAP_SPRUNG :: 41

// Tile ids that carry behaviour (see CLAUDE.md).
TILE_DOOR :: 2 // one lock
TILE_GATE1 :: 3 // one lock
TILE_GATE2 :: 4 // two locks (generated levels only)
TILE_GATE3 :: 5 // three locks (generated levels only)
TILE_EXIT :: 8
TILE_TRAP :: 9
TILE_MONSTER :: 66
TILE_KEY :: 128
TILE_POTION :: 129
TILE_JOOL :: 130
TILE_SHIELD :: 131
TILE_SWORD :: 132

FLAG_DOOR :: 6
FLAG_SOLID :: 7

// A level: a grid of tile ids (row-major, w by h) and where the player starts.
Level :: struct {
	title:            string,
	hint:             string,
	w, h:             int,
	start_x, start_y: int,
	tiles:            []u8,
}

CART_LEVEL :: len(LEVELS) - 1 // the last level is the cart's own map

Game :: struct {
	phase:  Phase,
	map_:   [MAP_W * MAP_H]u8, // the current level, stride mw
	mw, mh: int,
	level:  int,
	banner: bool, // show the level title until the first step
	x, y:   int,
	h:      int, // health
	ks:     int, // keys
	ps:     int, // potions
	js:     int, // jools
	ds:     int, // shields
	as:     int, // swords
	ms:     int, // kills
	sounds: [8]Sound,
	nsound: int,
	floats: [8]Floater,
}

FLOAT_LIFE :: 80 // frames a floating message lives
FLOAT_STACK :: 9 // pixels between messages made on the same turn

// A short message that starts on the cell where something happened and drifts up.
Floater :: struct {
	text:  [16]u8,
	n:     int, // 0 = unused
	color: u8,
	x, y:  int, // map cell
	lift:  int, // extra pixels up, so messages of one turn do not overlap
	age:   int, // frames
}

// Shows a message over the player.
@(private)
say :: proc(g: ^Game, text: string, color: u8 = 12) {
	lift, free := 0, -1
	for f, i in g.floats {
		if f.n == 0 {
			if free < 0 {
				free = i
			}
		} else if f.age < 12 && f.x == g.x && f.y == g.y {
			lift += FLOAT_STACK
		}
	}
	if free < 0 {
		return
	}
	f := &g.floats[free]
	f^ = {x = g.x, y = g.y, lift = lift, color = color}
	f.n = copy(f.text[:], text)
}

// One frame of drift; reports whether any message is still showing, so the page keeps redrawing.
tick :: proc(g: ^Game) -> bool {
	any_left := false
	for &f in g.floats {
		if f.n == 0 {
			continue
		}
		f.age += 1
		if f.age >= FLOAT_LIFE {
			f = {}
		} else {
			any_left = true
		}
	}
	return any_left
}

init_game :: proc(g: ^Game) {
	g^ = {}
	g.h = START_HEALTH
	g.phase = .Menu
	load_level(g, 0)
}

// Loads a level's map and puts the player on its start; health and items carry over.
load_level :: proc(g: ^Game, n: int) {
	lv := LEVELS[n]
	g.level = n
	g.mw, g.mh = lv.w, lv.h
	g.map_ = {}
	copy(g.map_[:], lv.tiles)
	g.x, g.y = lv.start_x, lv.start_y
	g.floats = {}
	g.banner = true
}

// mget: cells outside the map read as 0.
mget :: proc(g: ^Game, x, y: int) -> u8 {
	if x < 0 || y < 0 || x >= g.mw || y >= g.mh {
		return 0
	}
	return g.map_[y * g.mw + x]
}

mset :: proc(g: ^Game, x, y: int, t: u8) {
	if x < 0 || y < 0 || x >= g.mw || y >= g.mh {
		return
	}
	g.map_[y * g.mw + x] = t
}

// Keys a locked tile still wants (0 = not a lock). Tiles 2 and 3 are the cart's doors.
locks_of :: proc(c: u8) -> int {
	switch c {
	case TILE_DOOR, TILE_GATE1: return 1
	case TILE_GATE2: return 2
	case TILE_GATE3: return 3
	}
	return 0
}

// The tile left when one lock of a gate is opened (1 lock -> open floor).
@(private)
fewer_locks :: proc(locks: int) -> u8 {
	switch locks {
	case 2: return TILE_GATE1
	case 3: return TILE_GATE2
	}
	return 0
}

is_solid :: proc(c: u8) -> bool {
	return fget(c, FLAG_SOLID) || locks_of(c) > 0
}

fget :: proc(tile: u8, flag: uint) -> bool {
	return FLAGS[tile] & (1 << flag) != 0
}

alive :: proc(g: ^Game) -> bool {
	return g.h > 0
}

// Sounds queued by the last commands; the page drains them each frame.
take_sounds :: proc(g: ^Game, out: []Sound) -> int {
	n := min(g.nsound, len(out))
	copy(out[:n], g.sounds[:n])
	g.nsound = 0
	return n
}

@(private)
play :: proc(g: ^Game, s: Sound) {
	if g.nsound < len(g.sounds) {
		g.sounds[g.nsound] = s
		g.nsound += 1
	}
}

score :: proc(g: ^Game) -> int {
	return g.h * 100 + g.ms * 50 + g.js * 250 + g.ks * 500 + g.ps * 75
}

// Mv(dx, dy). Faithful quirk: a sword kill still lets the same bump resolve the
// shield/health branch, so the monster hits back on the turn it dies.
@(private)
move :: proc(g: ^Game, dx, dy: int) {
	nx, ny := g.x + dx, g.y + dy
	c := mget(g, nx, ny)
	if is_solid(c) {
		if locks := locks_of(c); locks > 0 && g.ks > 0 {
			play(g, .Door)
			g.ks -= 1
			if locks > 1 {
				say(g, "Lock opened", 4)
			} else {
				say(g, "Door unlocked", 4)
			}
			mset(g, nx, ny, fewer_locks(locks))
		} else if c == TILE_MONSTER {
			if g.as > 0 {
				play(g, .Sword_Kill)
				say(g, "Monster slain", 5)
				g.as -= 1
				g.ms += 1
				mset(g, nx, ny, 0)
			}
			if g.ds > 0 {
				play(g, .Shield_Block)
				say(g, "Shield blocks", 9)
				g.ds -= 1
			} else {
				g.h -= 1
				if g.h <= 0 {
					play(g, .Music_Death)
					say(g, "You died!", 3)
				} else {
					play(g, .Monster_Hit)
					say(g, "Ouch! -1 health", 3)
				}
			}
		} else {
			play(g, .Bump)
			if locks > 1 {
				buf: [16]u8
				say(g, num_text(buf[:], "Needs keys: ", locks), 12)
			} else if locks == 1 {
				say(g, "Need a key", 12)
			}
		}
		return
	}
	g.x, g.y = nx, ny
	switch c {
	case TILE_EXIT:
		play(g, .Music_Exit)
		if g.level + 1 < len(LEVELS) {
			load_level(g, g.level + 1)
		} else {
			g.phase = .Score
		}
	case TILE_KEY:
		play(g, .Key)
		say(g, "+1 key", 4)
		mset(g, nx, ny, 0)
		g.ks += 1
	case TILE_POTION:
		play(g, .Music_Potion)
		say(g, "+1 potion", 2)
		mset(g, nx, ny, 0)
		g.ps += 1
	case TILE_JOOL:
		play(g, .Music_Jool)
		say(g, "+1 jool", 11)
		mset(g, nx, ny, 0)
		g.js += 1
	case TILE_SHIELD:
		play(g, .Music_Shield)
		say(g, "+1 shield", 9)
		mset(g, nx, ny, 0)
		g.ds += 1
	case TILE_SWORD:
		play(g, .Music_Sword)
		say(g, "+1 sword", 12)
		mset(g, nx, ny, 0)
		g.as += 1
	case TILE_TRAP:
		mset(g, nx, ny, TRAP_SPRUNG)
		g.h -= 1
		if g.h <= 0 {
			play(g, .Music_Death)
			say(g, "You died!", 3)
		} else {
			play(g, .Trap)
			say(g, "Trap! -1 health", 3)
		}
	}
}

// Qf: quaffing always sets health to 3, even from full.
@(private)
quaff :: proc(g: ^Game) {
	if g.ps > 0 {
		play(g, .Music_Quaff)
		say(g, "Health restored", 5)
		g.ps -= 1
		g.h = START_HEALTH
	}
}

// Applies one command. Movement and quaffing only act while Playing and alive;
// F2 restarts from any screen (reset() reloads the cart, landing on the menu).
// The shell owns key repeat (the cart uses keyp(code, 10, 10)).
command :: proc(g: ^Game, cmd: Command) {
	if cmd == .Reset {
		init_game(g)
		return
	}
	switch g.phase {
	case .Menu:
		#partial switch cmd {
		case .Instructions:
			g.phase = .Help
		case .Start:
			play(g, .Music_Start)
			g.phase = .Play
		}
	case .Help:
		g.phase = .Menu
	case .Play:
		if !alive(g) {
			return
		}
		#partial switch cmd {
		case .Up:
			g.banner = false
			move(g, 0, -1)
		case .Down:
			g.banner = false
			move(g, 0, 1)
		case .Left:
			g.banner = false
			move(g, -1, 0)
		case .Right:
			g.banner = false
			move(g, 1, 0)
		case .Quaff:
			quaff(g)
		}
	case .Score:
	}
}
