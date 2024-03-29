const std = @import("std");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");
const zia = @import("zia");
const sdl = @import("sdl");
const components = game.components;

pub const Callback = struct {
    pub const name = "MouseInputSystem";
    pub const run = progress;
    pub const modifiers = .{flecs.queries.Filter(components.Player)};
};

fn progress(it: *flecs.Iterator(Callback)) void {
    var world = it.world();

    while (it.next()) |_| {
        if (world.getSingletonMut(components.MousePosition)) |position| {
            if (world.getSingletonMut(components.MouseTile)) |tile| {
                if (game.camera.get(components.Camera)) |camera| {
                    var mouse_pos = camera.matrix.invert().transformVec2(zia.input.mousePos());
                    position.x = mouse_pos.x;
                    position.y = mouse_pos.y;

                    // hack because the first frame we are getting nan, nan for mouse position :(
                    if (std.math.isNan(position.x))
                        position.x = 0;

                    if (std.math.isNan(position.y))
                        position.y = 0;

                    tile.x = @floatToInt(i32, @round(position.x / @intToFloat(f32, game.ppu)));
                    tile.y = @floatToInt(i32, @round(position.y / @intToFloat(f32, game.ppu)));

                    if (zia.input.mousePressed(.left)) {
                        world.setSingleton(&components.MouseAction{
                            .x = tile.x,
                            .y = tile.y,
                            .button = .left,
                            .action = .down,
                        });
                    }

                    if (zia.input.mousePressed(.right)) {
                        world.setSingleton(&components.MouseAction{
                            .x = tile.x,
                            .y = tile.y,
                            .button = .right,
                            .action = .down,
                        });
                    }

                    if (zia.input.mouseUp(.right)) {
                        world.setSingleton(&components.MouseAction{
                            .x = tile.x,
                            .y = tile.y,
                            .button = .right,
                            .action = .up,
                        });
                    }

                    if (zia.input.mouseDown(.left)) {
                        sdl.SDL_SetCursor(game.cursors.hand);
                    }

                    if (zia.input.mouseUp(.left)) {
                        if (world.getSingleton(components.MouseAction)) |mouse_action| {
                            if (mouse_action.x != tile.x or mouse_action.y != tile.y) {
                                world.setSingleton(&components.MouseDrag{
                                    .start_x = mouse_action.x,
                                    .start_y = mouse_action.y,
                                    .end_x = tile.x,
                                    .end_y = tile.y,
                                    .modifier = if (zia.input.keyDown(.lshift) or zia.input.keyDown(.rshift)) .shift else .none,
                                });
                            }
                        }
                        sdl.SDL_SetCursor(game.cursors.normal);
                        world.removeSingleton(components.MouseAction);
                    }

                    // draw the hovered tile
                    if (game.enable_editor) {
                        game.gizmos.box(.{ .x = @intToFloat(f32, tile.x * game.ppu), .y = @intToFloat(f32, tile.y * game.ppu) }, game.ppu, game.ppu, zia.math.Color.fromBytes(255, 255, 255, 200), 1);
                    }
                }
            }
        }
    }
}
