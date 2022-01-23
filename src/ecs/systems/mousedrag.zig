const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    const mousedrags = it.column(components.MouseDrag, 1);
    const broadphase = it.column(components.Broadphase, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (world.get(game.player, components.Tile)) |player_tile| {
            var distance_x = std.math.absInt(mousedrags[i].prev_x - player_tile.x) catch unreachable;
            var distance_y = std.math.absInt(mousedrags[i].prev_y - player_tile.y) catch unreachable;

            if (distance_x <= 1 and distance_y <= 1) {
                if (world.get(game.player, components.Collider)) |self_collider| {

                    // get all possible cells around the entity
                    const current_cell = self_collider.cell;

                    // collect all cells around the current_cell cell
                    var cells = [_]components.Grid.Cell{
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

                    var move: bool = false;
                    var index: usize = 0;
                    var cell: components.Grid.Cell = .{};

                    for (cells) |c| {
                        if (broadphase.*.entities.get(c)) |entities| {
                            for (entities.items) |other, j| {
                                if (other == game.player)
                                    continue;

                                if (world.get(other, components.Tile)) |otherTile| {
                                    // collision
                                    if (mousedrags[i].prev_x == otherTile.x and mousedrags[i].prev_y == otherTile.y) {
                                        if (world.hasFlag(other, components.Moveable)) {
                                            move = true;
                                            cell = c;
                                            index = j;
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    if (move) {
                        for (cells) |c| {
                            if (broadphase.*.entities.get(c)) |entities| {
                                for (entities.items) |other| {
                                    if (world.get(other, components.Tile)) |otherTile| {
                                        if (world.get(other, components.Collider)) |otherCollider| {
                                            // collision
                                            if (mousedrags[i].x == otherTile.x and mousedrags[i].y == otherTile.y) {
                                                if (!otherCollider.trigger and other != game.player)
                                                    move = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if (move) {
                        if (broadphase.*.entities.get(cell)) |entities| {
                            if (world.getMut(entities.items[index], components.Tile)) |moveTile| {
                                moveTile.x = mousedrags[i].x;
                                moveTile.y = mousedrags[i].y;

                                if (world.getMut(entities.items[index], components.Position)) |movePosition| {
                                    movePosition.x = @intToFloat(f32, moveTile.x * game.ppu);
                                    movePosition.y = @intToFloat(f32, moveTile.y * game.ppu);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    world.removeSingleton(components.MouseDrag);
}
