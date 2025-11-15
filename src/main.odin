package main

import rl "vendor:raylib"
import "core:math/rand"
import "core:encoding/cbor"
import "core:os"
import "core:fmt" // for debugging


Character :: struct {
    pos : rl.Vector2,
    size: rl.Vector2,
    colour: rl.Color,
    is_colliding: bool,
}

player := Character{}
player_direction := "LEFT" // LEFT, RIGHT, UP, DOWN

enemies: [dynamic]Character
too_many_enemies := false
any_collision := false

SaveData :: struct {
    money: i32,
    score: i32,
}

game_data := SaveData{}

init :: proc() {
    rl.InitWindow(800, 600, "BoopBoop by: sharkmu")

    load_game_data()

    generate_enemy(1)

    player = Character{
        pos = rl.Vector2{400, 300},
        size = rl.Vector2{48, 48},
        colour = rl.YELLOW,
    }
}

rand_num :: proc(min: f32, max: f32) -> f32 {
    r_initial := rand.float32()

	r_between_range := r_initial * (max - min) + min

    return r_between_range
}

load_game_data :: proc() {
    bytes, ok := os.read_entire_file("save.cbor");
    if !ok {
        save_game_data(game_data)
    }

    err := cbor.unmarshal_from_bytes(bytes, &game_data);
    if err != nil {
        fmt.println("Failed to unmarshal CBOR:", err);
    }
}

save_game_data :: proc(data: SaveData) {
    bytes, err := cbor.marshal_into_bytes(data);
    if err != nil {
        fmt.eprintln("CBOR marshal failed:", err);
        return;
    }

    file, error := os.open("save.cbor", os.O_CREATE | os.O_WRONLY | os.O_TRUNC);
    if error != nil {
        fmt.eprintln("Failed to open save.cbor");
        return;
    }
    defer os.close(file);

    os.write(file, bytes);
}

main :: proc() {
    init()

    player_sprite := rl.LoadTexture("assets/player.png")
    

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)

        // UI
        rl.DrawText(fmt.ctprint("Money:", game_data.money), 10, 10, 30, rl.BLACK)
        rl.DrawText(fmt.ctprint("Score:", game_data.score), 10, 50, 30, rl.BLACK)
                
        // Player
        player_movement()
        rl.DrawTexture(player_sprite, i32(player.pos.x), i32(player.pos.y), player.colour)
        player_rec := rl.Rectangle {
            x = player.pos.x,
            y = player.pos.y,
            width = f32(player_sprite.width),
            height = f32(player_sprite.height),
        }
        
        // Enemy
        enemy_index := 0
        for enemy in enemies {
            rl.DrawRectangleV(enemy.pos, enemy.size, enemy.colour)

            enemy_rec := rl.Rectangle {
                x = enemy.pos.x,
                y = enemy.pos.y,
                width = enemy.size.x,
                height = enemy.size.y,
            }

            if rl.CheckCollisionRecs(player_rec, enemy_rec) {
                boop_enemy(enemy_index)
                enemies[enemy_index].is_colliding = true
            } else {
                if enemies[enemy_index].is_colliding {
                    enemies[enemy_index].is_colliding = false
                    any_collision = false
                }
            }

            if enemies[enemy_index].is_colliding {
                any_collision = true
            }
            
            // Check if enemy is outside of the screen
            if enemy.pos.x < (0 - enemy.size.x) || enemy.pos.x > f32(rl.GetScreenWidth()) ||
               enemy.pos.y < (0 - enemy.size.y) || enemy.pos.y > f32(rl.GetScreenHeight()) 
            {                
                game_data.money += i32(0.2 * enemy.size.x)
                game_data.score += 1

                ordered_remove(&enemies, enemy_index)
                any_collision = false

                if !too_many_enemies {
                    r_enemy_amount := rand_num(1, 10)
                    generate_enemy(int(r_enemy_amount))
                }
                
                save_game_data(game_data)
            }

            enemy_index += 1
        }

        if len(enemies) > 12 {
            too_many_enemies = true
        }
        if too_many_enemies && len(enemies) < 1 {
            too_many_enemies = false
            generate_enemy(1)
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

player_movement :: proc() {
    if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
        if(player.pos.x > 0) && !any_collision {
            player.pos.x -= 400 * rl.GetFrameTime()
            player_direction = "LEFT"
        }
    }
    if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
        if player.pos.x < f32(rl.GetScreenWidth() - 64) && !any_collision {
            player.pos.x += 400 * rl.GetFrameTime()
            player_direction = "RIGHT"
        }
    }
    if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
        if player.pos.y > 0 && !any_collision {
            player.pos.y -= 400 * rl.GetFrameTime()
            player_direction = "UP"
        }
    }
    if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
        if player.pos.y < f32(rl.GetScreenHeight() - 64) && !any_collision {
            player.pos.y += 400 * rl.GetFrameTime()
            player_direction = "DOWN"
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
            is_colliding = false,
        }
        append(&enemies, e) 
    }
}

boop_enemy :: proc(index: int) {
    switch player_direction {
        case "LEFT":
            enemies[index].pos.x -= (5000 * rl.GetFrameTime())/enemies[index].size.x
            enemies[index].pos.y += (300 * rl.GetFrameTime())/enemies[index].size.y
        case "RIGHT":
            enemies[index].pos.x += (5000 * rl.GetFrameTime())/enemies[index].size.x
            enemies[index].pos.y -= (300 * rl.GetFrameTime())/enemies[index].size.y
        case "UP":
            enemies[index].pos.x += (300 * rl.GetFrameTime())/enemies[index].size.x
            enemies[index].pos.y -= (5000 * rl.GetFrameTime())/enemies[index].size.y
        case "DOWN":
            enemies[index].pos.x -= (300 * rl.GetFrameTime())/enemies[index].size.x
            enemies[index].pos.y += (5000 * rl.GetFrameTime())/enemies[index].size.y
    }
}
