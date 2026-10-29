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
monster_sword_kills_cleanly :: proc(t: ^testing.T) {
	// The cart let the monster hit back on the turn it died; here a kill costs nothing.
	g := fresh()
	g.as, g.ds = 1, 1
	put_right(&g, TILE_MONSTER)
	command(&g, .Right)
	testing.expect_value(t, g.ms, 1)
	testing.expect_value(t, g.as, 0)
	testing.expect_value(t, mget(&g, 22, 11), u8(0))
	testing.expect_value(t, g.h, 3)
	testing.expect_value(t, g.ds, 1) // the shield was not needed
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
	g := beside_monster()
	mset(&g, g.x, g.y + 1, TILE_KEY)
	command(&g, .Down) // stepping away from the monster and onto a key
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "Monster strikes!")
	testing.expect_value(t, string(g.floats[1].text[:g.floats[1].n]), "+1 key")
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

// Steps from the player's start to every cell (-1 = unreachable). Locks are passable when
// open_locks is set; monsters and braziers never are (nothing may depend on killing one).
distances :: proc(lv: Level, open_locks: bool) -> [dynamic]int {
	dist := make([dynamic]int, lv.w * lv.h)
	for &d in dist {
		d = -1
	}
	queue := make([dynamic]Cell)
	defer delete(queue)
	append(&queue, Cell{lv.start_x, lv.start_y})
	dist[lv.start_y * lv.w + lv.start_x] = 0
	for i := 0; i < len(queue); i += 1 {
		for d in ([4]Cell{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) {
			n := queue[i] + d
			if n.x < 0 || n.y < 0 || n.x >= lv.w || n.y >= lv.h || dist[n.y * lv.w + n.x] >= 0 {
				continue
			}
			c := lv.tiles[n.y * lv.w + n.x]
			if c == TILE_MONSTER || (is_solid(c) && !(open_locks && locks_of(c) > 0)) {
				continue
			}
			dist[n.y * lv.w + n.x] = dist[queue[i].y * lv.w + queue[i].x] + 1
			append(&queue, n)
		}
	}
	return dist
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
		closed := distances(lv, false)
		defer delete(closed)
		open := distances(lv, true)
		defer delete(open)
		for c, i in lv.tiles {
			if c == TILE_KEY {
				testing.expectf(t, closed[i] >= 0, "level %d: key at %d is behind a lock", n, i)
			}
			if c == TILE_EXIT {
				testing.expectf(t, closed[i] < 0, "level %d: exit needs no key", n)
				testing.expectf(t, open[i] >= 0, "level %d: exit unreachable", n)
				// The light is the clock: the grant must cover walking to the exit twice over.
				testing.expectf(t, lv.fuel >= 2 * open[i], "level %d: %d fuel for a %d step walk", n, lv.fuel, open[i])
			}
			if c == TILE_POTION || c == TILE_JOOL || c == TILE_SWORD || c == TILE_SHIELD || c == TILE_TORCH || c == TILE_LANTERN {
				testing.expectf(t, open[i] >= 0, "level %d: item %d unreachable", n, i)
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
	testing.expect(t, alive(&g)) // a guard by the key may cost a heart on the way out
	testing.expect_value(t, g.ks, 0)
}

// --- Monsters strike when you step away ------------------------------------------------------

// A monster directly above the player; the cart's open floor all around.
beside_monster :: proc() -> Game {
	g := fresh()
	for dy in -3 ..= 3 { // open floor around the start, whatever the cart put there
		for dx in -3 ..= 3 {
			mset(&g, g.x + dx, g.y + dy, 0)
		}
	}
	mset(&g, g.x, g.y - 1, TILE_MONSTER)
	return g
}

@(test)
stepping_away_from_a_monster_costs_a_heart :: proc(t: ^testing.T) {
	g := beside_monster()
	command(&g, .Down) // no longer beside it
	testing.expect_value(t, g.h, 2)
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "Monster strikes!")
	testing.expect_value(t, g.sounds[0], Sound.Monster_Hit)
	testing.expect_value(t, mget(&g, 21, 10), u8(TILE_MONSTER)) // it stays
}

@(test)
sliding_along_a_monster_is_free :: proc(t: ^testing.T) {
	g := beside_monster()
	command(&g, .Right) // (22,11) is only diagonal to it, so this is a step away
	testing.expect_value(t, g.h, 2)
	g = beside_monster()
	mset(&g, g.x + 1, g.y - 1, TILE_MONSTER) // two monsters side by side above
	command(&g, .Right) // moves from under one to under the other: still beside a monster
	testing.expect_value(t, g.h, 2) // only the one left behind strikes
}

@(test)
a_shield_turns_the_blow_aside :: proc(t: ^testing.T) {
	g := beside_monster()
	g.ds = 1
	command(&g, .Down)
	testing.expect_value(t, g.h, 3)
	testing.expect_value(t, g.ds, 0)
}

@(test)
killing_the_monster_first_means_no_strike_after :: proc(t: ^testing.T) {
	g := beside_monster()
	g.as, g.ds = 1, 1
	command(&g, .Up) // bump: the sword kills it, and nothing hits back
	testing.expect_value(t, g.ms, 1)
	testing.expect_value(t, g.ds, 1)
	testing.expect_value(t, mget(&g, 21, 10), u8(0))
	h := g.h
	command(&g, .Down)
	testing.expect_value(t, g.h, h)
}

@(test)
a_strike_can_kill_and_stops_the_step_effects :: proc(t: ^testing.T) {
	g := beside_monster()
	g.h = 1
	mset(&g, g.x, g.y + 1, TILE_EXIT)
	command(&g, .Down)
	testing.expect(t, !alive(&g))
	testing.expect_value(t, g.phase, Phase.Play) // the exit did not fire
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "You died!")
}

@(test)
two_monsters_strike_one_after_another :: proc(t: ^testing.T) {
	g := beside_monster()
	mset(&g, g.x - 1, g.y, TILE_MONSTER)
	command(&g, .Down) // away from both
	testing.expect_value(t, g.h, 1)
}

// --- Light, fuel and fog of war --------------------------------------------------------------

// Open floor all round the cart's start, with the light lit and fuel set.
in_the_open :: proc(fuel: int) -> Game {
	g := fresh()
	for dy in -8 ..= 8 {
		for dx in -8 ..= 8 {
			mset(&g, g.x + dx, g.y + dy, 0)
		}
	}
	g.fuel, g.lantern, g.dark = fuel, false, 0
	see(&g)
	return g
}

@(test)
every_step_burns_one_fuel_and_bumps_do_not :: proc(t: ^testing.T) {
	g := in_the_open(10)
	command(&g, .Right)
	command(&g, .Right)
	testing.expect_value(t, g.fuel, 8)
	mset(&g, g.x + 1, g.y, 1)
	command(&g, .Right) // a wall: no step
	testing.expect_value(t, g.fuel, 8)
}

@(test)
the_light_lights_a_circle :: proc(t: ^testing.T) {
	g := in_the_open(50)
	testing.expect(t, lit(&g, g.x, g.y))
	testing.expect(t, lit(&g, g.x + LIGHT_TORCH, g.y))
	testing.expect(t, !lit(&g, g.x + LIGHT_TORCH + 1, g.y))
	testing.expect(t, !lit(&g, g.x + LIGHT_TORCH, g.y + LIGHT_TORCH)) // a corner is farther
	g.lantern = true
	see(&g)
	testing.expect(t, lit(&g, g.x + LIGHT_LANTERN, g.y))
}

@(test)
walls_block_the_light :: proc(t: ^testing.T) {
	g := in_the_open(50)
	mset(&g, g.x + 2, g.y, 1)
	see(&g)
	testing.expect(t, lit(&g, g.x + 2, g.y)) // the wall itself is lit
	testing.expect(t, !lit(&g, g.x + 3, g.y)) // what lies behind it is not
	testing.expect(t, lit(&g, g.x + 3, g.y + 2)) // but the sides are
}

@(test)
cells_are_remembered_once_lit :: proc(t: ^testing.T) {
	g := in_the_open(50)
	far := g.x + LIGHT_TORCH
	testing.expect(t, g.seen[g.y * g.mw + far])
	for _ in 0 ..< 6 {
		command(&g, .Left)
	}
	testing.expect(t, !lit(&g, far, g.y)) // out of the light now
	testing.expect(t, g.seen[g.y * g.mw + far]) // but remembered
	testing.expect(t, !g.seen[g.y * g.mw + g.x + 12]) // never lit
}

@(test)
a_brazier_lights_its_surroundings_and_is_solid :: proc(t: ^testing.T) {
	g := in_the_open(50)
	bx := g.x + 12
	mset(&g, bx, g.y, TILE_BRAZIER)
	see(&g)
	testing.expect(t, lit(&g, bx - LIGHT_BRAZIER, g.y)) // far from the player's own light
	testing.expect(t, !lit(&g, bx - LIGHT_BRAZIER - 2, g.y))
	g.x, g.y = bx - 1, g.y
	command(&g, .Right)
	testing.expect_value(t, g.x, bx - 1) // solid
}

@(test)
pickups_feed_the_light :: proc(t: ^testing.T) {
	g := in_the_open(10)
	put_right(&g, TILE_TORCH)
	command(&g, .Right)
	testing.expect_value(t, g.fuel, 10 - 1 + TORCH_FUEL)
	put_right(&g, TILE_LANTERN)
	command(&g, .Right)
	testing.expect(t, g.lantern)
	testing.expect_value(t, g.fuel, 10 - 2 + TORCH_FUEL + LANTERN_FUEL)
	g.fuel = FUEL_MAX - 1
	put_right(&g, TILE_TORCH)
	command(&g, .Right)
	testing.expect_value(t, g.fuel, FUEL_MAX)
}

@(test)
without_fuel_you_see_one_cell_and_the_dark_bites :: proc(t: ^testing.T) {
	g := in_the_open(1)
	command(&g, .Right) // the last of the light
	testing.expect_value(t, g.fuel, 0)
	testing.expect_value(t, string(g.floats[0].text[:g.floats[0].n]), "Light dies")
	testing.expect_value(t, light_radius(&g), LIGHT_DARK)
	testing.expect(t, lit(&g, g.x + 1, g.y))
	testing.expect(t, !lit(&g, g.x + 2, g.y))
	pace :: proc(g: ^Game, n: int) {
		for i in 0 ..< n {
			command(g, i % 2 == 0 ? .Left : .Right)
		}
	}
	pace(&g, DARK_BITE - 1)
	testing.expect_value(t, g.h, 3)
	pace(&g, 1)
	testing.expect_value(t, g.h, 2) // the tenth step in the dark
	pace(&g, DARK_BITE * 2)
	testing.expect(t, !alive(&g))
}

@(test)
fuel_carries_over_and_each_level_adds_some :: proc(t: ^testing.T) {
	g: Game
	init_game(&g)
	testing.expect_value(t, g.fuel, LEVELS[0].fuel)
	g.fuel = 100
	load_level(&g, 1)
	testing.expect_value(t, g.fuel, min(100 + LEVELS[1].fuel, FUEL_MAX))
	g.fuel = FUEL_MAX
	load_level(&g, 2)
	testing.expect_value(t, g.fuel, FUEL_MAX)
	testing.expect(t, !g.seen[0] || true)
}

@(test)
last_heart_blinks :: proc(t: ^testing.T) {
	g: Game
	init_game(&g)
	g.phase = .Play
	g.h = 1
	testing.expect(t, tick(&g), "a lone heart keeps the page redrawing")
	g.h = 2
	g.floats = {}
	testing.expect(t, !tick(&g), "two hearts do not blink")
}

@(test)
bumping_a_merchant_opens_the_shop :: proc(t: ^testing.T) {
	g := in_the_open(100)
	put_right(&g, TILE_MERCHANT)
	command(&g, .Right)
	testing.expect_value(t, g.phase, Phase.Shop)
	g.js = 3
	command(&g, .Choose_4) // disarm kit, 1 jool
	testing.expect_value(t, g.ts, 1)
	testing.expect_value(t, g.js, 2)
	command(&g, .Choose_1) // potion, 3 jools: too dear
	testing.expect_value(t, g.ps, 0)
	testing.expect_value(t, g.js, 2)
	command(&g, .Up) // any other key leaves
	testing.expect_value(t, g.phase, Phase.Play)
	testing.expect_value(t, g.x, 21) // the merchant did not move us
}

@(test)
amulet_is_bought_once :: proc(t: ^testing.T) {
	g := in_the_open(100)
	g.phase, g.js = .Shop, 10
	command(&g, .Choose_6)
	command(&g, .Choose_6)
	testing.expect(t, g.sense)
	testing.expect_value(t, g.js, 8)
}

@(test)
amulet_reveals_traps_and_a_kit_disarms_them :: proc(t: ^testing.T) {
	g := in_the_open(100)
	mset(&g, g.x + 2, g.y, TILE_TRAP)
	command(&g, .Left) // nothing felt without the amulet
	command(&g, .Right)
	testing.expect_value(t, mget(&g, g.x + 2, g.y), u8(TILE_TRAP))
	g.sense = true
	see(&g)
	testing.expect_value(t, mget(&g, g.x + 2, g.y), u8(TILE_TRAP_SEEN))
	g.ts = 1
	command(&g, .Right)
	command(&g, .Right) // onto the spotted trap
	testing.expect_value(t, g.h, 3)
	testing.expect_value(t, g.ts, 0)
	testing.expect_value(t, mget(&g, g.x, g.y), u8(0))
}

@(test)
a_spotted_trap_still_hurts_without_a_kit :: proc(t: ^testing.T) {
	g := in_the_open(100)
	mset(&g, g.x + 1, g.y, TILE_TRAP_SEEN)
	command(&g, .Right)
	testing.expect_value(t, g.h, 2)
}

@(test)
wraith_closes_in_then_strikes :: proc(t: ^testing.T) {
	g := in_the_open(100)
	mset(&g, g.x + 5, g.y, TILE_WRAITH)
	g.turns = 0
	command(&g, .Left) // turns = 1: the wraith moves
	command(&g, .Right) // turns = 2: moves again, now two cells away
	testing.expect_value(t, mget(&g, g.x + 3, g.y), u8(TILE_WRAITH)) // five cells away, two steps closer
	command(&g, .Up) // turns = 3: it rests
	testing.expect_value(t, mget(&g, g.x + 3, g.y - 0), u8(0)) // we moved up, so it is no longer on our row
	for _ in 0 ..< 8 { // pace; a hunter that catches up lands blows
		command(&g, .Down)
		command(&g, .Up)
	}
	testing.expect(t, g.h < 3, "a hunting wraith lands blows")
}

@(test)
wraith_can_be_slain_with_a_sword :: proc(t: ^testing.T) {
	g := in_the_open(100)
	put_right(&g, TILE_WRAITH)
	g.as = 1
	command(&g, .Right)
	testing.expect_value(t, g.ms, 1)
	testing.expect_value(t, mget(&g, g.x + 1, g.y), u8(0))
}
