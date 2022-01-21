const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var movement_input = it.column(components.MovementInput, 1);
    var cooldowns = it.column(components.MovementCooldown, 2);
    var tiles = it.column(components.Tile, 3);
    var prev_tiles = it.column(components.PreviousTile, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (cooldowns[i].current >= cooldowns[i].end) {
            if (movement_input.*.direction != .none) {
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
                // zero velocity so animations stop
                prev_tiles[i].x = tiles[i].x;
                prev_tiles[i].y = tiles[i].y;
            }
        } else {
            cooldowns[i].current += zia.time.dt();
        }
    }
}
