const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const cameras = it.term(components.Camera, 1);
    const postprocesses = it.term(components.PostProcess, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        
        // end pass 3
        //zia.gfx.draw.unbindTexture(1);
        //zia.gfx.endPass();

        // postprocesses[i].bloom_shader.frag_uniform.tex_size_x = cameras[i].size.x;
        // postprocesses[i].bloom_shader.frag_uniform.tex_size_y = cameras[i].size.y;
        // postprocesses[i].bloom_shader.frag_uniform.horizontal = 1;
        // postprocesses[i].bloom_shader.frag_uniform.multiplier = 1.2;

        // zia.gfx.beginPass(.{ .color = zia.math.Color.black, .pass = cameras[i].pass_2, .shader = &postprocesses[i].bloom_shader.shader });
        // zia.gfx.draw.texture(cameras[i].pass_1.color_texture, .{}, .{});
        // zia.gfx.endPass();

        // postprocesses[i].bloom_shader.frag_uniform.horizontal = 0;

        // zia.gfx.beginPass(.{ .color = zia.math.Color.black, .pass = cameras[i].pass_4, .shader = &postprocesses[i].bloom_shader.shader });
        // zia.gfx.draw.texture(cameras[i].pass_2.color_texture, .{}, .{});
        // zia.gfx.endPass();

        postprocesses[i].finalize_shader.frag_uniform.texel_size = 8;
        postprocesses[i].finalize_shader.frag_uniform.tex_size_x = cameras[i].size.x;
        postprocesses[i].finalize_shader.frag_uniform.tex_size_y = cameras[i].size.y;

        zia.gfx.beginPass(.{ .pass = cameras[i].pass_5, .shader = &postprocesses[i].finalize_shader.shader });
        //zia.gfx.draw.bindTexture(cameras[i].pass_4.color_texture, 1);
        zia.gfx.draw.bindTexture(cameras[i].pass_3.color_texture, 2);
        zia.gfx.draw.texture(cameras[i].pass_0.color_texture, .{}, .{});
        zia.gfx.endPass();
        //zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);

        postprocesses[i].tiltshift_shader.frag_uniform.blur_amount = 1;

        zia.gfx.beginPass(.{ .pass = cameras[i].pass_1, .shader = &postprocesses[i].tiltshift_shader.shader });
        zia.gfx.draw.texture(cameras[i].pass_5.color_texture, .{}, .{});
        zia.gfx.endPass();

        // render the result image to the back buffer
        zia.gfx.beginPass(.{ .trans_mat = cameras[i].rt_transform });
        zia.gfx.draw.texture(cameras[i].pass_1.color_texture, cameras[i].rt_position, .{});
        zia.gfx.endPass();
    }
}
