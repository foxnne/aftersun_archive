const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub const Callback = struct {
    position: *components.Position,
    velocity: *const components.Velocity,

    pub const name = "MoveSystem";
    pub const run = progress;
    pub const modifiers = .{ flecs.queries.Not(components.Tile) };
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.velocity.x > 0 or comps.velocity.x < 0) {
            comps.position.x += comps.velocity.x;
        } else {
            comps.position.x = @round(comps.position.x);
        }

        if (comps.velocity.y > 0 or comps.velocity.y < 0) {
            comps.position.y += comps.velocity.y;
        } else {
            comps.position.y = @round(comps.position.y);
        }
    }
}
