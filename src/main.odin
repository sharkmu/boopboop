package main

import rl "vendor:raylib"
import "core:math/rand"
import "core:encoding/cbor"
import "core:os"
import "core:math"
import "core:fmt" // for debugging


Character :: struct {
    pos : rl.Vector2,
    size: rl.Vector2,
    colour: rl.Color,
    is_colliding: bool,
}

player := Character{}
player_direction := "LEFT" // LEFT, RIGHT, UP, DOWN
player_speed: f32

enemies: [dynamic]Character
too_many_enemies := false
any_collision := false

show_level_text := false
level_text_timer: f32 = 2.0
current_time: f64
extra_time: f64

// UI rectangles
restart_btn_rect := rl.Rectangle{}
shop_btn_rect := rl.Rectangle{}
shop_skins_btn_rect := rl.Rectangle{ x = 70, y = 120, width = 78, height = 30 } 
shop_enemy_shapes_btn_rect := rl.Rectangle{ x = 280, y = 120, width = 210, height = 30 }
shop_backgrounds_btn_rect := rl.Rectangle{ x = 570, y = 120, width = 198, height = 30 }
shop_exit_btn_rect := rl.Rectangle{}
btn_banana_rect := rl.Rectangle{}
use_buttons_rects := [dynamic]rl.Rectangle{}
lost_restart_btn_rect := rl.Rectangle{}

// Textures - sprites
// Player skins
player_banana_texture : rl.Texture2D
player_ding_texture : rl.Texture2D

// UI elements
restart_btn_texture : rl.Texture2D
shop_btn_texture : rl.Texture2D
buy_btn_green_texture : rl.Texture2D
buy_btn_red_texture : rl.Texture2D
owned_text_texture : rl.Texture2D
use_btn_texture : rl.Texture2D
using_btn_texture : rl.Texture2D

// Backgrounds
bg_linear_circles_texture : rl.Texture2D

// GAME_SCENE, SHOP_SCENE, SHOP_ENEMY_SHAPES_SCENE, SHOP_BACKGROUNDS_SCENE
current_scene := "GAME_SCENE"

// Owned items are a list, so that in the future if there are more of it, it will be is compatible
SaveData :: struct {
    money: i32,
    score: i32,
    level: i32,
    level_colour: rl.Color,
    owned_skins : [dynamic]string,
    using_skin : string,
    owned_enemy_shapes : [dynamic]string,
    using_enemy_shape : string,
    owned_backgrounds: [dynamic]string,
    using_background: string
}

game_data := SaveData{level=1, level_colour=rl.BLUE}

init :: proc() {
    rl.InitWindow(800, 600, "BoopBoop by: sharkmu")

    load_game_data()

    generate_enemy(1)

    player = Character{
        pos = rl.Vector2{400, 300},
        size = rl.Vector2{48, 48},
        colour = rl.YELLOW,
    }

    restart_btn_rect = rl.Rectangle{
        x = f32(rl.GetScreenWidth() - 32), y = 5, width = 32, height = 32
    }
    shop_btn_rect = rl.Rectangle{
        x = f32(rl.GetScreenWidth() - 70), y = 5, width = 32, height = 32
    }
    shop_exit_btn_rect = rl.Rectangle{
        x = f32(rl.GetScreenWidth() - 40), y = -12, width = 70, height = 70
    }
    btn_banana_rect = rl.Rectangle{
        x = f32(rl.GetScreenWidth()/2 - 140), y = 380, width = 64, height = 32
    }
    append(&use_buttons_rects, rl.Rectangle{
        x = f32(rl.GetScreenWidth()/2 - 140), y = 420, width = 64, height = 32
    })
    append(&use_buttons_rects, rl.Rectangle{
        x = f32(rl.GetScreenWidth()/2 + 170), y = 420, width = 64, height = 32
    })
    lost_restart_btn_rect = rl.Rectangle{
        x = f32(rl.GetScreenWidth()/2-70), y = f32(rl.GetScreenHeight()/2),
        width = 32*3.5, height = 32*3.5 // multipled by 3.5 to match scaling
    }

    // Load textures
    player_banana_texture = rl.LoadTexture("assets/player_banana.png")
    player_ding_texture = rl.LoadTexture("assets/player_ding.png")
    restart_btn_texture = rl.LoadTexture("assets/restart_button.png")
    shop_btn_texture = rl.LoadTexture("assets/shop_button.png")
    buy_btn_green_texture = rl.LoadTexture("assets/buy_button_green.png")
    buy_btn_red_texture = rl.LoadTexture("assets/buy_button_red.png")
    owned_text_texture = rl.LoadTexture("assets/owned_text.png")
    bg_linear_circles_texture = rl.LoadTexture("assets/bg_linear_circles.png")
    use_btn_texture = rl.LoadTexture("assets/use_button.png")
    using_btn_texture = rl.LoadTexture("assets/using_button.png")
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
    
    for !rl.WindowShouldClose() {
        switch current_scene {
            case "GAME_SCENE": game_scene()
            case "LOST_SCENE": lost_scene()
            case "SHOP_SCENE": shop_scene()
            case "SHOP_ENEMY_SHAPES_SCENE": shop_enemy_shapes_scene()
            case "SHOP_BACKGROUNDS_SCENE": shop_backgrounds_scene()
        }
    }
    rl.CloseWindow()
}

game_scene :: proc() {
    current_time = rl.GetTime() - extra_time
    rl.BeginDrawing()
    
    if game_data.using_background == "linear_circles" {
        rl.DrawTextureEx(bg_linear_circles_texture, {0,0}, 0, 1, rl.WHITE)
    } else {
        rl.ClearBackground(game_data.level_colour)
    }

    // Player
    player_movement()
    rl.DrawTexture(
        game_data.using_skin == "banana" ? player_banana_texture : player_ding_texture,
        i32(player.pos.x), i32(player.pos.y), player.colour
    )
    player_rec := rl.Rectangle {
        x = player.pos.x,
        y = player.pos.y,
        width = f32(player_ding_texture.width),
        height = f32(player_ding_texture.height),
    }
    
    // Enemy
    enemy_index := 0
    for enemy in enemies {
        enemy_outside := false

        if game_data.using_enemy_shape == "circle" {
            rl.DrawCircle(i32(enemy.pos.x), i32(enemy.pos.y), enemy.size.x/1.8, enemy.colour)

            enemy_radius := enemy.size.x / 1.8
            enemy_center := rl.Vector2{ 
                enemy.pos.x,
                enemy.pos.y,
            }
            rl.DrawCircleLines(
                i32(enemy_center.x),
                i32(enemy_center.y),
                enemy_radius,
                rl.BLACK,
            )

            if rl.CheckCollisionCircleRec(enemy_center, enemy_radius, player_rec) {
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

            if enemy.pos.x < (0 - enemy.size.x)/2 || enemy.pos.x > f32(rl.GetScreenWidth()) ||
               enemy.pos.y < (0 - enemy.size.y)/2 || enemy.pos.y > f32(rl.GetScreenHeight())
            {
                enemy_outside = true
            }
        } else {
            rl.DrawRectangleV(enemy.pos, enemy.size, enemy.colour)
            rl.DrawRectangleLines(
                i32(enemy.pos.x), i32(enemy.pos.y), 
                i32(enemy.size.x), i32(enemy.size.y), rl.BLACK
            )

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

            if enemy.pos.x < (0 - enemy.size.x) || enemy.pos.x > f32(rl.GetScreenWidth()) ||
               enemy.pos.y < (0 - enemy.size.y) || enemy.pos.y > f32(rl.GetScreenHeight()) 
            {
                enemy_outside = true
            }
        }
        if enemy_outside {                
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
        next_level()
    }

    // UI
    rl.DrawText(fmt.ctprint("Money:", game_data.money), 10, 10, 30, rl.BLACK)
    rl.DrawText(fmt.ctprint("Score:", game_data.score), 10, 50, 30, rl.BLACK)
    rl.DrawText(fmt.ctprint("Level:", game_data.level), 10, 90, 30, rl.BLACK)
    rl.DrawText(fmt.ctprint("Time:", math.floor(60-current_time)), 10, 130, 30, rl.BLACK)
    if show_level_text {
        frameTime := rl.GetFrameTime()
        rl.DrawText("New Level!", 250, 200, 60, rl.YELLOW)
        level_text_timer -= frameTime
        if level_text_timer <= 0 {
            show_level_text = false
        }
    }

    rl.DrawTexture(restart_btn_texture, i32(restart_btn_rect.x), i32(restart_btn_rect.y), rl.WHITE)
    rl.DrawTexture(shop_btn_texture, i32(shop_btn_rect.x), i32(shop_btn_rect.y), rl.WHITE)
    mouse_pos := rl.GetMousePosition()
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        if rl.CheckCollisionPointRec(mouse_pos, restart_btn_rect) {
            restart_level()
        }
        if rl.CheckCollisionPointRec(mouse_pos, shop_btn_rect) {
            rl.EndDrawing()
            current_scene = "SHOP_SCENE"
        }
    }

    if 60 - current_time <= 0 {
        rl.EndDrawing()
        current_scene = "LOST_SCENE"
    }

    rl.EndDrawing()
}

lost_scene :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.Color{35, 70, 18, u8(0.8)})

    rl.DrawText("You lost!", rl.GetScreenWidth()/2-220, rl.GetScreenHeight()/2-150, 100, rl.RED)
    rl.DrawTextureEx(
        restart_btn_texture, {f32(rl.GetScreenWidth()/2-70), f32(rl.GetScreenHeight()/2)}, 
        0, 3.5, rl.WHITE
    )
    mouse_pos := rl.GetMousePosition()
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        if rl.CheckCollisionPointRec(mouse_pos, lost_restart_btn_rect) {
            current_scene = "GAME_SCENE"
            restart_level()
        }
    }

    rl.EndDrawing()
}

shop_layout :: proc(active: string) {
    rl.DrawText("Shop", 270, 10, 100, rl.BLACK)
    rl.DrawText(
        "Skins", i32(shop_skins_btn_rect.x), 
        i32(shop_skins_btn_rect.y), i32(shop_skins_btn_rect.height), 
        active == "skins" ? rl.BLUE : rl.BLACK
    )
    rl.DrawText(
        "Enemy shapes", i32(shop_enemy_shapes_btn_rect.x), 
        i32(shop_enemy_shapes_btn_rect.y), i32(shop_enemy_shapes_btn_rect.height), 
        active == "enemy_shapes" ? rl.BLUE : rl.BLACK
    )
    rl.DrawText(
        "Backgrounds",  i32(shop_backgrounds_btn_rect.x), 
        i32(shop_backgrounds_btn_rect.y), i32(shop_backgrounds_btn_rect.height), 
        active == "backgrounds" ? rl.BLUE : rl.BLACK
    )
    rl.DrawText(
        "x", i32(shop_exit_btn_rect.x), i32(shop_exit_btn_rect.y), 
        i32(shop_exit_btn_rect.width), rl.BLACK
    )

    mouse_pos := rl.GetMousePosition()
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        if active == "skins" || active == "enemy_shapes" {
            if rl.CheckCollisionPointRec(mouse_pos, shop_backgrounds_btn_rect) {
                current_scene = "SHOP_BACKGROUNDS_SCENE"
            }
        }
        if active == "skins" || active == "backgrounds" {
            if rl.CheckCollisionPointRec(mouse_pos, shop_enemy_shapes_btn_rect) {
                current_scene = "SHOP_ENEMY_SHAPES_SCENE"
            }
        }
        if active == "enemy_shapes" || active == "backgrounds" {
            if rl.CheckCollisionPointRec(mouse_pos, shop_skins_btn_rect) {
                current_scene = "SHOP_SCENE"
            }
        }
        if rl.CheckCollisionPointRec(mouse_pos, shop_exit_btn_rect) {
            current_scene = "GAME_SCENE"
            extra_time = rl.GetTime() - current_time
        }
    }
}

shop_scene :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BEIGE)

    shop_layout("skins")

    banana_owned := false

    for skin in game_data.owned_skins {
        if skin == "banana" {
            banana_owned = true
        }
    }

    rl.DrawTextureEx(player_banana_texture, {f32(rl.GetScreenWidth())/2 - 150, 250}, 0, 1.5, rl.YELLOW)
    rl.DrawText("Banana", rl.GetScreenWidth()/2-160, 350, 30, rl.BLACK)
    rl.DrawTexture(
        banana_owned ? owned_text_texture : (game_data.money >= 100 ? buy_btn_green_texture : buy_btn_red_texture), 
        rl.GetScreenWidth()/2-140, 380, rl.WHITE
    )
    if banana_owned {
        rl.DrawTexture(
            game_data.using_skin == "banana" ? using_btn_texture : use_btn_texture, 
            i32(use_buttons_rects[0].x), i32(use_buttons_rects[0].y), rl.WHITE
        )
    } else {
        rl.DrawText("$100", rl.GetScreenWidth()/2 - 140, 420, 30, rl.DARKGREEN)
    }

    rl.DrawTextureEx(player_ding_texture, {f32(rl.GetScreenWidth())/2 + 150, 250}, 0, 1.5, rl.YELLOW)
    rl.DrawText("Ding", rl.GetScreenWidth()/2+170, 350, 30, rl.BLACK)
    rl.DrawTexture(owned_text_texture, rl.GetScreenWidth()/2+170, 380, rl.WHITE) // Default character
    rl.DrawTexture(
        game_data.using_skin == "banana" ? use_btn_texture : using_btn_texture, 
        i32(use_buttons_rects[1].x), i32(use_buttons_rects[1].y), rl.WHITE
    )

    mouse_pos := rl.GetMousePosition()
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        if rl.CheckCollisionPointRec(mouse_pos, btn_banana_rect) && !banana_owned && 
           game_data.money >= 100
        {
            game_data.money -= 100
            append(&game_data.owned_skins, "banana")
            save_game_data(game_data)
        }
        if rl.CheckCollisionPointRec(mouse_pos, use_buttons_rects[0]) && 
           game_data.using_skin != "banana" && banana_owned == true
        {
            game_data.using_skin = "banana"
            save_game_data(game_data)
        }
        if rl.CheckCollisionPointRec(mouse_pos, use_buttons_rects[1]) && 
           game_data.using_skin == "banana"
        {
            game_data.using_skin = "ding"
            save_game_data(game_data)
        }
    }

    rl.EndDrawing()
}

shop_enemy_shapes_scene :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BEIGE)

    shop_layout("enemy_shapes")

    circle_owned := false

    for shape in game_data.owned_enemy_shapes {
        if shape == "circle" {
            circle_owned = true
        }
    }

    rl.DrawCircle(rl.GetScreenWidth()/2 - 110, 300, 30, rl.BLUE)
    rl.DrawText("Circle", rl.GetScreenWidth()/2-155, 350, 30, rl.BLACK)
    rl.DrawTexture(
        circle_owned ? owned_text_texture : (game_data.money >= 50 ? buy_btn_green_texture : buy_btn_red_texture), 
        rl.GetScreenWidth()/2-140, 380, rl.WHITE
    )
    if circle_owned {
        rl.DrawTexture(
            game_data.using_enemy_shape == "circle" ? using_btn_texture : use_btn_texture, 
            i32(use_buttons_rects[0].x), i32(use_buttons_rects[0].y), rl.WHITE
        )
    } else {
        rl.DrawText("$50", rl.GetScreenWidth()/2 - 135, 420, 30, rl.DARKGREEN)
    }

    rl.DrawRectangleV({f32(rl.GetScreenWidth())/2 + 180, 280}, 50, rl.BLUE)
    rl.DrawText("Rectangle", rl.GetScreenWidth()/2+130, 350, 30, rl.BLACK)
    rl.DrawTexture(owned_text_texture, rl.GetScreenWidth()/2+170, 380, rl.WHITE) // Default shape
    rl.DrawTexture(
        game_data.using_enemy_shape == "circle" ? use_btn_texture : using_btn_texture, 
        i32(use_buttons_rects[1].x), i32(use_buttons_rects[1].y), rl.WHITE
    )

    mouse_pos := rl.GetMousePosition()
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        if rl.CheckCollisionPointRec(mouse_pos, btn_banana_rect) && !circle_owned &&
           game_data.money >= 50
        {
            game_data.money -= 100
            append(&game_data.owned_enemy_shapes, "circle")
            save_game_data(game_data)
        }
        if rl.CheckCollisionPointRec(mouse_pos, use_buttons_rects[0]) && 
           game_data.using_enemy_shape != "circle" && circle_owned == true
        {
            game_data.using_enemy_shape = "circle"
            save_game_data(game_data)
        }
        if rl.CheckCollisionPointRec(mouse_pos, use_buttons_rects[1]) && 
           game_data.using_enemy_shape == "circle"
        {
            game_data.using_enemy_shape = "rectangle"
            save_game_data(game_data)
        }
    }

    rl.EndDrawing()
}

shop_backgrounds_scene :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BEIGE)

    shop_layout("backgrounds")

    linear_circles_owned := false

    for bg in game_data.owned_backgrounds {
        if bg == "linear_circles" {
            linear_circles_owned = true
        }
    }

    rl.DrawTextureEx(bg_linear_circles_texture, {f32(rl.GetScreenWidth())/2 - 150, 270}, 0, 0.12, rl.WHITE)
    rl.DrawText("Linear Circles", rl.GetScreenWidth()/2-200, 350, 30, rl.BLACK)
    rl.DrawTexture(
        linear_circles_owned ? owned_text_texture : (game_data.money >= 150 ? buy_btn_green_texture : buy_btn_red_texture), 
        rl.GetScreenWidth()/2-140, 380, rl.WHITE
    )
    if linear_circles_owned {
        rl.DrawTexture(
            game_data.using_background == "linear_circles" ? using_btn_texture : use_btn_texture, 
            i32(use_buttons_rects[0].x), i32(use_buttons_rects[0].y), rl.WHITE
        )
    } else {
        rl.DrawText("$150", rl.GetScreenWidth()/2 - 140, 420, 30, rl.DARKGREEN)
    }

    rl.DrawRectangleV({f32(rl.GetScreenWidth())/2 + 155, 270}, {100, 70}, rl.BLUE)
    rl.DrawText("Solid Colour", rl.GetScreenWidth()/2+120, 350, 30, rl.BLACK)
    rl.DrawTexture(owned_text_texture, rl.GetScreenWidth()/2+170, 380, rl.WHITE) // Default bg
    rl.DrawTexture(
        game_data.using_background == "linear_circles" ? use_btn_texture : using_btn_texture, 
        i32(use_buttons_rects[1].x), i32(use_buttons_rects[1].y), rl.WHITE
    )

    mouse_pos := rl.GetMousePosition()
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        if rl.CheckCollisionPointRec(mouse_pos, btn_banana_rect) && !linear_circles_owned && 
           game_data.money >= 100
        {
            game_data.money -= 100
            append(&game_data.owned_backgrounds, "linear_circles")
            save_game_data(game_data)
        }
        if rl.CheckCollisionPointRec(mouse_pos, use_buttons_rects[0]) && 
           game_data.using_background != "linear_circles" && linear_circles_owned == true
        {
            game_data.using_background = "linear_circles"
            save_game_data(game_data)
        }
        if rl.CheckCollisionPointRec(mouse_pos, use_buttons_rects[1]) && 
           game_data.using_background == "linear_circles"
        {
            game_data.using_background = "solid_colour"
            save_game_data(game_data)
        }
    }

    rl.EndDrawing()
}

player_movement :: proc() {
    if (player.pos.x > 0) && !any_collision && player_direction == "LEFT" {
        player.pos.x -= player_speed * 100 * rl.GetFrameTime()
    }
    if player.pos.x < f32(rl.GetScreenWidth() - 64) && !any_collision && 
       player_direction == "RIGHT" 
    {
        player.pos.x += player_speed * 100 * rl.GetFrameTime()
    }
    if player.pos.y > 0 && !any_collision && player_direction == "UP" {
        player.pos.y -= player_speed * 100 * rl.GetFrameTime()
    }
    if player.pos.y < f32(rl.GetScreenHeight() - 64) && !any_collision && 
       player_direction == "DOWN" 
    {
        player.pos.y += player_speed * 100 * rl.GetFrameTime()
    }

    if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
        if player_speed < 3 {
            player_speed += 5 * rl.GetFrameTime()
        }
        if player_speed > 3 && player_speed <= 5.5 {
            player_speed += 10 * rl.GetFrameTime()
        }
        player_direction = "LEFT"
    }
    else if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
        if player_speed < 3 {
            player_speed += 5 * rl.GetFrameTime()
        }
        if player_speed > 3 && player_speed <= 5.5 {
            player_speed += 10 * rl.GetFrameTime()
        }
        player_direction = "RIGHT"
    }
    else if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
        if player_speed < 3 {
            player_speed += 5 * rl.GetFrameTime()
        }
        if player_speed > 3 && player_speed <= 5.5 {
            player_speed += 10 * rl.GetFrameTime()
        }
        player_direction = "UP"
    }
    else if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
        if player_speed < 3 {
            player_speed += 5 * rl.GetFrameTime()
        }
        if player_speed > 3 && player_speed <= 5.5 {
            player_speed += 10 * rl.GetFrameTime()
        }
        player_direction = "DOWN"
    }
    else {
        if player_speed > 0 {
            player_speed -= 35 * rl.GetFrameTime()
            if player_speed < 0 {
                player_speed = 0
            }
        }
    }
    if rl.IsKeyDown((.SPACE)) { next_level() }
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

next_level :: proc() {
    game_data.level += 1
    game_data.level_colour = rl.Color{u8(rand_num(80, 255)), u8(rand_num(80, 255)), u8(rand_num(80, 255)), u8(rand_num(50, 255))}
    save_game_data(game_data)

    too_many_enemies = false
    generate_enemy(1)

    show_level_text = true

    extra_time = rl.GetTime()
}

restart_level :: proc() {
    too_many_enemies = false
    delete(enemies)
    enemies = nil
    generate_enemy(1)

    extra_time = rl.GetTime()
}
