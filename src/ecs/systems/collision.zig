const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const tiles = it.term(components.Tile, 1);
    const cells = it.term(components.Cell, 2);
    const colliders = it.term(components.Collider, 2);
    const requests_optional = it.term_optional(components.MoveRequest, 3);
    const cooldowns_optional = it.term_optional(components.MovementCooldown, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        




        
    }
}