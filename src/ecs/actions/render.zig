const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;

pub fn render(query: ?*flecs.ecs_query_t) void {
    var it = flecs.ecs_query_iter(query);
    while (flecs.ecs_query_next(&it)) {
        var world = flecs.World{ .world = it.world.? };
        var positions = it.column(components.Position, 1);
        //var renderers = it.column(components.SpriteRenderer, 2);

        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            //const color_ptr = world.get(it.entities[i], components.Color);

            // get material
            var material_ptr = world.get(it.entities[i], components.Material);

            // apply material shaders and textures if exists
            if (material_ptr) |material| {
                zia.gfx.setShader(material.shader);

                for (material.textures) |texture, ii| {
                    zia.gfx.draw.bindTexture(texture.*, @intCast(c_uint, ii + 1));
                }
            }

            var spriteRendererPtr = world.get(it.entities[i], components.SpriteRenderer);
            var characterRendererPtr = world.get(it.entities[i], components.CharacterRenderer);

            if (spriteRendererPtr) |renderer| {
                // draw
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], renderer.texture, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .color = renderer.color,
                    .flipX = renderer.flipX,
                    .flipY = renderer.flipY,
                });
            }

            if (characterRendererPtr) |renderer| {
                

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], renderer.texture, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .color = renderer.bodyColor,
                    .flipX = renderer.flipX,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], renderer.texture, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .color = renderer.headColor,
                    .flipX = renderer.flipX,
                });

            }

            // unset material shaders and textures
            if (material_ptr) |material| {
                zia.gfx.setShader(null);

                zia.gfx.draw.unbindTexture(1);

                for (material.textures) |texture, ii| {
                    zia.gfx.draw.unbindTexture(@intCast(c_uint, ii + 1));
                }
            }
        }
    }
}
