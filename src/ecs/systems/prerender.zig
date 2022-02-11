const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var positions = it.term(components.Position, 1);
        var cameras = it.term(components.Camera, 2);
        var zooms = it.term(components.Zoom, 3);
        
        const window_size = .{ .x = @intToFloat(f32, zia.window.size().w), .y = @intToFloat(f32, zia.window.size().h) };

        var position = .{ .x = @round(positions[i].x), .y = @round(positions[i].y) };

        // translate by the cameras position
        cameras[i].transform = zia.math.Matrix3x2.identity;
        var cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(-position.x, -position.y);
        cameras[i].transform = cam_tmp.mul(cameras[i].transform);

        // center the camera viewport
        cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(@trunc(cameras[i].size.x * 0.5), @trunc(cameras[i].size.y * 0.5));
        cameras[i].transform = cam_tmp.mul(cameras[i].transform);

        // scale the render texture by zoom
        cameras[i].rt_transform = zia.math.Matrix3x2.identity;
        var rt_tmp = zia.math.Matrix3x2.identity;

        rt_tmp.scale(zooms[i].current, zooms[i].current);
        cameras[i].rt_transform = rt_tmp.mul(cameras[i].rt_transform);

        // center the render texture
        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(@trunc(window_size.x * 0.5), @trunc(window_size.y * 0.5));
        cameras[i].rt_transform = rt_tmp.mul(cameras[i].rt_transform);

        // translate the camera matrix for converting screen to world
        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(-position.x, -position.y);
        cameras[i].matrix = cameras[i].rt_transform.mul(rt_tmp);

        // center the render texture on the screen
        cameras[i].rt_position = .{ .x = @trunc(-cameras[i].size.x * 0.5), .y = @trunc(-cameras[i].size.y * 0.5) };

        // render the camera to the render texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.fromRgbBytes(70, 84, 72), .pass = cameras[i].pass_0, .trans_mat = cameras[i].transform });
    }
}
