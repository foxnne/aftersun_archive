const std = @import("std");
const imgui = @import("imgui");
const game = @import("game");
const flecs = @import("flecs");
const zia = @import("zia");
const components = @import("../ecs/components/components.zig");

var enable_debug_window: bool = false;

pub fn drawMenuBar() void {
    if (imgui.igBeginMainMenuBar()) {
        defer imgui.igEndMainMenuBar();

        if (imgui.igBeginMenu("View", true)) {
            defer imgui.igEndMenu();

            if (imgui.igMenuItemBool("Debug Window", "", enable_debug_window, true)) {
                enable_debug_window = !enable_debug_window;
            }
        }
    }
}

pub fn drawDebugWindow() void {
    if (!enable_debug_window)
        return;

    //imgui.igSetNextWindowPos(.{}, imgui.ImGuiCond_Always, .{});
    if (imgui.igBegin("Debug", &enable_debug_window, imgui.ImGuiWindowFlags_None)) {
        var stats = true;
        if (imgui.igCollapsingHeaderBoolPtr("Stats", &stats, imgui.ImGuiTreeNodeFlags_DefaultOpen)) {
            _ = imgui.igValueUint("FPS", @intCast(c_uint, zia.time.fps()));
        }

        var renderer = true;
        if (imgui.igCollapsingHeaderBoolPtr("Renderer", &renderer, imgui.ImGuiTreeNodeFlags_DefaultOpen)) {
             if (imgui.igRadioButtonBool("Diffuse", game.render_mode == .diffuse)){
                 game.render_mode = .diffuse;
             }
             if (imgui.igRadioButtonBool("Height", game.render_mode == .height)){
                 game.render_mode = .height;
             }
        }

        var player = true;
        if (imgui.igCollapsingHeaderBoolPtr("Player", &player, imgui.ImGuiTreeNodeFlags_None)) {

            
            if (game.player.getMut(components.Position)) |position| {

                if (imgui.igSliderFloat("Height", &position.z, 0, 256, "", imgui.ImGuiSliderFlags_None)) {
                
                }

            }


            const CellCallback = struct {
                cell: *const components.Cell,
            };

            var cell_filter = game.world.filter(CellCallback);
            var cell_it = cell_filter.iterator(CellCallback);

            while (cell_it.next()) |cells| {
                if (game.player.hasPair(flecs.c.EcsChildOf, cell_it.entity())) {
                    _ = imgui.igValueInt("Player Cell X", @intCast(c_int, cells.cell.x));
                    _ = imgui.igValueInt("Player Cell Y", @intCast(c_int, cells.cell.y));
                }
            }
        }
    }
    defer imgui.igEnd();
}
