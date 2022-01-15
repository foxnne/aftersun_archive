const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var tiles = it.column(components.Tile, 1);
    var cooldowns = it.column(components.MovementCooldown, 2);
    var prevtiles = it.column(components.PreviousTile, 3);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (world.getSingleton(components.MovementInput)) |movementInput| {
            if (cooldowns[i].current >= cooldowns[i].end) {
                var directionVector = movementInput.direction.vector2();
                var x = @floatToInt(i32, directionVector.x);
                var y = @floatToInt(i32, directionVector.y);

                prevtiles[i].x = tiles[i].x;
                prevtiles[i].y = tiles[i].y;

                tiles[i].x += x;
                tiles[i].y += y;

                if (movementInput.direction != .none) {
                    if (x != 0 and y != 0) {
                        cooldowns[i].end = 0.4 * zia.math.sqrt2 - (cooldowns[i].end - cooldowns[i].current);
                        cooldowns[i].current = 0;
                    } else {
                        cooldowns[i].end = 0.4 - (cooldowns[i].end - cooldowns[i].current);
                        cooldowns[i].current = 0;
                    }
                }
            } else {
                cooldowns[i].current += zia.time.dt();
            }
        }

        if (game.enable_editor) {
            game.gizmos.box(.{ .x = @intToFloat(f32, tiles[i].x * game.ppu), .y = @intToFloat(f32, tiles[i].y * game.ppu) }, game.ppu, game.ppu, zia.math.Color.gray, 1);
        }
    }
}
