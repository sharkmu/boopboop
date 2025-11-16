# Base concept tasks
- [x] You have to push out the enemies from the screen with the player character
- [x] Have cool physics
- [x] Everytime an enemy gets pushed out the player gets money based on the size of the enemy
- [x] The bigger the enemy is, the harder it is to push out
- [x] The bigger the enemy is, the more money the player gets

# Tasks
- [x] Implement a level system
    - [x] Change the background colour/image based on the level
    - [x] Display level number in the UI (`DrawText`)
- [x] Add ability to restart the level
- [ ] Add shop where the player can spend his/her money
- [ ] Add a timer
    - [ ] If the time runs out the player fails the level, have the ability to restart it
    - [ ] After every enemy pushed out the player gets time based on the size of the enemy
    - [ ] The bigger the enemy is, the more time the player gets after pushing it out
- [ ] Implement a player resizing system
    - [ ] After every completed level the player's size increases a bit
    - [ ] If the player pushes out an enemy that is bigger than the player, then the player's size and money instantly decreases a bit

# Fix tasks
- [ ] Better centering for texts. Use `rl.MeasureText()` to get better width values
