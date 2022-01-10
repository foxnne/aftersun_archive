const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var velocities = it.column(components.Velocity, 1);
    var speeds = it.column(components.Speed, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (world.getSingleton(components.MovementInput)) |movementInput| {
            var input = movementInput.direction.normalized();
            
            velocities[i].x = input.x * zia.time.dt() * speeds[i].value;
            velocities[i].y = input.y * zia.time.dt() * speeds[i].value;
        }
    }
}
