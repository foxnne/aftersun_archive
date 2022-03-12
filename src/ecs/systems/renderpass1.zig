const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;

pub const Callback = struct {
    position: *const components.Position,
    character_renderer: ?*const components.CharacterRenderer,
    sprite_renderer: ?*const components.SpriteRenderer,

    pub const name = "RenderPass1System";
    pub const run = progress;
    pub const modifiers = .{ flecs.queries.Filter(components.Tile), flecs.queries.Filter(components.Visible) };
    pub const order_by = orderBy;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.sprite_renderer) |renderer| {
            zia.gfx.draw.sprite(game.atlas.sprites[renderer.index], game.heightmap, .{
                .x = comps.position.x,
                .y = comps.position.y,
            }, .{
                .flipX = renderer.flipX,
                .flipY = renderer.flipY,
            });
        }

        if (comps.character_renderer) |renderer| {
            zia.gfx.draw.sprite(game.atlas.sprites[renderer.bodyIndex], game.heightmap, .{
                .x = comps.position.x,
                .y = comps.position.y,
            }, .{
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.headIndex], game.heightmap, .{
                .x = comps.position.x,
                .y = comps.position.y,
            }, .{
                .flipX = renderer.flipHead,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.bottomIndex], game.heightmap, .{
                .x = comps.position.x,
                .y = comps.position.y,
            }, .{
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.topIndex], game.heightmap, .{
                .x = comps.position.x,
                .y = comps.position.y,
            }, .{
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.hairIndex], game.heightmap, .{
                .x = comps.position.x,
                .y = comps.position.y,
            }, .{
                .flipX = renderer.flipHead,
            });
        }
    }
}

fn orderBy(id1: flecs.EntityId, c1: *const components.Position, id2: flecs.EntityId, c2: *const components.Position) c_int {
    if (c1.y == c2.y) {
        var e1 = flecs.Entity.init(game.world.world, id1);
        var e2 = flecs.Entity.init(game.world.world, id2);

        var counter1 = if (e1.get(components.Tile)) |tile| tile.counter else 0;
        var counter2 = if (e2.get(components.Tile)) |tile| tile.counter else 0;
        return @intCast(c_int, @boolToInt(counter1 > counter2)) - @intCast(c_int, @boolToInt(counter1 < counter2));

    }
    return @intCast(c_int, @boolToInt(c1.y > c2.y)) - @intCast(c_int, @boolToInt(c1.y < c2.y));
}
