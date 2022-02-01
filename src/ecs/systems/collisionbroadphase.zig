const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const actions = game.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const broadphase = it.term(components.CollisionBroadphase, 1);
    const grid = it.term(components.Grid, 2);
    const cells = it.term(components.Cell, 3);
    const tiles = it.term(components.Tile, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        cells[i].x = @divTrunc(tiles[i].x, grid.*.cellTiles);
        cells[i].y = @divTrunc(tiles[i].y, grid.*.cellTiles);

        broadphase.*.entities.append(cells[i], it.entities[i]);
    }
}
