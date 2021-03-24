const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

// adds all structs in this file to the world as new components
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

pub usingnamespace @import("camera.zig");
pub usingnamespace @import("material.zig");
pub usingnamespace @import("input.zig");
pub usingnamespace @import("sprite.zig");
pub usingnamespace @import("character.zig");
pub usingnamespace @import("collision.zig");
pub usingnamespace @import("postprocess.zig");
pub usingnamespace @import("environment.zig");
