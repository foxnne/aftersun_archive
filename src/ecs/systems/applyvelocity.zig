const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var subpixels = it.column(components.SubpixelPosition, 2);
    var velocities = it.column(components.Velocity, 3);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        velocities[i].temp_x += velocities[i].x;
        velocities[i].temp_y += velocities[i].y;

        var x = @trunc(velocities[i].temp_x);
        var y = @trunc(velocities[i].temp_y);
        
        velocities[i].temp_x -= x;
        velocities[i].temp_y -= y;

        positions[i].x += x;
        positions[i].y += y;

        subpixels[i].x += positions[i].x;
        subpixels[i].y += positions[i].y;

        x = @trunc(subpixels[i].x);
        y = @trunc(subpixels[i].y);

        subpixels[i].x -= x;
        subpixels[i].y -= y;

        positions[i].x = x;
        positions[i].y = y;
    }
}
