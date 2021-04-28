const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");

pub const Gizmos = struct {
    enabled: bool = false,
    gizmos: std.ArrayList(Gizmo),

    pub fn line(self: *Gizmos, start: zia.math.Vector2, end: zia.math.Vector2, color: zia.math.Color, thickness: f32) void {
        self.gizmos.append(.{ .shape = .{ .line = .{
            .start = start,
            .end = end,
            .color = color,
            .thickness = thickness,
        } } }) catch unreachable;
    }

    pub fn box(self: *Gizmos, position: zia.math.Vector2, width: f32, height: f32, color: zia.math.Color, thickness: f32) void {
        self.gizmos.append(.{ .shape = .{ .box = .{
            .width = width,
            .height = height,
            .position = .{ .x = position.x - width / 2, .y = position.y - height / 2 },
            .color = color,
            .thickness = thickness,
        } } }) catch unreachable;
    }

    pub fn circle(self: *Gizmos, position: zia.math.Vector2, radius: f32, color: zia.math.Color, thickness: f32) void {
        self.gizmos.append(.{ .shape = .{ .circle = .{
            .radius = radius,
            .position = position,
            .color = color,
            .thickness = thickness,
        } } }) catch unreachable;
    }
};

pub const Gizmo = struct {
    shape: Shape,

    pub const Shape = union(enum) {
        circle: Circle,
        line: Line,
        box: Box,
    };

    pub const Circle = struct {
        radius: f32,
        position: zia.math.Vector2,
        color: zia.math.Color,
        thickness: f32 = 1,
    };

    pub const Line = struct {
        start: zia.math.Vector2,
        end: zia.math.Vector2,
        color: zia.math.Color,
        thickness: f32 = 1,
    };

    pub const Box = struct {
        width: f32,
        height: f32,
        position: zia.math.Vector2,
        color: zia.math.Color,
        thickness: f32 = 1,
    };
};
