const zia = @import("zia");

pub const Player = struct {};

pub const CharacterAnimator = struct {
    headAnimation: []usize,
    bodyAnimation: []usize,
    hairAnimation: []usize,
    topAnimation: []usize,
    bottomAnimation: []usize,
    frame: usize = 0,
    elapsed: f32 = 0,
    fps: usize = 8,
    state: State = State.idle,

    pub const State = enum {
        idle,
        walk
    };
};

pub const CharacterRenderer = struct {
    headIndex: usize,
    bodyIndex: usize,
    hairIndex: usize,
    topIndex: usize,
    bottomIndex: usize,
    headColor: zia.math.Color = zia.math.Color.fromBytes(0, 0, 0, 1),
    bodyColor: zia.math.Color = zia.math.Color.fromBytes(0, 0, 0, 1),
    hairColor: zia.math.Color = zia.math.Color.fromBytes(0, 0, 0, 1),
    topColor: zia.math.Color = zia.math.Color.fromBytes(0, 0, 0, 1),
    bottomColor: zia.math.Color = zia.math.Color.fromBytes(0, 0, 0, 1),
    flipBody: bool = false,
    flipHead: bool = false,
};

pub const BodyDirection = struct {
    direction: zia.math.Direction = .s,
};

pub const HeadDirection = struct {
    direction: zia.math.Direction = .s,
};

