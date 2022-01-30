const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const cameras = it.term(components.Camera, 1);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        // end pass_0, begin the next pass
        zia.gfx.endPass();

        // render the heightmaps to the heightmap texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.fromRgbBytes(0, 0, 0), .pass = cameras[i].pass_1, .trans_mat = cameras[i].transform });
    }
}