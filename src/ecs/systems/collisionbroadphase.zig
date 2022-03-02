const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    cell: *components.Cell,
    tile: *const components.Tile,

    pub const name = "CollisionBroadphaseSystem";
    pub const run = progress;
    pub const order_by = orderBy;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    if (it.world().getSingletonMut(components.CollisionBroadphase)) |broadphase| {
        if (it.world().getSingleton(components.Grid)) |grid| {
            while (it.next()) |comps| {
                comps.cell.x = @divTrunc(comps.tile.x, grid.cellTiles);
                comps.cell.y = @divTrunc(comps.tile.y, grid.cellTiles);

                broadphase.entities.append(comps.cell.*, it.entity());
            }
        }
    }
}

fn orderBy(_: flecs.EntityId, c1: *const components.Tile, _: flecs.EntityId, c2: *const components.Tile) c_int {
    if (c1.y == c2.y){
        return @intCast(c_int, @boolToInt(c2.counter > c1.counter)) - @intCast(c_int, @boolToInt(c2.counter < c1.counter));
    } 
    return @intCast(c_int, @boolToInt(c2.y > c1.y)) - @intCast(c_int, @boolToInt(c2.y < c1.y));
}
