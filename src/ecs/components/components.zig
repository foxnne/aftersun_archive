const zia = @import("zia");

pub const Position = struct { x: f32 = 0, y: f32 = 0, z: i32 = 0 };

pub const Subpixel = struct { x: f32 = 0, y: f32 = 0};

pub const Velocity = struct { x: f32 = 0, y: f32 = 0, sub_x: f32 = 0, sub_y: f32 = 0 };

pub const Camera = struct {
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

pub const Color = struct {
    color: zia.math.Color = zia.math.Color.white,
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
