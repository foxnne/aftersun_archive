const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var velocities = it.column(components.Velocity, 2);
    var inputs = it.column(components.CharacterInput, 3);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var input = inputs[i].direction.normalized();

        velocities[i].x = input.x * zia.time.dt() * 60;
        velocities[i].y = input.y * zia.time.dt() * 60;

        positions[i].x += velocities[i].x;
        positions[i].y += velocities[i].y;
    }
}
