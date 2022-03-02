const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;

pub const Callback = struct {
    position: *const components.Position,
    material: ?*const components.Material,
    character_renderer: ?*const components.CharacterRenderer,
    sprite_renderer: ?*const components.SpriteRenderer,
    particle_renderer: ?*const components.ParticleRenderer,

    pub const name = "RenderPass0System";
    pub const run = progress;
    pub const modifiers = .{ flecs.queries.Filter(components.Tile) };
    pub const order_by = orderBy;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.material) |material| {
            zia.gfx.setShader(material.shader);

            if (material.textures) |textures| {
                for (textures) |texture, k| {
                    zia.gfx.draw.bindTexture(texture.*, @intCast(c_uint, k + 1));
                }
            }
        }

        if (comps.sprite_renderer) |renderer| {
            zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], renderer.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.color,
                .flipX = renderer.flipX,
                .flipY = renderer.flipY,
            });
        }

        if (comps.character_renderer) |renderer| {
            zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], renderer.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.headColor,
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], renderer.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.bodyColor,
                .flipX = renderer.flipHead,
            });

            zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.bottom], renderer.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.bottomColor,
                .flipX = renderer.flipBody,
            });
 
            zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.top], renderer.texture, .{
                .x = comps.position.x,
                .y = comps.position.y - @intToFloat(f32, comps.position.z),
            }, .{
                .color = renderer.topColor,
                .flipX = renderer.flipBody,
            });

            zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.hair], renderer.texture, .{
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
                    zia.gfx.draw.sprite(renderer.atlas.sprites[particle.sprite_index], renderer.texture, particle.position, .{
                        .color = particle.color,
                    });
                }
            }
        }

        if (comps.material) |material| {
            zia.gfx.draw.batcher.flush();
            zia.gfx.setShader(null);

            if (material.textures) |textures| {
                for (textures) |_, k| {
                    zia.gfx.draw.unbindTexture(@intCast(c_uint, k + 1));
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
                // else => {},
            }
        }
        game.gizmos.gizmos.shrinkAndFree(0);
    }
}

fn orderBy(_: flecs.EntityId, c1: *const components.Tile, _: flecs.EntityId, c2: *const components.Tile) c_int {
    if (c1.y == c2.y){
        return @intCast(c_int, @boolToInt(c1.counter > c2.counter)) - @intCast(c_int, @boolToInt(c1.counter < c2.counter));
    } 
    return @intCast(c_int, @boolToInt(c1.y > c2.y)) - @intCast(c_int, @boolToInt(c1.y < c2.y));
}