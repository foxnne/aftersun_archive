const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = @import("game").components;

pub const Callback = struct {
    request: *const components.MoveRequest,
    tile: *components.Tile,
    prev_tile: ?*components.PreviousTile,

    pub const name = "MoveTileSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.prev_tile) |prev_tile| {
            prev_tile.x = comps.tile.x;
            prev_tile.y = comps.tile.y;
            prev_tile.z = comps.tile.z;
        }

        comps.tile.x += comps.request.x;
        comps.tile.y += comps.request.y;
        comps.tile.z += comps.request.z;
        comps.tile.counter = game.getCounter();

        it.entity().setModified(components.Tile);

        it.entity().remove(components.MoveRequest);
    }
}
