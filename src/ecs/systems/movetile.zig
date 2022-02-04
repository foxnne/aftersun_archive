const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    //const world = flecs.World{ .world = it.world.? };

    const move_requests = it.term(components.MoveRequest, 1);
    const tiles = it.term(components.Tile, 2);
    const prevtiles = it.term(components.PreviousTile, 3);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        prevtiles[i].x = tiles[i].x;
        prevtiles[i].y = tiles[i].y;
        prevtiles[i].z = tiles[i].z;
        tiles[i].x += move_requests[i].x;
        tiles[i].y += move_requests[i].y;
        tiles[i].z += move_requests[i].z;
        tiles[i].counter = game.getCounter();
    }
}
