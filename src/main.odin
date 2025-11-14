package main

import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(800, 600, "BoopBoop by: sharkmu")
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
