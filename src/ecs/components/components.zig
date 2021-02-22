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

// tags
pub const Player = struct {};

// generic
pub const Position = struct { x: f32 = 0, y: f32 = 0, z: i32 = 0 };
pub const Velocity = struct { x: f32 = 0, y: f32 = 0 };
pub const Subpixel = struct { x: f32 = 0, y: f32 = 0, vx: f32 = 0, vy: f32 = 0 };
pub const Color = struct { color: zia.math.Color = zia.math.Color.white, };


pub usingnamespace @import("camera.zig");
pub usingnamespace @import("renderer.zig");
pub usingnamespace @import("input.zig");
pub usingnamespace @import("animator.zig");

pub const BodyDirection = struct {
    direction: zia.math.Direction = .S,
};

pub const HeadDirection = struct {
    direction: zia.math.Direction = .S,
};

