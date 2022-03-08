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
        blk: {
            var collider = it.entity().get(components.Collider);
            var tile = it.entity().get(components.Tile);

            if (collider) |c| {
                if (c.trigger)
                    continue;
            }

            if (tile) |t| {
                const current_cell = components.Cell{ .x = @divTrunc(t.x, 8), .y = @divTrunc(t.y, 8) };

                const move_direction = zia.math.Direction.find(8, @intToFloat(f32, comps.move_request.x), @intToFloat(f32, comps.move_request.y));

                const all_cells = switch (move_direction) {
                    .none => [_]components.Cell{ current_cell, current_cell, current_cell, current_cell },
                    .n => [_]components.Cell{ current_cell, current_cell, current_cell, .{ .x = current_cell.x, .y = current_cell.y - 1 } },
                    .e => [_]components.Cell{ current_cell, current_cell, current_cell, .{ .x = current_cell.x + 1, .y = current_cell.y } },
                    .s => [_]components.Cell{ current_cell, current_cell, current_cell, .{ .x = current_cell.x, .y = current_cell.y + 1 } },
                    .w => [_]components.Cell{ current_cell, current_cell, current_cell, .{ .x = current_cell.x - 1, .y = current_cell.y } },
                    .ne => [_]components.Cell{ current_cell, .{ .x = current_cell.x, .y = current_cell.y - 1 }, .{ .x = current_cell.x + 1, .y = current_cell.y }, .{ .x = current_cell.x + 1, .y = current_cell.y - 1 } },
                    .se => [_]components.Cell{ current_cell, .{ .x = current_cell.x, .y = current_cell.y + 1 }, .{ .x = current_cell.x + 1, .y = current_cell.y }, .{ .x = current_cell.x + 1, .y = current_cell.y + 1 } },
                    .sw => [_]components.Cell{ current_cell, .{ .x = current_cell.x, .y = current_cell.y + 1 }, .{ .x = current_cell.x - 1, .y = current_cell.y }, .{ .x = current_cell.x - 1, .y = current_cell.y + 1 } },
                    .nw => [_]components.Cell{ current_cell, .{ .x = current_cell.x, .y = current_cell.y - 1 }, .{ .x = current_cell.x - 1, .y = current_cell.y }, .{ .x = current_cell.x - 1, .y = current_cell.y - 1 } },
                };

                for (all_cells) |cell| {
                    const CellCallback = struct {
                        cell: *const components.Cell,
                    };
                    var cell_filter = it.world().filter(CellCallback);

                    var cell_it = cell_filter.iterator(CellCallback);
                    defer cell_filter.deinit();

                    while (cell_it.next()) |cells| {
                        if (cells.cell.x == cell.x and cells.cell.y == cell.y) {
                            const TileCallback = struct {
                                tile: *const components.Tile,
                                collider: *const components.Collider,
                            };

                            var tile_filter = it.world().filter(TileCallback);
                            defer tile_filter.deinit();

                            tile_filter.filter.terms[2].id = it.world().pair(flecs.c.EcsChildOf, cell_it.entity());

                            var tile_it = tile_filterw.iterator(TileCallback);
                            while (tile_it.next()) |tiles| {
                                
                                if (!tile_it.entity().hasPair(flecs.c.EcsChildOf, cell_it.entity()))
                                    std.log.err("tile is not a child of parent cell", .{});

                                if (t.x + comps.move_request.x == tiles.tile.x and t.y + comps.move_request.y == tiles.tile.y) {
                                    if (tiles.collider.trigger)
                                        continue;

                                    //collision
                                    comps.move_request.x = 0;
                                    comps.move_request.y = 0;
                                    if (it.entity().getMut(components.MovementCooldown)) |cooldown| {
                                        cooldown.current = cooldown.end;
                                    }
                                    break :blk;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// // Create a hierarchical query to compute the global position from the local position and the parent position
//     var query_t = std.mem.zeroes(flecs.c.ecs_query_desc_t);
//     // Read from entity's Local position
//     query_t.filter.terms[0] = std.mem.zeroInit(flecs.c.ecs_term_t, .{ .id = world.pair(Position, Local), .inout = flecs.c.EcsIn });
//     // Write to entity's World position
//     query_t.filter.terms[1] = std.mem.zeroInit(flecs.c.ecs_term_t, .{ .id = world.pair(Position, World), .inout = flecs.c.EcsOut });
//     // Read from parent's World position
//     query_t.filter.terms[2].id = world.pair(Position, World);
//     query_t.filter.terms[2].inout = flecs.c.EcsIn;
//     query_t.filter.terms[2].oper = flecs.c.EcsOptional;
//     query_t.filter.terms[2].subj.set.mask = flecs.c.EcsParent | flecs.c.EcsCascade;

//     const QCallback = struct { local: *const Position, world: *Position, parent: ?*const Position };
//     var query = flecs.Query.init(world, &query_t);
//     defer query.deinit();

//     {
//         // tester to show the same as above with struct query format
//         const Funky = struct {
//             pos_local: *const Position,
//             pos_world: *Position,
//             pos_parent: ?*const Position,

//             pub var modifiers = .{ q.PairI(Position, Local, "pos_local"), q.WriteonlyI(q.Pair(Position, World), "pos_world"), q.MaskI(q.Pair(Position, World), flecs.c.EcsParent | flecs.c.EcsCascade, "pos_parent") };
//         };
