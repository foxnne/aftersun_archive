const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");

const components = lucid.components;
const actions = lucid.actions;
const sorters = lucid.sorters;

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var cameras = it.column(components.Camera, 1);
    var zooms = it.column(components.Zoom, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        const size = zia.window.size();
        const size_w = @intToFloat(f32, size.w);
        const size_h = @intToFloat(f32, size.h);

        const design_w = @intToFloat(f32, cameras[i].design_w);
        const design_h = @intToFloat(f32, cameras[i].design_h);

        // reset the minimum zoom
        cameras[i].zoom_min = 1.0;

        // clamp zoom to always fill the screen
        if (design_w * cameras[i].zoom_min < size_w or design_h * cameras[i].zoom_min < size_h) {
            var zoom_w = @ceil(size_w / design_w);
            var zoom_h = @ceil(size_h / design_h);
            cameras[i].zoom_min = if (zoom_w > zoom_h) zoom_w else zoom_h;
        }

        if (zia.input.mouse_wheel_y > 0 and cameras[i].zoom < cameras[i].zoom_max)
            cameras[i].zoom_target = @round(cameras[i].zoom + 1.0);

        if (zia.input.mouse_wheel_y < 0 and cameras[i].zoom > cameras[i].zoom_min)
            cameras[i].zoom_target = @round(cameras[i].zoom - 1.0);

        if (cameras[i].zoom < cameras[i].zoom_target) {
            var increment = zia.time.dt() * cameras[i].zoom_speed;

            if (cameras[i].zoom_target - cameras[i].zoom > increment) {
                cameras[i].zoom += increment;
            } else {
                cameras[i].zoom = cameras[i].zoom_target;
            }
        } else {
            var increment = zia.time.dt() * cameras[i].zoom_speed;

            if (cameras[i].zoom - cameras[i].zoom_target > increment) {
                cameras[i].zoom -= increment;
            } else {
                cameras[i].zoom = cameras[i].zoom_target;
            }
        }

        // ensure that zoom is within bounds
        if (cameras[i].zoom < cameras[i].zoom_min) cameras[i].zoom = cameras[i].zoom_min;
        if (cameras[i].zoom > cameras[i].zoom_max) cameras[i].zoom = cameras[i].zoom_max;

    }
}
