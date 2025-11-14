package main

import rl "vendor:raylib"
import "core:math/rand"
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

    generate_enemy(1)

    player = Character{
        pos = rl.Vector2{400, 300},
        size = rl.Vector2{48, 48},
        colour = rl.YELLOW,
        is_enemy = false,
    }
}

rand_num :: proc(min: f32, max: f32) -> f32 {
    r_initial := rand.float32()

	r_between_range := r_initial * (max - min) + min

    return r_between_range
}

main :: proc() {
    init()

    player_sprite := rl.LoadTexture("assets/player.png")
    

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        
        player_movement()
        rl.DrawTexture(player_sprite, i32(player.pos.x), i32(player.pos.y), player.colour)
        player_rec := rl.Rectangle {
            x = player.pos.x,
            y = player.pos.y,
            width = f32(player_sprite.width),
            height = f32(player_sprite.height),
        }
        
        for enemy in enemies {
            rl.DrawRectangleV(enemy.pos, enemy.size, enemy.colour)

            enemy_rec := rl.Rectangle {
                x = enemy.pos.x,
                y = enemy.pos.y,
                width = enemy.size.x,
                height = enemy.size.y,
            }

            is_colliding := rl.CheckCollisionRecs(player_rec, enemy_rec)
            fmt.println(is_colliding)
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

generate_enemy :: proc(amount: int) {
    for i := 0; i < amount; i+=1 {
        size_num := rand_num(12, 48)
        e: Character = Character{ 
            pos = rl.Vector2{ rand_num(10, 700), rand_num(10, 500)},
            size = rl.Vector2{ size_num, size_num },
            colour = rl.Color{ u8(rand_num(0, 255)), u8(rand_num(0, 255)), u8(rand_num(0, 255)), 255},
            is_enemy = true,
        }
        append(&enemies, e) 
    }
}
