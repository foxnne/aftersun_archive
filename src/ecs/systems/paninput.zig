const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const imgui = @import("imgui");
const components = lucid.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var input = it.column(components.PanInput, 1);

    var margin: f32 = 40;
    var size = zia.window.drawableSize();
    var size_w = @intToFloat(f32, size.w);
    var size_h = @intToFloat(f32, size.h);
    var center_pos = .{ .x = size_w / 2, .y = size_h / 2 };
    var mouse_pos = zia.input.mousePos();

    if (mouse_pos.x < margin or mouse_pos.x > size_w - margin or mouse_pos.y < margin or mouse_pos.y > size_h - margin) {
        input.*.direction = zia.math.Direction.find(8, mouse_pos.x - center_pos.x, mouse_pos.y - center_pos.y);
    } else {
        input.*.direction = .None;
    }
}
