const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    position: *components.Position,
    tile: *const components.Tile,
    prev_tile: *const components.PreviousTile,
    cooldown: ?*const components.MovementCooldown,
    velocity: ?*components.Velocity,

    pub const name = "MoveToTileSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        var f = if (comps.cooldown) |cooldown| cooldown.current / cooldown.end else 1;

        // incase comps.cooldown.end is zero
        if (std.math.isNan(f))
            f = 0;

        const start = zia.math.Vector2{ .x = @intToFloat(f32, comps.prev_tile.x * 32), .y = @intToFloat(f32, comps.prev_tile.y * 32) };
        const end = zia.math.Vector2{ .x = @intToFloat(f32, comps.tile.x * 32), .y = @intToFloat(f32, comps.tile.y * 32) };

        var velocity = end.subtract(start);
        if (comps.velocity) |vel| {
            vel.x = velocity.x;
            vel.y = velocity.y;
        } else {
            //toss
            comps.position.z = @floatToInt(i32, std.math.sin(std.math.pi * f) * 10);
        }

        // lerp towards final position
        const position = start.add(velocity.scale(f));
        comps.position.x = position.x;
        comps.position.y = position.y;
    }
}
