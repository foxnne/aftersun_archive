const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    position: *const components.Position,
    camera: *components.Camera,
    zoom: *components.Zoom,

    pub const name = "PrerenderSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        const window_size = .{ .x = @intToFloat(f32, zia.window.size().w), .y = @intToFloat(f32, zia.window.size().h) };

        var position = .{ .x = @round(comps.position.x), .y = @round(comps.position.y) };

        // translate by the cameras position
        comps.camera.transform = zia.math.Matrix3x2.identity;
        var cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(-position.x, -position.y);
        comps.camera.transform = cam_tmp.mul(comps.camera.transform);

        // center the camera viewport
        cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(@trunc(comps.camera.size.x * 0.5), @trunc(comps.camera.size.y * 0.5));
        comps.camera.transform = cam_tmp.mul(comps.camera.transform);

        // scale the render texture by zoom
        comps.camera.rt_transform = zia.math.Matrix3x2.identity;
        var rt_tmp = zia.math.Matrix3x2.identity;

        rt_tmp.scale(comps.zoom.current, comps.zoom.current);
        comps.camera.rt_transform = rt_tmp.mul(comps.camera.rt_transform);

        // center the render texture
        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(@trunc(window_size.x * 0.5), @trunc(window_size.y * 0.5));
        comps.camera.rt_transform = rt_tmp.mul(comps.camera.rt_transform);

        // translate the camera matrix for converting screen to world
        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(-position.x, -position.y);
        comps.camera.matrix = comps.camera.rt_transform.mul(rt_tmp);

        // center the render texture on the screen
        comps.camera.rt_position = .{ .x = @trunc(-comps.camera.size.x * 0.5), .y = @trunc(-comps.camera.size.y * 0.5) };

        // bind the heightmap and palette
        zia.gfx.draw.bindTexture(game.heightmap, 1);
        zia.gfx.draw.bindTexture(game.palette, 2);

        // render the camera to the render texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.fromRgbBytes(80, 84, 42), .pass = comps.camera.pass_0, .trans_mat = comps.camera.transform, .shader = &game.uber_shader });
    }
}
