const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    camera: *const components.Camera,

    pub const name = "RenderPassEnd0System";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        // end pass_0, begin the next pass
        zia.gfx.endPass();

        // render the reversed heightmap order
        zia.gfx.beginPass(.{ .color = zia.math.Color.black, .pass = comps.camera.pass_2, .trans_mat = comps.camera.transform, .shader = &game.height_shader });
    }
}
