const std = @import("std");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");
const zia = @import("zia");
const sdl = @import("sdl");
const components = game.components;

pub const Callback = struct {
    use: *const components.MouseAction,

    pub const name = "MouseInputSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.use.action == .up and comps.use.button == .right) {
            const target_cell = components.Cell{ .x = @divTrunc(comps.use.x, game.cell_size), .y = @divTrunc(comps.use.y, game.cell_size) };

            var cell_term = flecs.Term(components.Cell).init(it.world());
            var cell_it = cell_term.iterator();

            while (cell_it.next()) |cell| {
                if (cell.x == target_cell.x and cell.y == target_cell.y) {
                    const TileCallback = struct {
                        tile: *components.Tile,
                    };

                    var tile_filter = it.world().filterParent(TileCallback, cell_it.entity());
                    defer tile_filter.deinit();

                    var counter: u64 = 0;
                    var target: ?flecs.Entity = null;

                    var tile_it = tile_filter.iterator(TileCallback);
                    while (tile_it.next()) |tiles| {
                        if (tile_it.entity().id == it.entity().id)
                            continue;

                        if (tiles.tile.x == comps.use.x and tiles.tile.y == comps.use.y) {
                            if (tiles.tile.counter >= counter) {
                                counter = tiles.tile.counter;
                                target = tile_it.entity();
                            }
                        }
                    }

                    if (target) |target_entity| {
                        game.player.set(&components.UseRequest{
                            .target = target_entity.id,
                        });
                    }
                }
            }

            it.world().removeSingleton(components.MouseAction);
        }
    }
}
