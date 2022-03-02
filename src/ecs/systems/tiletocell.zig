const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    tile: *const components.Tile,
    cell: *components.Cell,

    pub const name = "TileToCellSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        comps.cell.x = @divTrunc(comps.tile.x, game.ppu);
        comps.cell.y = @divTrunc(comps.tile.y, game.ppu);
    }
}
