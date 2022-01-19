const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };
    var move_requests = it.column(components.MoveRequest, 1);
    var tiles = it.column(components.Tile, 2);
    var prevtiles = it.column(components.PreviousTile, 3);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        prevtiles[i].x = tiles[i].x;
        prevtiles[i].y = tiles[i].y;
        prevtiles[i].z = tiles[i].z;
        tiles[i].x += move_requests[i].x;
        tiles[i].y += move_requests[i].y;
        tiles[i].z += move_requests[i].z;

        world.remove(it.entities[i], components.MoveRequest);
    }
}
