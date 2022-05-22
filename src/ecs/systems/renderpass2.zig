const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    position: *const components.Position,
    renderer: *const components.LightRenderer,

    pub const name = "RenderPass2System";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.renderer.active)
            zia.gfx.draw.sprite(game.light_atlas.sprites[comps.renderer.index], game.light_texture, .{
                .x = comps.position.x + comps.renderer.offset.x,
                .y = comps.position.y + comps.renderer.offset.y,
            }, .{
                .color = comps.renderer.color,
                .scaleX = comps.renderer.size.x,
                .scaleY = comps.renderer.size.y,
            });
    }
}
