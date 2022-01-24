const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const actions = game.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var tiles = it.column(components.Tile, 1);
    var broadphase = it.column(components.TileBroadphase, 2);

    if (world.getSingleton(components.Grid)) |grid| { 
        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            var x = @divTrunc(tiles[i].x, grid.cellTiles);
            var y = @divTrunc(tiles[i].y, grid.cellTiles);

            broadphase.*.entities.append(.{.x = x, .y = y}, it.entities[i]);

            
        }
    }
}
