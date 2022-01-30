const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const positions = it.term(components.Position, 1);
    //var tiles = it.term(components.Tile, 2);
    const character_renderers_optional = it.term_optional(components.CharacterRenderer, 3);
    const sprite_renderers_optional = it.term_optional(components.SpriteRenderer, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (sprite_renderers_optional) |renderers| {
            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y,
            }, .{
                .flipX = renderers[i].flipX,
                .flipY = renderers[i].flipY,
                .color = zia.math.Color.black,
            });
            if (renderers[i].emissionmap) |emissionmap| {
                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], emissionmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipX,
                    .flipY = renderers[i].flipY,
                });
            }
        }

        if (character_renderers_optional) |renderers| {
            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].body], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y,
            }, .{
                .flipX = renderers[i].flipBody,
                .color = zia.math.Color.black,
            });

            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].head], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y,
            }, .{
                .flipX = renderers[i].flipHead,
                .color = zia.math.Color.black,
            });

            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].hair], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y,
            }, .{
                .flipX = renderers[i].flipHead,
                .color = zia.math.Color.black,
            });

            if (renderers[i].emissionmap) |emissionmap| {
                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].body], emissionmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipBody,
                });

                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].head], emissionmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipHead,
                });

                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].hair], emissionmap, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipHead,
                });
            }
        }
    }
}
