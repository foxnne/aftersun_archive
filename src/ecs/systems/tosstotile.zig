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
        if (cooldowns[i].current < cooldowns[i].end)
            cooldowns[i].current += zia.time.dt();

        var f = cooldowns[i].current / cooldowns[i].end;

        // incase cooldowns[i].end is zero
        if (std.math.isNan(f)) {
            f = 0;
        }

        const start = zia.math.Vector2{ .x = @intToFloat(f32, prevtiles[i].x * 32), .y = @intToFloat(f32, prevtiles[i].y * 32) };
        const end = zia.math.Vector2{ .x = @intToFloat(f32, tiles[i].x * 32), .y = @intToFloat(f32, tiles[i].y * 32) };

        var velocity = end.subtract(start);

        // lerp towards final position
        const position = start.add(velocity.scale(f));
        positions[i].x = position.x;
        positions[i].y = position.y;
        positions[i].z = @floatToInt(i32, std.math.sin(std.math.pi * f) * 10);

        if (f >= 1 or cooldowns[i].end == 0) {
            prevtiles[i].x = tiles[i].x;
            prevtiles[i].y = tiles[i].y;
            //cooldowns[i].current = 0;

        }
    }
}
