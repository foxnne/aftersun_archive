const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");

/// adds all structs in this file to the world as new components
pub fn register(world: *flecs.World) void {
    const decls = @typeInfo(@This()).Struct.decls;
    inline for (decls) |decl| {
        if (decl.data == .Type and decl.is_pub)
            _ = world.newComponent(decl.data.Type);
    }
}

// generic
pub const Position = struct { x: f32 = 0, y: f32 = 0, z: i32 = 0 };
pub const Tile = struct { x: i32 = 0, y: i32 = 0, z: i32 = 0, counter: i32 = 0};
pub const PreviousTile = struct { x: i32 = 0, y: i32 = 0, z: i32 = 0 };
pub const Velocity = struct { x: f32 = 0, y: f32 = 0 };
pub const Subpixel = struct { x: f32 = 0, y: f32 = 0, vx: f32 = 0, vy: f32 = 0 };
pub const Speed = struct { value: f32 = 0 };

// tags

pub const Moveable = struct{};

// imports
pub usingnamespace @import("camera.zig");
pub usingnamespace @import("material.zig");
pub usingnamespace @import("input.zig");
pub usingnamespace @import("sprite.zig");
pub usingnamespace @import("character.zig");
pub usingnamespace @import("collision.zig");
pub usingnamespace @import("postprocess.zig");
pub usingnamespace @import("environment.zig");
pub usingnamespace @import("light.zig");
