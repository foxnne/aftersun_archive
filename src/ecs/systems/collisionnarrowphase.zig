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
            if (it.entity().get(components.Collider)) |self_collider| {
                if (self_collider.trigger)
                    continue;
            }

            if (it.entity().get(components.Tile)) |self_tile| {
                const target_cell = components.Cell{ .x = @divTrunc(self_tile.x + comps.move_request.x, game.cell_size), .y = @divTrunc(self_tile.y + comps.move_request.y, game.cell_size) };

                var cell_term = flecs.Term(components.Cell).init(it.world());
                var cell_it = cell_term.iterator();

                while (cell_it.next()) |cell| {
                    if (cell.x == target_cell.x and cell.y == target_cell.y) {
                        const TileCallback = struct {
                            tile: *const components.Tile,
                            collider: *const components.Collider,
                        };

                        var tile_filter = it.world().filterParent(TileCallback, cell_it.entity());
                        defer tile_filter.deinit();

                        var tile_it = tile_filter.iterator(TileCallback);
                        while (tile_it.next()) |tiles| {
                            if (self_tile.x + comps.move_request.x == tiles.tile.x and self_tile.y + comps.move_request.y == tiles.tile.y) {
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
