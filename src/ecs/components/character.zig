const zia = @import("zia");

pub const CharacterAnimator = struct {
    headAnimation: []usize,
    bodyAnimation: []usize,
    frame: usize = 0,
    elapsed: f32 = 0,
    fps: usize = 8,
    state: State = State.pause,

    pub const State = enum {
        idle,
        walk
    };
};

pub const CharacterRenderer = struct {
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    head: usize,
    body: usize,
    headColor: zia.math.Color = zia.math.Color.white,
    bodyColor: zia.math.Color = zia.math.Color.white,
    flipX: bool = false,
    flipBody: bool = false,
    flipHead: bool = false,
};

pub const BodyDirection = struct {
    direction: zia.math.Direction = .S,
};

pub const HeadDirection = struct {
    direction: zia.math.Direction = .S,
};

