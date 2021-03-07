const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const imgui = @import("imgui");

const components = lucid.components;
const actions = lucid.actions;
const sorters = lucid.sorters;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var cameras = it.column(components.Camera, 2);
    var renderqueues = it.column(components.RenderQueue, 3);

    var world = flecs.World{ .world = it.world.? };

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        const size = zia.window.size();
        const size_w = @intToFloat(f32, size.w);
        const size_h = @intToFloat(f32, size.h);

        const design_w = @intToFloat(f32, cameras[i].design_w);
        const design_h = @intToFloat(f32, cameras[i].design_h);

        var pass = zia.gfx.OffscreenPass.initWithOptions(cameras[i].design_w, cameras[i].design_h, .nearest, .clamp);

        // translate by the cameras position
        var camera_transform = zia.math.Matrix3x2.identity;
        var cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(-positions[i].x, -positions[i].y);
        camera_transform = cam_tmp.mul(camera_transform);

        // center the camera viewport
        cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(@round(pass.color_texture.width / 2), @round(pass.color_texture.height / 2));
        camera_transform = cam_tmp.mul(camera_transform);

        // scale the render texture by zoom
        var rt_transform = zia.math.Matrix3x2.identity;
        var rt_tmp = zia.math.Matrix3x2.identity;

        if (world.get(it.entities[i], components.Zoom)) |zoom| {
            //const zoom = @ptrCast(*const components.Zoom, @alignCast(@alignOf(components.Zoom), ptr));
            rt_tmp.scale(zoom.current, zoom.current);
            rt_transform = rt_tmp.mul(rt_transform);
        }

        // center the render texture
        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(size_w * 0.5, size_h * 0.5);
        rt_transform = rt_tmp.mul(rt_transform);

        // translate the camera matrix for converting screen to world
        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(-positions[i].x, -positions[i].y);
        cameras[i].trans_mat = rt_transform.mul(rt_tmp);

        // TODO!
        // pass gizmos the new matrix to render our gizmos at the correct scale
        // how do we handle multiple cameras?
        if (zia.enable_imgui)
            lucid.gizmos.setTransmat(cameras[i].trans_mat);

        // sort
        std.sort.sort(flecs.Entity, renderqueues[i].entities.items, &world, sort);

        //if (world.get(it.system, components.RenderQuery)) |renderQuery| {
        // render the camera to the render texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.dark_gray, .pass = pass, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity, j| {
            var position = world.get(entity, components.Position);

            if (world.get(entity, components.Material)) |material| {
                zia.gfx.setShader(material.shader);

                for (material.textures) |texture, k| {
                    zia.gfx.draw.bindTexture(texture.*, @intCast(c_uint, k + 1));
                }
            }

            if (world.get(entity, components.SpriteRenderer)) |renderer| {
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.color,
                    .flipX = renderer.flipX,
                    .flipY = renderer.flipY,
                });
            }

            if (world.get(entity, components.CharacterRenderer)) |renderer| {
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.bodyColor,
                    .flipX = renderer.flipHead,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.headColor,
                    .flipX = renderer.flipBody,
                });
            }

            if (world.get(entity, components.Material)) |material| {
                zia.gfx.setShader(null);

                for (material.textures) |texture, k| {
                    zia.gfx.draw.unbindTexture(@intCast(c_uint, k + 1));
                }
            }
        }
        //actions.render(renderQuery.renderers.?);
        zia.gfx.endPass();
        //}

        renderqueues[i].entities.shrinkAndFree(0);

        // center the render texture on the screen
        var rt_pos = .{ .x = @round(-pass.color_texture.width / 2), .y = @round(-pass.color_texture.height / 2) };

        // render the render texture to the back buffer
        zia.gfx.beginPass(.{ .color = zia.math.Color.zia, .trans_mat = rt_transform });

        zia.gfx.draw.texture(pass.color_texture, rt_pos, .{});
        zia.gfx.endPass();

        pass.deinit();
    }
}

// top down sort
fn sort(world: *flecs.World, lhs: flecs.Entity, rhs: flecs.Entity) bool {
    const pos1 = world.get(lhs, components.Position);
    const pos2 = world.get(rhs, components.Position);

    if (pos1.?.z == pos2.?.z) {
        if (pos1.?.y == pos2.?.y) {
            return pos1.?.x < pos2.?.x;
        } else {
            return pos1.?.y < pos2.?.y;
        }
    } else {
        return pos1.?.z < pos2.?.z;
    }
}
