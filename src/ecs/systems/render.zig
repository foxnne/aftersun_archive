const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;
const actions = game.actions;
const sorters = game.sorters;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var cameras = it.column(components.Camera, 2);
    var postprocesses = it.column(components.PostProcess, 3);
    var renderqueues = it.column(components.RenderQueue, 4);
    var environments = it.column(components.Environment, 5);

    var world = flecs.World{ .world = it.world.? };

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        const window_size = .{ .x = @intToFloat(f32, zia.window.size().w), .y = @intToFloat(f32, zia.window.size().h) };

        // translate by the cameras position
        var camera_transform = zia.math.Matrix3x2.identity;
        var cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(-positions[i].x, -positions[i].y);
        camera_transform = cam_tmp.mul(camera_transform);

        // center the camera viewport
        cam_tmp = zia.math.Matrix3x2.identity;
        cam_tmp.translate(cameras[i].size.x * 0.5, cameras[i].size.y * 0.5);
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
        rt_tmp.translate(window_size.x * 0.5, window_size.y * 0.5);
        rt_transform = rt_tmp.mul(rt_transform);

        // translate the camera matrix for converting screen to world
        rt_tmp = zia.math.Matrix3x2.identity;
        rt_tmp.translate(-positions[i].x, -positions[i].y);
        cameras[i].matrix = rt_transform.mul(rt_tmp);

        // center the render texture on the screen
        var rt_pos = .{ .x = -cameras[i].size.x * 0.5, .y = -cameras[i].size.y * 0.5 };

        // sort
        std.sort.sort(flecs.Entity, renderqueues[i].entities.items, &world, sort);

        // render the camera to the render texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.dark_gray, .pass = cameras[i].pass_0, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity| {
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

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.bottom], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.bottomColor,
                    .flipX = renderer.flipBody,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.top], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .color = renderer.topColor,
                    .flipX = renderer.flipBody,
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
                    for (textures) |_, k| {
                        zia.gfx.draw.unbindTexture(@intCast(c_uint, k + 1));
                    }
                }
            }
        }

        if (game.gizmos.enabled) {
            for (game.gizmos.gizmos.items) |gizmo| {
                switch (gizmo.shape) {
                    .line => {
                        zia.gfx.draw.line(gizmo.shape.line.start, gizmo.shape.line.end, gizmo.shape.line.thickness, gizmo.shape.line.color);
                    },
                    .box => {
                        zia.gfx.draw.hollowRect(gizmo.shape.box.position, gizmo.shape.box.width, gizmo.shape.box.height, gizmo.shape.box.thickness, gizmo.shape.box.color);
                    },
                    .circle => {
                        zia.gfx.draw.circle(gizmo.shape.circle.position, gizmo.shape.circle.radius, gizmo.shape.circle.thickness, 10, gizmo.shape.circle.color);
                    },
                    // else => {},
                }
            }
            game.gizmos.gizmos.shrinkAndFree(0);
        }

        zia.gfx.endPass();

        // render the heightmaps to the heightmap texture
        zia.gfx.beginPass(.{ .color = zia.math.Color.fromRgbBytes(0, 0, 0), .pass = cameras[i].pass_1, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity| {
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

                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.bottom], heightmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipBody,
                    });

                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.top], heightmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipBody,
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
        zia.gfx.beginPass(.{ .color = zia.math.Color.transparent, .pass = cameras[i].pass_2, .trans_mat = camera_transform });

        for (renderqueues[i].entities.items) |entity| {
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

        environments[i].environment_shader.frag_uniform.tex_width = cameras[i].size.x;
        environments[i].environment_shader.frag_uniform.tex_height = cameras[i].size.y;

        // render the environment, sun and sunshadows
        zia.gfx.beginPass(.{ .color = zia.math.Color.white, .pass = cameras[i].pass_3, .shader = &environments[i].environment_shader.shader });
        zia.gfx.draw.bindTexture(cameras[i].pass_1.color_texture, 1);
        zia.gfx.draw.bindTexture(cameras[i].pass_2.color_texture, 2);
        zia.gfx.draw.texture(cameras[i].pass_0.color_texture, .{}, .{ .color = environments[i].ambient_color });
        zia.gfx.endPass();
        zia.gfx.draw.batcher.flush();
        zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);

        // render the emission maps to the emission texture
        zia.gfx.beginPass(.{
            .color = zia.math.Color.black,
            .pass = cameras[i].pass_1,
            .trans_mat = camera_transform,
        });

        for (renderqueues[i].entities.items) |entity| {
            var position = world.get(entity, components.Position);

            if (world.get(entity, components.SpriteRenderer)) |renderer| {
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.index], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .flipX = renderer.flipX,
                    .flipY = renderer.flipY,
                    .color = zia.math.Color.black,
                });
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

            if (world.get(entity, components.CharacterRenderer)) |renderer| {
                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .flipX = renderer.flipBody,
                    .color = zia.math.Color.black,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .flipX = renderer.flipHead,
                    .color = zia.math.Color.black,
                });

                zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.hair], renderer.texture, .{
                    .x = position.?.x,
                    .y = position.?.y,
                }, .{
                    .flipX = renderer.flipHead,
                    .color = zia.math.Color.black,
                });

                if (renderer.emissionmap) |emissionmap| {
                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.body], emissionmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipBody,
                    });

                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.head], emissionmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipHead,
                    });

                    zia.gfx.draw.sprite(renderer.atlas.sprites[renderer.hair], emissionmap, .{
                        .x = position.?.x,
                        .y = position.?.y,
                    }, .{
                        .flipX = renderer.flipHead,
                    });
                }
            }
        }
        zia.gfx.endPass();

        renderqueues[i].entities.shrinkAndFree(0);

        postprocesses[i].bloom_shader.frag_uniform.tex_size_x = cameras[i].size.x;
        postprocesses[i].bloom_shader.frag_uniform.tex_size_y = cameras[i].size.y;
        postprocesses[i].bloom_shader.frag_uniform.horizontal = 1;
        postprocesses[i].bloom_shader.frag_uniform.multiplier = 1.2;

        zia.gfx.beginPass(.{ .color = zia.math.Color.black, .pass = cameras[i].pass_2, .shader = &postprocesses[i].bloom_shader.shader });
        zia.gfx.draw.texture(cameras[i].pass_1.color_texture, .{}, .{});
        zia.gfx.endPass();

        postprocesses[i].bloom_shader.frag_uniform.horizontal = 0;

        zia.gfx.beginPass(.{ .color = zia.math.Color.black, .pass = cameras[i].pass_4, .shader = &postprocesses[i].bloom_shader.shader });
        zia.gfx.draw.texture(cameras[i].pass_2.color_texture, .{}, .{});
        zia.gfx.endPass();

        postprocesses[i].finalize_shader.frag_uniform.texel_size = 8;
        postprocesses[i].finalize_shader.frag_uniform.tex_size_x = cameras[i].size.x;
        postprocesses[i].finalize_shader.frag_uniform.tex_size_y = cameras[i].size.y;

        zia.gfx.beginPass(.{ .pass = cameras[i].pass_5, .shader = &postprocesses[i].finalize_shader.shader });
        zia.gfx.draw.bindTexture(cameras[i].pass_4.color_texture, 1);
        zia.gfx.draw.bindTexture(cameras[i].pass_3.color_texture, 2);
        zia.gfx.draw.texture(cameras[i].pass_0.color_texture, .{}, .{});
        zia.gfx.endPass();
        zia.gfx.draw.unbindTexture(1);
        zia.gfx.draw.unbindTexture(2);

        postprocesses[i].tiltshift_shader.frag_uniform.blur_amount = 1;

        zia.gfx.beginPass(.{ .pass = cameras[i].pass_1, .shader = &postprocesses[i].tiltshift_shader.shader });
        zia.gfx.draw.texture(cameras[i].pass_5.color_texture, .{}, .{});
        zia.gfx.endPass();

        // render the result image to the back buffer
        zia.gfx.beginPass(.{ .trans_mat = rt_transform });
        zia.gfx.draw.texture(cameras[i].pass_1.color_texture, rt_pos, .{});
        zia.gfx.endPass();
    }
}

// top down sort
fn sort(world: *flecs.World, lhs: flecs.Entity, rhs: flecs.Entity) bool {
    const pos1 = world.get(lhs, components.Position);
    const pos2 = world.get(rhs, components.Position);

    if (pos1.?.z == pos2.?.z) {
        if (world.get(lhs, components.Tile)) |tile1| {
            if (world.get(rhs, components.Tile)) |tile2| {
                if (tile1.y == tile2.y)
                    return tile1.counter < tile2.counter;
            }
        }
        if (pos1.?.y == pos2.?.y) {
            return pos1.?.x < pos2.?.x;
        } else {
            return pos1.?.y < pos2.?.y;
        }
    } else {
        return pos1.?.z < pos2.?.z;
    }
}

// top down sort
fn reverseSort(world: *flecs.World, lhs: flecs.Entity, rhs: flecs.Entity) bool {
    const pos1 = world.get(lhs, components.Position);
    const pos2 = world.get(rhs, components.Position);

    if (pos1.?.z == pos2.?.z) {
        if (pos1.?.y == pos2.?.y) {
            return pos1.?.x < pos2.?.x;
        } else {
            return pos1.?.y > pos2.?.y;
        }
    } else {
        return pos1.?.z < pos2.?.z;
    }
}
