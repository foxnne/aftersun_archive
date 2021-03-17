const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("components.zig");

pub const Grid = struct {
    cellSize: i32 = 2, //cells wide/tall
    pixelsPerUnit: i32 = 32,
};

pub const Collider = struct {
    shape: Shape,
    cell: Cell = .{ .x = 0, .y = 0 },

    pub const Shape = union(enum) {
        circle: Circle,
        box: Box,
    };

    pub const Circle = struct {
        radius: f32,
    };

    pub const Box = struct {
        width: f32,
        height: f32,
    };

    pub const Cell = struct {
        x: i32 = 0,
        y: i32 = 0,
    };
};

pub const Broadphase = struct {
    entities: zia.utils.MultiHashMap(components.Collider.Cell, flecs.Entity),
};
