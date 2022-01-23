const zia = @import("zia");
const flecs = @import("flecs");

pub const MovementInput = struct {
    direction: zia.math.Direction = .none,
};

pub const MovementCooldown = struct {
    current: f32 = 0,
    end: f32 = 0,
};

pub const MoveRequest = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
};

pub const MouseInput = struct {
    position: zia.math.Vector2 = .{},
    camera: flecs.Entity,
};

pub const MouseDragRequest = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
};

pub const MouseDown = struct {
    x: i32 = 0,
    y: i32 = 0,
};
pub const MouseDrag = struct {
    prev_x: i32 = 0,
    prev_y: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
};