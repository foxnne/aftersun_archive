const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const actions = game.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var broadphase = it.term(components.CollisionBroadphase, 1);

    if (world.getSingleton(components.Grid)) |grid| {
        var broadphaseIt = flecs.ecs_query_iter(broadphase.*.query.?);
        while (flecs.ecs_query_next(&broadphaseIt)) {
            var j: usize = 0;
            while (j < broadphaseIt.count) : (j += 1) {
                const entity = broadphaseIt.entities[j];
                if (world.getMut(entity, components.Cell)) |cell| {
                    if (world.get(entity, components.Tile)) |tile| {
                        var x = @divTrunc(tile.x, grid.cellTiles);
                        var y = @divTrunc(tile.y, grid.cellTiles);

                        cell.x = x;
                        cell.y = y;

                        broadphase.*.entities.append(cell.*, entity);
                    }
                }
            }
        }
    }
}
