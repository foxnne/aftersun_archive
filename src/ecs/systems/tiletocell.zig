const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const tiles = it.term(components.Tile, 1);
    const cells = it.term(components.Cell, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        cells[i].x = @divTrunc(tiles[i].x, game.ppu);
        cells[i].y = @divTrunc(tiles[i].y, game.ppu);
    }
}
