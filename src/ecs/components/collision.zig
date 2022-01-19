const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("components.zig");

pub const Grid = struct {
    cellTiles: i32 = 2, //tiles wide/tall per cell

    pub const Cell = struct {
        x: i32 = 0,
        y: i32 = 0,
    };
};

pub const Collider = struct {
    cell: Grid.Cell = .{},
    trigger: bool = false,
};

pub const Broadphase = struct {
    entities: zia.utils.MultiHashMap(components.Grid.Cell, flecs.Entity),
};
