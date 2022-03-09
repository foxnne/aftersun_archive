const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    mouse_drag: *const components.MouseDrag,

    pub const name = "MouseDragSystem";
    pub const run = progress;
    pub const expr = "[out] MoveRequest()";
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        //only allow moving items nearest the player
        if (game.player.get(components.Tile)) |player_tile| {
            const dist_x = comps.mouse_drag.prev_x - player_tile.x;
            const dist_y = comps.mouse_drag.prev_y - player_tile.y;

            if (dist_x > 1 or dist_y > 1)
                return;
        }

        // get the cell we are dragging from
        const grab_cell = components.Cell{ .x = @divTrunc(comps.mouse_drag.x, game.cell_size), .y = @divTrunc(comps.mouse_drag.y, game.cell_size) };

        var cell_term = flecs.Term(components.Cell).init(it.world());
        var cell_it = cell_term.iterator();

        // iterate all cells
        while (cell_it.next()) |cell| {
            // match with dragging from cell
            if (cell.x == grab_cell.x and cell.y == grab_cell.y) {
                const TileCallback = struct {
                    tile: *const components.Tile,
                };
                // iterate tiles that are children of the cell
                var tile_filter = it.world().filterParent(TileCallback, cell_it.entity());
                defer tile_filter.deinit();
                var tile_it = tile_filter.iterator(TileCallback);

                var counter: i32 = 0;
                var entity: ?flecs.Entity = null;
                var tile: components.Tile = .{};
                while (tile_it.next()) |tiles| {
                    // match grab tile
                    if (tiles.tile.x == comps.mouse_drag.prev_x and tiles.tile.y == comps.mouse_drag.prev_y) {
                        if (tile_it.entity().has(components.Moveable)) {
                            // find the tile with the highest counter
                            if (tiles.tile.counter >= counter) {
                                counter = tiles.tile.counter;
                                entity = tile_it.entity();
                                tile = tiles.tile.*;
                            }
                        }
                    }
                }

                if (entity) |e| {
                    std.log.debug("called", .{});
                    e.set(&components.MoveRequest{ .x = comps.mouse_drag.x - tile.x, .y = comps.mouse_drag.y - tile.y });
                    e.set(&components.MovementCooldown{ .current = 0, .end = 0.2 });
                }
            }
        }
    }
}
