const zia = @import("zia");
const flecs = @import("flecs");

pub const Position = struct { x: f32 = 0, y: f32 = 0, z: i32 = 0 };
pub const Velocity = struct { x: f32 = 0, y: f32 = 0};
pub const Subpixel = struct { x: f32 = 0, y: f32 = 0, vx: f32 = 0, vy: f32 = 0};

pub const Camera = struct {
    trans_mat: zia.math.Matrix3x2 = undefined,
    zoom_min: f32 = 1.0,
    zoom_max: f32 = 4.0,
    zoom: f32 = 1.0,
    zoom_target: f32 = 1.0,
    zoom_speed: f32 = 4.0,
    design_w: i32,
    design_h: i32,
};

pub const Zoom = struct {
    zoom_min: f32 = 1.0,
    zoom_max: f32 = 4.0,
    zoom_target: f32 = 1.0,
    zoom_speed: f32 = 4.0,
};

pub const Follow = struct {
    target: flecs.Entity,
    max_distance: f32 = 80,
    min_distance: f32 = 30,
    speed: f32 = 40.0,
};

pub const SpriteRenderer = struct {
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    index: usize = 0,
    flipX: bool = false,
    flipY: bool = false,
};

pub const CompositeRenderer = struct {
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    indices: []usize,
    colors: []usize,
};

pub const CompositeAnimator = struct {
    animations: [][]usize,
    elapsed: f32 = 0,
    fps: usize = 8,
    state: State = State.pause,

    pub const State = enum {
        pause,
        play,
    };
};

pub const Color = struct {
    color: zia.math.Color = zia.math.Color.white,
};

pub const SpriteAnimator = struct {
    animation: []usize,
    frame: usize = 0,
    elapsed: f32 = 0,
    fps: usize = 10,
    state: State = State.pause,

    pub const State = enum {
        pause,
        play,
    };
};

pub const MovementInput = struct {
    direction: zia.math.Direction = .None,
};

pub const BodyDirection = struct {
    direction: zia.math.Direction = .S,
    state: State = .idle,

    pub const State = enum {
        idle, walking
    };
};

pub const Grid = struct {
    cell_size: i32,
    x: i32, // offset x
    y: i32, // offset y
};

pub const ColliderShape = enum {
    box,
    circle
};

pub const Collider = struct {
    shape: ColliderShape,
    width: f32,
    height: f32,
    x: f32 = 0, // offset x
    y: f32 = 0, // offset y
};
