package main

import rl "vendor:raylib"

player_pos := rl.Vector2{400, 300}

main :: proc() {
    rl.InitWindow(800, 600, "BoopBoop by: sharkmu")

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        
        player_movement()
        rl.DrawRectangleV(player_pos, {64, 64}, rl.YELLOW)
        
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
        if player_pos.x < 736{
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