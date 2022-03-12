const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;

pub const Callback = struct {
    position: *const components.Position,
    character_renderer: ?*const components.CharacterRenderer,
    sprite_renderer: ?*const components.SpriteRenderer,
    particle_renderer: ?*const components.ParticleRenderer,

    pub const name = "RenderPass0System";
    pub const run = progress;
    pub const modifiers = .{ flecs.queries.Filter(components.Tile), flecs.queries.Filter(components.Visible) };
    pub const order_by = orderBy;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        
        if (comps.sprite_renderer) |renderer| {
            zia.gfx.draw.sprite(game.atlas.sprites[renderer.index], game.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.color,
                .flipX = renderer.flipX,
                .flipY = renderer.flipY,
            });
        }

        if (comps.character_renderer) |renderer| {

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.bodyIndex], game.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.headColor,
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.headIndex], game.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.bodyColor,
                .flipX = renderer.flipHead,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.bottomIndex], game.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.bottomColor,
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.topIndex], game.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.topColor,
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(game.atlas.sprites[renderer.hairIndex], game.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.hairColor,
                .flipX = renderer.flipHead,
            });
        }

        if (comps.particle_renderer) |renderer| {
            for (renderer.particles) |particle| {
                if (particle.alive) {
                    zia.gfx.draw.sprite(game.atlas.sprites[particle.sprite_index], game.texture, particle.position, .{
                        .color = particle.color,
                    });
                }
            }
        }
    }

    if (game.gizmos.enabled) {
        for (game.gizmos.gizmos.items) |gizmo| {
            switch (gizmo.shape) {
                .line => {
                    zia.gfx.draw.line(gizmo.shape.line.start, gizmo.shape.line.end, gizmo.shape.line.thickness, gizmo.shape.line.color);
                },
                .box => {
                    zia.gfx.draw.hollowRect(gizmo.shape.box.position, gizmo.shape.box.width, gizmo.shape.box.height, gizmo.shape.box.thickness, gizmo.shape.box.color);
                },
                .circle => {
                    zia.gfx.draw.circle(gizmo.shape.circle.position, gizmo.shape.circle.radius, gizmo.shape.circle.thickness, 10, gizmo.shape.circle.color);
                },
            }
        }
        game.gizmos.gizmos.shrinkAndFree(0);
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
