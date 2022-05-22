const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    camera: *const components.Camera,

    pub const name = "RenderPassEnd1System";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        // end pass_0, begin the next pass
        zia.gfx.endPass();

        // unbind the heightmap and palette
        zia.gfx.draw.unbindTexture(1);
        // zia.gfx.draw.unbindTexture(2);

        // render the lightmaps to the lightmap texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.transparent, .pass = comps.camera.pass_1, .trans_mat = comps.camera.transform });
    }
}
