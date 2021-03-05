const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("components.zig");

pub const Grid = struct {
    chunkSize: i32 = 2, //cells wide/tall
    cellWidth: i32 = 32,
    cellHeight: i32 = 32
};

pub const Collider = struct {
    shape: Shape,
    chunk: Chunk = .{ .x = 0, .y = 0 },

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

    pub const Chunk = struct {
        x: i32 = 0,
        y: i32 = 0,
    };
};

pub const Broadphase = struct {
    entities: zia.utils.MultiHashMap(components.Collider.Chunk, flecs.Entity),
};
