const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    camera: *const components.Camera,
    environment: *const components.Environment,

    pub const name = "RenderEndSystem";
    pub const run = progress;
};  

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        zia.gfx.endPass();

        game.environment_shader.frag_uniform.tex_width = comps.camera.size.x;
        game.environment_shader.frag_uniform.tex_height = comps.camera.size.y;

        // render the environment, sun and sunshadows
        zia.gfx.beginPass(.{ .color = zia.math.Color.white, .pass = comps.camera.pass_3, .shader = &game.environment_shader.shader });
        zia.gfx.draw.bindTexture(comps.camera.pass_0.color_texture2.?, 1);
        zia.gfx.draw.bindTexture(comps.camera.pass_2.color_texture, 2);
        zia.gfx.draw.texture(comps.camera.pass_0.color_texture, .{}, .{ .color = comps.environment.ambient_color });
        zia.gfx.endPass();
        zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);

        game.finalize_shader.frag_uniform.texel_size = 8;
        game.finalize_shader.frag_uniform.tex_size_x = comps.camera.size.x;
        game.finalize_shader.frag_uniform.tex_size_y = comps.camera.size.y;

        zia.gfx.beginPass(.{ .pass = comps.camera.pass_4, .shader = &game.finalize_shader.shader });
        zia.gfx.draw.bindTexture(comps.camera.pass_3.color_texture, 1);
        zia.gfx.draw.texture(comps.camera.pass_0.color_texture, .{}, .{});
        zia.gfx.endPass();
        zia.gfx.draw.unbindTexture(1);

        game.tiltshift_shader.frag_uniform.blur_amount = 1;

        zia.gfx.beginPass(.{ .pass = comps.camera.pass_1, .shader = &game.tiltshift_shader.shader });
        zia.gfx.draw.texture(comps.camera.pass_4.color_texture, .{}, .{});
        zia.gfx.endPass();

        // render the result image to the back buffer
        zia.gfx.beginPass(.{ .trans_mat = comps.camera.rt_transform });
        switch (game.render_mode) {
            .diffuse => zia.gfx.draw.texture(comps.camera.pass_1.color_texture, comps.camera.rt_position, .{}),
            .height => zia.gfx.draw.texture(comps.camera.pass_0.color_texture2.?, comps.camera.rt_position, .{})
        }

        
        zia.gfx.endPass();
    }
}
