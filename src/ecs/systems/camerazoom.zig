const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");

const components = lucid.components;
const actions = lucid.actions;
const sorters = lucid.sorters;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
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
        zooms[i].min = 1.0;

        // clamp zoom to always fill the screen
        if (design_w * zooms[i].min < size_w or design_h * zooms[i].min < size_h) {
            var zoom_w = @ceil(size_w / design_w);
            var zoom_h = @ceil(size_h / design_h);
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

        // ensure we snap to target
        if (@fabs(zooms[i].current - zooms[i].target) <= 0.1) {
            zooms[i].current = zooms[i].target;
        }

        // ensure that zoom is within bounds
        if (zooms[i].current < zooms[i].min) zooms[i].current = zooms[i].min;
        if (zooms[i].current > zooms[i].max) zooms[i].current = zooms[i].max;

    }
}
