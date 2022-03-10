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
    pub const modifiers = .{ flecs.queries.Filter(components.Tile), flecs.queries.Filter(components.Visible)};
    pub const order_by = orderBy;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.sprite_renderer) |renderer| {
            if (renderer.heightmap) |heightmap| {
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], heightmap, .{
                    .x = comps.position.x,
                    .y = comps.position.y,
                }, .{
                    .flipX = renderer.flipX,
                    .flipY = renderer.flipY,
                });
            }
        }

        if (comps.character_renderer) |renderer| {
            if (renderer.heightmap) |heightmap| {
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], heightmap, .{
                    .x = comps.position.x,
                    .y = comps.position.y,
                }, .{
                    .flipX = renderer.flipBody,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], heightmap, .{
                    .x = comps.position.x,
                    .y = comps.position.y,
                }, .{
                    .flipX = renderer.flipHead,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.bottom], heightmap, .{
                    .x = comps.position.x,
                    .y = comps.position.y,
                }, .{
                    .flipX = renderer.flipBody,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.top], heightmap, .{
                    .x = comps.position.x,
                    .y = comps.position.y,
                }, .{
                    .flipX = renderer.flipBody,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.hair], heightmap, .{
                    .x = comps.position.x,
                    .y = comps.position.y,
                }, .{
                    .flipX = renderer.flipHead,
                });
            }
        }
    }
}

fn orderBy(_: flecs.EntityId, c1: *const components.Tile, _: flecs.EntityId, c2: *const components.Tile) c_int {
    if (c1.y == c2.y){
        return @intCast(c_int, @boolToInt(c1.counter > c2.counter)) - @intCast(c_int, @boolToInt(c1.counter < c2.counter));
    } 
    return @intCast(c_int, @boolToInt(c1.y > c2.y)) - @intCast(c_int, @boolToInt(c1.y < c2.y));
}
