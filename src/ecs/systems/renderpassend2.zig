const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var cameras = it.term(components.Camera, 1);
    var environments = it.term(components.Environment, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        zia.gfx.endPass();

        environments[i].environment_shader.frag_uniform.tex_width = cameras[i].size.x;
        environments[i].environment_shader.frag_uniform.tex_height = cameras[i].size.y;

        // render the environment, sun and sunshadows
        zia.gfx.beginPass(.{ .color = zia.math.Color.white, .pass = cameras[i].pass_3, .shader = &environments[i].environment_shader.shader });
        zia.gfx.draw.bindTexture(cameras[i].pass_1.color_texture, 1);
        zia.gfx.draw.bindTexture(cameras[i].pass_2.color_texture, 2);
        zia.gfx.draw.texture(cameras[i].pass_0.color_texture, .{}, .{ .color = environments[i].ambient_color });
        zia.gfx.endPass();
        zia.gfx.draw.batcher.flush();
        zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);

        // render the emission maps to the emission texture
        zia.gfx.beginPass(.{
            .color = zia.math.Color.black,
            .pass = cameras[i].pass_1,
            .trans_mat = cameras[i].transform,
        });

    }
}
