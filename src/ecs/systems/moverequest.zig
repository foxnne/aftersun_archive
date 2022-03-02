const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    cooldown: *components.MovementCooldown,
    tile: *const components.Tile,
    prev_tile: *components.PreviousTile,

    pub const name = "MoveRequestSystem";
    pub const run = progress;
    pub const expr = "[out] MoveRequest()"; 
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (it.world().getSingleton(components.MovementInput)) |input| {
            if (comps.cooldown.current >= comps.cooldown.end) {
                if (input.direction != .none) {
                    const directionVector = input.direction.vector2();
                    const x = @floatToInt(i32, directionVector.x);
                    const y = @floatToInt(i32, directionVector.y);

                    it.entity().set(&components.MoveRequest{
                        .x = x,
                        .y = y,
                    });

                    if (x != 0 and y != 0) {
                        comps.cooldown.end = 0.4 * zia.math.sqrt2 - (comps.cooldown.end - comps.cooldown.current) - it.iter.delta_time;
                        comps.cooldown.current = zia.time.dt();
                    } else if (x != 0 or y != 0) {
                        comps.cooldown.end = 0.4 - (comps.cooldown.end - comps.cooldown.current) - it.iter.delta_time;
                        comps.cooldown.current = zia.time.dt();
                    }
                } else {
                    // zero velocity so animations stop
                    comps.prev_tile.x = comps.tile.x;
                    comps.prev_tile.y = comps.tile.y;
                }
            } else {
                comps.cooldown.current += zia.time.dt();
            }
        }
    }
}
