const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var tiles = it.column(components.Tile, 2);
    var prevtiles = it.column(components.PreviousTile, 3);
    var cooldowns = it.column(components.MovementCooldown, 4);
    var velocities = it.column(components.Velocity, 5);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        if (cooldowns[i].current > 0) {

            var f = cooldowns[i].current / cooldowns[i].end;

            var start = zia.math.Vector2{ .x = @intToFloat(f32, prevtiles[i].x * 32), .y = @intToFloat(f32, prevtiles[i].y * 32) };
            var end = zia.math.Vector2{ .x = @intToFloat(f32, tiles[i].x * 32), .y = @intToFloat(f32, tiles[i].y * 32) };

            var velocity = end.subtract(start);
            velocities[i].x = velocity.x;
            velocities[i].y = velocity.y;

            //lerp
            var position = start.add(end.subtract(start).scale(f));

            positions[i].x = position.x;
            positions[i].y = position.y;

        }
    }
}
