#+build !js
package game

import "core:testing"

fresh :: proc() -> Game {
	g: Game
	init_game(&g)
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
	testing.expect_value(t, g.x, 21)
	testing.expect_value(t, g.y, 11)
	testing.expect_value(t, g.h, 3)
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
	testing.expect_value(t, g.x, 21)
	testing.expect_value(t, mget(&g, 22, 11), MAP_INITIAL[11 * MAP_W + 22])
}

@(test)
map_edge_reads_empty :: proc(t: ^testing.T) {
	g := fresh()
	g.x, g.y = 0, 0
	command(&g, .Left)
	testing.expect_value(t, g.x, -1) // off-map reads 0 so the cart walks off too
}
