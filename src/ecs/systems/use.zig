const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const relations = game.relations;

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

                        var counter: u64 = 0;
                        var entity: ?flecs.Entity = null;
                        while (tile_it.next()) |tiles| {
                            // match use tile
                            if (tiles.tile.x == comps.request.x and tiles.tile.y == comps.request.y) {

                                // find the tile with the highest counter
                                if (tiles.tile.counter >= counter) {
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

                            if (target.get(components.UseRecipe)) |recipe| {
                                var meets_required: bool = true;

                                if (!it.entity().has(recipe.primary))
                                    meets_required = false;

                                if (recipe.secondary) |secondary| {
                                    if (!it.entity().has(secondary))
                                        meets_required = false;
                                }

                                if (recipe.tertiary) |tertiary| {
                                    if (!it.entity().has(tertiary))
                                        meets_required = false;
                                }

                                if (recipe.not) |not| {
                                    if (target.has(not))
                                        meets_required = false;
                                }

                                if (meets_required) {
                                    if (recipe.produces) |result| {
                                        var new = it.world().newEntity();
                                        new.isA(result);

                                        if (target.get(components.Tile)) |tile| {
                                            new.set(&components.Tile{
                                                .x = tile.x,
                                                .y = tile.y,
                                                .z = tile.z,
                                                .counter = game.getCounter(),
                                            });
                                            if (target.get(components.PreviousTile)) |_| {
                                                new.set(&components.PreviousTile{
                                                    .x = tile.x,
                                                    .y = tile.y,
                                                    .z = tile.z,
                                                });
                                            }
                                        }

                                        if (target.get(components.Position)) |position|
                                            new.set(position);

                                        new.set(&components.MoveRequest{});

                                        new.set(&components.MovementCooldown{
                                            .current = 0,
                                            .end = 0.2,
                                        });
                                    }

                                    if (recipe.consumes == .self or recipe.consumes == .both) {
                                        if (target.getMut(components.Count)) |count| {
                                            if (count.value > 1) {
                                                count.value -= 1;
                                                target.setModified(components.Count);
                                            } else {
                                                target.delete();
                                            }
                                        } else {
                                            target.delete();
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
