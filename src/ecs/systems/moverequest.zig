const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var movement_input = it.column(components.MovementInput, 1);
    var cooldowns = it.column(components.MovementCooldown, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (cooldowns[i].current >= cooldowns[i].end) {
            var directionVector = movement_input.*.direction.vector2();
            var x = @floatToInt(i32, directionVector.x);
            var y = @floatToInt(i32, directionVector.y);
            
            world.set(it.entities[i], &components.MoveRequest{
                .x = x,
                .y = y,
            });

            if (x != 0 and y != 0) {
                cooldowns[i].end = 0.4 * zia.math.sqrt2 - (cooldowns[i].end - cooldowns[i].current);
                cooldowns[i].current = 0;
            } else if (x != 0 or y != 0) {
                cooldowns[i].end = 0.4 - (cooldowns[i].end - cooldowns[i].current);
                cooldowns[i].current = 0;
            }
        } else {
            cooldowns[i].current += zia.time.dt();
        }
    }
}
