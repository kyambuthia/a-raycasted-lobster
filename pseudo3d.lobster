// pseudo3d.lobster - inside-sphere traversal prototype
// A software-projected 3D view of a player walking on the inner surface of a sphere.

// World scale: one Lobster unit is treated as one meter.
let meters_per_unit = 1.0
let sphere_r = 180.0
let player_height_m = 1.8
let player_radius_m = 0.35
let player_eye_m = 1.58
let camera_back_m = 7.0
let camera_up_m = 2.4
let walk_speed_mps = 5.2
let road_width_m = 8.0

let map_w = 16
let map_h = 16

def city_parcel(mx:int, my:int) -> int:
    if my == 3 and mx >= 3 and mx <= 5: return 2
    if my >= 4 and my <= 5 and mx == 3: return 2
    if my >= 3 and my <= 4 and (mx == 10 or mx == 12): return 3
    if my == 7 and mx >= 7 and mx <= 10: return 4
    if my == 8 and mx == 7: return 4
    if my >= 10 and my <= 12 and (mx == 7 or mx == 11): return 5
    if my == 12 and (mx == 8 or mx == 10): return 5
    return 0

def wall_color(n:int) -> float4:
    return switch n:
        case 2: float4 { 0.2, 0.8, 0.35, 1.0 }
        case 3: float4 { 0.25, 0.35, 0.9, 1.0 }
        case 4: float4 { 0.95, 0.85, 0.2, 1.0 }
        case 5: float4 { 0.9, 0.25, 0.8, 1.0 }
        default: float4 { 0.8, 0.18, 0.18, 1.0 }

def building_height(n:int) -> float:
    return switch n:
        case 2: 12.0
        case 3: 28.0
        case 4: 46.0
        case 5: 18.0
        default: 16.0

def tower_radius(n:int) -> float:
    return switch n:
        case 3: 0.32
        case 4: 0.42
        case 5: 0.28
        default: 0.34

def wrap_degrees(a:float) -> float:
    var r = a
    while r < 0.0: r += 360.0
    while r >= 360.0: r -= 360.0
    return r

def sphere_point(lon:float, lat:float, radius:float) -> float3:
    let clat = cos(lat)
    return float3 { radius * clat * cos(lon), radius * sin(lat), radius * clat * sin(lon) }

def equal_area_lat(my:float) -> float:
    let v = clamp(1.0 - 2.0 * my / float(map_h), -0.99, 0.99)
    return asin(v)

def sphere_cell_point(mx:float, my:float, radius:float) -> float3:
    let lon = mx / float(map_w) * 360.0
    let lat = equal_area_lat(my)
    return sphere_point(lon, lat, radius)

def tangent_inward_up(lon:float, lat:float) -> float3:
    let outward = normalize(sphere_point(lon, lat, 1.0))
    return float3 { -outward.x, -outward.y, -outward.z }

def tangent_east(lon:float) -> float3:
    return normalize(float3 { -sin(lon), 0.0, cos(lon) })

def tangent_north(lon:float, lat:float) -> float3:
    return normalize(float3 { -sin(lat) * cos(lon), cos(lat), -sin(lat) * sin(lon) })

def tangent_forward(lon:float, lat:float, yaw:float) -> float3:
    return normalize(tangent_north(lon, lat) * cos(yaw) + tangent_east(lon) * sin(yaw))

def map_x_from_lon(lon:float) -> int:
    return int(wrap_degrees(lon) / 360.0 * float(map_w))

def map_y_from_lat(lat:float) -> int:
    return clamp(int((1.0 - sin(lat)) * float(map_h) * 0.5), 0, map_h - 1)

def sphere_cell_at(lon:float, lat:float) -> int:
    return city_parcel(map_x_from_lon(lon), map_y_from_lat(lat))

def can_stand_at(lon:float, lat:float) -> bool:
    if lat < -80.0 or lat > 80.0: return false
    return sphere_cell_at(lon, lat) == 0

def draw_line3(a:float3, b:float3, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float, col:float4, thickness:float):
    let ar = a - cam
    let br = b - cam
    let az = dot(ar, forward)
    let bz = dot(br, forward)
    if az > 0.05 and bz > 0.05:
        let ax = screen_w * 0.5 + dot(ar, right) / az * focal
        let ay = screen_h * 0.5 - dot(ar, up) / az * focal
        let bx = screen_w * 0.5 + dot(br, right) / bz * focal
        let by = screen_h * 0.5 - dot(br, up) / bz * focal
        gl.color(col)
        gl.line(float2 { ax, ay }, float2 { bx, by }, thickness)

def draw_screen_circle3(p:float3, world_radius:float, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float, col:float4, segments:int):
    let pr = p - cam
    let pz = dot(pr, forward)
    if pz > 0.05:
        let px = screen_w * 0.5 + dot(pr, right) / pz * focal
        let py = screen_h * 0.5 - dot(pr, up) / pz * focal
        let sr = max(world_radius / pz * focal, 2.0)
        gl.push_model_view()
        gl.translate(float2 { px, py })
        gl.color(col)
        gl.circle(sr, segments)
        gl.pop_model_view()

def screen_point(p:float3, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float) -> float3:
    let pr = p - cam
    let pz = dot(pr, forward)
    return float3 {
        screen_w * 0.5 + dot(pr, right) / pz * focal,
        screen_h * 0.5 - dot(pr, up) / pz * focal,
        pz
    }

def draw_screen_capsule(bottom:float2, top:float2, radius:float, col:float4):
    let axis = top - bottom
    let len = max(magnitude(axis), 0.01)
    let unit = axis / len
    let side = float2 { -unit.y, unit.x }
    let half = side * radius
    gl.color(col)
    gl.polygon([bottom + half, top + half, top - half, bottom - half])
    gl.push_model_view()
    gl.translate(bottom)
    gl.circle(radius, 24)
    gl.pop_model_view()
    gl.push_model_view()
    gl.translate(top)
    gl.circle(radius, 24)
    gl.pop_model_view()

def draw_quad3(a:float3, b:float3, c:float3, d:float3, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float, col:float4):
    let ar = a - cam
    let br = b - cam
    let cr = c - cam
    let dr = d - cam
    let az = dot(ar, forward)
    let bz = dot(br, forward)
    let cz = dot(cr, forward)
    let dz = dot(dr, forward)
    if az > 0.05 and bz > 0.05 and cz > 0.05 and dz > 0.05:
        let ax = screen_w * 0.5 + dot(ar, right) / az * focal
        let ay = screen_h * 0.5 - dot(ar, up) / az * focal
        let bx = screen_w * 0.5 + dot(br, right) / bz * focal
        let by = screen_h * 0.5 - dot(br, up) / bz * focal
        let cx = screen_w * 0.5 + dot(cr, right) / cz * focal
        let cy = screen_h * 0.5 - dot(cr, up) / cz * focal
        let dx = screen_w * 0.5 + dot(dr, right) / dz * focal
        let dy = screen_h * 0.5 - dot(dr, up) / dz * focal
        gl.color(col)
        gl.polygon([float2 { ax, ay }, float2 { bx, by }, float2 { cx, cy }, float2 { dx, dy }])

def draw_tri3(a:float3, b:float3, c:float3, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float, col:float4):
    let ar = a - cam
    let br = b - cam
    let cr = c - cam
    let az = dot(ar, forward)
    let bz = dot(br, forward)
    let cz = dot(cr, forward)
    if az > 0.05 and bz > 0.05 and cz > 0.05:
        let ax = screen_w * 0.5 + dot(ar, right) / az * focal
        let ay = screen_h * 0.5 - dot(ar, up) / az * focal
        let bx = screen_w * 0.5 + dot(br, right) / bz * focal
        let by = screen_h * 0.5 - dot(br, up) / bz * focal
        let cx = screen_w * 0.5 + dot(cr, right) / cz * focal
        let cy = screen_h * 0.5 - dot(cr, up) / cz * focal
        gl.color(col)
        gl.polygon([float2 { ax, ay }, float2 { bx, by }, float2 { cx, cy }])

def draw_building(mx:int, my:int, cell:int, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float):
    let cx = float(mx) + 0.5
    let cy = float(my) + 0.5
    let footprint = tower_radius(cell)
    let outer_r = sphere_r - 0.08
    let inner_r = sphere_r - building_height(cell)
    let roof_center = sphere_cell_point(cx, cy, inner_r)
    let base = wall_color(cell)
    for(16) seg:
        let a0 = float(seg) / 16.0 * 360.0
        let a1 = float(seg + 1) / 16.0 * 360.0
        let x0 = cx + cos(a0) * footprint
        let y0 = cy + sin(a0) * footprint
        let x1 = cx + cos(a1) * footprint
        let y1 = cy + sin(a1) * footprint
        let p0 = sphere_cell_point(x0, y0, outer_r)
        let p1 = sphere_cell_point(x1, y1, outer_r)
        let q0 = sphere_cell_point(x0, y0, inner_r)
        let q1 = sphere_cell_point(x1, y1, inner_r)
        let shade = 0.48 + abs(cos(a0)) * 0.28
        draw_quad3(p0, p1, q1, q0, cam, right, up, forward, screen_w, screen_h, focal, base * shade)
        draw_tri3(roof_center, q0, q1, cam, right, up, forward, screen_w, screen_h, focal, base * 0.95)
        draw_line3(q0, q1, cam, right, up, forward, screen_w, screen_h, focal, float4 { 1.0, 1.0, 1.0, 0.35 }, 1.0)
        for(4) floor:
            let t = float(floor + 1) / 5.0
            let r = outer_r + (inner_r - outer_r) * t
            let f0 = sphere_cell_point(x0, y0, r)
            let f1 = sphere_cell_point(x1, y1, r)
            draw_line3(f0, f1, cam, right, up, forward, screen_w, screen_h, focal, float4 { 0.85, 0.95, 1.0, 0.24 }, 1.0)

def draw_surface_parcel(mx:int, my:int, occupied:int, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float):
    let inset = 0.04
    let r = sphere_r - 0.16
    let a = sphere_cell_point(float(mx) + inset, float(my) + inset, r)
    let b = sphere_cell_point(float(mx + 1) - inset, float(my) + inset, r)
    let c = sphere_cell_point(float(mx + 1) - inset, float(my + 1) - inset, r)
    let d = sphere_cell_point(float(mx) + inset, float(my + 1) - inset, r)
    if occupied == 0:
        draw_quad3(a, b, c, d, cam, right, up, forward, screen_w, screen_h, focal, float4 { 0.075, 0.095, 0.105, 1.0 })
        let mid_ab = (a + b) * 0.5
        let mid_cd = (c + d) * 0.5
        let mid_bc = (b + c) * 0.5
        let mid_da = (d + a) * 0.5
        draw_line3(mid_ab, mid_cd, cam, right, up, forward, screen_w, screen_h, focal, float4 { 0.95, 0.88, 0.45, 0.22 }, 1.0)
        draw_line3(mid_bc, mid_da, cam, right, up, forward, screen_w, screen_h, focal, float4 { 0.95, 0.88, 0.45, 0.16 }, 1.0)

def draw_player_capsule(feet:float3, inward_up:float3, flat_forward:float3, cam:float3, right:float3, up:float3, forward:float3, screen_w:float, screen_h:float, focal:float):
    let bottom3 = feet + inward_up * player_radius_m
    let top3 = feet + inward_up * (player_height_m - player_radius_m)
    let mid3 = feet + inward_up * (player_height_m * 0.5)
    let b = screen_point(bottom3, cam, right, up, forward, screen_w, screen_h, focal)
    let t = screen_point(top3, cam, right, up, forward, screen_w, screen_h, focal)
    let m = screen_point(mid3, cam, right, up, forward, screen_w, screen_h, focal)
    if b.z > 0.05 and t.z > 0.05 and m.z > 0.05:
        let sr = max(player_radius_m / m.z * focal, 6.0)
        let bottom = float2 { b.x, b.y }
        let top = float2 { t.x, t.y }
        draw_screen_capsule(bottom, top, sr, float4 { 0.16, 0.72, 1.0, 0.96 })
        draw_screen_capsule(bottom + float2 { sr * 0.18, -sr * 0.08 }, top + float2 { sr * 0.18, -sr * 0.08 }, sr * 0.58, float4 { 0.55, 0.92, 1.0, 0.38 })
        draw_line3(mid3, mid3 + flat_forward * 1.2, cam, right, up, forward, screen_w, screen_h, focal, float4 { 1.0, 0.95, 0.25, 1.0 }, 3.0)
    draw_screen_circle3(feet, player_radius_m * 1.45, cam, right, up, forward, screen_w, screen_h, focal, float4 { 0.1, 0.95, 0.6, 0.28 }, 24)

var lon = 0.0
var lat = -8.0
var yaw = 92.0
var pitch = -8.0
var fov = 68.0

gl.window("A Raycasted Lobster - True Sphere Interior", 960, 600)
gl.set_font_name("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
gl.cursor(false)

while gl.frame() and gl.button("escape") != 1:
    let screen_w = float(gl.window_size().x)
    let screen_h = float(gl.window_size().y)
    let dt = gl.delta_time()
    let mouse = gl.mouse_delta(0)

    yaw = wrap_degrees(yaw + float(mouse.x) * 0.16)
    pitch = clamp(pitch - float(mouse.y) * 0.16, -78.0, 78.0)
    if gl.button("q") >= 1: fov = max(fov - dt * 36.0, 35.0)
    if gl.button("e") >= 1: fov = min(fov + dt * 36.0, 115.0)

    let angular_speed = degrees(walk_speed_mps / sphere_r) * dt
    var move_f = 0.0
    var move_r = 0.0
    if gl.button("w") >= 1 or gl.button("up") >= 1: move_f += angular_speed
    if gl.button("s") >= 1 or gl.button("down") >= 1: move_f -= angular_speed
    if gl.button("d") >= 1: move_r += angular_speed
    if gl.button("a") >= 1: move_r -= angular_speed

    let lat_scale = max(cos(lat), 0.18)
    let next_lat = clamp(lat + cos(yaw) * move_f + cos(yaw + 90.0) * move_r, -80.0, 80.0)
    let next_lon = wrap_degrees(lon + (sin(yaw) * move_f + sin(yaw + 90.0) * move_r) / lat_scale)
    if can_stand_at(next_lon, lat): lon = next_lon
    if can_stand_at(lon, next_lat): lat = next_lat

    let feet = sphere_point(lon, lat, sphere_r - 0.12)
    let up0 = tangent_inward_up(lon, lat)
    let flat_forward = tangent_forward(lon, lat, yaw)
    let cam = feet - flat_forward * camera_back_m + up0 * camera_up_m
    let right = normalize(cross(flat_forward, up0))
    let target = feet + up0 * player_eye_m + flat_forward * 8.0 + up0 * sin(pitch) * 3.0
    let forward = normalize(target - cam)
    let view_up = normalize(cross(right, forward))
    let focal = screen_h * 0.5 / tan(fov * 0.5)

    gl.clear(float4 { 0.025, 0.03, 0.045, 1.0 })

    // Interior sphere latitude rings.
    for(13) yi:
        let gy = float(yi + 1)
        var prev = sphere_cell_point(0.0, gy, sphere_r)
        for(64) xi:
            let p = sphere_cell_point(float(xi + 1) / 64.0 * float(map_w), gy, sphere_r)
            draw_line3(prev, p, cam, right, view_up, forward, screen_w, screen_h, focal, float4 { 0.18, 0.42, 0.52, 0.42 }, 1.0)
            prev = p

    // Interior sphere longitude arcs.
    for(16) xi:
        let gx = float(xi)
        var prev = sphere_cell_point(gx, 0.0, sphere_r)
        for(40) yi:
            let p = sphere_cell_point(gx, float(yi + 1) / 40.0 * float(map_h), sphere_r)
            draw_line3(prev, p, cam, right, view_up, forward, screen_w, screen_h, focal, float4 { 0.16, 0.32, 0.44, 0.36 }, 1.0)
            prev = p

    // Spherical surface parcels and city blocks.
    for(map_w) mx:
        for(map_h) my:
            let cell = city_parcel(mx, my)
            draw_surface_parcel(mx, my, cell, cam, right, view_up, forward, screen_w, screen_h, focal)
            if cell != 0:
                draw_building(mx, my, cell, cam, right, view_up, forward, screen_w, screen_h, focal)

    draw_player_capsule(feet, up0, flat_forward, cam, right, view_up, forward, screen_w, screen_h, focal)

    // Center reticle and HUD.
    gl.color(float4 { 0.9, 0.96, 0.9, 0.7 })
    gl.line(float2 { screen_w * 0.5 - 8.0, screen_h * 0.5 }, float2 { screen_w * 0.5 + 8.0, screen_h * 0.5 }, 1.0)
    gl.line(float2 { screen_w * 0.5, screen_h * 0.5 - 8.0 }, float2 { screen_w * 0.5, screen_h * 0.5 + 8.0 }, 1.0)

    gl.set_font_size(16)
    gl.push_model_view()
    gl.translate(float2 { 14.0, 12.0 })
    gl.color(float4 { 0.0, 0.0, 0.0, 0.68 })
    gl.rect(float2 { 390.0, 76.0 })
    gl.color(float4 { 0.92, 0.96, 0.9, 1.0 })
    gl.translate(float2 { 10.0, 8.0 })
    gl.text("third-person capsule scale test")
    gl.translate(float2 { 0.0, 22.0 })
    gl.text("WASD traverse shell, mouse yaw/pitch")
    gl.translate(float2 { 0.0, 22.0 })
    gl.text("Q/E FOV " + string(fov) + "  R=" + string(sphere_r) + "m")
    gl.pop_model_view()
