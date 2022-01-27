const std = @import("std");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");
const zia = @import("zia");
const sdl = @import("sdl");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var input = it.term(components.MouseInput, 1);
    var tile = it.term(components.Tile, 2);
    var world = flecs.World{ .world = it.world.? };

    var camera_ptr = world.get(input.*.camera, components.Camera);
    if (camera_ptr) |camera| {
        input.*.position = camera.matrix.invert().transformVec2(zia.input.mousePos());

        // hack because the first frame we are getting nan, nan for mouse position :(
        if (std.math.isNan(input.*.position.x))
            input.*.position.x = 0;

        if (std.math.isNan(input.*.position.y))
            input.*.position.y = 0;

        tile.*.x = @floatToInt(i32, @round(input.*.position.x / @intToFloat(f32, game.ppu)));
        tile.*.y = @floatToInt(i32, @round(input.*.position.y / @intToFloat(f32, game.ppu)));

        if (zia.input.mousePressed(.left)) {
            world.setSingleton(&components.MouseDown{
                .x = tile.*.x,
                .y = tile.*.y,
            });

            
        }

        if (zia.input.mouseDown(.left)) {
            sdl.SDL_SetCursor(game.cursors.hand);
            
        }


        if (zia.input.mouseUp(.left)) {
            if (world.getSingleton(components.MouseDown)) |mouse_down| {
                if (mouse_down.x != tile.*.x or mouse_down.y != tile.*.y) {
                    //drag

                    world.setSingleton(&components.MouseDrag{
                        .prev_x = mouse_down.x,
                        .prev_y = mouse_down.y,
                        .x = tile.*.x,
                        .y = tile.*.y,
                    });
    
                }
            }
            sdl.SDL_SetCursor(game.cursors.normal);
            world.removeSingleton(components.MouseDown);
        }

        // draw the hovered tile
        if (game.enable_editor) {
            game.gizmos.box(.{ .x = @intToFloat(f32, tile.*.x * game.ppu), .y = @intToFloat(f32, tile.*.y * game.ppu) }, game.ppu, game.ppu, zia.math.Color.gray, 1);
        }
    }
}
