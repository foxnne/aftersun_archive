const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    collider: *const components.Collider,
    cell: *const components.Cell,
    move_request: *components.MoveRequest,
    cooldown: *components.MovementCooldown,
    tile: *components.Tile,

    pub const name = "CollisionNarrowphaseSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    if (it.world().getSingleton(components.CollisionBroadphase)) |broadphase| {
        while (it.next()) |comps| {
            if (comps.collider.trigger)
                continue; //we are a trigger, so ignore all collisions

            // get all possible cells around the entity
            const current_cell = comps.cell;

            // collect all cells around the current_cell cell
            var all_cells = [_]components.Cell{
                current_cell.*,
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
                if (broadphase.entities.get(cell)) |entities| {
                    for (entities.items) |other| {
                        if (other.id != it.entity().id) {
                            if (other.get(components.Collider)) |otherCollider| {

                                // other collider is a trigger, here we could eventually add a trigger action
                                if (otherCollider.trigger)
                                    continue;

                                if (other.get(components.Tile)) |otherTile| {
                                    // collision
                                    if (comps.tile.x + comps.move_request.x == otherTile.x and comps.tile.y + comps.move_request.y == otherTile.y) {
                                        // zero out move request and cooldown
                                        comps.move_request.x = 0;
                                        comps.move_request.y = 0;
                                        comps.cooldown.current = 0;
                                        comps.cooldown.end = 0;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
