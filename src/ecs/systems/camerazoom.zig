const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;

pub const Callback = struct {
    camera: *const components.Camera,
    zoom: *components.Zoom,

    pub const name = "CameraZoomSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        const window_size = .{ .x = @intToFloat(f32, zia.window.size().w), .y = @intToFloat(f32, zia.window.size().h) };

        // reset the minimum zoom
        comps.zoom.min = 1.0;

        // clamp zoom to always fill the screen
        if (comps.camera.size.x * comps.zoom.min < window_size.x or comps.camera.size.y * comps.zoom.min < window_size.y) {
            var zoom_w = @ceil(window_size.x / comps.camera.size.x);
            var zoom_h = @ceil(window_size.y / comps.camera.size.y);
            comps.zoom.min = if (zoom_w > zoom_h) zoom_w else zoom_h;
        }

        if (zia.input.mouse_wheel_y > 0 and comps.zoom.current < comps.zoom.max)
            comps.zoom.target = @round(comps.zoom.current + 1.0);

        if (zia.input.mouse_wheel_y < 0 and comps.zoom.current > comps.zoom.min)
            comps.zoom.target = @round(comps.zoom.current - 1.0);

        if (comps.zoom.current < comps.zoom.target) {
            var increment = zia.time.dt() * comps.zoom.speed;

            if (comps.zoom.target - comps.zoom.current > increment) {
                comps.zoom.current += increment;
            } else {
                comps.zoom.current = comps.zoom.target;
            }
        } else {
            var increment = zia.time.dt() * comps.zoom.speed;

            if (comps.zoom.current - comps.zoom.target > increment) {
                comps.zoom.current -= increment;
            } else {
                comps.zoom.current = comps.zoom.target;
            }
        }

        // ensure that zoom is within bounds
        if (comps.zoom.current < comps.zoom.min) comps.zoom.current = comps.zoom.min;
        if (comps.zoom.current > comps.zoom.max) comps.zoom.current = comps.zoom.max;
    }
}
