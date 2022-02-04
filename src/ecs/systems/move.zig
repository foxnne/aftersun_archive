const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const positions = it.term(components.Position, 1);
    const velocities = it.term(components.Velocity, 2);
    const subpixels_optional = it.term_optional(components.Subpixel, 3);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (velocities[i].x > 0 or velocities[i].x < 0) {
            if (subpixels_optional) |subpixels| {
                const movement_x = subpixels[i].x + velocities[i].x;
                const movement_x_rounded = @trunc(movement_x);
                positions[i].x += movement_x_rounded;
                subpixels[i].x = movement_x - movement_x_rounded;
            } else {
                positions[i].x += velocities[i].x;
            }
        } else {
            positions[i].x = @trunc(positions[i].x);
            if (subpixels_optional) |subpixels| {
                subpixels[i].x = 0;
            }
        } 

        if (velocities[i].y > 0 or velocities[i].y < 0) {
            if (subpixels_optional) |subpixels| {
                const movement_y = subpixels[i].y + velocities[i].y;
                const movement_y_rounded = @trunc(movement_y);
                positions[i].y += movement_y_rounded;
                subpixels[i].y = movement_y - movement_y_rounded;

            } else {
                positions[i].y += velocities[i].y;
            }
        } else {
            positions[i].y = @trunc(positions[i].y);
            if (subpixels_optional) |subpixels| {
                subpixels[i].y = 0;
            }
        }
    }
}
