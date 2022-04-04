const zia = @import("zia");

pub const SpriteRenderer = struct {
    index: usize = 0,
    flipX: bool = false,
    flipY: bool = false,
    color: zia.math.Color = zia.math.Color.white,
    frag_mode: FragMode = .default,
    vert_mode: VertMode = .default,

    pub const FragMode = enum(u8) {
        default = 0,
        palette = 1,
    };

    pub const VertMode = enum(u8) {
        default = 0,
        sway = 1,
    };
};

pub const SpriteAnimator = struct {
    animation: []usize,
    frame: usize = 0,
    elapsed: f32 = 0,
    fps: usize = 8,
    state: State = State.pause,

    pub const State = enum {
        pause,
        play,
    };
};