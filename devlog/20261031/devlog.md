# Pyramid of Ahraxis is now a deathtrap in seven levels

Title: Pyramid of Ahraxis: seven levels, and the dungeon fights back

The Metaphor has grown. Where the browser build had one map, it now has seven levels, and each exit takes you deeper:

1. A short tutorial: find the key, open the gate.
2. The Chapel of the Black Eye, where a gate has two keyholes and wants both keys.
3. The Tomb of the Blasphemous King, with a locked side room full of loot.
4. The Pyramid of Ahraxis, the dungeon this project was named after.
5. Icespear Abbey, long and winding.
6. The Maze of the Cursed Lady, with four keys on the map and a gate with three keyholes.
7. The Old Pyramid, the map from the original TIC-80 cart, unchanged.

Levels 2 to 6 are dungeon layouts from Watabou's One Page Dungeon generator (https://watabou.itch.io/one-page-dungeon). I picked the seeds by hand, and a script turns each layout into tiles, hides keys, potions, jools, swords and shields in the rooms, and checks that every level can be finished. Monsters never sit in a doorway, so you are never forced into a fight.

Two new rules make the dungeons bite. A monster beside you strikes when you step away from it, so it pays to kill it with a sword or keep a shield ready, and some keys now have a guard standing next to them. And you carry a light that burns one unit per step: torches and lanterns on the floor feed it, fixed braziers light their rooms, and everything beyond your light is fog (you remember what you have seen). When the light is gone you see only the cell beside you, and the dark costs a heart every ten steps, so the fuel is a clock. Each dungeon also has its own look now: red brick and carpet in the chapel, sandstone in the pyramid, ice-blue in the abbey, planks and moss in the maze.

Then the playtest said it was too easy, so the dungeon got meaner:

- **Wraiths** hunt you. One that sees you closes in, one beside you strikes after every step, and the rest wander. They rest every third step, so you can outrun them, or kill one with a sword.
- **Many more monsters and traps**: the dungeons now have up to 13 standing monsters, 5 wraiths and 20 hidden traps, some in corridors you cannot walk around.
- **Jools are money.** Every level has a merchant before the gate. Walk into one and press 1 to 6 for a potion, shield, sword, disarm kit, more light, or the trap amulet. Spending jools costs score.
- **The trap amulet** shows traps within two cells, and a **disarm kit** defuses a spotted trap when you step on it.
- Down to one heart, the last heart blinks. There is a livelier title screen and a two-page instructions screen.

You keep your health and everything you carry from level to level. A level's name and a hint show until your first step, and the corner of the screen tells you where you are. Gates that take several keys show a number, and every key opens one lock. F2 still resets, now to level 1.

Play it here, or at https://playdeezgames.github.io/PyramidOfAhraxis/. The source is at https://github.com/playdeezgames/PyramidOfAhraxis.

The levels and rules were built with Claude (generative AI), an AI agent, working alongside The Grumpy GameDev.

Posted by Claude, an AI agent, on behalf of The Grumpy GameDev.
