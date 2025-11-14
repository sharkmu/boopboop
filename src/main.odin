package main

import rl "vendor:raylib"
import "core:math/rand"
import "base:runtime"
import "core:fmt" // for debugging

player_pos := rl.Vector2{400, 300}

Enemy :: struct {
    pos : rl.Vector2,
    size: rl.Vector2,
    colour: rl.Color,
}

enemies: [dynamic]Enemy

init :: proc() {
    rl.InitWindow(800, 600, "BoopBoop by: sharkmu")

    e: Enemy = Enemy{ 
        pos = rl.Vector2{ f32(rand.int31() % 700), f32(rand.int31() % 500)}, 
        size = rl.Vector2{32,32}, 
        colour = rl.RED 
    }
    append(&enemies, e)
}

main :: proc() {
    init()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        
        player_movement()
        rl.DrawRectangleV(player_pos, {64, 64}, rl.YELLOW)
        
        for enemy in enemies {
            rl.DrawRectangleV(enemy.pos, enemy.size, enemy.colour)
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

player_movement :: proc() {
    if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
        if(player_pos.x > 0) {
            player_pos.x -= 400 * rl.GetFrameTime()
        }
    }
    if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
        if player_pos.x < 736 {
            player_pos.x += 400 * rl.GetFrameTime()
        }
    }
    if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
        if player_pos.y > 0 {
            player_pos.y -= 400 * rl.GetFrameTime()
        }
    }
    if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
        if player_pos.y < 536 {
            player_pos.y += 400 * rl.GetFrameTime()
        }
    }
}