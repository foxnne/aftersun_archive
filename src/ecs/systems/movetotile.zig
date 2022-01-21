const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const positions = it.column(components.Position, 1);
    const tiles = it.column(components.Tile, 2);
    const prevtiles = it.column(components.PreviousTile, 3);
    const cooldowns = it.column(components.MovementCooldown, 4);
    const velocities = it.column(components.Velocity, 5);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var f = cooldowns[i].current / cooldowns[i].end;

        // incase cooldowns[i].end is zero
        if (std.math.isNan(f))
            f = 0;

        const start = zia.math.Vector2{ .x = @intToFloat(f32, prevtiles[i].x * 32), .y = @intToFloat(f32, prevtiles[i].y * 32) };
        const end = zia.math.Vector2{ .x = @intToFloat(f32, tiles[i].x * 32), .y = @intToFloat(f32, tiles[i].y * 32) };

        var velocity = end.subtract(start);
        velocities[i].x = velocity.x;
        velocities[i].y = velocity.y;

        // lerp towards final position
        const position = start.add(velocity.scale(f));
        positions[i].x = position.x;
        positions[i].y = position.y;
    }
}
