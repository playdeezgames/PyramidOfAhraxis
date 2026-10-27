#+build js
package main

// Thin browser layer: the page owns requestAnimationFrame, key repeat and audio, and calls
// these exports. Commands and sounds are small integers (game.Command / game.Sound).

import "base:runtime"
import "tggd:game"

state: struct {
	rules:  game.Game,
	screen: game.Frame,
	dirty:  bool,
	queue:  [8]game.Sound,
	nq:     int,
	qi:     int,
}

main :: proc() {
	game.init_game(&state.rules)
	state.dirty = true
}

// odin.js stops after main unless a step export exists; the page drives everything else.
@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	return true
}

@(export)
platform_command :: proc "c" (command: i32) {
	context = runtime.default_context()
	game.command(&state.rules, game.Command(command))
	state.nq = game.take_sounds(&state.rules, state.queue[:])
	state.qi = 0
	state.dirty = true
}

// Next sound of the last command as game.Sound + 1, or 0 when there are no more.
@(export)
platform_take_sound :: proc "c" () -> i32 {
	if state.qi >= state.nq {
		return 0
	}
	s := state.queue[state.qi]
	state.qi += 1
	return i32(s) + 1
}

// Returns 1 when the frame pointer holds new pixels.
@(export)
platform_frame :: proc "c" () -> i32 {
	context = runtime.default_context()
	if !state.dirty {
		return 0
	}
	state.dirty = false
	game.draw_game(&state.screen, &state.rules)
	game.resolve(&state.screen)
	return 1
}

@(export)
platform_frame_ptr :: proc "c" () -> rawptr {
	return &state.screen.rgba
}
