const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    camera: *const components.Camera,
    environment: *const components.Environment,

    pub const name = "RenderPassEnd2System";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        zia.gfx.endPass();

        comps.environment.environment_shader.frag_uniform.tex_width = comps.camera.size.x;
        comps.environment.environment_shader.frag_uniform.tex_height = comps.camera.size.y;

        // render the environment, sun and sunshadows
        zia.gfx.beginPass(.{ .color = zia.math.Color.white, .pass = comps.camera.pass_3, .shader = &comps.environment.environment_shader.shader });
        zia.gfx.draw.bindTexture(comps.camera.pass_1.color_texture, 1);
        zia.gfx.draw.bindTexture(comps.camera.pass_2.color_texture, 2);
        zia.gfx.draw.texture(comps.camera.pass_0.color_texture, .{}, .{ .color = comps.environment.ambient_color });
        zia.gfx.endPass();
        zia.gfx.draw.batcher.flush();
        zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);

    }
}
