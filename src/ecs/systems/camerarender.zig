const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");
const actions = @import("../actions/actions.zig");
const sorters = @import("../sorters/sorters.zig");

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var cameras = it.column(components.Camera, 2);

    var world = flecs.World{ .world = it.world.? };

    // collect renderers
    var renderQuery = flecs.ecs_query_new(world.world, "Position, SpriteRenderer, ?Color");
    // sort renderers
    flecs.ecs_query_order_by(world.world, renderQuery, world.newComponent(components.Position), sorters.sortY);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        const size = zia.window.size();
        const size_w = @intToFloat(f32, size.w);
        const size_h = @intToFloat(f32, size.h);
        const half_w = size_w * 0.5;
        const half_h = size_h * 0.5;

        const design_w = @intToFloat(f32, cameras[i].design_w);
        const design_h = @intToFloat(f32, cameras[i].design_h);

        var pass = zia.gfx.OffscreenPass.initWithOptions(cameras[i].design_w, cameras[i].design_h, .nearest, .clamp);

        // reset the minimum zoom
        cameras[i].zoom_min = 1.0;

        // clamp zoom to always fill the screen
        if (design_w * cameras[i].zoom_min < size_w or design_h * cameras[i].zoom_min < size_h) {
            var zoom_w = @ceil(size_w / design_w);
            var zoom_h = @ceil(size_h / design_h);
            cameras[i].zoom_min = if (zoom_w > zoom_h) zoom_w else zoom_h;
        }

        if (zia.input.mouse_wheel_y > 0 and cameras[i].zoom < cameras[i].zoom_max)
            cameras[i].zoom_target = @round(cameras[i].zoom + 1.0);

        if (zia.input.mouse_wheel_y < 0 and cameras[i].zoom > cameras[i].zoom_min)
            cameras[i].zoom_target = @round(cameras[i].zoom - 1.0);

        if (cameras[i].zoom < cameras[i].zoom_target) {
            var increment = zia.time.dt() * cameras[i].zoom_speed;

            if (cameras[i].zoom_target - cameras[i].zoom > increment) {
                cameras[i].zoom += increment;
            } else {
                cameras[i].zoom = cameras[i].zoom_target;
            }
        } else {
            var increment = zia.time.dt() * cameras[i].zoom_speed;

            if (cameras[i].zoom - cameras[i].zoom_target > increment) {
                cameras[i].zoom -= increment;
            } else {
                cameras[i].zoom = cameras[i].zoom_target;
            }
        }

        // ensure that zoom is within bounds
        if (cameras[i].zoom < cameras[i].zoom_min) cameras[i].zoom = cameras[i].zoom_min;
        if (cameras[i].zoom > cameras[i].zoom_max) cameras[i].zoom = cameras[i].zoom_max;

        // center the camera viewport on the position
        var camera_transform = zia.math.Matrix3x2.identity;
        var cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(-positions[i].x + pass.color_texture.width / 2, -positions[i].y + pass.color_texture.height / 2);
        camera_transform = cam_tmp.mul(camera_transform);

        // scale and center the camera viewport
        var rt_transform = zia.math.Matrix3x2.identity;
        var rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.scale(cameras[i].zoom, cameras[i].zoom);
        rt_transform = rt_tmp.mul(rt_transform);

        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(half_w, half_h);
        rt_transform = rt_tmp.mul(rt_transform);

        // center the render texture on the screen
        var rt_pos = .{ .x = -pass.color_texture.width / 2, .y = -pass.color_texture.height / 2 };

        // render the camera to the render texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.dark_gray, .pass = pass, .trans_mat = camera_transform });
        actions.render(renderQuery);
        zia.gfx.endPass();

        // render the render texture to the back buffer
        zia.gfx.beginPass(.{ .color = zia.math.Color.zia, .trans_mat = rt_transform });
        zia.gfx.draw.texture(pass.color_texture, rt_pos, .{});
        zia.gfx.endPass();

        pass.deinit();
    }
}
