const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var cameras = it.column(components.Camera, 2);
    var renderqueues = it.column(components.RenderQueue, 3);

    var world = flecs.World{ .world = it.world.? };

    const camExp = 400; //pixels to expand camera bounds by

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var renderIt = flecs.ecs_query_iter(renderqueues[i].query);

        var cam_br = cameras[i].matrix.invert().transformVec2(.{ .x = @intToFloat(f32, zia.window.width() + camExp), .y = @intToFloat(f32, zia.window.height() + camExp) });
        var cam_tl = cameras[i].matrix.invert().transformVec2(.{ .x = -camExp, .y = -camExp });

        while (flecs.ecs_query_next(&renderIt)) {
            var j: usize = 0;
            while (j < renderIt.count) : (j += 1) {
                const entity = renderIt.entities[j];
                const position = world.get(entity, components.Position);

                //TODO: handle x and y flipping and take into account when finding the renderer bounds!

                if (world.get(entity, components.SpriteRenderer)) |renderer| {
                    const source = renderer.atlas.sprites[renderer.index].source;
                    const origin = renderer.atlas.sprites[renderer.index].origin;
                    const br = .{
                        .x = position.?.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                        .y = position.?.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                    };
                    const tl = .{
                        .x = position.?.x - @intToFloat(f32, origin.x),
                        .y = position.?.y - @intToFloat(f32, origin.y),
                    };

                    if (visible(cam_tl, cam_br, tl, br)) {
                        renderqueues[i].entities.append(renderIt.entities[j]) catch unreachable;
                        continue;
                    }
                }

                if (world.get(entity, components.CharacterRenderer)) |renderer| {
                    var source = renderer.atlas.sprites[renderer.head].source;
                    var origin = renderer.atlas.sprites[renderer.head].origin;
                    var br = .{
                        .x = position.?.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                        .y = position.?.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                    };
                    var tl = .{
                        .x = position.?.x - @intToFloat(f32, origin.x),
                        .y = position.?.y - @intToFloat(f32, origin.y),
                    };

                    if (visible(cam_tl, cam_br, tl, br)) {
                        renderqueues[i].entities.append(renderIt.entities[j]) catch unreachable;

                        // if (game.gizmos.enabled) {
                        //     game.gizmos.box(.{ .x = tl.x + (br.x - tl.x) / 2, .y = tl.y + (br.y - tl.y) / 2 }, br.x - tl.x, br.y - tl.y, zia.math.Color.yellow, 1);
                        // }
                        continue;
                    }

                    source = renderer.atlas.sprites[renderer.body].source;
                    origin = renderer.atlas.sprites[renderer.body].origin;
                    br = .{
                        .x = position.?.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                        .y = position.?.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                    };
                    tl = .{
                        .x = position.?.x - @intToFloat(f32, origin.x),
                        .y = position.?.y - @intToFloat(f32, origin.y),
                    };

                    if (visible(cam_tl, cam_br, tl, br)) {
                        renderqueues[i].entities.append(renderIt.entities[j]) catch unreachable;

                        // if (game.gizmos.enabled) {
                        //     game.gizmos.box(.{ .x = tl.x + (br.x - tl.x) / 2, .y = tl.y + (br.y - tl.y) / 2 }, br.x - tl.x, br.y - tl.y, zia.math.Color.yellow, 1);
                        // }
                        continue;
                    }
                }

                if (world.get(entity, components.LightRenderer)) |renderer| {
                    const source = renderer.atlas.sprites[renderer.index].source;
                    const origin = renderer.atlas.sprites[renderer.index].origin;
                    const br = .{
                        .x = position.?.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                        .y = position.?.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                    };
                    const tl = .{
                        .x = position.?.x - @intToFloat(f32, origin.x),
                        .y = position.?.y - @intToFloat(f32, origin.y),
                    };

                    if (visible(cam_tl, cam_br, tl, br)) {
                        renderqueues[i].entities.append(renderIt.entities[j]) catch unreachable;
                        continue;
                    }
                }
            }
        }
    }
}

// returns true if renderer bounds overlap the camera bounds
fn visible(cam_tl: zia.math.Vector2, cam_br: zia.math.Vector2, ren_tl: zia.math.Vector2, ren_br: zia.math.Vector2) bool {
    return (ren_tl.x < cam_br.x and ren_br.x > cam_tl.x and ren_tl.y < cam_br.y and ren_br.y > cam_tl.y);
}
