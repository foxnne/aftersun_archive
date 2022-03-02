const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    pub const name = "MouseDragSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    var world = it.world();

    if (world.getSingleton(components.MouseDrag)) |mouse_drag| {
        if (world.getSingleton(components.CollisionBroadphase)) |broadphase| {
            while (it.next()) |_| {
                if (game.player.get(components.Tile)) |player_tile| {
                    var distance_x = std.math.absInt(mouse_drag.prev_x - player_tile.x) catch unreachable;
                    var distance_y = std.math.absInt(mouse_drag.prev_y - player_tile.y) catch unreachable;

                    if (distance_x <= 1 and distance_y <= 1) {
                        if (game.player.get(components.Cell)) |self_cell| {
                            // collect all cells around the current_cell cell

                            const current_cell = self_cell.*;

                            var cells = [_]components.Cell{
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
                            var cell: components.Cell = .{};

                            for (cells) |c| {
                                if (broadphase.entities.get(c)) |entities| {
                                    for (entities.items) |other, j| {
                                        if (other.id == game.player.id)
                                            continue;

                                        if (other.get(components.Tile)) |otherTile| {
                                            // collision
                                            if (mouse_drag.prev_x == otherTile.x and mouse_drag.prev_y == otherTile.y) {
                                                if (other.has(components.Moveable)) {
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
                                    if (broadphase.entities.get(c)) |entities| {
                                        for (entities.items) |other| {
                                            if (other.get(components.Tile)) |otherTile| {
                                                if (other.get(components.Collider)) |otherCollider| {
                                                    // collision
                                                    if (mouse_drag.x == otherTile.x and mouse_drag.y == otherTile.y) {
                                                        if (!otherCollider.trigger and other.id != game.player.id)
                                                            move = false;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if (move) {
                                if (broadphase.entities.get(cell)) |entities| {
                                    if (entities.items[index].get(components.Tile)) |_| {
                                        if (entities.items[index].get(components.PreviousTile)) |_| {
                                            //prev_tile.x = moveTile.x;
                                            //prev_tile.y = moveTile.y;
                                            if (entities.items[index].get(components.TossCooldown)) |_| {
                                                //cooldown.current = 0;
                                                //cooldown.end = 0.2;
                                            }
                                        }

                                        //moveTile.x = mouse_drag.x;
                                        //moveTile.y = mouse_drag.y;
                                        //moveTile.counter = game.getCounter();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            world.removeSingleton(components.MouseDrag);
        }
    }
}
