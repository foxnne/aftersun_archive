const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    //var world = flecs.World{ .world = it.world.? };
    var positions = it.term(components.Position, 1);
    //var tiles = it.term(components.Tile, 2);
    var materials_optional = it.term_optional(components.Material, 3);
    var character_renderers_optional = it.term_optional(components.CharacterRenderer, 4);
    var sprite_renderers_optional = it.term_optional(components.SpriteRenderer, 5);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (materials_optional) |materials| {
            zia.gfx.setShader(materials[i].shader);

            if (materials[i].textures) |textures| {
                for (textures) |texture, k| {
                    zia.gfx.draw.bindTexture(texture.*, @intCast(c_uint, k + 1));
                }
            }
        }

        if (sprite_renderers_optional) |renderers| {
            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y - @intToFloat(f32, positions[i].z),
            }, .{
                .color = renderers[i].color,
                .flipX = renderers[i].flipX,
                .flipY = renderers[i].flipY,
            });
        }

        if (character_renderers_optional) |renderers| {
            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].body], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y - @intToFloat(f32, positions[i].z),
            }, .{
                .color = renderers[i].headColor,
                .flipX = renderers[i].flipBody,
            });

            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].head], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y - @intToFloat(f32, positions[i].z),
            }, .{
                .color = renderers[i].bodyColor,
                .flipX = renderers[i].flipHead,
            });

            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].bottom], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y - @intToFloat(f32, positions[i].z),
            }, .{
                .color = renderers[i].bottomColor,
                .flipX = renderers[i].flipBody,
            });

            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].top], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y - @intToFloat(f32, positions[i].z),
            }, .{
                .color = renderers[i].topColor,
                .flipX = renderers[i].flipBody,
            });

            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].hair], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y - @intToFloat(f32, positions[i].z),
            }, .{
                .color = renderers[i].hairColor,
                .flipX = renderers[i].flipHead,
            });
        }

        if (materials_optional) |materials| {
            zia.gfx.draw.batcher.flush();
            zia.gfx.setShader(null);

            if (materials[i].textures) |textures| {
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
