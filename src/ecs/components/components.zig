const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");

/// adds all structs in this file to the world as new components
pub fn register(world: flecs.World) void {
    const decls = @typeInfo(@This()).Struct.decls;
    inline for (decls) |decl| {
        if (decl.data == .Type and decl.is_pub)
            _ = world.registerComponent(decl.data.Type);
    }
}

// imports
pub usingnamespace @import("camera.zig");
pub usingnamespace @import("input.zig");
pub usingnamespace @import("sprite.zig");
pub usingnamespace @import("character.zig");
pub usingnamespace @import("collision.zig");
pub usingnamespace @import("environment.zig");
pub usingnamespace @import("light.zig");
pub usingnamespace @import("particles.zig");
pub usingnamespace @import("weather.zig");

// generic
pub const Position = struct { x: f32 = 0, y: f32 = 0, z: f32 = 0 };
pub const Tile = struct { x: i32 = 0, y: i32 = 0, z: i32 = 0, counter: u64 = 0};
pub const PreviousTile = struct { x: i32 = 0, y: i32 = 0, z: i32 = 0 };
pub const Velocity = struct { x: f32 = 0, y: f32 = 0 };
pub const Speed = struct { value: f32 = 0 };

// tags
pub const Moveable = struct{};
pub const Useable = struct{};
pub const Cook = struct{};
pub const Fire = struct{};

// relations
pub const Item = struct {
    id: u64,
};

pub const Stackable = struct{
    indices: []usize = undefined,
};

pub const Count = struct {
    value: usize,
};
pub const StackRequest = struct {
    count: i32,
    other: ?flecs.Entity = null,
};  
pub const UseRecipe = struct {
    primary: flecs.EntityId,
    secondary: ?flecs.EntityId = null,
    tertiary: ?flecs.EntityId = null, 
    not: ?flecs.EntityId = null,
    produces: ?flecs.Entity = null,
    consumes: Consumes = .none,
    
    pub const Consumes = enum {
        none,
        self,
        other,
        both,
    };
};



