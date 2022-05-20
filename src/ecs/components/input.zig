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

pub const MouseAction = struct {
    x: i32 = 0,
    y: i32 = 0,
    button: Button = .left,
    action: Action = .down,

    pub const Button = enum { left, right };
    pub const Action = enum { up, down };
};

pub const MouseDrag = struct {
    start_x: i32 = 0,
    start_y: i32 = 0,
    end_x: i32 = 0,
    end_y: i32 = 0,
    modifier: Modifier = .none,

    pub const Modifier = enum {
        none,
        shift,
    };
};

pub const UseRequest = struct {
    target: flecs.EntityId,
};

pub const UseTarget = struct {
    x: i32,
    y: i32,
};

pub const UseCooldown = struct {
    current: f32 = 0,
    end: f32 = 0,
};
