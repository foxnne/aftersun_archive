const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;
const actions = game.actions;
const sorters = game.sorters;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var cameras = it.column(components.Camera, 1);
    var zooms = it.column(components.Zoom, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        const window_size = .{ .x = @intToFloat(f32, zia.window.size().w), .y = @intToFloat(f32, zia.window.size().h) };

        // reset the minimum zoom
        zooms[i].min = 1.0;

        // clamp zoom to always fill the screen
        if (cameras[i].size.x * zooms[i].min < window_size.x or cameras[i].size.y * zooms[i].min < window_size.y) {
            var zoom_w = @ceil(window_size.x / cameras[i].size.x);
            var zoom_h = @ceil(window_size.y / cameras[i].size.y);
            zooms[i].min = if (zoom_w > zoom_h) zoom_w else zoom_h;
        }

        if (zia.input.mouse_wheel_y > 0 and zooms[i].current < zooms[i].max)
            zooms[i].target = @round(zooms[i].current + 1.0);

        if (zia.input.mouse_wheel_y < 0 and zooms[i].current > zooms[i].min)
            zooms[i].target = @round(zooms[i].current - 1.0);

        if (zooms[i].current < zooms[i].target) {
            var increment = zia.time.dt() * zooms[i].speed;

            if (zooms[i].target - zooms[i].current > increment) {
                zooms[i].current += increment;
            } else {
                zooms[i].current = zooms[i].target;
            }
        } else {
            var increment = zia.time.dt() * zooms[i].speed;

            if (zooms[i].current - zooms[i].target > increment) {
                zooms[i].current -= increment;
            } else {
                zooms[i].current = zooms[i].target;
            }
        }

        // ensure that zoom is within bounds
        if (zooms[i].current < zooms[i].min) zooms[i].current = zooms[i].min;
        if (zooms[i].current > zooms[i].max) zooms[i].current = zooms[i].max;
    }
}
