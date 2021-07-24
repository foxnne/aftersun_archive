const std = @import("std");
const imgui = @import("imgui");
const game = @import("game");
const flecs = @import("flecs");
const zia = @import("zia");

var world: *flecs.World = undefined;

var enable_debug_window: bool = false;

pub fn init (_world: *flecs.World) void {
    //frames = std.ArrayList(f32).initCapacity(std.testing.allocator, 20) catch unreachable;
    world = _world;
}

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
        _ = imgui.igValueUint("FPS", @intCast(c_uint, zia.time.fps()));
        //_ = imgui.igValueUint("Entities", @intCast(c_uint,  ));

    


    }
    defer imgui.igEnd();
}
