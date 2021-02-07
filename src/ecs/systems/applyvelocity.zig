const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var subpixels = it.column(components.Subpixel, 2);
    var velocities = it.column(components.Velocity, 3);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (velocities[i].x != 0 and velocities[i].y != 0) {
            velocities[i].sub_x += velocities[i].x;
            velocities[i].sub_y += velocities[i].y;

            var x = @trunc(velocities[i].sub_x);
            var y = @trunc(velocities[i].sub_y);

            velocities[i].sub_x -= x;
            velocities[i].sub_y -= y;

            positions[i].x += x;
            positions[i].y += y;
        } else {
            positions[i].x += velocities[i].x;
            positions[i].y += velocities[i].y;
        }

        subpixels[i].x += positions[i].x;
        subpixels[i].y += positions[i].y;

        var x = @trunc(subpixels[i].x);
        var y = @trunc(subpixels[i].y);

        subpixels[i].x -= x;
        subpixels[i].y -= y;

        positions[i].x = x;
        positions[i].y = y;
    }
}
