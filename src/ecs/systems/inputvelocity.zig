const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var movementInputPtr = world.getSingleton(components.MovementInput);

    var velocities = it.column(components.Velocity, 1);
    var speed: f32 = 80;

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (movementInputPtr) |movementInput| {
            var input = movementInput.direction.normalized();
            
            velocities[i].x = input.x * zia.time.dt() * speed;
            velocities[i].y = input.y * zia.time.dt() * speed;
        }
    }
}
