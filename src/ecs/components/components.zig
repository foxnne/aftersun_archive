const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

pub fn register(world: *flecs.World) void {
    const decls = @typeInfo(@import("components.zig")).Struct.decls;

    comptime var count: usize = 0;

    inline for (decls) |decl| {
        if (decl.data == .Type and decl.is_pub)
            count += 1;
    }

    comptime var types: [count]type = undefined;

    comptime var i: usize = 0;
    inline for (decls) |decl| {
        if (decl.data == .Type and decl.is_pub) {
            types[i] = decl.data.Type;
            i += 1;
        }
    }

    inline for (types) |t| {
        _ = world.newComponent(t);
    }
}

// generic
pub const Position = struct { x: f32 = 0, y: f32 = 0, z: i32 = 0 };
pub const Velocity = struct { x: f32 = 0, y: f32 = 0 };
pub const Subpixel = struct { x: f32 = 0, y: f32 = 0, vx: f32 = 0, vy: f32 = 0 };

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

pub usingnamespace @import("camera.zig");
pub usingnamespace @import("renderer.zig");
pub usingnamespace @import("input.zig");
pub usingnamespace @import("animator.zig");
pub usingnamespace @import("character.zig");


