const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("components.zig");

pub const Cell = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const Collider = struct {
    trigger: bool = false,
};


