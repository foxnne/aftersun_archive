const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    tile: *const components.Tile,
    prev_tile: *components.PreviousTile,

    pub const name = "MoveRequestSystem";
    pub const run = progress;
    pub const modifiers = .{flecs.queries.Filter(components.Player)};
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (it.world().getSingleton(components.DirectionalInput)) |input| {
            var cooled = if (it.entity().get(components.MovementCooldown)) |cooldown| cooldown.current >= cooldown.end else true;

            if (cooled) {
                if (input.direction != .none) {
                    const directionVector = input.direction.vector2();
                    const x = @floatToInt(i32, directionVector.x);
                    const y = @floatToInt(i32, directionVector.y);

                    it.entity().set(&components.MoveRequest{
                        .x = x,
                        .y = y,
                    });

                    if (x != 0 and y != 0) {
                        it.entity().set(&components.MovementCooldown{
                            .end = 0.4 * zia.math.sqrt2 - it.iter.delta_time,
                            .current = it.iter.delta_time,
                        });
                    } else if (x != 0 or y != 0) {
                        it.entity().set(&components.MovementCooldown{
                            .end = 0.4 - it.iter.delta_time,
                            .current = it.iter.delta_time,
                        });
                    }
                } else {
                    // zero velocity so animations stop
                    comps.prev_tile.x = comps.tile.x;
                    comps.prev_tile.y = comps.tile.y;
                }
            }
        }
    }
}
