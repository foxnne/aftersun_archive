const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    mouse_drag: *const components.MouseDrag,

    pub const name = "MouseDragSystem";
    pub const run = progress;
    pub const expr = "[out] MoveRequest(), [out] Tile()";
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        // only allow moving items nearest the player
        if (game.player.get(components.Tile)) |player_tile| {
            const dist_x = comps.mouse_drag.prev_x - player_tile.x;
            const dist_y = comps.mouse_drag.prev_y - player_tile.y;

            if (dist_x > 1 or dist_y > 1)
                return;
        }        

        const TileCallback = struct {
            tile: *const components.Tile,
            prev_tile: *components.PreviousTile,

            pub const order_by = orderBy;
        };

        var tile_query = it.world().query(TileCallback);
        defer tile_query.deinit();

        var tile_it = tile_query.iterator(TileCallback);

        while (tile_it.next()) |tiles| {
            if (tiles.tile.x == comps.mouse_drag.prev_x and tiles.tile.y == comps.mouse_drag.prev_y) {
                if (tile_it.entity().has(components.Moveable)) {
                    if (it.world().getSingleton(components.Tile)) |tile| {
                        tile_it.entity().set(&components.MoveRequest{ .x = tile.x - tiles.tile.x, .y = tile.y - tiles.tile.y });
                        tile_it.entity().set(&components.MovementCooldown{ .current = 0, .end = 0.2 });
                        break;
                    }
                }
            }
        }
    }
}

fn orderBy(_: flecs.EntityId, c1: *const components.Tile, _: flecs.EntityId, c2: *const components.Tile) c_int {
    if (c1.y == c2.y) {
        return @intCast(c_int, @boolToInt(c2.counter > c1.counter)) - @intCast(c_int, @boolToInt(c2.counter < c1.counter));
    }
    return @intCast(c_int, @boolToInt(c2.y > c1.y)) - @intCast(c_int, @boolToInt(c2.y < c1.y));
}
