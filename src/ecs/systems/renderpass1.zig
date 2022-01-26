const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.term(components.Position, 1);
    //var tiles = it.term(components.Tile, 2);
    var character_renderers_optional = it.term_optional(components.CharacterRenderer, 3);
    var sprite_renderers_optional = it.term_optional(components.SpriteRenderer, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (sprite_renderers_optional) |renderers| {
            if (renderers[i].heightmap) |heightmap| {
                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], heightmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipX,
                    .flipY = renderers[i].flipY,
                });
            }
        }

        if (character_renderers_optional) |renderers| {
            if (renderers[i].heightmap) |heightmap| {
                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].body], heightmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipBody,
                });

                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].head], heightmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipHead,
                });

                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].bottom], heightmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipBody,
                });

                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].top], heightmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipBody,
                });

                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].hair], heightmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipHead,
                });
            }
        }
    }
}
