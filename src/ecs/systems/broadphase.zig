const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const actions = game.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var colliders = it.column(components.Collider, 1);
    var tiles = it.column(components.Tile, 2);
    var broadphase = it.column(components.Broadphase, 3);

    if (world.getSingleton(components.Grid)) |grid| { 
        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            var x = @divTrunc(tiles[i].x, grid.cellTiles);
            var y = @divTrunc(tiles[i].y, grid.cellTiles);

            colliders[i].cell = .{ .x = x, .y = y };

            broadphase.*.entities.append(colliders[i].cell, it.entities[i]);

            
        }
    }
}
