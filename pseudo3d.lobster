// pseudo3d.lobster - A pseudo-3D raycasting game MVP
// DDA Raycaster inspired by Wolfenstein 3D / Doom-era games
// Controls: WASD move, Mouse look, ESC to quit

// ===== WORLD MAP =====
// 0 = empty, 1-5 = wall types with different colors
let worldmap = [
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,2,2,2,0,0,0,0,3,0,3,0,0,1],
    [1,0,0,2,0,0,0,0,0,0,3,0,3,0,0,1],
    [1,0,0,2,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,4,4,4,4,0,0,0,0,1],
    [1,0,0,0,0,0,0,4,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,5,0,5,0,5,0,0,0,1],
    [1,0,0,0,0,0,0,5,0,0,0,5,0,0,0,1],
    [1,0,0,0,0,0,0,5,5,0,5,5,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
]

let map_w = 16
let map_h = 16

// ===== WALL COLOR FUNCTION =====
def wall_color(n:int) -> float4:
    return switch n:
        case 1: float4 { 0.8, 0.2, 0.2, 1.0 }   // Red
        case 2: float4 { 0.2, 0.8, 0.2, 1.0 }   // Green
        case 3: float4 { 0.2, 0.3, 0.8, 1.0 }   // Blue
        case 4: float4 { 0.8, 0.8, 0.2, 1.0 }   // Yellow
        case 5: float4 { 0.8, 0.2, 0.8, 1.0 }   // Magenta
        default: float4 { 0.5, 0.5, 0.5, 1.0 }  // Gray

// ===== PLAYER STATE =====
// Starting position: center of an empty cell (avoids boundary issues)
var pos = float2 { 8.0, 7.0 }
var dir = float2 { 1.0, 0.0 }
var plane = float2 { 0.0, 0.66 }  // FOV ~= 2 * atan(0.66) = 66 degrees

// ===== GAME SETTINGS =====
let render_width = 320      // Number of ray columns (lower = retro feel)
let move_speed = 4.0        // Units per second
let mouse_sens = 0.2        // Degrees per pixel of mouse movement

// ===== WINDOW SETUP =====
gl.window("Pseudo 3D Raycaster MVP", 960, 600)
gl.cursor(false)

// ===== MAIN GAME LOOP =====
while gl.frame() and gl.button("escape") != 1:
    let screen_w = float(gl.window_size().x)
    let screen_h = float(gl.window_size().y)
    let dt = gl.delta_time()

    // ---- INPUT ----
    // Mouse look (rotation)
    let mouse_rot = float(gl.mouse_delta(0).x) * mouse_sens
    if mouse_rot != 0.0:
        // 2D rotation: apply rotation matrix to dir and plane vectors
        let cos_r = cos(mouse_rot)
        let sin_r = sin(mouse_rot)
        let old_dir_x = dir.x
        dir.x = dir.x * cos_r - dir.y * sin_r
        dir.y = old_dir_x * sin_r + dir.y * cos_r
        let old_plane_x = plane.x
        plane.x = plane.x * cos_r - plane.y * sin_r
        plane.y = old_plane_x * sin_r + plane.y * cos_r

    // Forward / backward (W/S or Up/Down arrows)
    if gl.button("w") >= 1 or gl.button("up") >= 1:
        let new_x = pos.x + dir.x * dt * move_speed
        let new_y = pos.y + dir.y * dt * move_speed
        if worldmap[int(pos.y)][int(new_x)] == 0: pos.x = new_x
        if worldmap[int(new_y)][int(pos.x)] == 0: pos.y = new_y
    if gl.button("s") >= 1 or gl.button("down") >= 1:
        let new_x = pos.x - dir.x * dt * move_speed
        let new_y = pos.y - dir.y * dt * move_speed
        if worldmap[int(pos.y)][int(new_x)] == 0: pos.x = new_x
        if worldmap[int(new_y)][int(pos.x)] == 0: pos.y = new_y

    // Strafe left / right (A/D)
    if gl.button("a") >= 1:
        let new_x = pos.x - plane.x * dt * move_speed
        let new_y = pos.y - plane.y * dt * move_speed
        if worldmap[int(pos.y)][int(new_x)] == 0: pos.x = new_x
        if worldmap[int(new_y)][int(pos.x)] == 0: pos.y = new_y
    if gl.button("d") >= 1:
        let new_x = pos.x + plane.x * dt * move_speed
        let new_y = pos.y + plane.y * dt * move_speed
        if worldmap[int(pos.y)][int(new_x)] == 0: pos.x = new_x
        if worldmap[int(new_y)][int(pos.x)] == 0: pos.y = new_y

    // ---- RENDERING ----
    // Ceiling (sky color)
    gl.clear(float4 { 0.3, 0.3, 0.6, 1.0 })

    // Floor (simple solid color, drawn below the horizon)
    gl.push_model_view()
    gl.translate(float2 { 0.0, screen_h * 0.5 })
    gl.color(float4 { 0.15, 0.15, 0.15, 1.0 })
    gl.rect(float2 { screen_w, screen_h * 0.5 })
    gl.pop_model_view()

    // ---- RAYCASTING (DDA Algorithm) ----
    let strip_w = screen_w / render_width

    for(render_width) x:
        // Camera space X: -1 (left) to 1 (right)
        let camera_x = 2.0 * float(x) / render_width - 1.0
        let ray_x = dir.x + plane.x * camera_x
        let ray_y = dir.y + plane.y * camera_x

        // Current map cell
        var map_x = int(pos.x)
        var map_y = int(pos.y)

        // Distance ray travels between grid lines (avoid /0)
        var delta_x = 999999.0
        var delta_y = 999999.0
        if ray_x != 0.0: delta_x = abs(1.0 / ray_x)
        if ray_y != 0.0: delta_y = abs(1.0 / ray_y)

        // Step direction and initial side distance
        var step_x = 0
        var side_x = 0.0
        if ray_x < 0.0:
            step_x = -1
            side_x = (pos.x - float(map_x)) * delta_x
        else:
            step_x = 1
            side_x = (float(map_x) + 1.0 - pos.x) * delta_x

        var step_y = 0
        var side_y = 0.0
        if ray_y < 0.0:
            step_y = -1
            side_y = (pos.y - float(map_y)) * delta_y
        else:
            step_y = 1
            side_y = (float(map_y) + 1.0 - pos.y) * delta_y

        // DDA: step through grid until we hit a wall
        var hit = 0
        var side = 0  // 0 = x-side, 1 = y-side

        while hit == 0:
            if side_x < side_y:
                side_x += delta_x
                map_x += step_x
                side = 0
            else:
                side_y += delta_y
                map_y += step_y
                side = 1
            // Safety: bounds check (map is walled so this shouldn't fail)
            if map_x >= 0 and map_x < map_w and map_y >= 0 and map_y < map_h:
                hit = worldmap[map_y][map_x]
            else:
                hit = 1

        // Perpendicular distance (avoids fisheye)
        var perp = 1.0
        if side == 0:
            perp = (float(map_x) - pos.x + (1.0 - float(step_x)) * 0.5) / ray_x
        else:
            perp = (float(map_y) - pos.y + (1.0 - float(step_y)) * 0.5) / ray_y

        // Clamp to avoid extreme values
        if perp < 0.01: perp = 0.01

        // Wall height inversely proportional to distance
        let line_h = screen_h / perp
        let draw_start = (screen_h - line_h) * 0.5

        // Wall color with side shading
        var col = wall_color(hit)
        if side == 1: col = col * 0.6  // Y-side walls are darker

        // Distance fog
        let fog = max(1.0 - perp * 0.04, 0.25)
        col = float4 { col.x * fog, col.y * fog, col.z * fog, 1.0 }

        // Draw the wall strip
        gl.push_model_view()
        gl.translate(float2 { float(x) * strip_w, draw_start })
        gl.color(col)
        gl.rect(float2 { strip_w + 1.0, line_h })
        gl.pop_model_view()

    // ---- MINIMAP OVERLAY ----
    let mm_scale = 8.0
    let mm_x = 10.0
    let mm_y = screen_h - mm_scale * map_h - 10.0
    let mm_w = mm_scale * map_w
    let mm_h = mm_scale * map_h

    // Enter minimap coordinate space
    gl.push_model_view()
    gl.translate(float2 { mm_x, mm_y })

    // Background
    gl.color(float4 { 0.0, 0.0, 0.0, 0.6 })
    gl.rect(float2 { mm_w, mm_h })

    // Wall cells on minimap
    for(map_w) mx:
        for(map_h) my:
            if worldmap[my][mx] != 0:
                gl.push_model_view()
                gl.translate(float2 { float(mx) * mm_scale, float(my) * mm_scale })
                gl.color(float4 { 1.0, 1.0, 1.0, 0.6 })
                gl.rect(float2 { mm_scale, mm_scale })
                gl.pop_model_view()

    // Player dot on minimap
    gl.push_model_view()
    gl.translate(float2 { pos.x * mm_scale, pos.y * mm_scale })
    gl.color(float4 { 0.0, 1.0, 0.0, 1.0 })
    gl.circle(3.0, 8)
    gl.pop_model_view()

    // Player direction indicator on minimap
    gl.push_model_view()
    gl.translate(float2 { pos.x * mm_scale, pos.y * mm_scale })
    gl.color(float4 { 1.0, 1.0, 0.0, 0.8 })
    gl.line(float2 { 0.0, 0.0 }, float2 { dir.x * 12.0, dir.y * 12.0 }, 2.0)
    gl.pop_model_view()

    // Exit minimap coordinate space
    gl.pop_model_view()
