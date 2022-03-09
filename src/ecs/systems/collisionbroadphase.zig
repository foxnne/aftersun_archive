const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    tile: *const components.Tile,

    pub const name = "CollisionBroadphaseSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        var cell = components.Cell{ .x = @divTrunc(comps.tile.x, game.cell_size), .y = @divTrunc(comps.tile.y, game.cell_size) };

        const CellCallback = struct {
            cell: *const components.Cell,
        };
        var filter = it.world().filter(CellCallback);

        var cell_it = filter.iterator(CellCallback);
        defer filter.deinit();

        var contains = false;

        while (cell_it.next()) |cells| {
            if (cells.cell.x == cell.x and cells.cell.y == cell.y) {
                it.entity().childOf(cell_it.entity());
                contains = true;
            } else {
                if (it.entity().hasPair(flecs.c.EcsChildOf, cell_it.entity())) {
                    // parent but wrong/outdated cell
                    it.entity().removePair(flecs.c.EcsChildOf, cell_it.entity());
                }
            }
        }

        if (!contains) {
            var parent = it.world().newEntity();
            parent.add(components.Cell);
            parent.set(&cell);
            it.entity().addPair(flecs.c.EcsChildOf, parent);
        }
    }
}
