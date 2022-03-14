const zia = @import("zia");
const flecs = @import("flecs");

pub const DirectionalInput = struct {
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

pub const MousePosition = struct {
    x: f32 = 0,
    y: f32 = 0,
};

pub const MouseTile = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const MouseDown = struct {
    x: i32 = 0,
    y: i32 = 0,
    button: Button = .left,

    pub const Button = enum { left, right };
};

pub const MouseDrag = struct {
    start_x: i32 = 0,
    start_y: i32 = 0,
    end_x: i32 = 0,
    end_y: i32 = 0,
};

pub const UseRequest = struct {
    x: i32 = 0,
    y: i32 = 0,
};
