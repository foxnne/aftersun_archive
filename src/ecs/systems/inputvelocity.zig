const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("lucid").components;

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var inputs = it.column(components.MovementInput, 1);
    var velocities = it.column(components.Velocity, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
      
        var input = inputs[i].direction.normalized();

        // 40, 80 and 120 work here as speed without causing jitter
        velocities[i].x = input.x * zia.time.dt() * 80;
        velocities[i].y = input.y * zia.time.dt() * 80;
    }
}