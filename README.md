# project-lazarus
Lazarus reimplemented in tasm

## Playing the game

### Ending the game

Press `ESC` to end the game.

## Project structure

### Graphics

All objects are are abstracted behind a drawable object that contains the
needed geometry with a pointer to the sprite data. Every time the sprite
updates, it needs to send its updated data make a call to be redrawn. In
reality it is not actually directly written to the graphics buffer, but to a
back buffer that will be copied to the graphics buffer when all drawing
operations are done (dubble buffering).

**TODO:** Replace the responsiblility of drawing the sprites to a global game
object.

### Physics

The game is tile based, but the falling of the boxes can happen outside the tiles, so there is a smoother animation while falling.

There are 3 buffers reserved for the physics objects.
* Moving objects: Objects that can be moved and need to be recalculated every frame
* Static objects: Only collision is needed with moving objects but will never move on there own
* Dynamic objects: Objects that do not move but can be interacted with. They behave mostly as static objects but can interact (need collision detection) with moving objects.

A pointer to all on screen entities participating in the physics cycle are in
their own array. Each array has a map that contains a binary value whether a
element is active.


### Crates

There is 1 buffer reserved for the crate objects which stores the structs representing the crates.

crates spawn at the top of the screen. They fall till they hit another object in the game and if the player gets hit/squished it's GAME OVER.