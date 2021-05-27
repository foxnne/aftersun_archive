const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var velocities = it.column(components.Velocity, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (velocities[i].x > 0 or velocities[i].x < 0) {
            positions[i].x += velocities[i].x;
        } else {
            positions[i].x = @round(positions[i].x);
        }

        if (velocities[i].y > 0 or velocities[i].y < 0) {
            positions[i].y += velocities[i].y;
        } else {
            positions[i].y = @round(positions[i].y);
        }
    }
}
