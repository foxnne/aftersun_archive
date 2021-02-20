const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("lucid").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    //var inputs = it.column(components.MovementInput, 1);
    var world = flecs.World{ .world = it.world.? };

    var movementInputPtr = world.getSingleton(components.MovementInput);

    var velocities = it.column(components.Velocity, 1);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (movementInputPtr) |movementInput| {
            var input = movementInput.direction.normalized();

            // 40, 80 and 120 work here as speed without causing jitter
            velocities[i].x = input.x * zia.time.dt() * 80;
            velocities[i].y = input.y * zia.time.dt() * 80;
        }
    }
}
