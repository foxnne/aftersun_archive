const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {

    const positions = it.term(components.Position, 1);
    const tiles = it.term(components.Tile, 2);
    const prevtiles = it.term(components.PreviousTile, 3);
    const cooldowns = it.term(components.TossCooldown, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        var f = cooldowns[i].current / cooldowns[i].end;

        // incase cooldowns[i].end is zero
        if (std.math.isNan(f))
            f = 0;

        const start = zia.math.Vector2{ .x = @intToFloat(f32, prevtiles[i].x * 32), .y = @intToFloat(f32, prevtiles[i].y * 32) };
        const end = zia.math.Vector2{ .x = @intToFloat(f32, tiles[i].x * 32), .y = @intToFloat(f32, tiles[i].y * 32) };


        // lerp towards final position
        const position = start.add(velocity.scale(f));
        positions[i].x = position.x;
        positions[i].y = position.y;
    }
}