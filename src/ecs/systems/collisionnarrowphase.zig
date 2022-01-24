const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const actions = game.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var colliders = it.column(components.Collider, 1);
    var cells = it.column(components.Cell, 2);
    var broadphase = it.column(components.CollisionBroadphase, 3);
    var move_requests = it.column(components.MoveRequest, 4);
    var cooldowns = it.column(components.MovementCooldown, 5);
    var tiles = it.column(components.Tile, 6);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (colliders[i].trigger)
            continue; //we are a trigger, so ignore all collisions

        // get all possible cells around the entity
        const current_cell = cells[i];

        // collect all cells around the current_cell cell
        var all_cells = [_]components.Cell{
            current_cell,
            .{ .x = current_cell.x + 1, .y = current_cell.y }, //east
            .{ .x = current_cell.x - 1, .y = current_cell.y }, //west
            .{ .x = current_cell.x, .y = current_cell.y - 1 }, //north
            .{ .x = current_cell.x, .y = current_cell.y + 1 }, //south
            .{ .x = current_cell.x + 1, .y = current_cell.y - 1 }, //ne
            .{ .x = current_cell.x + 1, .y = current_cell.y + 1 }, //se
            .{ .x = current_cell.x - 1, .y = current_cell.y + 1 }, //sw
            .{ .x = current_cell.x - 1, .y = current_cell.y - 1 }, //nw
        };

        // iterate cells finding all possible collideable entities
        for (all_cells) |cell| {
            if (broadphase.*.entities.get(cell)) |entities| {
                for (entities.items) |other| {
                    if (other != it.entities[i]) {
                        if (world.get(other, components.Collider)) |otherCollider| {

                            // other collider is a trigger, here we could eventually add a trigger action
                            if (otherCollider.trigger)
                                continue;

                            if (world.get(other, components.Tile)) |otherTile| {
                                // collision
                                if (tiles[i].x + move_requests[i].x == otherTile.x and tiles[i].y + move_requests[i].y == otherTile.y) {
                                    // zero out move request and cooldown
                                    move_requests[i].x = 0;
                                    move_requests[i].y = 0;
                                    cooldowns[i].current = 0;
                                    cooldowns[i].end = 0;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
