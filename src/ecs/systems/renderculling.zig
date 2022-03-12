const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    position: *components.Position,
    character_renderer: ?*components.CharacterRenderer,
    sprite_renderer: ?*components.SpriteRenderer,
    light_renderer: ?*components.LightRenderer,

    pub const name = "RenderCullingSystem";
    pub const run = progress;
    pub const expr = "[out] Visible()";
};

fn progress(it: *flecs.Iterator(Callback)) void {
    if (game.camera.get(components.Camera)) |camera| {
        const cam_br = camera.matrix.invert().transformVec2(.{ .x = @intToFloat(f32, zia.window.width() + camera.margin), .y = @intToFloat(f32, zia.window.height() + camera.margin) });
        const cam_tl = camera.matrix.invert().transformVec2(.{ .x = -@intToFloat(f32, camera.margin), .y = -@intToFloat(f32, camera.margin) });

        while (it.next()) |comps| {
            if (comps.sprite_renderer) |renderer| {
                const source = game.atlas.sprites[renderer.index].source;
                const origin = game.atlas.sprites[renderer.index].origin;
                const br = .{
                    .x = comps.position.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = comps.position.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                const tl = .{
                    .x = comps.position.x - @intToFloat(f32, origin.x),
                    .y = comps.position.y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    it.entity().add(components.Visible);
                    continue;
                } else {
                    it.entity().remove(components.Visible);
                    continue;
                }
            }

            if (comps.character_renderer) |renderer| {
                var source = game.atlas.sprites[renderer.headIndex].source;
                var origin = game.atlas.sprites[renderer.headIndex].origin;
                var br = .{
                    .x = comps.position.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = comps.position.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                var tl = .{
                    .x = comps.position.x - @intToFloat(f32, origin.x),
                    .y = comps.position.y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    it.entity().add(components.Visible);

                    continue;
                }

                source = game.atlas.sprites[renderer.bodyIndex].source;
                origin = game.atlas.sprites[renderer.bodyIndex].origin;
                br = .{
                    .x = comps.position.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = comps.position.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                tl = .{
                    .x = comps.position.x - @intToFloat(f32, origin.x),
                    .y = comps.position.y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    it.entity().add(components.Visible);

                    continue;
                } else {
                    it.entity().remove(components.Visible);
                    continue;
                }
            }

            if (comps.light_renderer) |renderer| {
                const source = game.atlas.sprites[renderer.index].source;
                const origin = game.atlas.sprites[renderer.index].origin;
                const br = .{
                    .x = comps.position.x + @intToFloat(f32, source.width) - @intToFloat(f32, origin.x),
                    .y = comps.position.y + @intToFloat(f32, source.height) - @intToFloat(f32, origin.y),
                };
                const tl = .{
                    .x = comps.position.x - @intToFloat(f32, origin.x),
                    .y = comps.position.y - @intToFloat(f32, origin.y),
                };

                if (visible(cam_tl, cam_br, tl, br)) {
                    it.entity().add(components.Visible);
                    continue;
                } else {
                    it.entity().remove(components.Visible);
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
