const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = @import("game").components;

pub const Callback = struct {
    request: *const components.UseRequest,

    pub const name = "UseSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        blk: {
            if (it.entity().get(components.Tile)) |from_tile| {

                //only allow using items nearest the user
                const dist_x = std.math.absInt(comps.request.x - from_tile.x) catch unreachable;
                const dist_y = std.math.absInt(comps.request.y - from_tile.y) catch unreachable;

                if (dist_x > 1 or dist_y > 1)
                    return;

                const use_cell = components.Cell{ .x = @divTrunc(comps.request.x, game.cell_size), .y = @divTrunc(comps.request.y, game.cell_size) };

                var cell_term = flecs.Term(components.Cell).init(it.world());
                defer cell_term.deinit();
                var cell_it = cell_term.iterator();

                // iterate all cells
                while (cell_it.next()) |cell| {
                    if (cell.x == use_cell.x and cell.y == use_cell.y) {
                        const TileCallback = struct {
                            tile: *const components.Tile,
                        };
                        // iterate tiles that are children of the cell
                        var tile_filter = it.world().filterParent(TileCallback, cell_it.entity());
                        defer tile_filter.deinit();
                        var tile_it = tile_filter.iterator(TileCallback);

                        var counter: i32 = -1;
                        var entity: ?flecs.Entity = null;
                        while (tile_it.next()) |tiles| {
                            // match use tile
                            if (tiles.tile.x == comps.request.x and tiles.tile.y == comps.request.y) {

                                // find the tile with the highest counter
                                if (tiles.tile.counter > counter) {
                                    counter = tiles.tile.counter;
                                    entity = tile_it.entity();
                                }
                            }
                        }

                        if (entity) |target| {
                            if (target.get(components.MovementCooldown)) |cooldown| {
                                if (cooldown.current < cooldown.end)
                                    break :blk;
                            }

                            if (target.has(components.Useable)) {
                                if (target.getMut(components.Toggleable)) |toggleable| {
                                    toggleable.state = !toggleable.state;
                                    if (target.get(components.ToggleAnimation)) |toggle_animation| {
                                        if (target.getMut(components.SpriteAnimator)) |animator| {
                                            if (toggleable.state == false) {
                                                animator.state = .pause;
                                            } else {
                                                animator.state = .play;
                                            }
                                        }

                                        if (target.getMut(components.SpriteRenderer)) |renderer| {
                                            if (toggleable.state == false) {
                                                renderer.index = toggle_animation.off_index;
                                            }
                                        }

                                        if (target.getMut(components.LightRenderer)) |renderer| {
                                            renderer.active = toggleable.state;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            it.entity().remove(components.UseRequest);
        }
    }
}
