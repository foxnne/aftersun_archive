const std = @import("std");
const flecs = @import("flecs");
const zia = @import("zia");

pub const Camera = struct {
    matrix: zia.math.Matrix3x2 = undefined,
    transform: zia.math.Matrix3x2 = undefined,
    rt_position: zia.math.Vector2 = .{},
    rt_transform: zia.math.Matrix3x2 = undefined,
    size: zia.math.Vector2 = .{},
    margin: i32 = 400,
    pass_0: zia.gfx.OffscreenPass,
    pass_1: zia.gfx.OffscreenPass,
    pass_2: zia.gfx.OffscreenPass,
    pass_3: zia.gfx.OffscreenPass,
    pass_4: zia.gfx.OffscreenPass,
    pass_5: zia.gfx.OffscreenPass,
};

pub const Visible = struct {};

pub const RenderQueue = struct {
    query: ?*flecs.Query,
    entities: std.ArrayList(flecs.Entity),
};

pub const Zoom = struct {
    min: f32 = 1.0,
    max: f32 = 4.0,
    current: f32 = 1.0,
    target: f32 = 1.0,
    speed: f32 = 4.0,
};

pub const Follow = struct {
    target: flecs.Entity,
    max_distance: f32 = 50,
    min_distance: f32 = 10,
    easing: f32 = 0.05,
};
