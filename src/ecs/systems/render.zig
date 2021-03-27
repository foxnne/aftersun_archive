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
    var postprocesses = it.column(components.PostProcess, 3);
    var renderqueues = it.column(components.RenderQueue, 4);
    var environments = it.column(components.Environment, 5);

    var world = flecs.World{ .world = it.world.? };

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        const size = zia.window.size();
        const size_w = @intToFloat(f32, size.w);
        const size_h = @intToFloat(f32, size.h);

        const design_w = @intToFloat(f32, cameras[i].design_w);
        const design_h = @intToFloat(f32, cameras[i].design_h);

        environments[i].environment_shader.frag_uniform.tex_width = design_w;
        environments[i].environment_shader.frag_uniform.tex_height = design_h;

        var main_pass = zia.gfx.OffscreenPass.initWithOptions(cameras[i].design_w, cameras[i].design_h, .linear, .clamp);
        defer main_pass.deinit();
        var height_pass = zia.gfx.OffscreenPass.initWithOptions(cameras[i].design_w, cameras[i].design_h, .nearest, .clamp);
        defer height_pass.deinit();
        var light_pass = zia.gfx.OffscreenPass.initWithOptions(cameras[i].design_w, cameras[i].design_h, .linear, .clamp);
        defer light_pass.deinit();
        var emission_pass = zia.gfx.OffscreenPass.initWithOptions(cameras[i].design_w, cameras[i].design_h, .linear, .clamp);
        defer emission_pass.deinit();
        var environment_pass = zia.gfx.OffscreenPass.initWithOptions(cameras[i].design_w, cameras[i].design_h, .linear, .clamp);
        defer environment_pass.deinit();

        // translate by the cameras position
        var camera_transform = zia.math.Matrix3x2.identity;
        var cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(-positions[i].x, -positions[i].y);
        camera_transform = cam_tmp.mul(camera_transform);

        // center the camera viewport
        cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(@round(main_pass.color_texture.width / 2), @round(main_pass.color_texture.height / 2));
        camera_transform = cam_tmp.mul(camera_transform);

        // scale the render texture by zoom
        var rt_transform = zia.math.Matrix3x2.identity;
        var rt_tmp = zia.math.Matrix3x2.identity;

        if (world.get(it.entities[i], components.Zoom)) |zoom| {
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

        // center the render texture on the screen
        var rt_pos = .{ .x = @round(-main_pass.color_texture.width / 2), .y = @round(-main_pass.color_texture.height / 2) };

        // TODO!
        // pass gizmos the new matrix to render our gizmos at the correct scale
        // how do we handle multiple cameras?
        if (zia.enable_imgui)
            lucid.gizmos.setTransmat(cameras[i].trans_mat);

        // sort
        std.sort.sort(flecs.Entity, renderqueues[i].entities.items, &world, sort);

        // render the camera to the render texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.dark_gray, .pass = main_pass, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity, j| {
            var position = world.get(entity, components.Position);

            if (world.get(entity, components.Material)) |material| {
                zia.gfx.setShader(material.shader);

                if (material.textures) |textures| {
                    for (textures) |texture, k| {
                        zia.gfx.draw.bindTexture(texture.*, @intCast(c_uint, k + 1));
                    }
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
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.headColor,
                    .flipX = renderer.flipBody,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.bodyColor,
                    .flipX = renderer.flipHead,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.hair], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.hairColor,
                    .flipX = renderer.flipHead,
                });
            }

            if (world.get(entity, components.Material)) |material| {
                zia.gfx.draw.batcher.flush();
                zia.gfx.setShader(null);

                if (material.textures) |textures| {
                    for (textures) |texture, k| {
                        zia.gfx.draw.unbindTexture(@intCast(c_uint, k + 1));
                    }
                }
            }
        }
        zia.gfx.endPass();

        // render the heightmaps to the heightmap texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.black, .pass = height_pass, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity, j| {
            var position = world.get(entity, components.Position);

            if (world.get(entity, components.SpriteRenderer)) |renderer| {
                if (renderer.heightmap) |heightmap| {
                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], heightmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipX,
                        .flipY = renderer.flipY,
                    });
                }
            }

            if (world.get(entity, components.CharacterRenderer)) |renderer| {
                if (renderer.heightmap) |heightmap| {
                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], heightmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipBody,
                    });

                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], heightmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipHead,
                    });

                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.hair], heightmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipHead,
                    });
                }
            }
        }
        zia.gfx.endPass();

        // render the lightmaps to the lightmap texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.transparent, .pass = light_pass, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity, j| {
            var position = world.get(entity, components.Position);

            if (world.get(entity, components.LightRenderer)) |renderer| {
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.color,
                });
            }
        }
        zia.gfx.endPass();

        // render the emission maps to the emission texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.black, .pass = emission_pass, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity, j| {
            var position = world.get(entity, components.Position);

            if (world.get(entity, components.SpriteRenderer)) |renderer| {
                if (renderer.emissionmap) |emissionmap| {
                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], emissionmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipX,
                        .flipY = renderer.flipY,
                    });
                }
            }

            // if (world.get(entity, components.CharacterRenderer)) |renderer| {
            //     if (renderer.heightmap) |heightmap| {
            //         zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], heightmap, .{
            //             .x = position.?.x,
            //             .y = position.?.y,
            //         }, .{
            //             .flipX = renderer.flipBody,
            //         });

            //         zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], heightmap, .{
            //             .x = position.?.x,
            //             .y = position.?.y,
            //         }, .{
            //             .flipX = renderer.flipHead,
            //         });

            //         zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.hair], heightmap, .{
            //             .x = position.?.x,
            //             .y = position.?.y,
            //         }, .{
            //             .flipX = renderer.flipHead,
            //         });
            //     }
            // }
        }
        zia.gfx.endPass();

        renderqueues[i].entities.shrinkAndFree(0);

        // render the environment, sun and sunshadows
        zia.gfx.beginPass(.{ .color = zia.math.Color.white, .pass = environment_pass, .shader = &environments[i].environment_shader.shader });
        zia.gfx.draw.bindTexture(height_pass.color_texture, 1);
        zia.gfx.draw.bindTexture(light_pass.color_texture, 2);
        zia.gfx.draw.texture(main_pass.color_texture, .{}, .{ .color = environments[i].sun_color });
        zia.gfx.endPass();
        zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);

        // render the main pass combining other passes and postprocess
        zia.gfx.beginPass(.{ .trans_mat = rt_transform, .shader = &postprocesses[i].shader.shader });
        zia.gfx.draw.bindTexture(emission_pass.color_texture, 1);
        zia.gfx.draw.bindTexture(environment_pass.color_texture, 2);
        zia.gfx.draw.texture(main_pass.color_texture, rt_pos, .{});
        zia.gfx.endPass();
        zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);        
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
