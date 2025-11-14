package main

import rl "vendor:raylib"
import "core:math/rand"
import "base:runtime"
import "core:fmt" // for debugging


Character :: struct {
    pos : rl.Vector2,
    size: rl.Vector2,
    colour: rl.Color,
    is_enemy: bool,
}

player := Character{}
enemies: [dynamic]Character

init :: proc() {
    rl.InitWindow(800, 600, "BoopBoop by: sharkmu")

    e: Character = Character{ 
        pos = rl.Vector2{ f32(rand.int31() % 700), f32(rand.int31() % 500)}, 
        size = rl.Vector2{32, 32}, 
        colour = rl.RED,
        is_enemy = true,
    }
    append(&enemies, e)

    player = Character{
        pos = rl.Vector2{400, 300},
        size = rl.Vector2{48, 48},
        colour = rl.YELLOW,
        is_enemy = false,
    }
}

main :: proc() {
    init()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        
        player_movement()
        rl.DrawRectangleV(player.pos, player.size, player.colour)
        
        for enemy in enemies {
            rl.DrawRectangleV(enemy.pos, enemy.size, enemy.colour)
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

player_movement :: proc() {
    if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
        if(player.pos.x > 0) {
            player.pos.x -= 400 * rl.GetFrameTime()
        }
    }
    if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
        if player.pos.x < f32(rl.GetScreenWidth() - 48) {
            player.pos.x += 400 * rl.GetFrameTime()
        }
    }
    if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
        if player.pos.y > 0 {
            player.pos.y -= 400 * rl.GetFrameTime()
        }
    }
    if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
        if player.pos.y < f32(rl.GetScreenHeight() - 48) {
            player.pos.y += 400 * rl.GetFrameTime()
        }
    }
}
