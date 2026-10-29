#+build !js
package game

import "core:testing"

// A game on the cart's own map (the last level), where the original rules were pinned.
fresh :: proc() -> Game {
	g: Game
	init_game(&g)
	load_level(&g, CART_LEVEL)
	g.phase = .Play
	return g
}

// Puts one tile directly to the right of the player and clears the rest of the way.
put_right :: proc(g: ^Game, t: u8) {
	mset(g, g.x + 1, g.y, t)
}

@(test)
initial_state :: proc(t: ^testing.T) {
	g: Game
	init_game(&g)
	testing.expect_value(t, g.phase, Phase.Menu)
	testing.expect_value(t, g.level, 0)
	testing.expect_value(t, g.h, 3)
	testing.expect_value(t, g.x, LEVELS[0].start_x)
	testing.expect_value(t, g.y, LEVELS[0].start_y)
}

@(test)
cart_level_is_the_original_map :: proc(t: ^testing.T) {
	g := fresh()
	testing.expect_value(t, g.x, 21)
	testing.expect_value(t, g.y, 11)
	// BOOT shifted the hidden layer down: the start cell is the exit tile.
	testing.expect_value(t, mget(&g, 21, 11), u8(TILE_EXIT))
	for c in g.map_ {
		testing.expect(t, c < 32 || c >= 64)
	}
}

@(test)
menu_flow :: proc(t: ^testing.T) {
	g: Game
	init_game(&g)
	command(&g, .Up) // ignored on the menu
	testing.expect_value(t, g.phase, Phase.Menu)
	command(&g, .Instructions)
	testing.expect_value(t, g.phase, Phase.Help)
	command(&g, .Right) // any key goes back
	testing.expect_value(t, g.phase, Phase.Menu)
	command(&g, .Start)
	testing.expect_value(t, g.phase, Phase.Play)
	out: [8]Sound
	n := take_sounds(&g, out[:])
	testing.expect_value(t, n, 1)
	testing.expect_value(t, out[0], Sound.Music_Start)
}

@(test)
wall_blocks_and_bumps :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, 1)
	command(&g, .Right)
	testing.expect_value(t, g.x, 21)
	testing.expect_value(t, g.sounds[0], Sound.Bump)
}

@(test)
walking_onto_exit_scores :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, TILE_EXIT)
	command(&g, .Right)
	testing.expect_value(t, g.x, 22)
	testing.expect_value(t, g.phase, Phase.Score)
	command(&g, .Left) // no movement on the score screen
	testing.expect_value(t, g.x, 22)
}

@(test)
pickups :: proc(t: ^testing.T) {
	cases := [?]u8{TILE_KEY, TILE_POTION, TILE_JOOL, TILE_SHIELD, TILE_SWORD}
	for tile in cases {
		g := fresh()
		put_right(&g, tile)
		command(&g, .Right)
		testing.expect_value(t, g.x, 22)
		testing.expect_value(t, mget(&g, 22, 11), u8(0))
		total := g.ks + g.ps + g.js + g.ds + g.as
		testing.expect_value(t, total, 1)
	}
}

@(test)
door_needs_key :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, 2)
	command(&g, .Right)
	testing.expect_value(t, g.x, 21)
	testing.expect_value(t, mget(&g, 22, 11), u8(2))
	g.ks = 1
	command(&g, .Right)
	testing.expect_value(t, g.x, 21) // opening does not move
	testing.expect_value(t, mget(&g, 22, 11), u8(0))
	testing.expect_value(t, g.ks, 0)
	command(&g, .Right)
	testing.expect_value(t, g.x, 22)
}

@(test)
monster_without_gear_hurts :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, TILE_MONSTER)
	command(&g, .Right)
	testing.expect_value(t, g.h, 2)
	testing.expect_value(t, g.x, 21)
	testing.expect_value(t, mget(&g, 22, 11), u8(TILE_MONSTER))
	testing.expect_value(t, g.sounds[0], Sound.Monster_Hit)
}

@(test)
monster_shield_blocks :: proc(t: ^testing.T) {
	g := fresh()
	g.ds = 1
	put_right(&g, TILE_MONSTER)
	command(&g, .Right)
	testing.expect_value(t, g.h, 3)
	testing.expect_value(t, g.ds, 0)
}

@(test)
monster_sword_kills_but_still_hits_back :: proc(t: ^testing.T) {
	// Original quirk: the shield/health branch runs after a sword kill too.
	g := fresh()
	g.as = 1
	put_right(&g, TILE_MONSTER)
	command(&g, .Right)
	testing.expect_value(t, g.ms, 1)
	testing.expect_value(t, g.as, 0)
	testing.expect_value(t, mget(&g, 22, 11), u8(0))
	testing.expect_value(t, g.h, 2)
}

@(test)
death_stops_play :: proc(t: ^testing.T) {
	g := fresh()
	g.h = 1
	put_right(&g, TILE_MONSTER)
	command(&g, .Right)
	testing.expect_value(t, g.h, 0)
	testing.expect_value(t, g.sounds[0], Sound.Music_Death)
	mset(&g, 20, 11, 0)
	command(&g, .Left)
	testing.expect_value(t, g.x, 21)
	g.ps = 1
	command(&g, .Quaff)
	testing.expect_value(t, g.h, 0)
}

@(test)
trap_springs_once :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, TILE_TRAP)
	command(&g, .Right)
	testing.expect_value(t, g.x, 22)
	testing.expect_value(t, g.h, 2)
	testing.expect_value(t, mget(&g, 22, 11), u8(TRAP_SPRUNG))
	command(&g, .Left)
	command(&g, .Right) // sprung trap is just floor
	testing.expect_value(t, g.h, 2)
}

@(test)
quaff_restores_to_three :: proc(t: ^testing.T) {
	g := fresh()
	command(&g, .Quaff)
	testing.expect_value(t, g.nsound, 0) // no potion, nothing happens
	g.ps = 2
	g.h = 1
	command(&g, .Quaff)
	testing.expect_value(t, g.h, 3)
	testing.expect_value(t, g.ps, 1)
	g.h = 3 // wasted on full health, as in the original
	command(&g, .Quaff)
	testing.expect_value(t, g.ps, 0)
}

@(test)
score_formula :: proc(t: ^testing.T) {
	g := fresh()
	g.h, g.ms, g.js, g.ks, g.ps = 2, 3, 4, 1, 2
	testing.expect_value(t, score(&g), 200 + 150 + 1000 + 500 + 150)
}

@(test)
reset_restores_map_and_state :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, TILE_KEY)
	command(&g, .Right)
	command(&g, .Reset)
	testing.expect_value(t, g.phase, Phase.Menu)
	testing.expect_value(t, g.ks, 0)
	testing.expect_value(t, g.level, 0) // a reset starts again from the tutorial
	testing.expect_value(t, g.x, LEVELS[0].start_x)
	load_level(&g, CART_LEVEL)
	testing.expect_value(t, mget(&g, 22, 11), MAP_INITIAL[11 * MAP_W + 22])
}

@(test)
map_edge_reads_empty :: proc(t: ^testing.T) {
	g := fresh()
	g.x, g.y = 0, 0
	command(&g, .Left)
	testing.expect_value(t, g.x, -1) // off-map reads 0 so the cart walks off too
}

@(test)
pickup_floats_a_message_that_expires :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, TILE_KEY)
	command(&g, .Right)
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "+1 key")
	testing.expect_value(t, g.floats[0].x, g.x)
	for _ in 0 ..< FLOAT_LIFE - 1 {
		testing.expect(t, tick(&g))
	}
	testing.expect(t, !tick(&g))
	testing.expect_value(t, g.floats[0].n, 0)
}

@(test)
messages_of_one_turn_stack :: proc(t: ^testing.T) {
	g := fresh()
	g.as = 1
	put_right(&g, TILE_MONSTER)
	command(&g, .Right) // the sword kills it, and the quirk lets it hit back
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "Monster slain")
	testing.expect_value(t, string(g.floats[1].text[:g.floats[1].n]), "Ouch! -1 health")
	testing.expect_value(t, g.floats[1].lift, FLOAT_STACK)
}

@(test)
locked_door_says_so :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, 2)
	command(&g, .Right)
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "Need a key")
}

// Walks the exit of every level but the last into the next one, keeping what you carry.
@(test)
exit_loads_the_next_level :: proc(t: ^testing.T) {
	g: Game
	init_game(&g)
	g.phase = .Play
	g.ks, g.js, g.h = 2, 3, 2
	for n in 0 ..< CART_LEVEL {
		testing.expect_value(t, g.level, n)
		mset(&g, g.x + 1, g.y, TILE_EXIT)
		g.banner = false
		command(&g, .Right)
		testing.expect_value(t, g.level, n + 1)
		testing.expect_value(t, g.phase, Phase.Play)
		testing.expect_value(t, g.x, LEVELS[n + 1].start_x)
		testing.expect_value(t, g.y, LEVELS[n + 1].start_y)
		testing.expect(t, g.banner)
	}
	testing.expect_value(t, g.ks, 2)
	testing.expect_value(t, g.js, 3)
	testing.expect_value(t, g.h, 2)
}

@(test)
last_exit_goes_to_the_score :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, TILE_EXIT)
	command(&g, .Right)
	testing.expect_value(t, g.phase, Phase.Score)
}

@(test)
banner_stays_until_the_first_step :: proc(t: ^testing.T) {
	g: Game
	init_game(&g)
	command(&g, .Start)
	testing.expect(t, g.banner)
	command(&g, .Quaff) // no potion, not a step
	testing.expect(t, g.banner)
	command(&g, .Up)
	testing.expect(t, !g.banner)
}

@(test)
gate_with_several_locks_takes_a_key_at_a_time :: proc(t: ^testing.T) {
	g := fresh()
	put_right(&g, TILE_GATE3)
	command(&g, .Right)
	testing.expect_value(t, g.x, 21)
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "Needs keys: 3")
	g.ks = 3
	command(&g, .Right)
	testing.expect_value(t, g.ks, 2)
	testing.expect_value(t, mget(&g, 22, 11), u8(TILE_GATE2))
	testing.expect_value(t, string(g.floats[1].text[:g.floats[1].n]), "Lock opened")
	command(&g, .Right)
	testing.expect_value(t, mget(&g, 22, 11), u8(TILE_GATE1))
	command(&g, .Right)
	testing.expect_value(t, g.ks, 0)
	testing.expect_value(t, mget(&g, 22, 11), u8(0))
	testing.expect_value(t, string(g.floats[3].text[:g.floats[3].n]), "Door unlocked")
	command(&g, .Right)
	testing.expect_value(t, g.x, 22)
}

// --- Every generated level can be finished -------------------------------------------------

Cell :: [2]int

// Cells reachable from the player's start. Locks are passable when open_locks is set;
// monsters never are (nothing may depend on killing one).
reachable :: proc(lv: Level, open_locks: bool) -> [dynamic]bool {
	seen := make([dynamic]bool, lv.w * lv.h)
	queue := make([dynamic]Cell)
	defer delete(queue)
	append(&queue, Cell{lv.start_x, lv.start_y})
	seen[lv.start_y * lv.w + lv.start_x] = true
	for i := 0; i < len(queue); i += 1 {
		for d in ([4]Cell{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) {
			n := queue[i] + d
			if n.x < 0 || n.y < 0 || n.x >= lv.w || n.y >= lv.h || seen[n.y * lv.w + n.x] {
				continue
			}
			c := lv.tiles[n.y * lv.w + n.x]
			if c == TILE_MONSTER || (is_solid(c) && !(open_locks && locks_of(c) > 0)) {
				continue
			}
			seen[n.y * lv.w + n.x] = true
			append(&queue, n)
		}
	}
	return seen
}

@(test)
generated_levels_can_be_finished :: proc(t: ^testing.T) {
	for lv, n in LEVELS[:CART_LEVEL] {
		testing.expect_value(t, len(lv.tiles), lv.w * lv.h)
		locks, keys, exits := 0, 0, 0
		for c in lv.tiles {
			locks += locks_of(c)
			keys += int(c == TILE_KEY)
			exits += int(c == TILE_EXIT)
		}
		testing.expectf(t, exits == 1, "level %d has %d exits", n, exits)
		testing.expectf(t, locks > 0 && keys == locks, "level %d: %d keys for %d locks", n, keys, locks)

		// Before any lock opens: every key can be fetched, and the exit cannot.
		closed := reachable(lv, false)
		defer delete(closed)
		open := reachable(lv, true)
		defer delete(open)
		for c, i in lv.tiles {
			if c == TILE_KEY {
				testing.expectf(t, closed[i], "level %d: key at %d is behind a lock", n, i)
			}
			if c == TILE_EXIT {
				testing.expectf(t, !closed[i], "level %d: exit needs no key", n)
				testing.expectf(t, open[i], "level %d: exit unreachable", n)
			}
			if c == TILE_POTION || c == TILE_JOOL || c == TILE_SWORD || c == TILE_SHIELD {
				testing.expectf(t, open[i], "level %d: item %d unreachable", n, i)
			}
		}
	}
}

// Plays level 1 from the start to the exit by the shortest safe route, as a player would.
@(test)
tutorial_is_playable :: proc(t: ^testing.T) {
	g: Game
	init_game(&g)
	command(&g, .Start)
	lv := LEVELS[0]
	// Breadth-first search with the rules themselves: steps that are blocked do nothing.
	Node :: struct {
		pos:  Cell,
		prev: int,
		dir:  Command,
	}
	nodes := make([dynamic]Node)
	defer delete(nodes)
	seen := make([]bool, lv.w * lv.h)
	defer delete(seen)
	append(&nodes, Node{{lv.start_x, lv.start_y}, -1, .Up})
	seen[lv.start_y * lv.w + lv.start_x] = true
	have_key := false
	key_at := -1
	for c, i in lv.tiles {
		if c == TILE_KEY {
			key_at = i
		}
	}
	// Route 1: start to the key, with every lock closed. Route 2: key to the exit through the gate.
	route :: proc(lv: Level, from: Cell, to: Cell, open_locks: bool) -> [dynamic]Command {
		out := make([dynamic]Command)
		nodes := make([dynamic]Node)
		defer delete(nodes)
		seen := make([]bool, lv.w * lv.h)
		defer delete(seen)
		append(&nodes, Node{from, -1, .Up})
		seen[from.y * lv.w + from.x] = true
		for i := 0; i < len(nodes); i += 1 {
			if nodes[i].pos == to {
				path := make([dynamic]Command)
				defer delete(path)
				for j := i; nodes[j].prev >= 0; j = nodes[j].prev {
					append(&path, nodes[j].dir)
				}
				for k := len(path) - 1; k >= 0; k -= 1 {
					append(&out, path[k])
				}
				return out
			}
			steps := [4]struct {
				d:   Cell,
				cmd: Command,
			}{{{1, 0}, .Right}, {{-1, 0}, .Left}, {{0, 1}, .Down}, {{0, -1}, .Up}}
			for s in steps {
				n := nodes[i].pos + s.d
				if n.x < 0 || n.y < 0 || n.x >= lv.w || n.y >= lv.h || seen[n.y * lv.w + n.x] {
					continue
				}
				c := lv.tiles[n.y * lv.w + n.x]
				if c == TILE_MONSTER || c == TILE_TRAP || (is_solid(c) && !(open_locks && locks_of(c) > 0)) {
					continue
				}
				seen[n.y * lv.w + n.x] = true
				append(&nodes, Node{n, i, s.cmd})
			}
		}
		return out
	}
	_ = have_key
	to_key := route(lv, {lv.start_x, lv.start_y}, {key_at % lv.w, key_at / lv.w}, false)
	defer delete(to_key)
	testing.expect(t, len(to_key) > 0)
	for cmd in to_key {
		command(&g, cmd)
	}
	testing.expect_value(t, g.ks, 1)
	exit_at := -1
	for c, i in lv.tiles {
		if c == TILE_EXIT {
			exit_at = i
		}
	}
	to_exit := route(lv, {g.x, g.y}, {exit_at % lv.w, exit_at / lv.w}, true)
	defer delete(to_exit)
	testing.expect(t, len(to_exit) > 0)
	for cmd in to_exit {
		x, y := g.x, g.y
		command(&g, cmd)
		if g.x == x && g.y == y { // a lock: the first press opens it, the second walks through
			command(&g, cmd)
		}
	}
	testing.expect_value(t, g.level, 1)
	testing.expect_value(t, g.h, 3)
	testing.expect_value(t, g.ks, 0)
}
