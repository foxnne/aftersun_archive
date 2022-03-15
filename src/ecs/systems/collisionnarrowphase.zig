const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    move_request: *components.MoveRequest,

    pub const name = "CollisionNarrowphaseSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        
            if (it.entity().get(components.Collider)) |self_collider| {
                if (self_collider.trigger)
                    continue;
            }

            if (it.entity().getMut(components.Tile)) |self_tile| {
                const target_cell = components.Cell{ .x = @divTrunc(self_tile.x + comps.move_request.x, game.cell_size), .y = @divTrunc(self_tile.y + comps.move_request.y, game.cell_size) };

                var cell_term = flecs.Term(components.Cell).init(it.world());
                var cell_it = cell_term.iterator();

                while (cell_it.next()) |cell| {
                    if (cell.x == target_cell.x and cell.y == target_cell.y) {
                        const TileCallback = struct {
                            tile: *components.Tile,
                            collider: *const components.Collider,
                        };

                        var tile_filter = it.world().filterParent(TileCallback, cell_it.entity());
                        defer tile_filter.deinit();

                        var tile_it = tile_filter.iterator(TileCallback);
                        while (tile_it.next()) |tiles| {
                            if (self_tile.x + comps.move_request.x == tiles.tile.x and self_tile.y + comps.move_request.y == tiles.tile.y) {
                                if (tiles.collider.trigger) {
                                    tile_it.entity().set(&components.UseRequest{
                                        .x = tiles.tile.x,
                                        .y = tiles.tile.y,
                                    });
                                    continue;
                                }

                                //collision
                                comps.move_request.x = 0;
                                comps.move_request.y = 0;
                                if (it.entity().getMut(components.MovementCooldown)) |cooldown| {
                                    cooldown.current = 0;
                                    cooldown.end = 0;
                                }
                                break;
                            }
                        }

                        if (it.entity().getMut(components.PreviousTile)) |prev_tile| {
                            prev_tile.x = self_tile.x;
                            prev_tile.y = self_tile.y;
                            prev_tile.z = self_tile.z;
                        }
                        self_tile.x += comps.move_request.x;
                        self_tile.y += comps.move_request.y;
                        self_tile.z += comps.move_request.z;
                        self_tile.counter = game.getCounter();

                        it.entity().setModified(components.Tile);
                    }
                }
            }
        }

        it.entity().remove(components.MoveRequest);
    }

