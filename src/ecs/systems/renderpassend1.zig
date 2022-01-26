const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var cameras = it.term(components.Camera, 1);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        // end pass_0, begin the next pass
        zia.gfx.endPass();

        // render the lightmaps to the lightmap texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.transparent, .pass = cameras[i].pass_2, .trans_mat = cameras[i].transform });
    }
}
