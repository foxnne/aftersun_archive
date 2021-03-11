const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("lucid").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var velocities = it.column(components.Velocity, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        positions[i].x += velocities[i].x;
        positions[i].y += velocities[i].y;
    }
}
