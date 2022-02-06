const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const positions = it.term(components.Position, 1);
    const renderers = it.term(components.LightRenderer, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], renderers[i].texture, .{
            .x = positions[i].x,
            .y = positions[i].y,
        }, .{
            .color = renderers[i].color,
            .scaleX = renderers[i].size.x,
            .scaleY = renderers[i].size.y,
        });
    }
}
