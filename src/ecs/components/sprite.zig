const zia = @import("zia");

pub const SpriteRenderer = struct {
    texture: zia.gfx.Texture,
    heightmap: ?zia.gfx.Texture = null,
    //emissionmap: ?zia.gfx.Texture = null,
    atlas: zia.gfx.Atlas,
    index: usize = 0,
    flipX: bool = false,
    flipY: bool = false,
    color: zia.math.Color = zia.math.Color.white,
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