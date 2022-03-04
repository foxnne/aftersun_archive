const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("components.zig");

pub const Grid = struct {
    cellTiles: i32 = 8, //tiles wide/tall per cell

};

pub const Cell = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const Collider = struct {
    trigger: bool = false,
};

pub const CollisionBroadphase = struct {
    entities: zia.utils.MultiHashMap(components.Cell, flecs.Entity),
};


