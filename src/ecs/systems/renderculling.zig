const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    const positions = it.term(components.Position, 1);
    const character_renderers_optional = it.term_optional(components.CharacterRenderer, 2);
    const sprite_renderers_optional = it.term_optional(components.SpriteRenderer, 3);
    const light_renderers_optional = it.term_optional(components.LightRenderer, 4);

    if (world.get(game.camera, components.Camera)) |camera| {
        const cam_br = camera.matrix.invert().transformVec2(.{ .x = @intToFloat(f32, zia.window.width() + camera.margin), .y = @intToFloat(f32, zia.window.height() + camera.margin) });
        const cam_tl = camera.matrix.invert().transformVec2(.{ .x = -@intToFloat(f32, camera.margin), .y = -@intToFloat(f32, camera.margin) });

        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            if (sprite_renderers_optional) |renderers| {
                const source = renderers[i].atlas.sprites[renderers[i].index].source;
                const origin = renderers[i].atlas.sprites[renderers[i].index].origin;
                const br = .{
                    .x = positions[i].x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = positions[i].y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                const tl = .{
                    .x = positions[i].x - @intToFloat(f32, origin.x),
                    .y = positions[i].y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    world.add(it.entities[i], components.Visible);
                    continue;
                } else {
                    world.remove(it.entities[i], components.Visible);
                    continue;
                }
            }

            if (character_renderers_optional) |renderers| {
                var source = renderers[i].atlas.sprites[renderers[i].head].source;
                var origin = renderers[i].atlas.sprites[renderers[i].head].origin;
                var br = .{
                    .x = positions[i].x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = positions[i].y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                var tl = .{
                    .x = positions[i].x - @intToFloat(f32, origin.x),
                    .y = positions[i].y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    world.add(it.entities[i], components.Visible);

                    continue;
                }
                 
                
                

                source = renderers[i].atlas.sprites[renderers[i].body].source;
                origin = renderers[i].atlas.sprites[renderers[i].body].origin;
                br = .{
                    .x = positions[i].x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = positions[i].y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                tl = .{
                    .x = positions[i].x - @intToFloat(f32, origin.x),
                    .y = positions[i].y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    world.add(it.entities[i], components.Visible);
                    
                    continue;
                } else {
                    world.remove(it.entities[i], components.Visible);
                    continue;
                }
            }

            if (light_renderers_optional) |renderers| {
                const source = renderers[i].atlas.sprites[renderers[i].index].source;
                const origin = renderers[i].atlas.sprites[renderers[i].index].origin;
                const br = .{
                    .x = positions[i].x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = positions[i].y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                const tl = .{
                    .x = positions[i].x - @intToFloat(f32, origin.x),
                    .y = positions[i].y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    world.add(it.entities[i], components.Visible);
                    continue;
                } else {
                    world.remove(it.entities[i], components.Visible);
                    continue;
                }
            }
        }
    }
}

// returns true if renderer bounds overlap the camera bounds
fn visible(cam_tl: zia.math.Vector2, cam_br: zia.math.Vector2, ren_tl: zia.math.Vector2, ren_br: zia.math.Vector2) bool {
    return (ren_tl.x < cam_br.x and ren_br.x > cam_tl.x and ren_tl.y < cam_br.y and ren_br.y > cam_tl.y);
}
